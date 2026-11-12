"""Compact spectral reconstruction. Fresh nested donor CV; no cached predictions.

Input/response scaling, PCA and score scaling are fitted inside each split.
Selection uses donor-weighted spectral MSE, never diagnostic categories/ratios.
Matches the explicitly checked PCA_TANH analysis, not sklearn MLPRegressor.
"""
import argparse
import hashlib
import itertools
import json
import platform
import time
import warnings
from pathlib import Path

import numpy as np
import scipy
from scipy import io, linalg, optimize
from threadpoolctl import threadpool_limits


def scale(a):
    mu = a.mean(0)
    sd = a.std(0, ddof=1)
    sd[sd == 0] = 1
    return (a - mu) / sd, mu, sd


def neural_objective(theta, z, t, h, alpha):
    n, p = z.shape
    k = t.shape[1]
    a = p*h; b = a+h; c = b+h*k
    w1 = theta[:a].reshape(p, h); b1 = theta[a:b]
    w2 = theta[b:c].reshape(h, k); b2 = theta[c:]
    hidden = np.tanh(z @ w1 + b1)
    error = hidden @ w2 + b2 - t
    loss = (np.sum(error**2) + alpha*(np.sum(w1**2)+np.sum(w2**2)))/(2*n)
    delta = error/n
    delta1 = (delta @ w2.T)*(1-hidden**2)
    grad = np.concatenate([(z.T @ delta1 + alpha*w1/n).ravel(), delta1.sum(0),
                           (hidden.T @ delta + alpha*w2/n).ravel(), delta.sum(0)])
    return loss, grad


def fit_predict(a, b, q, param, seed, maxiter):
    a, xm, xs = scale(a)
    b, ym, ys = scale(b)
    q = (q-xm)/xs
    ux, sx, vx = linalg.svd(a, full_matrices=False, check_finite=False)
    uy, sy, vy = linalg.svd(b, full_matrices=False, check_finite=False)
    px, py, h = param['input_pcs'], param['output_pcs'], param['hidden']
    for s, shape, count in [(sx, a.shape, px), (sy, b.shape, py)]:
        rank = np.count_nonzero(s > max(shape)*np.finfo(float).eps*s[0])
        if count > rank:
            raise ValueError(f'PCA requests {count} components but training rank is {rank}. '
                             'Reduce the PCA grid/response components; no silent truncation.')
    # Keep SVD signs and score arithmetic identical to the validated reference.
    z = (ux*sx)[:, :px]; zs = z.std(0, ddof=1)
    t = (uy*sy)[:, :py]; ts = t.std(0, ddof=1)
    zq = q @ vx[:px].T
    z, t, zq = z/zs, t/ts, zq/zs
    rng = np.random.default_rng(seed)
    theta = np.concatenate([rng.normal(0, np.sqrt(2/(px+h)), size=px*h), np.zeros(h),
                            rng.normal(0, np.sqrt(2/(h+py)), size=h*py), np.zeros(py)])
    result = optimize.minimize(neural_objective, theta, args=(z, t, h, param['alpha']),
        jac=True, method='L-BFGS-B', options={'maxiter': maxiter, 'maxls': 50,
                                            'gtol': 1e-6, 'ftol': 1e-10})
    a1 = px*h; b1 = a1+h; c1 = b1+h*py; theta = result.x
    yp = np.tanh(zq @ theta[:a1].reshape(px, h)+theta[a1:b1]) @ theta[b1:c1].reshape(h, py)+theta[c1:]
    pred = ((yp*ts) @ vy[:py])*ys+ym
    if not np.isfinite(pred).all():
        raise ValueError('Compact MLP produced non-finite predictions.')
    return pred, {'seed': int(seed), 'iterations': int(result.nit),
        'convergence_warning': not bool(result.success), 'message': str(result.message),
        'gradient_norm': float(np.linalg.norm(result.jac)), 'parameters': (px+1)*h+(h+1)*py,
        'output_variance_retained': float(np.sum(sy[:py]**2)/np.sum(sy**2))}


def vector(cfg, key, dtype):
    return np.atleast_1d(cfg[key]).astype(dtype).tolist()


def reconstruct(x, y, groups, cfg):
    x, y = np.asarray(x, dtype=float), np.asarray(y, dtype=float)
    groups = np.asarray(groups, dtype=str).reshape(-1)
    if x.ndim != 2 or y.ndim != 2 or len(x) != len(y) or len(x) != len(groups):
        raise ValueError('X, Y and donor IDs must contain matching rows.')
    if not np.isfinite(x).all() or not np.isfinite(y).all() or np.any(groups == ''):
        raise ValueError('Matrices must be finite and donor IDs nonempty.')
    ids = np.unique(groups)
    folds = int(cfg['compactInnerFolds'])
    if not 2 <= folds <= len(ids)-1:
        raise ValueError('Inner folds must be between 2 and the number of outer-training donors.')
    grid = [dict(input_pcs=p, output_pcs=int(cfg['compactOutputPCs']), hidden=h, alpha=a)
            for p, h, a in itertools.product(vector(cfg, 'compactInputPCGrid', int),
                vector(cfg, 'compactHiddenGrid', int), vector(cfg, 'compactAlphaGrid', float))]
    seeds = vector(cfg, 'compactSeeds', int)
    if not grid or not seeds or len(seeds) != len(set(seeds)):
        raise ValueError('A nonempty grid and distinct initialization seeds are required.')
    pred = np.full_like(y, np.nan); logs = []; start = time.time()
    for cid in ids:
        te = groups == cid; tr = ~te
        train_ids = ids[ids != cid].copy()
        np.random.default_rng(int(cfg['compactInnerSeed'])).shuffle(train_ids)
        validation = np.array_split(train_ids, folds)
        losses = np.zeros(len(grid)); inner_warnings = 0
        for vg in validation:
            va = tr & np.isin(groups, vg); ft = tr & ~va
            for j, param in enumerate(grid):
                p, meta = fit_predict(x[ft], y[ft], x[va], param, seeds[0], int(cfg['compactMaxIterations']))
                inner_warnings += int(meta['convergence_warning'])
                error = np.mean((p-y[va])**2, axis=1)
                losses[j] += sum(error[groups[va] == g].mean() for g in vg)
        losses /= len(train_ids)
        selected = grid[int(np.argmin(losses))]
        predictions = []; fits = []
        for seed in seeds:
            p, meta = fit_predict(x[tr], y[tr], x[te], selected, seed, int(cfg['compactMaxIterations']))
            predictions.append(p); fits.append(meta)
        pred[te] = np.mean(predictions, axis=0)
        logs.append(dict(held_out=str(cid), training_donors=train_ids.tolist(),
            inner_validation_donors=[v.tolist() for v in validation], selected=selected,
            inner_losses=losses.tolist(), inner_nonconverged_fits=inner_warnings, fits=fits))
        print(f'Compact PCA + MLP: donor {len(logs)}/{len(ids)}; '
              f'{time.time()-start:.1f} seconds', flush=True)
    count = sum(f['convergence_warning'] for entry in logs for f in entry['fits'])
    inner_count = sum(entry['inner_nonconverged_fits'] for entry in logs)
    if count or inner_count:
        warnings.warn(f'Convergence warnings: {count} final and {inner_count} inner fits. '
                      'Inspect tuning diagnostics before interpreting results.')
    return pred, dict(model='PCA_MLP', validation='nested leave-one-donor-out',
        selection_metric='donor-weighted mean squared spectral error', grid=grid, folds=logs,
        configuration=cfg, final_nonconverged_fits=count, inner_nonconverged_fits=inner_count,
        python=platform.python_version(), numpy=np.__version__, scipy=scipy.__version__,
        backend_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        seconds=time.time()-start, ensemble='equal mean; first initialization used for inner tuning',
        optimizer=dict(method='L-BFGS-B', maxls=50, gtol=1e-6, ftol=1e-10))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', required=True)
    parser.add_argument('--output', required=True)
    parser.add_argument('--metadata', required=True)
    args = parser.parse_args()
    data = io.loadmat(args.input, simplify_cells=True)
    cfg = json.loads(str(data['configJson']))
    with threadpool_limits(limits=1):
        pred, log = reconstruct(data['X'], data['Y'], data['rowIDs'], cfg)
    io.savemat(args.output, {'predictions': pred})
    Path(args.metadata).write_text(json.dumps(log, indent=2, allow_nan=False), encoding='utf-8')


if __name__ == '__main__':
    main()

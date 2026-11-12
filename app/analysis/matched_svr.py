"""Fresh nested SVR fit for the MATLAB matched-comparison mode.

Only reads MATLAB's current predictor matrix/outcomes/options, never reference
predictions or saved tuning. See requirements_matched_svr.txt for tested versions.
"""
import os
for key in ('OMP_NUM_THREADS', 'MKL_NUM_THREADS', 'OPENBLAS_NUM_THREADS'):
    os.environ[key] = '1'
import argparse
import itertools
import json
import platform
import numpy as np
import scipy
import sklearn
from scipy.io import loadmat
from sklearn.model_selection import KFold
from sklearn.svm import SVR
from threadpoolctl import threadpool_limits


def run(data):
    X = np.asarray(data['X'], dtype=float)
    y = np.asarray(data['y'], dtype=float).ravel()
    groups = np.asarray(data['groups'], dtype=int).ravel()
    ids = list(dict.fromkeys(groups.tolist()))
    K = min(int(data['K']), len(ids)-1)
    seed = int(data['seed'])
    if len(ids) < 4 or K < 2 or X.shape[0] != len(y) or not np.isfinite(y).all():
        raise ValueError('Need aligned finite outcomes and at least four donors.')
    block_sizes = np.atleast_1d(data['blockSizes']).astype(int).ravel()
    standardize = bool(data['standardize'])
    candidates = list(itertools.product(
        np.atleast_1d(data['cGrid']).ravel().tolist(),
        np.atleast_1d(data['eGrid']).ravel().tolist(),
        np.atleast_1d(data['sGrid']).ravel().tolist()))
    if not candidates or any(c<=0 or e<0 or s<=0 for c,e,s in candidates):
        raise ValueError('Invalid SVR parameter grid.')

    def prepare(train, test):
        A = X[train].copy(); Q = X[test].copy()
        A[~np.isfinite(A)] = np.nan; Q[~np.isfinite(Q)] = np.nan
        med = np.nanmedian(A, axis=0); med[~np.isfinite(med)] = 0
        A = np.where(np.isfinite(A), A, med)
        Q = np.where(np.isfinite(Q), Q, med)
        if standardize:
            mean = A.mean(axis=0); sd = A.std(axis=0, ddof=1)
            sd[(sd==0) | ~np.isfinite(sd)] = 1
            A = (A-mean)/sd; Q = (Q-mean)/sd
            if len(block_sizes):
                if any(block_sizes<1) or sum(block_sizes)!=X.shape[1]:
                    raise ValueError('Block sizes must cover all columns.')
                # Separate division, matching the original two-block pipeline.
                start = 0
                for size in block_sizes:
                    A[:, start:start+size] /= np.sqrt(size)
                    Q[:, start:start+size] /= np.sqrt(size)
                    start += size
        elif len(block_sizes):
            raise ValueError('Block scaling requires standardization.')
        return A, Q

    def predict(A, b, Q, param):
        c, e, s = param
        return SVR(C=c, epsilon=e, kernel='rbf', gamma=1/(2*s**2),
                   tol=1e-3, shrinking=True).fit(A, b).predict(Q)

    predictions = np.full(len(y), np.nan); tuning = []
    with threadpool_limits(limits=1):
        for outer, held in enumerate(ids):
            train = groups != held; test = ~train
            train_ids = np.array([g for g in ids if g != held])
            folds = np.zeros(len(train_ids), dtype=int)
            loss = np.zeros(len(candidates))
            for fold, (ti, vi) in enumerate(KFold(K, shuffle=True, random_state=seed).split(train_ids)):
                fit = np.isin(groups, train_ids[ti]); val = np.isin(groups, train_ids[vi])
                folds[vi] = fold+1
                A, Q = prepare(fit, val)
                for j, param in enumerate(candidates):
                    p = predict(A, y[fit], Q, param)
                    loss[j] += np.sum((p-y[val])**2)
            best = int(np.argmin(loss)); A, Q = prepare(train, test)
            predictions[test] = predict(A, y[train], Q, candidates[best])
            c, e, s = candidates[best]
            tuning.append(dict(Group=int(held), BoxConstraint=c, Epsilon=e, KernelScale=s,
                               InnerRMSE=float(np.sqrt(loss[best]/sum(train))), InnerFolds=K,
                               InnerGroups=train_ids.tolist(), InnerFold=folds.tolist(),
                               Candidates=candidates, CandidateMSE=(loss/sum(train)).tolist()))
            print(f'SVR matched {K}-fold: outer donor {outer+1}/{len(ids)}', flush=True)
    return dict(predictions=predictions.tolist(), tuning=tuning,
                environment=dict(python=platform.python_version(), numpy=np.__version__,
                                 scipy=scipy.__version__, sklearn=sklearn.__version__),
                solver='sklearn.svm.SVR; RBF gamma=1/(2*sigma^2); tol=0.001; shrinking=True')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', required=True); parser.add_argument('--output', required=True)
    args = parser.parse_args()
    result = run(loadmat(args.input, squeeze_me=True))
    with open(args.output, 'w', encoding='utf-8') as handle:
        json.dump(result, handle, indent=2, allow_nan=False)

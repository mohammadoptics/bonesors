"""Fast independent numerical and donor-isolation tests (no research data)."""
import contextlib
import io
import sys
import unittest
from pathlib import Path
import numpy as np
from scipy.optimize import check_grad
from threadpoolctl import threadpool_limits
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from compact_mlp_reconstruct import neural_objective, reconstruct


class CompactTests(unittest.TestCase):
    def test_gradient(self):
        rng = np.random.default_rng(13)
        z = rng.normal(size=(9, 3)); t = rng.normal(size=(9, 2)); theta = rng.normal(size=26)
        err = check_grad(lambda w: neural_objective(w, z, t, 4, 1)[0],
                         lambda w: neural_objective(w, z, t, 4, 1)[1], theta)
        self.assertLess(err, 1e-5)

    def test_nested_isolation_and_repeatability(self):
        rng = np.random.default_rng(71)
        x = rng.normal(size=(12, 8)); y = rng.normal(size=(12, 7))
        groups = np.repeat(['a', 'b', 'c', 'd', 'e', 'f'], 2)
        cfg = dict(compactInputPCGrid=[2], compactOutputPCs=2, compactHiddenGrid=[2],
            compactAlphaGrid=[1], compactInnerFolds=2, compactInnerSeed=41,
            compactSeeds=[7, 17], compactMaxIterations=1500)
        with threadpool_limits(1), contextlib.redirect_stdout(io.StringIO()):
            p, meta = reconstruct(x, y, groups, cfg)
            p2, _ = reconstruct(x, y, groups, cfg)
            changed = y.copy(); changed[groups == 'a'] += 100
            p3, meta3 = reconstruct(x, changed, groups, cfg)
        np.testing.assert_array_equal(p, p2)
        np.testing.assert_array_equal(p[groups == 'a'], p3[groups == 'a'])
        self.assertEqual(meta['folds'][0]['selected'], meta3['folds'][0]['selected'])
        for fold in meta['folds']:
            self.assertNotIn(fold['held_out'], fold['training_donors'])
            self.assertEqual(len(fold['fits']), 2)
            self.assertNotIn(fold['held_out'], sum(fold['inner_validation_donors'], []))
        cfg['compactInputPCGrid'] = [100]
        with self.assertRaisesRegex(ValueError, 'training rank'):
            reconstruct(x, y, groups, cfg)


if __name__ == '__main__':
    unittest.main()

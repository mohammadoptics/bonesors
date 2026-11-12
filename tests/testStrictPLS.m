function tests = testStrictPLS
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
rootFolder = fileparts(fileparts(mfilename('fullpath')));
testCase.TestData.OriginalPath = path;
addpath(rootFolder);
addpath(fullfile(rootFolder, 'analysis'));
end

function teardownOnce(testCase)
path(testCase.TestData.OriginalPath);
end

function testNestedPLSReturnsOnePredictionAndRankPerCadaver(testCase)
[X, y, ids] = localSyntheticData();
[yPred, ranks, tuning] = localPredictTscorePLS(X, y, ids, 4, [], true);

verifySize(testCase, yPred, size(y));
verifySize(testCase, ranks, size(y));
verifyTrue(testCase, all(isfinite(yPred)));
verifyTrue(testCase, all(ranks >= 1 & ranks <= 4));
verifyEqual(testCase, numel(tuning), numel(unique(ids)));
verifyTrue(testCase, all(isfinite([tuning.InnerRMSE])));
verifyFalse(testCase, any([tuning.FixedRank]));
end

function testHeldOutTargetCannotAffectItsOwnPredictionOrRank(testCase)
[X, y, ids] = localSyntheticData();
[prediction1, ranks1, tuning1] = localPredictTscorePLS(X, y, ids, 4, [], true);

yChanged = y;
yChanged(1) = yChanged(1) + 1000;
[prediction2, ranks2, tuning2] = localPredictTscorePLS( ...
    X, yChanged, ids, 4, [], true);

verifyEqual(testCase, prediction2(1), prediction1(1), 'AbsTol', 1e-10);
verifyEqual(testCase, ranks2(1), ranks1(1));
verifyEqual(testCase, tuning2(1).InnerRMSE, tuning1(1).InnerRMSE, ...
    'AbsTol', 1e-10);
end

function testFixedRankSkipsInnerSelection(testCase)
[X, y, ids] = localSyntheticData();
[~, ranks, tuning] = localPredictTscorePLS(X, y, ids, 4, 2, true);

verifyEqual(testCase, ranks, 2 * ones(size(ranks)));
verifyTrue(testCase, all([tuning.FixedRank]));
verifyTrue(testCase, all(isnan([tuning.InnerRMSE])));
end

function [X, y, ids] = localSyntheticData()
previousState = rng;
cleanup = onCleanup(@()rng(previousState)); %#ok<NASGU>
rng(11, 'twister');
X = randn(12, 6);
y = 1.8 * X(:,1) - 0.9 * X(:,2) + 0.2 * randn(12,1);
ids = "CAD" + string((1:12).');
end

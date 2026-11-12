function tests = testNestedSVR
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
rootFolder = fileparts(fileparts(mfilename('fullpath')));
testCase.TestData.OriginalPath = path;
addpath(rootFolder);
addpath(fullfile(rootFolder,'analysis'));
end

function teardownOnce(testCase)
path(testCase.TestData.OriginalPath);
end

function testBayesianOptimizationReturnsStrictOuterPredictions(testCase)
assumeEqual(testCase,exist('bayesopt','file'),2);
previousState = rng;
cleanup = onCleanup(@()rng(previousState));
rng(21,'twister');
X = randn(5,4);
y = 1.4*X(:,1)-0.6*X(:,2)+0.1*randn(5,1);
ids = "CAD" + string((1:5).');

settings = analysisDefaultSettings().feature;
settings.svrOptimizationMode = "bayesian";
settings.svrInnerFolds = 3;
settings.svrMaxCandidates = 4;
settings.svrBoxConstraintGrid = [0.1 1 10];
settings.svrEpsilonGrid = [0.01 0.1];
settings.svrKernelScaleGrid = [0.5 2 8];
settings.svrBoxConstraint = 1;
settings.svrEpsilon = 0.05;
settings.svrKernelScale = 2;
settings.randomSeed = 4;

[prediction,tuning] = localPredictTscoreSVR(X,y,ids,settings);
verifySize(testCase,prediction,size(y));
verifyTrue(testCase,all(isfinite(prediction)));
verifyEqual(testCase,numel(tuning),numel(ids));
verifyEqual(testCase,[tuning.CandidatesEvaluated],4*ones(1,numel(ids)));
verifyEqual(testCase,[tuning.InnerFolds],3*ones(1,numel(ids)));
verifyTrue(testCase,all(isfinite([tuning.InnerRMSE])));
end

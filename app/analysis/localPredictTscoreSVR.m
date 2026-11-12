function [yPred,tuning] = localPredictTscoreSVR(X,y,cadIDs,featureSettings,blockSizes)
%LOCALPREDICTTSCORESVR Grouped-LOCO SVR with optional nested tuning.
if nargin<5, blockSizes=[]; end
if ~isempty(blockSizes) && ~featureSettings.standardizePredictors
    error('MainGUI:TscoreBlockScaling','Block scaling requires within-fold standardization.');
end

if exist('fitrsvm','file') ~= 2
    error(['SVR T-score prediction requires MATLAB fitrsvm ' ...
        '(Statistics and Machine Learning Toolbox).']);
end

mode = "fixed";
if isfield(featureSettings,'svrOptimizationMode')
    mode = lower(string(featureSettings.svrOptimizationMode));
end
uniqueCadIDs = unique(cadIDs,'stable');
yPred = nan(size(y));
tuning = repmat(struct('CadaverID',"",'BoxConstraint',NaN, ...
    'Epsilon',NaN,'KernelScale',NaN,'InnerRMSE',NaN, ...
    'InnerFolds',0,'CandidatesEvaluated',0),numel(uniqueCadIDs),1);

for i = 1:numel(uniqueCadIDs)
    test = cadIDs == uniqueCadIDs(i);
    train = ~test;
    if mode == "bayesian"
        [parameters,innerRMSE,nCandidates,nFolds] = ...
            localTuneParametersBayesian( ...
            X(train,:),y(train),cadIDs(train),featureSettings,i,blockSizes);
    elseif mode == "nested"
        [parameters,innerRMSE,nCandidates,nFolds] = localTuneParameters( ...
            X(train,:),y(train),cadIDs(train),featureSettings,i,blockSizes);
    else
        parameters = [featureSettings.svrBoxConstraint, ...
            featureSettings.svrEpsilon,featureSettings.svrKernelScale];
        innerRMSE = NaN;
        nCandidates = 1;
        nFolds = 0;
    end

    yPred(test) = localFitPredict(X(train,:),y(train),X(test,:),parameters, ...
        featureSettings.standardizePredictors,blockSizes);
    tuning(i).CadaverID = uniqueCadIDs(i);
    tuning(i).BoxConstraint = parameters(1);
    tuning(i).Epsilon = parameters(2);
    tuning(i).KernelScale = parameters(3);
    tuning(i).InnerRMSE = innerRMSE;
    tuning(i).InnerFolds = nFolds;
    tuning(i).CandidatesEvaluated = nCandidates;
    if any(mode == ["bayesian" "nested"])
        fprintf(['SVR %s tuning %d/%d: held out %s; C=%.3g, epsilon=%.3g, ' ...
            'scale=%.3g; inner RMSE=%.3f; evaluations=%d\n'], ...
            char(mode),i,numel(uniqueCadIDs),uniqueCadIDs(i), ...
            parameters(1),parameters(2),parameters(3),innerRMSE,nCandidates);
        drawnow limitrate
    end
end
end

function [bestParameters,bestRMSE,nCandidates,nFolds] = ...
        localTuneParametersBayesian(X,y,cadIDs,settings,outerFold,blockSizes)
if exist('bayesopt','file') ~= 2
    error('MainGUI:SVRBayesianUnavailable', ...
        'Bayesian SVR optimization requires MATLAB bayesopt.');
end

uniqueIDs = unique(cadIDs,'stable');
if numel(uniqueIDs) < 3
    error('MainGUI:SVRInnerValidation', ...
        'Bayesian SVR optimization requires at least three training cadavers.');
end
nFolds = min(settings.svrInnerFolds,numel(uniqueIDs));

previousState = rng;
cleanup = onCleanup(@()rng(previousState));
rng(settings.randomSeed + outerFold - 1,'twister');
shuffledIDs = uniqueIDs(randperm(numel(uniqueIDs)));
foldNumber = zeros(numel(uniqueIDs),1);
for j = 1:numel(shuffledIDs)
    foldNumber(uniqueIDs == shuffledIDs(j)) = mod(j-1,nFolds)+1;
end

fixed = [settings.svrBoxConstraint settings.svrEpsilon ...
    settings.svrKernelScale];
cBounds = localBayesianBounds(settings.svrBoxConstraintGrid,fixed(1));
eBounds = localBayesianBounds(settings.svrEpsilonGrid,fixed(2));
sBounds = localBayesianBounds(settings.svrKernelScaleGrid,fixed(3));

epsilonTransform = 'log';
if eBounds(1) <= 0, epsilonTransform = 'none'; end
variables = [ ...
    optimizableVariable('BoxConstraint',cBounds,'Transform','log')
    optimizableVariable('Epsilon',eBounds,'Transform',epsilonTransform)
    optimizableVariable('KernelScale',sBounds,'Transform','log')];
initialX = array2table(fixed, ...
    'VariableNames',{'BoxConstraint','Epsilon','KernelScale'});

objective = @(candidate)localBayesianObjective(candidate,X,y,cadIDs, ...
    uniqueIDs,foldNumber,nFolds,settings.standardizePredictors,blockSizes);
maxEvaluations = round(settings.svrMaxCandidates);
results = bayesopt(objective,variables, ...
    'MaxObjectiveEvaluations',maxEvaluations, ...
    'NumSeedPoints',min(6,maxEvaluations), ...
    'InitialX',initialX, ...
    'IsObjectiveDeterministic',true, ...
    'AcquisitionFunctionName','expected-improvement-plus', ...
    'UseParallel',false, ...
    'Verbose',0, ...
    'PlotFcn',{});

[bestPointTable,bestRMSE] = bestPoint(results, ...
    'Criterion','min-observed');
bestParameters = [bestPointTable.BoxConstraint bestPointTable.Epsilon ...
    bestPointTable.KernelScale];
nCandidates = results.NumObjectiveEvaluations;
if ~isfinite(bestRMSE) || bestRMSE >= 1e12
    error('MainGUI:SVRTuningFailed', ...
        'Every Bayesian SVR candidate failed during grouped inner validation.');
end
end

function bounds = localBayesianBounds(gridValues,fixedValue)
values = [gridValues(:); fixedValue];
values = values(isfinite(values));
bounds = [min(values) max(values)];
if numel(values) < 2 || bounds(1) == bounds(2)
    error('MainGUI:SVRBayesianRange', ...
        'Bayesian SVR optimization requires a nonzero range for every parameter.');
end
end

function value = localBayesianObjective(candidate,X,y,cadIDs,uniqueIDs, ...
        foldNumber,nFolds,standardize,blockSizes)
parameters = [candidate.BoxConstraint candidate.Epsilon candidate.KernelScale];
value = localEvaluateParameters(X,y,cadIDs,uniqueIDs,foldNumber,nFolds, ...
    parameters,standardize,blockSizes);
if ~isfinite(value), value = 1e12; end
end

function [bestParameters,bestRMSE,nCandidates,nFolds] = localTuneParameters( ...
        X,y,cadIDs,settings,outerFold,blockSizes)
uniqueIDs = unique(cadIDs,'stable');
if numel(uniqueIDs) < 3
    error('MainGUI:SVRInnerValidation', ...
        'Nested SVR optimization requires at least three training cadavers.');
end
nFolds = min(settings.svrInnerFolds,numel(uniqueIDs));

[C,E,S] = ndgrid(unique(settings.svrBoxConstraintGrid), ...
    unique(settings.svrEpsilonGrid),unique(settings.svrKernelScaleGrid));
candidates = [C(:) E(:) S(:)];
fixed = [settings.svrBoxConstraint settings.svrEpsilon settings.svrKernelScale];
candidates = unique([fixed;candidates],'rows','stable');

previousState = rng;
cleanup = onCleanup(@()rng(previousState));
rng(settings.randomSeed + outerFold - 1,'twister');
if size(candidates,1) > settings.svrMaxCandidates
    keep = [1; 1 + randperm(size(candidates,1)-1,settings.svrMaxCandidates-1).'];
    candidates = candidates(keep,:);
end
nCandidates = size(candidates,1);

shuffledIDs = uniqueIDs(randperm(numel(uniqueIDs)));
foldNumber = zeros(numel(uniqueIDs),1);
for j = 1:numel(shuffledIDs)
    foldNumber(uniqueIDs == shuffledIDs(j)) = mod(j-1,nFolds)+1;
end

scores = inf(nCandidates,1);
for candidateIndex = 1:nCandidates
    scores(candidateIndex) = localEvaluateParameters(X,y,cadIDs,uniqueIDs, ...
        foldNumber,nFolds,candidates(candidateIndex,:), ...
        settings.standardizePredictors,blockSizes);
end

[bestRMSE,bestIndex] = min(scores);
if ~isfinite(bestRMSE)
    error('MainGUI:SVRTuningFailed', ...
        'Every SVR candidate failed during grouped inner validation.');
end
bestParameters = candidates(bestIndex,:);
end

function value = localEvaluateParameters(X,y,cadIDs,uniqueIDs,foldNumber, ...
        nFolds,parameters,standardize,blockSizes)
innerPrediction = nan(size(y));
for fold = 1:nFolds
    heldIDs = uniqueIDs(foldNumber == fold);
    innerTest = ismember(cadIDs,heldIDs);
    innerTrain = ~innerTest;
    try
        innerPrediction(innerTest) = localFitPredict(X(innerTrain,:),y(innerTrain), ...
            X(innerTest,:),parameters,standardize,blockSizes);
    catch
        value = Inf;
        return
    end
end
if all(isfinite(innerPrediction))
    value = localCadaverBalancedRMSE(y,innerPrediction,cadIDs,uniqueIDs);
else
    value = Inf;
end
end

function prediction = localFitPredict(X,y,Q,parameters,standardize,blockSizes)
if ~isempty(blockSizes)
    [X,Q]=localStandardizeTrainTest(X,Q,blockSizes);
    standardize=false;
end
mdl = fitrsvm(X,y,'KernelFunction','gaussian', ...
    'KernelScale',parameters(3), ...
    'BoxConstraint',parameters(1), ...
    'Epsilon',parameters(2), ...
    'Standardize',logical(standardize));
prediction=predict(mdl,Q);
end

function value = localCadaverBalancedRMSE(y,yPred,cadIDs,uniqueIDs)
truth = nan(numel(uniqueIDs),1);
prediction = nan(numel(uniqueIDs),1);
for k = 1:numel(uniqueIDs)
    rows = cadIDs == uniqueIDs(k);
    truth(k) = mean(y(rows),'omitnan');
    prediction(k) = mean(yPred(rows),'omitnan');
end
value = sqrt(mean((prediction-truth).^2,'omitnan'));
end

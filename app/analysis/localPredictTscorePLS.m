function [yPred, ranks, tuning] = localPredictTscorePLS( ...
        X, y, cadIDs, maxRank, fixedRank, standardizePredictors, blockSizes)
%LOCALPREDICTTSCOREPLS Strict grouped-LOCO PLS regression.
% Rank selection is performed by grouped inner LOCO using only the outer
% training cadavers. A fixed rank is used only when supplied a priori.

if nargin < 5
    fixedRank = [];
end
if nargin < 6 || isempty(standardizePredictors)
    standardizePredictors = true;
end
if nargin < 7, blockSizes = []; end
if ~isempty(blockSizes) && ~standardizePredictors
    error('MainGUI:TscoreBlockScaling', ...
        'Block scaling requires within-fold column standardization.');
end

cadIDs = string(cadIDs(:));
y = y(:);
uniqueCadIDs = unique(cadIDs, 'stable');
yPred = nan(size(y));
ranks = nan(size(y));
tuning = repmat(struct('CadaverID',"", 'Rank',NaN, 'InnerRMSE',NaN, ...
    'InnerCadavers',0, 'MaxRankEvaluated',0, 'FixedRank',false), ...
    numel(uniqueCadIDs), 1);

for i = 1:numel(uniqueCadIDs)
    test = cadIDs == uniqueCadIDs(i);
    train = ~test;
    Xtrain = X(train,:);
    ytrain = y(train);
    trainIDs = cadIDs(train);
    Xtest = X(test,:);

    foldMaxRank = min([maxRank, size(Xtrain,1)-1, size(Xtrain,2)]);
    if foldMaxRank < 1
        error('MainGUI:PLSInsufficientTrainingData', ...
            'PLS requires at least two outer-training rows and one predictor.');
    end

    if isempty(fixedRank)
        [rank, innerRMSE, innerMaxRank] = localChooseRankInnerLOCO( ...
            Xtrain, ytrain, trainIDs, foldMaxRank, standardizePredictors, blockSizes);
        usedFixedRank = false;
    else
        rank = min(max(1, round(fixedRank)), foldMaxRank);
        innerRMSE = NaN;
        innerMaxRank = foldMaxRank;
        usedFixedRank = true;
    end

    if standardizePredictors
        [XtrainUse, XtestUse] = localStandardizeTrainTest(Xtrain, Xtest, blockSizes);
    else
        XtrainUse = Xtrain;
        XtestUse = Xtest;
    end
    [~,~,~,~,beta] = plsregress(XtrainUse, ytrain, rank);
    yPred(test) = [ones(sum(test),1) XtestUse] * beta;
    ranks(test) = rank;

    tuning(i).CadaverID = uniqueCadIDs(i);
    tuning(i).Rank = rank;
    tuning(i).InnerRMSE = innerRMSE;
    tuning(i).InnerCadavers = numel(unique(trainIDs));
    tuning(i).MaxRankEvaluated = innerMaxRank;
    tuning(i).FixedRank = usedFixedRank;
end
end

function [bestRank, bestRMSE, innerMaxRank] = localChooseRankInnerLOCO( ...
        X, y, cadIDs, maxRank, standardizePredictors, blockSizes)
uniqueIDs = unique(cadIDs, 'stable');
if numel(uniqueIDs) < 3
    error('MainGUI:PLSInnerValidation', ...
        'Nested PLS rank selection requires at least three outer-training cadavers.');
end

groupCounts = arrayfun(@(id) sum(cadIDs == id), uniqueIDs);
minimumInnerTrainingRows = size(X,1) - max(groupCounts);
innerMaxRank = min([maxRank, minimumInnerTrainingRows-1, size(X,2)]);
if innerMaxRank < 1
    error('MainGUI:PLSInnerValidation', ...
        'Not enough inner-training data to select a PLS rank.');
end

pred = nan(numel(y), innerMaxRank);
for i = 1:numel(uniqueIDs)
    innerTest = cadIDs == uniqueIDs(i);
    innerTrain = ~innerTest;
    Xtrain = X(innerTrain,:);
    Xtest = X(innerTest,:);
    if standardizePredictors
        [Xtrain, Xtest] = localStandardizeTrainTest(Xtrain, Xtest, blockSizes);
    end
    for rank = 1:innerMaxRank
        [~,~,~,~,beta] = plsregress(Xtrain, y(innerTrain), rank);
        pred(innerTest,rank) = [ones(sum(innerTest),1) Xtest] * beta;
    end
end

scores = inf(1, innerMaxRank);
for rank = 1:innerMaxRank
    if all(isfinite(pred(:,rank)))
        scores(rank) = localCadaverBalancedRMSE(y, pred(:,rank), cadIDs, uniqueIDs);
    end
end
[bestRMSE, bestRank] = min(scores);
if ~isfinite(bestRMSE)
    error('MainGUI:PLSInnerValidation', ...
        'Every PLS rank failed during grouped inner validation.');
end
end

function value = localCadaverBalancedRMSE(y, yPred, cadIDs, uniqueIDs)
truth = nan(numel(uniqueIDs),1);
prediction = nan(numel(uniqueIDs),1);
for k = 1:numel(uniqueIDs)
    rows = cadIDs == uniqueIDs(k);
    truth(k) = mean(y(rows), 'omitnan');
    prediction(k) = mean(yPred(rows), 'omitnan');
end
value = sqrt(mean((prediction-truth).^2, 'omitnan'));
end

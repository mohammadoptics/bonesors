function yPred = localPredictTscoreMLP(X, y, cadIDs, featureSettings,blockSizes)
%LOCALPREDICTTSCOREMLP Grouped-LOCO multilayer-perceptron regression.
if nargin<5, blockSizes=[]; end
if ~isempty(blockSizes) && ~featureSettings.standardizePredictors
    error('MainGUI:TscoreBlockScaling','Block scaling requires within-fold standardization.');
end

if exist('fitrnet','file') ~= 2 && exist('fitnet','file') ~= 2
    error(['MLP T-score prediction requires fitrnet from Statistics and ' ...
        'Machine Learning Toolbox, or fitnet from Deep Learning Toolbox.']);
end

yPred = nan(size(y));
uniqueCadIDs = unique(cadIDs,'stable');
for i = 1:numel(uniqueCadIDs)
    test = cadIDs == uniqueCadIDs(i);
    train = ~test;
    Xtrain = X(train,:);
    Xtest = X(test,:);
    if featureSettings.standardizePredictors
        [Xtrain,Xtest] = localStandardizeTrainTest(Xtrain,Xtest,blockSizes);
    end

    previousState = rng;
    cleanup = onCleanup(@()rng(previousState));
    rng(featureSettings.randomSeed + i - 1,'twister');
    if exist('fitrnet','file') == 2
        mdl = fitrnet(Xtrain,y(train), ...
            'LayerSizes',featureSettings.mlpHiddenLayers, ...
            'Activations','relu', ...
            'Lambda',featureSettings.mlpRegularization, ...
            'Standardize',false, ...
            'StandardizeResponses',true, ...
            'IterationLimit',featureSettings.mlpMaxEpochs, ...
            'Verbose',0);
        yPred(test) = predict(mdl,Xtest);
    else
        net = fitnet(featureSettings.mlpHiddenLayers,'trainscg');
        % Prevent the fallback network from undoing the requested block weights.
        if ~isempty(blockSizes), net.inputs{1}.processFcns={}; end
        net.divideFcn = 'dividetrain';
        net.trainParam.showWindow = false;
        net.trainParam.showCommandLine = false;
        net.trainParam.epochs = featureSettings.mlpMaxEpochs;
        net.performParam.regularization = min(max(featureSettings.mlpRegularization,0),1);
        net = train(net,Xtrain.',y(train).');
        yPred(test) = net(Xtest.').';
    end
end
end

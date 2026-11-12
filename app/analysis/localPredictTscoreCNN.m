function yPred = localPredictTscoreCNN(X, y, cadIDs, featureSettings)
%LOCALPREDICTTSCORECNN Grouped-LOCO 1-D convolutional regression.

if exist('trainNetwork','file') ~= 2
    error(['CNN T-score prediction requires trainNetwork from the MATLAB ' ...
        'Deep Learning Toolbox.']);
end

yPred = nan(size(y));
uniqueCadIDs = unique(cadIDs,'stable');
nFeatures = size(X,2);
for i = 1:numel(uniqueCadIDs)
    test = cadIDs == uniqueCadIDs(i);
    train = ~test;
    Xtrain = X(train,:);
    Xtest = X(test,:);
    if featureSettings.standardizePredictors
        [Xtrain,Xtest] = localStandardizeTrainTest(Xtrain,Xtest);
    end

    yTrainRaw = y(train);
    muY = mean(yTrainRaw);
    sdY = std(yTrainRaw);
    if ~isfinite(sdY) || sdY == 0, sdY = 1; end
    yTrain = (yTrainRaw-muY)./sdY;

    Xtrain4d = reshape(Xtrain.',[nFeatures 1 1 size(Xtrain,1)]);
    Xtest4d = reshape(Xtest.',[nFeatures 1 1 size(Xtest,1)]);
    layers = [ ...
        imageInputLayer([nFeatures 1 1],'Normalization','none','Name','input')
        convolution2dLayer([5 1],16,'Padding','same','Name','conv1')
        reluLayer('Name','relu1')
        maxPooling2dLayer([2 1],'Stride',[2 1],'Name','pool1')
        convolution2dLayer([5 1],32,'Padding','same','Name','conv2')
        reluLayer('Name','relu2')
        globalAveragePooling2dLayer('Name','globalAverage')
        fullyConnectedLayer(16,'Name','dense')
        reluLayer('Name','relu3')
        fullyConnectedLayer(1,'Name','prediction')
        regressionLayer('Name','output')];

    previousState = rng;
    cleanup = onCleanup(@()rng(previousState));
    rng(featureSettings.randomSeed + i - 1,'twister');
    options = trainingOptions('adam', ...
        'MaxEpochs',featureSettings.cnnMaxEpochs, ...
        'MiniBatchSize',min(featureSettings.cnnMiniBatchSize,sum(train)), ...
        'InitialLearnRate',5e-4, ...
        'L2Regularization',featureSettings.cnnRegularization, ...
        'Shuffle','every-epoch','ExecutionEnvironment','auto', ...
        'Plots','none','Verbose',false);
    net = trainNetwork(Xtrain4d,yTrain,layers,options);
    yPredNormalized = predict(net,Xtest4d,'MiniBatchSize',size(Xtest,1));
    yPred(test) = sdY*yPredNormalized(:)+muY;
end
end

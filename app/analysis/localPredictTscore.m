function result = localPredictTscore(records, tissueToUse, spectrumNumber, maxRank, featureSettings)
    result = localComputeTscorePrediction(records, tissueToUse, spectrumNumber, maxRank, featureSettings);
    if ~result.ok
        return
    end

    fprintf('\n=== Cadaver-dataset T-score prediction ===\n');
    fprintf('Predictors: %s\n', result.featureLabel);
    if strcmpi(featureSettings.tscoreModel,'ridge')
        fprintf('Cadavers: %d   Rows: %d   Features: %d   Inner folds: %d\n', ...
            result.nCadavers,numel(result.y),result.nFeatures,featureSettings.ridgeInnerFolds);
    else
        fprintf('Cadavers: %d   Rows: %d   Features: %d   Max rank tested: %d\n', ...
            result.nCadavers, numel(result.y), result.nFeatures, result.maxRank);
    end
    digits=3;
    if isfield(featureSettings,'validationProtocol') && featureSettings.validationProtocol=="matchedKFold"
        digits=4;
    end
    fprintf('Best model: %s   r = %.*f   RMSE_CV = %.*f\n', ...
        result.modelText,digits,result.rVal,digits,result.rmseVal);

    localPlotTscorePrediction(result.y, result.yPred, result.cats, result.bestRank, ...
        tissueToUse, spectrumNumber, result.featureLabel, result.modelText, ...
        featureSettings);
    localPlotTscoreConfusionMatrix(result.y, result.yPred, result.cats, result.featureLabel);
end

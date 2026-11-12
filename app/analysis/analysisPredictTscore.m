function analysisPredictTscore(context)
if isfield(context.ud.config.tscore,'figureMode') && context.ud.config.tscore.figureMode=="locationComparison"
    analysisTscorePublication(context); return
end
o = context.options; s = context.settings;
models = upper(string(context.ud.config.tscore.models));
for model = models
    feature = s.feature;
    feature.tscoreModel = lower(model);
    result = localPredictTscore(context.records, o.tissue, o.spectrumNumbers, ...
        s.maxRank, feature);
    matched=isfield(feature,'validationProtocol') && feature.validationProtocol=="matchedKFold" && any(model==["PLS" "SVR"]);
    if (model == "RIDGE" || matched) && result.ok
        [accuracy,balanced] = localTscoreClassificationSummary(result.y,result.yPred,result.cats);
        fprintf('Correct classifications: %d/%d (%.2f%%); balanced accuracy %.2f%%\n', ...
            round(accuracy*numel(result.y)),numel(result.y),100*accuracy,100*balanced);
        if strlength(string(context.outputDirectory))>0
            if matched
                localSaveMatchedTscoreRun(context,result,feature);
            else
                localSaveRidgeTscoreRun(context,result,feature);
            end
        else
            fprintf('Choose an analysis output folder to save predictions and settings.\n');
        end
    end
end
end

function analysisRatioGroupTscore(context)
%ANALYSISRATIOGROUPTSCORE Run one independent T-score analysis per ratio.

if ~context.settings.feature.useRaman
    error('MainGUI:RatioGroupTscoreRequiresRaman', [ ...
        'Ratio group T-score analysis requires Raman predictors. Configure ', ...
        'the predictor source as Raman only or Raman + demographics.']);
end

ratioNames = localNormalizeTscoreRatioSelection( ...
    context.settings.feature.tscoreRatioNames);
if isempty(ratioNames)
    error('MainGUI:RatioGroupTscoreRatiosRequired', ...
        'Select at least one ratio in the T-score Feature representation section.');
end

[summaryTable,plotEntries] = localComputeRatioGroupTscoreTable(context, ratioNames);

fprintf('\n=== Ratio group T-score analysis (independent ratios) ===\n');
fprintf(['Each checked ratio is evaluated separately. The selected tag settings ', ...
    'are used consistently for every ratio.\n']);
fprintf('Tissue: %s   Spectrum expression: %s\n', ...
    char(context.options.tissue), char(context.options.spectrumExpression));
fprintf('Ratios: %s\n',char(strjoin( ...
    arrayfun(@(name)localTscoreRatioLabel(name,false),ratioNames),', ')));
disp(summaryTable);
localPlotRatioGroupTscore(plotEntries,context.options.spectrumNumbers);
end

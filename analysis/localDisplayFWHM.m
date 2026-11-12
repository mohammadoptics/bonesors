function hFig = localDisplayFWHM(records, tissueToUse, spectrumNumbers, featureSettings, plotSettings)
%LOCALDISPLAYFWHM Match Raman-ratio grouping, markers, summaries and statistics.
if nargin < 5 || isempty(plotSettings), plotSettings = struct(); end
if ~isfield(plotSettings,'ratioSummaryBoxFlag')
    plotSettings.ratioSummaryBoxFlag = false;
end
if numel(spectrumNumbers) > 1 && ...
        (string(featureSettings.spectrumCombineMode) == "concat" || ...
         localIsRatioLevelCombineMode(featureSettings))
    error('MainGUI:FWHMRequiresSpectrum', ...
        'FWHM requires a physical spectrum, not concatenated features or combined band ratios.');
end

cats = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
bank = localBuildFWHMBankFromRecords(records, cats, featureSettings);
metrics = localFWHMMetricDefinitions();
for k = 1:numel(metrics)
    metrics(k).label = sprintf('%s (cm^{-1})', metrics(k).label);
end
opts.categories = cats;
opts.colors = {'b','g','r'};
opts.markers = {'s','d','o'};
opts.useSummaryBoxes = plotSettings.ratioSummaryBoxFlag;
opts.figureName = sprintf('%s FWHM - spectrum %s', tissueToUse, mat2str(spectrumNumbers));
if numel(spectrumNumbers) > 1
    opts.figureName = sprintf('%s %s', opts.figureName, featureSettings.spectrumCombineMode);
end
opts.figureName = sprintf('%s | normalize first: %s (%s)', opts.figureName, ...
    featureSettings.normalizationRegion, featureSettings.normalizationMethod);
fprintf('\nFWHM display: columns %s; normalize each to %s (%s), then %s.\n', ...
    mat2str(spectrumNumbers), featureSettings.normalizationRegion, ...
    featureSettings.normalizationMethod, featureSettings.spectrumCombineMode);
fprintf('Widths in cm^-1 use local-minimum baselines and interpolated half-height crossings. Undefined widths are omitted per band.\n');
if numel(spectrumNumbers) > 1 && string(featureSettings.spectrumCombineMode) == "diff"
    warning('MainGUI:DifferenceSpectrumFWHM', ...
        'These are widths of a normalized difference spectrum, not intrinsic widths of the original tissue bands.');
end
hFig = plotMetricBank(bank, metrics, opts);
end

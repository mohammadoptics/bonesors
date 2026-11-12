function hFig = analysisDisplayFWHM(context)
%ANALYSISDISPLAYFWHM Standalone band-width display using the ratio controls.
o = context.options;
s = context.settings;
plotSettings = s.plot;
plotSettings.priorityTags = o.tags;
hFig = localDisplayFWHM(context.records, o.tissue, o.spectrumNumbers, ...
    s.feature, plotSettings);
end

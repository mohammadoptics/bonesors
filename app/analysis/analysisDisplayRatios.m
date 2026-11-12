function analysisDisplayRatios(context)
o = context.options;
s = context.settings;
plotSettings = s.plot;
plotSettings.priorityTags = o.tags;
localDisplayRatios(context.records, o.tissue, o.spectrumNumbers, ...
    s.feature, plotSettings);
end

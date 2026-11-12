function analysisCompareRatios(context)
o = context.options; s = context.settings;
primary = collectRecords(context, o.tissue, true);
secondary = collectRecords(context, o.comparisonTissue, true);
localCompareRatioPlots(primary, secondary, o.spectrumNumbers, o.tags, ...
    s.feature, s.plot.ratioSummaryBoxFlag, s.plot.plotFWHMFlag, ...
    o.tissue, o.comparisonTissue);
end

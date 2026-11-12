function analysisCompareClassification(context)
o = context.options; s = context.settings;
primary = collectRecords(context, o.tissue, s.feature.useRaman);
secondary = collectRecords(context, o.comparisonTissue, s.feature.useRaman);
localCompareClassificationPlots(primary, secondary, o.spectrumNumbers, ...
    s.maxRank, s.feature, o.tissue, o.comparisonTissue);
end

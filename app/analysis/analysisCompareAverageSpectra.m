function analysisCompareAverageSpectra(context)
o = context.options; s = context.settings;
primary = collectRecords(context, o.tissue, true);
secondary = collectRecords(context, o.comparisonTissue, true);
compareSettings = s.compare;
compareSettings.primaryLabel = analysisTissueLabel(o.tissue);
compareSettings.secondaryLabel = analysisTissueLabel(o.comparisonTissue);
localCompareAverageSpectra(primary, secondary, o.spectrumNumbers, o.tags, ...
    s.feature, s.plot.useIanitaJForAverageSpectra, compareSettings);
end

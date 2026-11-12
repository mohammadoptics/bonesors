function analysisSpatialCategorySpectra(context)
%ANALYSISSPATIALCATEGORYSPECTRA Plot selected-tag spectra in N/OPE/OP panels.
o = context.options;
s = context.settings;
localValidateSpatialPlotRequest(o);
localPlotSpatialCategorySpectra(context.records, o.tissue, ...
    o.spectrumNumbers, o.tags, o.tagMatchMode, s.feature, ...
    s.plot.useIanitaJForAverageSpectra, s.spatial);
end

function analysisSpatialMetricProfiles(context)
%ANALYSISSPATIALMETRICPROFILES Plot five ratios and five FWHM profiles.
o = context.options;
s = context.settings;
localValidateSpatialPlotRequest(o);
localPlotSpatialMetricProfiles(context.records, o.tissue, ...
    o.spectrumNumbers, o.tags, o.tagMatchMode, s.feature, s.spatial);
end

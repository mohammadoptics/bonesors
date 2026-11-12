function analysisDetectOutliers(context)
o = context.options; s = context.settings;
localDetectRatioOutliers(context.records, o.tissue, o.spectrumNumbers, ...
    s.feature, s.outlier, context.datasetFile);
end

function analysisVisualizeAutoscaling(context)
o = context.options; s = context.settings;
localVisualizeAutoscaling(context.records, o.tissue, o.spectrumNumbers, ...
    s.feature, s.autoscaleExampleCadaverID);
end

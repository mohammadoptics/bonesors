function analysisSweepTscore(context)
o = context.options; s = context.settings;
outputAnchor = context.datasetFile;
if strlength(context.outputDirectory) > 0
    [~, name, extension] = fileparts(context.datasetFile);
    outputAnchor = fullfile(context.outputDirectory, [name extension]);
end
localSweepTscoreSettings(context.records, o.tissue, o.spectrumNumbers, ...
    s.maxRank, s.feature, s.sweep, outputAnchor);
end

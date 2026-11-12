function analysisStrictPredictTscore(context)
o = context.options; s = context.settings;
strict = s.strict;
if strlength(context.outputDirectory) > 0
    strict.outputFolder = context.outputDirectory;
    strict.askForOutputFolder = false;
end
localRunStrictPredictTscoreFromAnalyze(context.datasetFile, ...
    context.ud.statusFilename, o.tags, o.spectrumNumbers, ...
    s.maxRank, s.feature, strict);
end

function config=twoDigitDifferencePreset(config)
% Reproducible fixed representation; does not load data or saved predictions.
config.tscore=completeTscoreConfiguration(config.tscore);
config.tscore.figureMode="individual";
config.analysis.mode="predictTscore"; config.analysis.tissue="T";
config.analysis.spectrumNumbers=[3 2]; config.analysis.spectrumExpression="3-2";
config.analysis.spectrumCombineMode="diff";
config.analysis.tags={'D2P1_MM00','D3P1_MM00'};
config.analysis.tagSelectionMode="all"; config.analysis.tagMatchMode="exact";
config.tscore.locationCombineMode="concat";
config.tscore.locationTags=["D2P1_MM00" "D3P1_MM00"];
config.tscore.predictorSource="raman";
config.tscore.useAge=true; config.tscore.useBMI=true; config.tscore.useWeight=true; config.tscore.useSex=false;
config.tscore.ramanFeatureMode="spectrum";
config.tscore.normalizationRegion="CH2"; config.tscore.normalizationMethod="peak";
config.tscore.models="PLS"; config.tscore.maxPLSRank=10; config.tscore.fixedPLSRank=[];
config.tscore.standardizePredictors=true; config.tscore.blockScaleRamanDemographics=false;
config.tscore.validationProtocol="matchedKFold"; config.tscore.matchedInnerFolds=5;
config.tscore.randomSeed=20260921;
config.tscore.svrOptimizationMode="nested";
config.tscore.svrBoxConstraintGrid=[.3 3 30 100];
config.tscore.svrEpsilonGrid=[.05 .2]; config.tscore.svrKernelScaleGrid=[.3 1 3];
end

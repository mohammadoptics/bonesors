function config = intactRatioRidgePreset(config)
%INTACTRATIORIDGEPRESET Direct intact 6-mm ratios + demographics, nested ridge.
% Does not load data, remove donors, or inject saved predictions.
config.tscore=completeTscoreConfiguration(config.tscore);
config.tscore.figureMode="individual";
config.tscore.locationCombineMode="records";
config.analysis.mode="predictTscore";
config.analysis.tissue="T";
config.analysis.spectrumNumbers=3; config.analysis.spectrumExpression="3";
config.analysis.spectrumCombineMode="single";
config.analysis.tags={'D3P1_MM00'};
config.analysis.tagSelectionMode="single"; config.analysis.tagMatchMode="exact";
config.tscore.predictorSource="combined";
config.tscore.useAge=true; config.tscore.useSex=false;
config.tscore.useBMI=true; config.tscore.useWeight=true;
config.tscore.ramanFeatureMode="ratios";
config.tscore.ramanRatioNames=["PO4_CO3" "PO4_AmideIII" "PO4_CH2" "PO4_AmideI" "CO3_AmideIII"];
config.tscore.normalizationRegion="none";
config.tscore.normalizationMethod="peak";
config.tscore.models="RIDGE";
config.tscore.validationProtocol="legacy";
config.tscore.standardizePredictors=true;
config.tscore.blockScaleRamanDemographics=true;
config.tscore.ridgeAlphaGrid=[0.01 0.1 1 10 100];
config.tscore.ridgeInnerFolds=5;
config.tscore.randomSeed=20260919;
end

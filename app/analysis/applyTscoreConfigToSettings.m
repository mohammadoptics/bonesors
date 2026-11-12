function settings = applyTscoreConfigToSettings(settings, config)
%APPLYTSCORECONFIGTOSETTINGS Map GUI selections to scientific settings.

config = validateTscoreConfiguration(config);
source = string(config.predictorSource);
settings.maxRank = config.maxPLSRank;
settings.feature.useRaman = any(source == ["raman" "combined"]);
settings.feature.useAge = source ~= "raman" && config.useAge;
settings.feature.useSex = source ~= "raman" && config.useSex;
settings.feature.useBMI = source ~= "raman" && config.useBMI;
settings.feature.useWeight = source ~= "raman" && config.useWeight;
settings.feature.standardizePredictors = config.standardizePredictors;
settings.feature.blockScaleRamanDemographics = config.blockScaleRamanDemographics;
settings.feature.validationProtocol = config.validationProtocol;
settings.feature.matchedInnerFolds = config.matchedInnerFolds;
settings.feature.matchedSVRPython = config.matchedSVRPython;
settings.feature.ridgeAlphaGrid = config.ridgeAlphaGrid;
settings.feature.ridgeInnerFolds = config.ridgeInnerFolds;
settings.feature.normalizationRegion = config.normalizationRegion;
settings.feature.normalizationMethod = config.normalizationMethod;
settings.feature.tscoreFeatureMode = config.ramanFeatureMode;
settings.feature.locationCombineMode = config.locationCombineMode;
settings.feature.locationTags = config.locationTags;
settings.feature.tscoreRatioNames = config.ramanRatioNames;
settings.feature.fixedPLSRank = config.fixedPLSRank;
settings.feature.svrBoxConstraint = config.svrBoxConstraint;
settings.feature.svrEpsilon = config.svrEpsilon;
settings.feature.svrKernelScale = config.svrKernelScale;
settings.feature.svrOptimizationMode = config.svrOptimizationMode;
settings.feature.svrBoxConstraintGrid = config.svrBoxConstraintGrid;
settings.feature.svrEpsilonGrid = config.svrEpsilonGrid;
settings.feature.svrKernelScaleGrid = config.svrKernelScaleGrid;
settings.feature.svrInnerFolds = config.svrInnerFolds;
settings.feature.svrMaxCandidates = config.svrMaxCandidates;
settings.feature.mlpHiddenLayers = config.mlpHiddenLayers;
settings.feature.mlpRegularization = config.mlpRegularization;
settings.feature.mlpMaxEpochs = config.mlpMaxEpochs;
settings.feature.cnnMaxEpochs = config.cnnMaxEpochs;
settings.feature.cnnMiniBatchSize = config.cnnMiniBatchSize;
settings.feature.cnnRegularization = config.cnnRegularization;
settings.feature.randomSeed = config.randomSeed;
end

function settings = analysisDefaultSettings()
%ANALYSISDEFAULTSETTINGS Central scientific defaults for dataset analyses.

settings.maxRank = 12;
settings.autoscaleExampleCadaverID = "";

settings.plot = struct('plotAverageSpectraFlag',false, 'errMode','none', ...
    'plotFWHMFlag',false, 'ratioSummaryBoxFlag',false, ...
    'useIanitaJForAverageSpectra',true);

settings.compare = struct('metricsPosition',[0.98 0.78], ...
    'residualPosition',[0.04 0.59], 'showResidualTrace',false, ...
    'residualReferenceMode',"category", 'showResidualAgreementPanel',true, ...
    'individualAgreementMetric',"MAPE", 'averagePlotMode',"categoryOffset", ...
    'errMode','none');

settings.categoryAverage = struct('xlim',[1000 1720], ...
    'sourceMode',"selected", 'normalizationRegions',"useFeatureSettings", ...
    'normalizationMethod',"useFeatureSettings", ...
    'finalNormalizationRegion',"none", ...
    'finalNormalizationMethod',"peak", 'showDSValues',false);

settings.spatial = struct('xlim',[800 1750], 'showSEM',true, ...
    'stackOffset',0.30, 'lineWidth',1.7, ...
    'markerSize',6);

feature = struct();
feature.useRaman = true;
feature.useAge = false;
feature.useSex = false;
feature.useBMI = false;
feature.useWeight = false;
feature.standardizePredictors = true;
feature.blockScaleRamanDemographics = false;
feature.validationProtocol = "legacy";
feature.matchedInnerFolds = 5;
feature.normalizationRegion = "PO4";
feature.normalizationMethod = "peak";
feature.spectrumCombineMode = "diff";
feature.tscoreFeatureMode = "spectrum";
feature.tscoreRatioNames = {'PO4_CO3','PO4_AmideIII','PO4_CH2', ...
    'PO4_AmideI','CO3_AmideIII'};
feature.tscoreModel = "svr";
feature.fixedPLSRank = [];
feature.svrBoxConstraint = 0.75;
feature.svrEpsilon = 0.01;
feature.svrKernelScale = 30;
feature.svrOptimizationMode = "bayesian";
feature.svrBoxConstraintGrid = [0.1 0.3 1 3 10 30];
feature.svrEpsilonGrid = [0.01 0.03 0.05 0.1 0.2];
feature.svrKernelScaleGrid = [5 10 20 30 50 80];
feature.svrInnerFolds = 5;
feature.svrMaxCandidates = 40;
feature.mlpHiddenLayers = [20 10];
feature.mlpRegularization = 0.01;
feature.mlpMaxEpochs = 300;
feature.cnnMaxEpochs = 150;
feature.cnnMiniBatchSize = 8;
feature.cnnRegularization = 1e-4;
feature.randomSeed = 1;
settings.feature = feature;

strict = strictTscoreDefaultConfig();
strict.reconTagsToUse = {'D2P1_MM00','D3P1_MM00'};
strict.intactSpectraToUse = [2 3];
strict.reconCombineMode = "diff";
strict.reconNormalizationRegion = "CH2";
strict.reconNormalizationMethod = "peak";
strict.normalizePredictors = true;
strict.normalizeResponse = true;
strict.exposedSpectrumToPredict = 2;
strict.reconNComponents = 5;
strict.standardizeBeforeReconstructionPLS = true;
strict.askForOutputFolder = false;
strict.outputFolder = "";
strict.plotClassification = true;
strict.saveStrictPredictedCadavers = true;
strict.strictPredictedFileName = "strictPredictedCadavers.mat";
strict.measuredAnalysisSpectrumNumber = 2;
strict.measuredAnalysisSpectrumCombineMode = "concat";
strict.measuredTscoreNormalizationRegion = "CH2";
strict.measuredTscoreNormalizationMethod = "peak";
strict.measuredStandardizeTscorePredictors = true;
strict.measuredTscoreModel = "SVR";
strict.measuredMaxTscoreRank = 15;
strict.measuredFixedTscoreRank = [];
strict.measuredSvrBoxConstraint = 12.5;
strict.measuredSvrEpsilon = 0.3;
strict.measuredSvrKernelScale = 112.5;
settings.strict = strict;

settings.sweep = struct('svrBoxConstraint',[0.3 1 3 10 20 30], ...
    'svrEpsilon',[0.02 0.03 0.05 0.1 0.2 0.3 0.4], ...
    'svrKernelScale',[5 10 15 22.34 30 50 60 70 80 100], ...
    'maxRowsToPrint',25, 'saveCSV',true);

settings.outlier = struct('method',"robustZ", 'robustZThreshold',3.5, ...
    'iqrMultiplier',1.5, 'minOutlierRatios',2, ...
    'groupMode',"category", 'groupWithinCategory',true, 'saveCSV',false);

settings.po4QC = struct('po4Band',[930 990], 'lipidBand',[1284 1320], ...
    'normalizationSource',"featureSettings", 'threshold',0.5, ...
    'labelFlagged',true, 'saveCSV',false);
end

function config = guiDefaultConfig()
%GUIDEFAULTCONFIG Central defaults for GUI_Ver2.
% Keep user-facing defaults here instead of scattering flags across callbacks.

config.schemaVersion = 2;
config.analysis = struct();
config.analysis.mode = "displayRatios";
config.analysis.tissue = "E";
config.analysis.comparisonTissue = "P";
config.analysis.spectrumNumbers = 2;
config.analysis.spectrumExpression = "2";
config.analysis.spectrumCombineMode = "single";
config.analysis.tags = {'D2P1_MM00'};
config.analysis.tagSelectionMode = "single";
config.analysis.tagMatchMode = "exact";
config.analysis.locationCombineMode = "records"; % T-score: records | concat | mean
config.analysis.categoryAverageIncludeComparison = false;
config.display = struct('applyVerticalOffset', true, ...
    'normalizationRegion', "AmideI", 'normalizationMethod', "peak");
config.files = struct('skipDuplicatePaths', true);
config.preparation = struct('saveMode', "exposedOnly");
config.analysisOutputDirectory = "";
config.reconstruction = reconstructionDefaultConfig();
config.strict = strictTscoreDefaultConfig();
% Shared by ratio and category-average plots, independent from T-score settings.
% Normalize each column before expression and category averaging.
config.ratioDisplay = struct('normalizationRegion', "PO4", ...
    'normalizationMethod', "peak");

% T-score prediction is configured in a separate dialog so the main
% analysis tab remains compact. These values are shared by the dialog and
% the analysis modules.
config.tscore = struct();
config.tscore.predictorSource = "raman";       % raman | demographics | combined
config.tscore.useAge = true;
config.tscore.useSex = true;
config.tscore.useBMI = true;
config.tscore.useWeight = false;
config.tscore.ramanFeatureMode = "spectrum";  % spectrum | ratios | ratiosConcat
config.tscore.locationCombineMode = "records"; % records | concat | mean
config.tscore.locationTags = ["D2P1_MM00" "D3P1_MM00"];
config.tscore.figureMode = "individual"; % individual | locationComparison
config.tscore.figureSelectionConfigured = false;
config.tscore.figureRamanTags = strings(1,0);
config.tscore.figureCombinedTags = strings(1,0);
config.tscore.figureIncludeDemographics = true;
config.tscore.figureIncludeConcatenatedRaman = true;
config.tscore.figureIncludeConcatenatedCombined = true;
config.tscore.ramanRatioNames = ["PO4_CO3" "PO4_AmideIII" "PO4_CH2" ...
    "PO4_AmideI" "CO3_AmideIII"];
config.tscore.normalizationRegion = "PO4";
config.tscore.normalizationMethod = "peak";
config.tscore.models = ["PLS" "SVR"];
config.tscore.standardizePredictors = true;
config.tscore.blockScaleRamanDemographics = false;
config.tscore.validationProtocol = "legacy"; % legacy | matchedKFold (PLS/SVR)
config.tscore.matchedInnerFolds = 5;
config.tscore.matchedSVRPython = string(getenv('BONESORS_PYTHON'));
config.tscore.ridgeAlphaGrid = [0.01 0.1 1 10 100];
config.tscore.ridgeInnerFolds = 5;
config.tscore.maxPLSRank = 12;
config.tscore.fixedPLSRank = [];
config.tscore.svrBoxConstraint = 0.75;
config.tscore.svrEpsilon = 0.01;
config.tscore.svrKernelScale = 30;
config.tscore.svrOptimizationMode = "bayesian"; % bayesian | nested | fixed
config.tscore.svrBoxConstraintGrid = [0.1 0.3 1 3 10 30];
config.tscore.svrEpsilonGrid = [0.01 0.03 0.05 0.1 0.2];
config.tscore.svrKernelScaleGrid = [5 10 20 30 50 80];
config.tscore.svrInnerFolds = 5;
config.tscore.svrMaxCandidates = 40;
config.tscore.mlpHiddenLayers = [20 10];
config.tscore.mlpRegularization = 0.01;
config.tscore.mlpMaxEpochs = 300;
config.tscore.cnnMaxEpochs = 150;
config.tscore.cnnMiniBatchSize = 8;
config.tscore.cnnRegularization = 1e-4;
config.tscore.randomSeed = 1;
end

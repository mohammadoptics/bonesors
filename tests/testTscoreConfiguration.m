function tests = testTscoreConfiguration
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
rootFolder = fileparts(fileparts(mfilename('fullpath')));
testCase.TestData.RootFolder = rootFolder;
testCase.TestData.OriginalPath = path;
addpath(rootFolder);
addpath(fullfile(rootFolder,'analysis'));
end

function teardownOnce(testCase)
path(testCase.TestData.OriginalPath);
end

function testDefaultConfigurationIsValid(testCase)
config = guiDefaultConfig();
validated = validateTscoreConfiguration(config.tscore);
verifyEqual(testCase,validated.predictorSource,"raman");
verifyEqual(testCase,validated.models,["PLS" "SVR"]);
verifyTrue(testCase,validated.standardizePredictors);
verifyEmpty(testCase,validated.fixedPLSRank);
verifyEqual(testCase,validated.svrOptimizationMode,"bayesian");
verifyEqual(testCase,validated.svrMaxCandidates,40);
verifyEqual(testCase,validated.ramanRatioNames, ...
    ["PO4_CO3" "PO4_AmideIII" "PO4_CH2" "PO4_AmideI" "CO3_AmideIII"]);
end

function testSelectedRatioSubsetIsValidatedAndMapped(testCase)
config = guiDefaultConfig();
config.tscore.ramanFeatureMode = "ratios";
config.tscore.ramanRatioNames = ["PO4_CH2" "PO4_CO3"];
validated = validateTscoreConfiguration(config.tscore);
verifyEqual(testCase,validated.ramanRatioNames,["PO4_CH2" "PO4_CO3"]);

settings = applyTscoreConfigToSettings(analysisDefaultSettings(),validated);
verifyEqual(testCase,string(settings.feature.tscoreRatioNames), ...
    ["PO4_CH2" "PO4_CO3"]);
end

function testRatioModeRequiresASelection(testCase)
config = guiDefaultConfig();
config.tscore.ramanFeatureMode = "ratios";
config.tscore.ramanRatioNames = strings(1,0);
verifyError(testCase,@()validateTscoreConfiguration(config.tscore), ...
    'MainGUI:TscoreRatios');
end

function testSummaryReportsPredictorsModelsAndValidation(testCase)
config = guiDefaultConfig();
config.tscore.predictorSource = "combined";
summary = string(formatTscoreConfigSummary(config.tscore));
verifyTrue(testCase,contains(summary,"Raman + demographics"));
verifyTrue(testCase,contains(summary,"PLS (nested rank)"));
verifyTrue(testCase,contains(summary,"SVR (Bayesian nested tuning)"));
verifyTrue(testCase,contains(summary,"grouped LOCO"));
end

function testCNNRejectsCombinedPredictors(testCase)
config = guiDefaultConfig();
config.tscore.predictorSource = "combined";
config.tscore.models = "CNN";
verifyError(testCase,@()validateTscoreConfiguration(config.tscore), ...
    'MainGUI:TscoreCNNPredictors');
end

function testFixedPLSConfigurationAndSummary(testCase)
config = guiDefaultConfig();
config.tscore.models = "PLS";
config.tscore.fixedPLSRank = 6;
validated = validateTscoreConfiguration(config.tscore);
verifyEqual(testCase,validated.fixedPLSRank,6);
verifyTrue(testCase,contains(string(formatTscoreConfigSummary(validated)), ...
    "PLS (fixed rank 6)"));
end

function testFixedPLSRankCannotExceedMaximum(testCase)
config = guiDefaultConfig();
config.tscore.fixedPLSRank = config.tscore.maxPLSRank + 1;
verifyError(testCase,@()validateTscoreConfiguration(config.tscore), ...
    'MainGUI:TscoreFixedPLSRank');
end

function testDialogCreatesCompactTabbedControls(testCase)
parent = figure('Visible','off');
cleanupParent = onCleanup(@()localDelete(parent));
ud = struct('config',guiDefaultConfig());
parent.UserData = ud;
dialogFig = configureTscorePredictionDialog(parent,false);
cleanupDialog = onCleanup(@()localDelete(dialogFig));
mainTabs=findobj(dialogFig,'Tag','TscoreMainTabs');
verifyEqual(testCase,numel(mainTabs.Children),5);
verifyEmpty(testCase,findobj(dialogFig,'Tag','TscoreLocationCombineMode'));
verifyEqual(testCase,numel(findobj(dialogFig,'Tag','TscorePredictorSource')),1);
verifyEqual(testCase,numel(findobj(dialogFig,'Tag','TscoreModelPLS')),1);
verifyEqual(testCase,numel(findobj(dialogFig,'Tag','TscoreModelSVR')),1);
verifyEqual(testCase,numel(findobj(dialogFig,'Tag','TscoreModelMLP')),1);
verifyEqual(testCase,numel(findobj(dialogFig,'Tag','TscoreModelCNN')),1);
verifyEqual(testCase,numel(findobj(dialogFig,'Tag','TscorePLSRankMode')),1);
verifyEqual(testCase,numel(findobj(dialogFig,'Tag','TscorePLSRankValue')),1);
verifyEqual(testCase,numel(findobj(dialogFig,'Tag','TscoreRatioPanel')),1);
verifyEqual(testCase,numel(findobj(dialogFig,'Tag','TscoreRatioPO4CO3')),1);
verifyEqual(testCase,numel(findobj(dialogFig,'Tag','TscoreRatioPO4AmideIII')),1);
verifyEqual(testCase,numel(findobj(dialogFig,'Tag','TscoreRatioPO4CH2')),1);
verifyEqual(testCase,numel(findobj(dialogFig,'Tag','TscoreRatioPO4AmideI')),1);
verifyEqual(testCase,numel(findobj(dialogFig,'Tag','TscoreRatioCO3AmideIII')),1);
svrMode = findobj(dialogFig,'Tag','TscoreSvrTuningMode');
verifyEqual(testCase,get(svrMode,'Value'),1);
end

function testDialogAppliesIndividualAndMultipleRatios(testCase)
parent = figure('Visible','off');
cleanupParent = onCleanup(@()localDelete(parent));
parent.UserData = struct('config',guiDefaultConfig());
dialogFig = configureTscorePredictionDialog(parent,false);
cleanupDialog = onCleanup(@()localDelete(dialogFig));

featureControl = findobj(dialogFig,'Tag','TscoreRamanFeatureMode');
set(featureControl,'Value',2);
featureCallback = get(featureControl,'Callback');
featureCallback(featureControl,[]);

ratioTags = {'TscoreRatioPO4CO3','TscoreRatioPO4AmideIII', ...
    'TscoreRatioPO4CH2','TscoreRatioPO4AmideI','TscoreRatioCO3AmideIII'};
for k = 1:numel(ratioTags)
    set(findobj(dialogFig,'Tag',ratioTags{k}),'Value',0);
end
set(findobj(dialogFig,'Tag','TscoreRatioPO4CO3'),'Value',1);
set(findobj(dialogFig,'Tag','TscoreRatioPO4CH2'),'Value',1);

applyControl = findobj(dialogFig,'Tag','TscoreApply');
applyCallback = get(applyControl,'Callback');
applyCallback(applyControl,[]);

updated = parent.UserData.config.tscore;
verifyEqual(testCase,updated.ramanFeatureMode,"ratios");
verifyEqual(testCase,updated.ramanRatioNames,["PO4_CO3" "PO4_CH2"]);
end

function testDialogAppliesFixedPLSComponents(testCase)
parent = figure('Visible','off');
cleanupParent = onCleanup(@()localDelete(parent));
parent.UserData = struct('config',guiDefaultConfig());
dialogFig = configureTscorePredictionDialog(parent,false);
cleanupDialog = onCleanup(@()localDelete(dialogFig));

modeControl = findobj(dialogFig,'Tag','TscorePLSRankMode');
rankControl = findobj(dialogFig,'Tag','TscorePLSRankValue');
set(modeControl,'Value',2);
modeCallback = get(modeControl,'Callback');
modeCallback(modeControl,[]);
set(rankControl,'String','6');

applyControl = findobj(dialogFig,'Tag','TscoreApply');
applyCallback = get(applyControl,'Callback');
applyCallback(applyControl,[]);

updated = parent.UserData.config.tscore;
verifyEqual(testCase,updated.fixedPLSRank,6);
verifyGreaterThanOrEqual(testCase,updated.maxPLSRank,6);
end

function localDelete(handle)
if isgraphics(handle), delete(handle); end
end

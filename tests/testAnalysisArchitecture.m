function tests = testAnalysisArchitecture
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
rootFolder = fileparts(fileparts(mfilename('fullpath')));
testCase.TestData.RootFolder = fullfile(rootFolder,'app');
testCase.TestData.OriginalPath = path;
addpath(rootFolder, fullfile(rootFolder,'app'));
addpath(fullfile(rootFolder,'app','analysis'));
end

function teardownOnce(testCase)
path(testCase.TestData.OriginalPath);
end

function testRegistryExposesOneReconstructionEntry(testCase)
modes = analysisModeRegistry();
values = string({modes.value});
labels = string({modes.label});

verifyEqual(testCase, sum(string({modes.kind})=="reconstruction"),1);
verifyTrue(testCase, any(values=="reconstructSpectra"));
verifyTrue(testCase, any(labels=="Reconstruct spectra"));
verifyFalse(testCase, any(ismember(values,["reconstructPLS","reconstructMLP","reconstructKRR"])));
verifyFalse(testCase, any(contains(lower(labels), "paired dataset")));
end

function testComparisonModesDeclareComparisonControl(testCase)
modes = analysisModeRegistry();
values = string({modes.value});
expected = ["compareAverageSpectra","compareRatioPlots", ...
    "compareTscorePlots","compareClassificationPlots"];

for value = expected
    idx = find(values == value, 1);
    verifyNotEmpty(testCase, idx);
    verifyTrue(testCase, modes(idx).usesComparison);
    verifyTrue(testCase, modes(idx).usesTissue);
end
end

function testSpatialModesUseAllSelectedTags(testCase)
modes = analysisModeRegistry();
values = string({modes.value});
expected = ["spatialCategorySpectra","spatialMetricProfiles"];

for value = expected
    idx = find(values == value, 1);
    verifyNotEmpty(testCase, idx);
    verifyTrue(testCase, modes(idx).usesTissue);
    verifyTrue(testCase, modes(idx).requiresAllTags);
    verifyFalse(testCase, modes(idx).usesComparison);
end
end

function testOutputProducingModesRequireOutputFolderMetadata(testCase)
modes = analysisModeRegistry();
values = string({modes.value});
expected = ["strictPredictTscore","sweepTscoreSettings", ...
    "reconstructSpectra","locoTscore"];

for value = expected
    idx = find(values == value, 1);
    verifyNotEmpty(testCase, idx);
    verifyTrue(testCase, modes(idx).producesOutput);
end
end

function testEveryCadaverAnalysisHasDedicatedModule(testCase)
rootFolder = testCase.TestData.RootFolder;
expected = {
    'analysisDisplayRatios.m'
    'analysisDisplayFWHM.m'
    'analysisDetectOutliers.m'
    'analysisPredictTscore.m'
    'analysisGroupTscore.m'
    'analysisRatioGroupTscore.m'
    'analysisStrictPredictTscore.m'
    'analysisCompareAverageSpectra.m'
    'analysisCategoryAverageSpectra.m'
    'analysisCompareRatios.m'
    'analysisPO4VisibilityQC.m'
    'analysisDemographics.m'
    'analysisVisualizeAutoscaling.m'
    'analysisCompareTscore.m'
    'analysisCompareClassification.m'
    'analysisSweepTscore.m'
    'analysisSpatialCategorySpectra.m'
    'analysisSpatialMetricProfiles.m'};

for k = 1:numel(expected)
    verifyTrue(testCase, isfile(fullfile(rootFolder, 'analysis', expected{k})), ...
        sprintf('Missing analysis module: %s', expected{k}));
end
end

function testGroupTscoreModeIsTableOnlyDatasetAnalysis(testCase)
modes = analysisModeRegistry();
values = string({modes.value});
idx = find(values == "groupTscore", 1);
verifyNotEmpty(testCase, idx);
verifyEqual(testCase, string(modes(idx).kind), "datasetAnalysis");
verifyTrue(testCase, modes(idx).usesTissue);
verifyFalse(testCase, modes(idx).usesComparison);
verifyFalse(testCase, modes(idx).producesOutput);

moduleText = fileread(fullfile(testCase.TestData.RootFolder, ...
    'analysis', 'analysisGroupTscore.m'));
verifyFalse(testCase, contains(moduleText, 'localPlot'));
end

function testGroupTscoreLabelsAndRatioMode(testCase)
modes = analysisModeRegistry();
values = string({modes.value});
labels = string({modes.label});

tagIdx = find(values == "groupTscore",1);
ratioIdx = find(values == "ratioGroupTscore",1);
verifyEqual(testCase,labels(tagIdx),"Tag group T-score analysis");
verifyEqual(testCase,labels(ratioIdx),"Ratio group T-score analysis");
verifyEqual(testCase,string(modes(ratioIdx).kind),"datasetAnalysis");
verifyTrue(testCase,modes(ratioIdx).usesTissue);
verifyFalse(testCase,modes(ratioIdx).usesComparison);
verifyFalse(testCase,modes(ratioIdx).producesOutput);

moduleText = fileread(fullfile(testCase.TestData.RootFolder, ...
    'analysis','analysisRatioGroupTscore.m'));
verifyTrue(testCase,contains(moduleText,'localPlotRatioGroupTscore'));
verifyTrue(testCase,isfile(fullfile(testCase.TestData.RootFolder, ...
    'analysis','localComputeRatioGroupTscoreTable.m')));
verifyTrue(testCase,isfile(fullfile(testCase.TestData.RootFolder, ...
    'analysis','localPlotRatioGroupTscore.m')));
end

function testStrictPLSPredictorIsSharedModule(testCase)
verifyTrue(testCase, isfile(fullfile(testCase.TestData.RootFolder, ...
    'analysis', 'localPredictTscorePLS.m')));
end

function testDispatcherRemainsThin(testCase)
dispatcher = fileread(fullfile(testCase.TestData.RootFolder, ...
    'runCadaverDatasetAnalysis.m'));
verifyLessThan(testCase, numel(splitlines(string(dispatcher))), 100);
verifyEqual(testCase, numel(regexp(dispatcher, '(?m)^function\s', 'match')), 1);
end

function testDefaultTissuesAreValid(testCase)
config = guiDefaultConfig();
verifyTrue(testCase, any(config.analysis.tissue == ["E","P","T"]));
verifyTrue(testCase, any(config.analysis.comparisonTissue == ["E","P","T"]));
end

function testSpatialProfileXAxisLabel(testCase)
plotter = fileread(fullfile(testCase.TestData.RootFolder, ...
    'analysis','localPlotSpatialProfileGrid.m'));
verifyTrue(testCase,contains(plotter,"Spatial location tag"));
end

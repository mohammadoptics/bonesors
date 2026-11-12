function tests = testTagSelection
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
rootFolder = fileparts(fileparts(mfilename('fullpath')));
testCase.TestData.OriginalPath = path;
addpath(rootFolder, fullfile(rootFolder,'app'));
end

function teardownOnce(testCase)
path(testCase.TestData.OriginalPath);
end

function testNormalizesAndDeduplicatesCaseInsensitively(testCase)
actual = normalizeTagSelection({' d2p1_mm00 ', 'D2P1_MM00', 'D3P1_MM00'});
verifyEqual(testCase, actual, {'d2p1_mm00', 'D3P1_MM00'});
end

function testSingleExactTag(testCase)
available = {'D2P1_MM00', 'D3P1_MM00', 'D2P1_MP03'};
verifyEqual(testCase, selectTagRows(available, {'D3P1_MM00'}, ...
    'single', 'exact'), 2);
end

function testSingleRejectsMultipleTags(testCase)
verifyError(testCase, @()selectTagRows({'A','B'}, {'A','B'}, ...
    'single', 'exact'), 'MainGUI:SingleTagRequired');
end

function testPriorityUsesRequestedOrder(testCase)
available = {'D2P1_MM00', 'D3P1_MM00'};
verifyEqual(testCase, selectTagRows(available, ...
    {'D9P1_MM00','D3P1_MM00','D2P1_MM00'}, 'priority', 'exact'), 2);
end

function testPrefixAndAllModes(testCase)
available = {'D2P1_MM00', 'D3P1_MM00', 'D2P1_MP03'};
verifyEqual(testCase, selectTagRows(available, {'D2P1'}, ...
    'all', 'prefix'), [1 3]);
end

function testSpectrumParser(testCase)
verifyEqual(testCase, parseSpectrumNumbers('1, 2 3'), [1 2 3]);
verifyError(testCase, @()parseSpectrumNumbers('2.5'), ...
    'MainGUI:InvalidSpectrumNumber');
end

function testSpectrumExpressionSubtractionPreservesWrittenOrder(testCase)
[columns, mode, expression] = parseSpectrumExpression('3 - 2');
verifyEqual(testCase, columns, [3 2]);
verifyEqual(testCase, mode, "diff");
verifyEqual(testCase, expression, "3-2");
end

function testSpectrumExpressionAddition(testCase)
[columns, mode, expression] = parseSpectrumExpression('3+2+1');
verifyEqual(testCase, columns, [3 2 1]);
verifyEqual(testCase, mode, "add");
verifyEqual(testCase, expression, "3+2+1");
end

function testSpectrumExpressionConcatenation(testCase)
[columns, mode, expression] = parseSpectrumExpression('3|2');
verifyEqual(testCase, columns, [3 2]);
verifyEqual(testCase, mode, "concat");
verifyEqual(testCase, expression, "3|2");

[columns, mode, expression] = parseSpectrumExpression('3, 2');
verifyEqual(testCase, columns, [3 2]);
verifyEqual(testCase, mode, "concat");
verifyEqual(testCase, expression, "3|2");
end

function testSpectrumExpressionRejectsMixedOperations(testCase)
verifyError(testCase, @()parseSpectrumExpression('3-2+1'), ...
    'MainGUI:InvalidSpectrumExpression');
verifyError(testCase, @()parseSpectrumExpression('3-2-1'), ...
    'MainGUI:InvalidSpectrumExpression');
end

function testPredictionRejectsAllTags(testCase)
defaults = guiDefaultConfig();
options = defaults.analysis;
options.mode = "predictTscore";
options.tagSelectionMode = "all";
verifyError(testCase, @()validateAnalysisRequest(options), ...
    'MainGUI:AllTagsNotAllowedForPrediction');
end

function testConcatenationRequiresFeatureVectorAnalysis(testCase)
defaults = guiDefaultConfig();
options = defaults.analysis;
options.spectrumCombineMode = "concat";
options.mode = "displayRatios";
verifyError(testCase, @()validateAnalysisRequest(options), ...
    'MainGUI:ConcatRequiresFeatureVectorAnalysis');

options.mode = "predictTscore";
validateAnalysisRequest(options);

options.mode = "groupTscore";
validateAnalysisRequest(options);

options.mode = "ratioGroupTscore";
validateAnalysisRequest(options);
end

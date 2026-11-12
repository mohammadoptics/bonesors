function tests = testSpectrumExpressions
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
rootFolder = fileparts(fileparts(mfilename('fullpath')));
testCase.TestData.OriginalPath = path;
addpath(rootFolder);
addpath(fullfile(rootFolder, 'analysis'));
end

function teardownOnce(testCase)
path(testCase.TestData.OriginalPath);
end

function testSubtractNormalizesEachColumnBeforeCombining(testCase)
wn = (1:4).';
spectrum3 = [2; 4; 6; 8];
spectrum2 = [1; 3; 3; 6];
settings = localSettings("diff");

actual = localBuildRatioSpectrum(wn, [spectrum3 spectrum2], settings);
expected = spectrum3 ./ max(spectrum3) - spectrum2 ./ max(spectrum2);

verifyEqual(testCase, actual, expected, 'AbsTol', 1e-12);
end

function testAddNormalizesEachColumnBeforeCombining(testCase)
wn = (1:4).';
spectrum3 = [2; 4; 6; 8];
spectrum2 = [1; 3; 3; 6];
settings = localSettings("add");

actual = localBuildRatioSpectrum(wn, [spectrum3 spectrum2], settings);
expected = spectrum3 ./ max(spectrum3) + spectrum2 ./ max(spectrum2);

verifyEqual(testCase, actual, expected, 'AbsTol', 1e-12);
end

function testConcatNormalizesAndPreservesWrittenColumnOrder(testCase)
wn = (1:4).';
spectrum3 = [2; 4; 6; 8];
spectrum2 = [1; 3; 3; 6];
settings = localSettings("concat");

actual = localBuildSpectrumFeatures(wn, [spectrum3 spectrum2], settings);
expected = [reshape(spectrum3 ./ max(spectrum3), 1, []) ...
    reshape(spectrum2 ./ max(spectrum2), 1, [])];

verifyEqual(testCase, actual, expected, 'AbsTol', 1e-12);
end

function testCombinationRejectsDisabledNormalization(testCase)
options = struct('spectrumCombineMode', "diff");
settings = localSettings("diff");
settings.normalizationRegion = "none";
verifyError(testCase, @()validateSpectrumCombinationSettings(options, settings), ...
    'MainGUI:SpectrumCombinationRequiresNormalization');

options.spectrumCombineMode = "single";
validateSpectrumCombinationSettings(options, settings);
end

function settings = localSettings(mode)
settings = struct('normalizationRegion', "FullSpectrum", ...
    'normalizationMethod', "peak", 'spectrumCombineMode', mode);
end

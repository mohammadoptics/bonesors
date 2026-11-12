function tests = testRatioDisplayNormalization
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
rootFolder = fileparts(fileparts(mfilename('fullpath')));
testCase.TestData.OriginalPath = path;
addpath(rootFolder, fullfile(rootFolder, 'analysis'));
end

function teardownOnce(testCase)
path(testCase.TestData.OriginalPath);
end

function testDefaultsAndIndependentConfig(testCase)
c = guiDefaultConfig();
verifyEqual(testCase, c.ratioDisplay.normalizationRegion, "PO4");
s = analysisDefaultSettings();
s.feature.spectrumCombineMode = "diff";
for region = ["none","PO4","CO3","CH2","AmideI","AmideIII","FullSpectrum"]
    for method = ["peak","peakBaseline","area"]
        r = struct('normalizationRegion', region, 'normalizationMethod', method);
        actual = applyRatioDisplayConfigToSettings(s, r);
        verifyEqual(testCase, actual.feature.normalizationRegion, region);
        verifyEqual(testCase, actual.feature.normalizationMethod, method);
        verifyEqual(testCase, actual.feature.fixedPLSRank, s.feature.fixedPLSRank);
    end
end
verifyEqual(testCase, c.tscore.normalizationRegion, "PO4");
end

function testSubtractAndAddAfterIndividualNormalization(testCase)
[wn, spectra] = sampleSpectra();
for expression = ["3-2","3+2"]
    [columns, mode] = parseSpectrumExpression(expression);
    verifyEqual(testCase, columns, [3 2]);
    for region = ["PO4","CH2","AmideIII","FullSpectrum"]
        for method = ["peak","peakBaseline","area"]
            s = analysisDefaultSettings();
            s.feature.spectrumCombineMode = mode;
            s = applyRatioDisplayConfigToSettings(s, struct( ...
                'normalizationRegion', region, 'normalizationMethod', method));
            a = normalizeSpectra(wn, spectra(:,1), region, method);
            b = normalizeSpectra(wn, spectra(:,2), region, method);
            if mode == "diff", expected = a-b; else, expected = a+b; end
            actual = localBuildRatioSpectrum(wn, spectra, s.feature);
            verifyEqual(testCase, actual, expected, 'AbsTol', 1e-12);
            expectedRatios = localCalcRatios(wn, expected);
            actualRatios = localBuildRatioStruct(wn, spectra, s.feature);
            verifyEqual(testCase, actualRatios.PO4_CO3, expectedRatios.PO4_CO3, 'AbsTol', 1e-10);
        end
    end
end
end

function testRegionChangesDifferenceButNotSingleSpectrumRatio(testCase)
[wn, spectra] = sampleSpectra();
s = analysisDefaultSettings();
s.feature.spectrumCombineMode = "diff";
s.feature.normalizationRegion = "CH2";
ch2 = localBuildRatioStruct(wn, spectra, s.feature);
singleCH2 = localBuildRatioStruct(wn, spectra(:,1), s.feature);
s.feature.normalizationRegion = "AmideIII";
amide = localBuildRatioStruct(wn, spectra, s.feature);
singleAmide = localBuildRatioStruct(wn, spectra(:,1), s.feature);
verifyGreaterThan(testCase, abs(ch2.PO4_CO3-amide.PO4_CO3), 1e-3);
verifyEqual(testCase, singleCH2.PO4_CO3, singleAmide.PO4_CO3, 'AbsTol', 1e-12);
end

function testConcatenationIsNotOneRatioSpectrum(testCase)
s = analysisDefaultSettings();
s.feature.spectrumCombineMode = "concat";
c = guiDefaultConfig();
verifyError(testCase, @()applyRatioDisplayConfigToSettings(s, c.ratioDisplay), ...
    'MainGUI:RatioDisplayConcatenation');
end

function testGUIControlVisibility(testCase)
existing = findall(groot, 'Type', 'figure');
GUI_Ver2;
created = setdiff(findall(groot, 'Type', 'figure'), existing);
cleanup = onCleanup(@()delete(created)); %#ok<NASGU>
verifyNumElements(testCase, created, 1);
fig = created(1);
c = fig.UserData.controls;
verifyEqual(testCase, string(c.ratioRegionPopup.Visible), "on");
verifyEqual(testCase, string(c.tscoreConfigButton.Visible), "off");
registry = analysisModeRegistry();
c.modePopup.Value = find(strcmp({registry.value}, 'predictTscore'));
callback = c.modePopup.Callback;
callback(c.modePopup, []);
verifyEqual(testCase, string(c.ratioRegionPopup.Visible), "off");
verifyEqual(testCase, string(c.tscoreConfigButton.Visible), "on");
c.modePopup.Value = find(strcmp({registry.value}, 'compareRatioPlots'));
callback(c.modePopup, []);
verifyEqual(testCase, string(c.ratioRegionPopup.Visible), "on");
c.ratioRegionPopup.Value = 5; % Amide III selection is shared across display modes.
c.ratioMethodPopup.Value = 3; % Area.
c.modePopup.Value = find(strcmp({registry.value}, 'categoryAverageSpectra'));
callback(c.modePopup, []);
verifyEqual(testCase, string(c.ratioRegionPopup.Visible), "on");
verifyEqual(testCase, string(c.tscoreConfigButton.Visible), "off");
verifyEqual(testCase, c.ratioRegionPopup.Value, 5);
verifyEqual(testCase, c.ratioMethodPopup.Value, 3);
verifyTrue(testCase, contains(string(c.ratioMethodPopup.TooltipString), "average by category"));
c.ratioRegionPopup.Value = find(strcmp(c.ratioRegionPopup.String, 'None'));
normCallback = c.ratioRegionPopup.Callback;
normCallback(c.ratioRegionPopup, []);
verifyEqual(testCase, string(c.ratioMethodPopup.Enable), "off");
c.ratioRegionPopup.Value = 1;
normCallback(c.ratioRegionPopup, []);
verifyEqual(testCase, string(c.ratioMethodPopup.Enable), "on");
end

function testNoneUsesLoadedIntensitiesAndPreservesTscoreValidation(testCase)
[wn, spectra] = sampleSpectra();
for mode = ["single","diff","add"]
    s = analysisDefaultSettings();
    s.feature.spectrumCombineMode = mode;
    s = applyRatioDisplayConfigToSettings(s, struct( ...
        'normalizationRegion', "none", 'normalizationMethod', "peak"));
    if mode == "single"
        input = spectra(:,1); expected = input;
    elseif mode == "diff"
        input = spectra; expected = spectra(:,1)-spectra(:,2);
    else
        input = spectra; expected = spectra(:,1)+spectra(:,2);
    end
    verifyEqual(testCase, localBuildRatioSpectrum(wn, input, s.feature), expected);
    for analysisMode = ["displayRatios","compareRatioPlots","categoryAverageSpectra"]
        options = struct('mode', analysisMode, 'spectrumCombineMode', mode);
        validateSpectrumCombinationSettings(options, s.feature);
    end
    if mode ~= "single"
        options.mode = "predictTscore";
        verifyError(testCase, @()validateSpectrumCombinationSettings(options, s.feature), ...
            'MainGUI:SpectrumCombinationRequiresNormalization');
    end
end
end

function testCategoryMeanNormalizesBeforeExpressionAndAveraging(testCase)
[wn, spectra] = sampleSpectra();
records(1) = struct('Wavenumber', wn, 'Spectrum', spectra);
records(2) = struct('Wavenumber', wn, 'Spectrum', spectra.*[1.7 0.6]+0.1);
for mode = ["single","diff","add"]
    inputRecords = records;
    if mode == "single"
        for k = 1:2, inputRecords(k).Spectrum = records(k).Spectrum(:,1); end
    end
    for region = ["none","PO4","CO3","CH2","AmideI","AmideIII","FullSpectrum"]
        for method = ["peak","peakBaseline","area"]
            s = analysisDefaultSettings();
            s.feature.spectrumCombineMode = mode;
            s = applyRatioDisplayConfigToSettings(s, struct( ...
                'normalizationRegion', region, 'normalizationMethod', method));
            expected = zeros(size(wn));
            for k = 1:2
                a = normalizeSpectra(wn, inputRecords(k).Spectrum(:,1), region, method);
                if mode == "single"
                    combined = a;
                else
                    b = normalizeSpectra(wn, inputRecords(k).Spectrum(:,2), region, method);
                    if mode == "diff", combined = a-b; else, combined = a+b; end
                end
                expected = expected + combined/2;
            end
            [actualWn, actual, n] = localMeanSpectrumForRecordsCombined( ...
                inputRecords, s.feature, false, "none", "peak");
            verifyEqual(testCase, actualWn, wn);
            verifyEqual(testCase, n, 2);
            verifyEqual(testCase, actual, expected, 'AbsTol', 1e-12);
        end
    end
end
end

function [wn, spectra] = sampleSpectra()
wn = (800:2:1750).';
centers = [960 1075 1440 1650 1270];
widths = [12 10 25 20 20];
amplitudes = [8 2; 3 1; 4 2; 3 2; 5 1];
spectra = ones(numel(wn),2)*0.05;
for k = 1:numel(centers)
    spectra = spectra + exp(-0.5*((wn-centers(k))/widths(k)).^2)*amplitudes(k,:);
end
end

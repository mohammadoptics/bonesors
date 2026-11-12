function tests = testFWHMDisplay
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
testCase.TestData.OriginalPath = path;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root, fullfile(root,'analysis'));
end

function teardownOnce(testCase)
path(testCase.TestData.OriginalPath);
end

function testRegistryMatchesRatioControls(testCase)
modes = analysisModeRegistry();
ratio = modes(strcmp({modes.value},'displayRatios'));
width = modes(strcmp({modes.value},'displayFWHM'));
verifyNumElements(testCase, width, 1);
verifyEqual(testCase, width.label, 'Display Raman FWHM');
for name = ["kind","datasetType","usesTissue","usesComparison","requiresAllTags","producesOutput"]
    verifyEqual(testCase, width.(name), ratio.(name));
end
end

function testGUIControlVisibilityAndSharedSelection(testCase)
existing = findall(groot,'Type','figure');
GUI_Ver2;
created = setdiff(findall(groot,'Type','figure'),existing);
cleanup = onCleanup(@()delete(created)); %#ok<NASGU>
verifyNumElements(testCase,created,1);
c = created(1).UserData.controls;
c.ratioRegionPopup.Value = 3; % CH2.
c.ratioMethodPopup.Value = 2;
modes = analysisModeRegistry();
c.modePopup.Value = find(strcmp({modes.value},'displayFWHM'));
callback = c.modePopup.Callback;
callback(c.modePopup,[]);
verifyEqual(testCase,string(c.ratioRegionPopup.Visible),"on");
verifyEqual(testCase,c.ratioRegionPopup.Value,3);
verifyEqual(testCase,c.ratioMethodPopup.Value,2);
verifyEqual(testCase,string(c.tscoreConfigButton.Visible),"off");
verifyEqual(testCase,string(c.tissuePopup.Enable),"on");
verifyEqual(testCase,string(c.comparisonTissuePopup.Enable),"off");
verifyTrue(testCase,contains(string(c.ratioMethodPopup.TooltipString),'FWHM'));
labels = findall(created(1),'Style','text');
verifyTrue(testCase,any(arrayfun(@(h)any(contains(string(h.String),'FWHM display:'),'all'),labels)));
c.ratioRegionPopup.Value = find(strcmp(c.ratioRegionPopup.String,'None'));
normCallback = c.ratioRegionPopup.Callback;
normCallback(c.ratioRegionPopup,[]);
verifyEqual(testCase,string(c.ratioMethodPopup.Enable),"off");
verifyTrue(testCase,any(arrayfun(@(h)any(contains(string(h.String),'FWHM display: use loaded intensities'),'all'),labels)));
c.ratioRegionPopup.Value = 3;
normCallback(c.ratioRegionPopup,[]);
c.modePopup.Value = find(strcmp({modes.value},'displayRatios'));
callback(c.modePopup,[]);
verifyEqual(testCase,c.ratioRegionPopup.Value,3);
end

function testGaussianWidthAndScaling(testCase)
wn = (930:0.1:990).';
sigma = 6;
y = exp(-0.5*((wn-960)/sigma).^2);
[actual,ok] = localFWHM(wn,y,[930 990]);
verifyTrue(testCase,ok);
verifyEqual(testCase,actual,2*sqrt(2*log(2))*sigma,'AbsTol',0.005);
verifyEqual(testCase,localFWHM(wn,7*y+2,[930 990]),actual,'AbsTol',1e-10);
end

function testBankUsesPerSpectrumNormalization(testCase)
[records,feature] = sampleRecords();
for mode = ["single","diff","add"]
    feature.spectrumCombineMode = mode;
    input = records;
    for k = 1:numel(input)
        if mode == "single", input(k).Spectrum = input(k).Spectrum(:,1); end
    end
    for region = ["none","CH2","PO4"]
        feature.normalizationRegion = region;
        validateSpectrumCombinationSettings(struct('mode',"displayFWHM", ...
            'spectrumCombineMode',mode),feature);
        bank = localBuildFWHMBankFromRecords(input,{'NORMAL','OSTEOPENIA','OSTEOPOROSIS'},feature);
        for k = 1:numel(input)
            expected = localCalcFWHMFeatures(input(k).Wavenumber, ...
                localBuildRatioSpectrum(input(k).Wavenumber,input(k).Spectrum,feature));
            verifyEqual(testCase,bank.(input(k).Category),expected);
        end
    end
end
end

function testStandaloneFivePanelDisplay(testCase)
[records,feature] = sampleRecords();
for k = 1:numel(records), records(k).Spectrum = records(k).Spectrum(:,1); end
existing = findall(groot,'Type','figure');
fig = localDisplayFWHM(records,'T',3,feature,struct());
cleanup = onCleanup(@()delete(fig)); %#ok<NASGU>
verifyNumElements(testCase,setdiff(findall(groot,'Type','figure'),existing),1);
verifyTrue(testCase,contains(fig.Name,'FWHM'));
axesHandles = findall(fig,'Type','axes');
verifyNumElements(testCase,axesHandles,5);
bank = localBuildFWHMBankFromRecords(records,{'NORMAL','OSTEOPENIA','OSTEOPOROSIS'},feature);
metrics = localFWHMMetricDefinitions();
markers = {["s","square"],["d","diamond"],["o","circle"]};
for k = 1:numel(metrics)
    ax = axesHandles(strcmp(string(arrayfun(@(a)a.YLabel.String,axesHandles,'UniformOutput',false)), ...
        string(metrics(k).label)+" (cm^{-1})"));
    verifyNumElements(testCase,ax,1);
    points = findall(ax,'Type','scatter');
    verifyNumElements(testCase,points,3);
    for j = 1:numel(records)
        point = points(ismember(string({points.Marker}), markers{j}));
        assertNumElements(testCase,point,1);
        verifyEqual(testCase,point.YData,bank.(records(j).Category).(metrics(k).field),'AbsTol',1e-10);
    end
end
end

function testInvalidBandsDoNotCrashPlot(testCase)
[records,feature] = sampleRecords();
for k = 1:numel(records), records(k).Spectrum = zeros(size(records(k).Wavenumber)); end
feature.normalizationRegion = "none";
fig = localDisplayFWHM(records,'E',2,feature,struct());
cleanup = onCleanup(@()delete(fig)); %#ok<NASGU>
axesHandles = findall(fig,'Type','axes');
verifyNumElements(testCase,axesHandles,5);
for ax = axesHandles.'
    verifyEqual(testCase,ax.YLim,[0 1]);
    texts = findall(ax,'Type','text');
    verifyTrue(testCase,any(strcmp({texts.String},'No valid measurements')));
end
end

function testNonphysicalCombinationsRejected(testCase)
[records,feature] = sampleRecords();
for mode = ["concat","ratiodiff","rationormdiff","ratiosymnormdiff"]
    feature.spectrumCombineMode = mode;
    verifyError(testCase,@()localDisplayFWHM(records,'T',[3 2],feature,struct()), ...
        'MainGUI:FWHMRequiresSpectrum');
end
end

function [records,feature] = sampleRecords()
wn = (800:0.5:1750).';
centers = [960 1075 1270 1440 1650];
widths = [8 10 12 15 10];
spectra = zeros(numel(wn),2);
for k = 1:numel(centers)
    spectra = spectra + exp(-0.5*((wn-centers(k))/widths(k)).^2)*[k+2 1];
end
cats = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
for k = 1:3
    records(k) = struct('Wavenumber',wn,'Spectrum',spectra*k,'Category',cats{k}); %#ok<AGROW>
end
s = analysisDefaultSettings();
feature = s.feature;
feature.spectrumCombineMode = "single";
feature.normalizationRegion = "CH2";
feature.normalizationMethod = "peak";
end

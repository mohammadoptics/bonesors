function tests = testTscorePlotStyle
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
rootFolder = fileparts(fileparts(mfilename('fullpath')));
testCase.TestData.OriginalPath = path;
addpath(rootFolder, fullfile(rootFolder,'app'));
addpath(fullfile(rootFolder,'app','analysis'));
end

function teardownOnce(testCase)
path(testCase.TestData.OriginalPath);
end

function testStyleUsesReadableMarkerSize(testCase)
style = localTscorePlotStyle();
verifyEqual(testCase, style.markerSize, 9);
verifyEqual(testCase, style.scatterSize, 81);
verifyEqual(testCase, style.axisFontSize, 15);
verifyEqual(testCase, style.axisLineWidth, 1.7);
end

function testNestedRankDetailsAreNotPrintedOnPlot(testCase)
annotation = string(localTscoreModelAnnotation( ...
    "PLS nested LOCO ranks 2-4 (median 3)",NaN));
verifyEqual(testCase, annotation, "model = PLS");
verifyFalse(testCase, contains(lower(annotation),"nested"));
verifyFalse(testCase, contains(lower(annotation),"loco"));
end

function testContextHeaderIncludesOffsetAndNormalization(testCase)
settings = analysisDefaultSettings();
settings.feature.normalizationRegion = "CH2";
header = string(localTscorePlotContextText(2,settings.feature));
verifyTrue(testCase, contains(header,"Offset = 3-mm"));
verifyTrue(testCase, contains(header,"Normalization = CH_{2}"));

settings.feature.normalizationRegion = "PO4";
header = string(localTscorePlotContextText(3,settings.feature));
verifyTrue(testCase, contains(header,"Offset = 6-mm"));
verifyTrue(testCase, contains(header,"Normalization = PO_{4}^{3-}"));
end

function testSingleTscorePlotUsesCompactStyle(testCase)
cleanup = onCleanup(@()delete(findall(groot,'Type','figure')));
yTrue = [-3;-2;-1;0;1;2];
yPred = [-2.8;-2.2;-0.8;0.1;0.8;1.7];
cats = ["OSTEOPOROSIS";"OSTEOPOROSIS";"OSTEOPENIA"; ...
    "OSTEOPENIA";"NORMAL";"NORMAL"];
settings = analysisDefaultSettings();
settings.feature.normalizationRegion = "CH2";
localPlotTscorePrediction(yTrue,yPred,cats,NaN,'E',2, ...
    "E spectrum 2 PLS","PLS nested LOCO ranks 2-4 (median 3)", ...
    settings.feature);

fig = gcf;
ax = findobj(fig,'Type','axes');
points = findall(ax,'Type','scatter');
style = localTscorePlotStyle();
verifyEqual(testCase, ax.FontSize, style.axisFontSize);
verifyEqual(testCase, ax.LineWidth, style.axisLineWidth);
verifyEqual(testCase, numel(points), 3);
for k = 1:numel(points)
    verifyEqual(testCase, get(points(k),'SizeData'), style.scatterSize);
end
end


function testRatioGroupUsesOneFigureWithLetteredSubplots(testCase)
cleanup = onCleanup(@()delete(findall(groot,'Type','figure')));
settings = analysisDefaultSettings();
result = struct('ok',true,'y',[-3;-2;-1;0;1], ...
    'yPred',[-2.8;-2.1;-0.9;0.1;0.8], ...
    'cats',["OSTEOPOROSIS";"OSTEOPOROSIS";"OSTEOPENIA";"NORMAL";"NORMAL"], ...
    'bestRank',1,'modelText',"PLS fixed rank 1");
entries(1) = struct('RatioName',"PO4_CH2",'Model',"PLS", ...
    'FeatureSettings',settings.feature,'Result',result,'Status',"OK");
settings.feature.useWeight = true;
entries(2) = struct('RatioName',"PO4_CO3",'Model',"PLS", ...
    'FeatureSettings',settings.feature,'Result',result,'Status',"OK");

fig = localPlotRatioGroupTscore(entries,2);
verifyEqual(testCase,numel(findall(groot,'Type','figure')),1);
axesHandles = findall(fig,'Type','axes');
titles = string(arrayfun(@(ax)get(get(ax,'Title'),'String'), ...
    axesHandles,'UniformOutput',false));
verifyTrue(testCase,any(contains(titles,"(A, PO_{4}^{3-} / CH_{2})")));
verifyTrue(testCase,any(contains(titles, ...
    "(B, PO_{4}^{3-} / CO_{3}^{2-} + weight)")));
verifyEqual(testCase,numel(findall(fig,'Type','legend')),1);
yLabels = string(arrayfun(@(ax)get(get(ax,'YLabel'),'String'), ...
    axesHandles,'UniformOutput',false));
verifyTrue(testCase,all(yLabels == "Predicted T-score"));
xLabels = string(arrayfun(@(ax)get(get(ax,'XLabel'),'String'), ...
    axesHandles,'UniformOutput',false));
verifyTrue(testCase,all(xLabels == "Measured T-score"));
annotations = findall(fig,'Tag','TscoreAnnotation');
positions = get(annotations,'Position');
if ~iscell(positions), positions = {positions}; end
positions = vertcat(positions{:});
verifyEqual(testCase,positions(:,1:2),repmat([0.95 0.06],numel(annotations),1));
allText = strings(numel(annotations),1);
for k = 1:numel(annotations)
    value = get(annotations(k),'String');
    if iscell(value), value = strjoin(string(value),newline); end
    allText(k) = string(value);
end
verifyFalse(testCase,any(contains(allText,"Offset")));
verifyFalse(testCase,any(contains(allText,"Ratio")));
verifyFalse(testCase,any(contains(allText,"Normalization")));
verifyFalse(testCase,any(contains(allText,"n =")));
end

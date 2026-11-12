function figureHandle = localPlotRatioGroupTscore(plotEntries, spectrumNumber)
%LOCALPLOTRATIOGROUPTSCORE Plot every ratio/model result in one figure.

nPanels = numel(plotEntries);
if nPanels == 0
    figureHandle = gobjects(0);
    return
end

nColumns = min(3,ceil(sqrt(nPanels)));
nRows = ceil(nPanels/nColumns);
figureHandle = figure('Name','Ratio group T-score analysis', ...
    'Color','w','Units','inches', ...
    'Position',[0 0 min(18,5.5*nColumns) min(14,5.5*nRows)]);
layout = tiledlayout(figureHandle,nRows,nColumns, ...
    'TileSpacing','compact','Padding','compact');
sharedLegend = gobjects(0);

for panelIndex = 1:nPanels
    ax = nexttile(layout);
    entry = plotEntries(panelIndex);
    demographicSuffix = localDemographicTitleSuffix(entry.FeatureSettings);
    panelTitle = sprintf('(%c, %s%s)',char('A' + panelIndex - 1), ...
        char(localTscoreRatioLabel(entry.RatioName,true)), ...
        char(demographicSuffix));

    if isstruct(entry.Result) && isfield(entry.Result,'ok') && entry.Result.ok
        result = entry.Result;
        options = struct('showContext',false, 'showTotalN',false, ...
            'showLegend',isempty(sharedLegend), ...
            'xLabel','Measured T-score', 'yLabel','Predicted T-score', ...
            'titleInterpreter','tex', 'annotationPosition',[0.95 0.06], ...
            'annotationHorizontalAlignment','right', ...
            'annotationVerticalAlignment','bottom');
        panelLegend = localPlotTscorePredictionPanel( ...
            ax,result.y,result.yPred,result.cats, ...
            result.bestRank,panelTitle,result.modelText,spectrumNumber, ...
            entry.FeatureSettings,"",options);
        if isgraphics(panelLegend)
            sharedLegend = panelLegend;
        end
    else
        axis(ax,'off');
        title(ax,panelTitle,'Interpreter','tex','FontWeight','bold', ...
            'FontSize',localTscorePlotStyle().titleFontSize);
        text(ax,0.05,0.95,sprintf('model = %s\n%s', ...
            char(entry.Model),char(entry.Status)), ...
            'Units','normalized','VerticalAlignment','top', ...
            'Tag','TscoreAnnotation', ...
            'FontSize',localTscorePlotStyle().annotationFontSize);
    end
end


if isgraphics(sharedLegend)
    sharedLegend.Orientation = 'horizontal';
    sharedLegend.NumColumns = 3;
    sharedLegend.Layout.Tile = 'south';
end
end

function suffix = localDemographicTitleSuffix(featureSettings)
names = strings(0,1);
if isfield(featureSettings,'useAge') && featureSettings.useAge
    names(end+1) = "age";
end
if isfield(featureSettings,'useSex') && featureSettings.useSex
    names(end+1) = "sex";
end
if isfield(featureSettings,'useBMI') && featureSettings.useBMI
    names(end+1) = "BMI";
end
if isfield(featureSettings,'useWeight') && featureSettings.useWeight
    names(end+1) = "weight";
end

if isempty(names)
    suffix = "";
else
    suffix = " + " + strjoin(names," + ");
end
end

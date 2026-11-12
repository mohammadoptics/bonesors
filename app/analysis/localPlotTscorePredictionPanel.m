function legendHandle = localPlotTscorePredictionPanel(ax, yTrue, yPred, cats, bestRank, ...
        panelTitle, modelText, spectrumNumber, featureSettings, ...
        contextTextOverride, plotOptions)
    if nargin < 10
        contextTextOverride = "";
    end
    if nargin < 11
        plotOptions = struct();
    end
    plotOptions = localCompletePlotOptions(plotOptions);
    legendHandle = gobjects(0);
    catList = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
    catClr  = containers.Map(catList, {'b','g','r'});
    marks = {'s','d','o'};
    style = localTscorePlotStyle();
    dotSize = style.scatterSize;
    markerSizeLeg = style.markerSize;

    hold(ax,'on');
    axis(ax,'square');

    hLegend = gobjects(1,numel(catList));
    for k = 1:numel(catList)
        idx = strcmpi(cats, catList{k});
        if ~any(idx)
            continue
        end

        scatter(ax, yTrue(idx), yPred(idx), dotSize, ...
            'Marker', marks{k}, ...
            'MarkerFaceColor', catClr(catList{k}), ...
            'MarkerEdgeColor', catClr(catList{k}), ...
            'HandleVisibility','off');

        hLegend(k) = plot(ax, nan, nan, marks{k}, ...
            'MarkerFaceColor', catClr(catList{k}), ...
            'MarkerEdgeColor', catClr(catList{k}), ...
            'LineStyle','none', ...
            'MarkerSize', markerSizeLeg, ...
            'DisplayName', sprintf('%s (n=%d)', catList{k}, sum(idx)));
    end

    lims = [min([yTrue; yPred]) max([yTrue; yPred])];
    pad = 0.08 * range(lims);
    if pad == 0, pad = 1; end
    lims = lims + [-pad pad];
    xlim(ax, lims);
    ylim(ax, lims);
    plot(ax, lims, lims, 'k--', 'LineWidth', style.referenceLineWidth, ...
        'HandleVisibility','off');

    rVal = corr(yTrue, yPred, 'Rows','complete');
    rmseVal = sqrt(mean((yPred - yTrue).^2));
    modelLine = localTscoreModelAnnotation(modelText, bestRank);
    annotationLines = strings(0,1);
    if plotOptions.showContext
        if strlength(string(contextTextOverride)) > 0
            contextText = char(string(contextTextOverride));
        else
            contextText = localTscorePlotContextText(spectrumNumber, featureSettings);
        end
        annotationLines(end+1) = string(contextText);
    end
    annotationLines(end+1) = sprintf('r = %.3f',rVal);
    annotationLines(end+1) = sprintf('RMSE_{CV} = %.3f',rmseVal);
    annotationLines(end+1) = string(modelLine);
    if plotOptions.showTotalN
        annotationLines(end+1) = sprintf('n = %d',numel(yTrue));
    end
    text(ax, plotOptions.annotationPosition(1), ...
        plotOptions.annotationPosition(2), ...
        char(strjoin(annotationLines,newline)), ...
        'Units','normalized', ...
        'HorizontalAlignment',plotOptions.annotationHorizontalAlignment, ...
        'VerticalAlignment',plotOptions.annotationVerticalAlignment, ...
        'Tag','TscoreAnnotation', ...
        'FontSize',style.annotationFontSize);

    xlabel(ax,plotOptions.xLabel);
    ylabel(ax,plotOptions.yLabel);
    title(ax, panelTitle, 'Interpreter',plotOptions.titleInterpreter, ...
        'FontSize',style.titleFontSize, 'FontWeight','bold');

    validLeg = isgraphics(hLegend);
    if plotOptions.showLegend && any(validLeg)
        legendHandle = legend(ax, hLegend(validLeg), ...
            'Location','southeast','Box','off');
        legendHandle.ItemTokenSize = style.legendTokenSize;
        legendHandle.FontSize = style.legendFontSize;
    end

    set(ax,'FontSize',style.axisFontSize, ...
        'LineWidth',style.axisLineWidth, 'Box','off', 'TickDir','out');
end

function options = localCompletePlotOptions(options)
defaults = struct('showContext',true, 'showTotalN',true, ...
    'showLegend',true, 'xLabel','DXA measured Wrist T-Score', ...
    'yLabel','Predicted Wrist T-score from Finger Raman', ...
    'titleInterpreter','none', 'annotationPosition',[0.06 0.94], ...
    'annotationHorizontalAlignment','left', ...
    'annotationVerticalAlignment','top');
names = fieldnames(defaults);
for k = 1:numel(names)
    if ~isfield(options,names{k})
        options.(names{k}) = defaults.(names{k});
    end
end
end

function localPlotTscorePrediction(yTrue, yPred, cats, bestRank, ...
        ~, spectrumNumber, featureLabel, modelText, featureSettings)
    catList = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
    catClr  = containers.Map(catList, {'b','g','r'});
    marks = {'s','d','o'};
    style = localTscorePlotStyle();
    dotSize = style.scatterSize;
    markerSizeLeg = style.markerSize;

    figure('Name', sprintf('T-score prediction - %s', featureLabel), ...
        'Color','w','Units','inches','Position',[0 0 8 8]);
    ax = gca; hold(ax,'on'); axis(ax,'square');

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
    contextText = localTscorePlotContextText(spectrumNumber, featureSettings);
    digits=3;
    if isfield(featureSettings,'validationProtocol') && featureSettings.validationProtocol=="matchedKFold"
        digits=4;
    end
    text(ax, 0.05, 0.95, sprintf('%s\nr = %.*f\nRMSE_{CV} = %.*f\n%s\nn = %d', ...
        contextText,digits,rVal,digits,rmseVal,modelLine,numel(yTrue)), ...
        'Units','normalized', ...
        'VerticalAlignment','top', ...
        'Tag','TscoreAnnotation', ...
        'FontSize',style.annotationFontSize);

    xlabel(ax,'DXA measured Wrist T-Score');
    ylabel(ax,'Predicted Wrist T-score from Finger Raman');
    title(ax, featureLabel, 'Interpreter','none', ...
        'FontSize',style.titleFontSize, 'FontWeight','bold');

    validLeg = isgraphics(hLegend);
    if any(validLeg)
        lgd = legend(ax, hLegend(validLeg), 'Location','southeast','Box','off');
        lgd.ItemTokenSize = style.legendTokenSize;
        lgd.FontSize = style.legendFontSize;
    end

    set(ax,'FontSize',style.axisFontSize, ...
        'LineWidth',style.axisLineWidth, 'Box','off', 'TickDir','out');
end

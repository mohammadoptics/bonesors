function hFig = localPlotSpatialProfileGrid(values, recordTags, ...
        recordCategories, tagOrder, tagLabels, metrics, figureTitle, ...
        plotSettings)
%LOCALPLOTSPATIALPROFILEGRID Five metric panels with N/OPE/OP mean +/- SEM.

catList = ["NORMAL","OSTEOPENIA","OSTEOPOROSIS"];
catLabels = ["N","OPE","OP"];
catColors = [0 0 1; 0 1 0; 1 0 0];
catMarkers = {'s','d','o'};
nTags = numel(tagOrder);
nMetrics = numel(metrics);
panelLetters = localPanelLetters(nMetrics);

hFig = figure('Name',figureTitle, 'Color','w', ...
    'Units','inches','Position',[0.4 0.8 14.5 5.1]);
tl = tiledlayout(hFig, 1, nMetrics, ...
    'TileSpacing','compact', 'Padding','compact');

for m = 1:nMetrics
    ax = nexttile(tl);
    hold(ax,'on');
    hLines = gobjects(numel(catList),1);

    for c = 1:numel(catList)
        means = nan(1,nTags);
        sems = nan(1,nTags);
        for t = 1:nTags
            idx = strcmpi(recordCategories, catList(c)) & ...
                strcmpi(recordTags, tagOrder(t));
            y = values(idx,m);
            y = y(isfinite(y));
            if isempty(y), continue, end
            means(t) = mean(y, 'omitnan');
            if numel(y) > 1
                sems(t) = std(y, 0, 'omitnan') / sqrt(numel(y));
            end
        end

        hLines(c) = plot(ax, 1:nTags, means, ...
            'LineStyle','-', 'Marker',catMarkers{c}, ...
            'LineWidth',plotSettings.lineWidth, ...
            'MarkerSize',plotSettings.markerSize, ...
            'Color',catColors(c,:), ...
            'MarkerFaceColor',catColors(c,:), ...
            'MarkerEdgeColor',catColors(c,:), ...
            'DisplayName',catLabels(c));

        if plotSettings.showSEM
            keep = isfinite(means) & isfinite(sems);
            if any(keep)
                errorbar(ax, find(keep), means(keep), sems(keep), ...
                    'LineStyle','none', 'Color',catColors(c,:), ...
                    'LineWidth',1.1, 'CapSize',6, ...
                    'HandleVisibility','off');
            end
        end
    end

    set(ax, 'XTick',1:nTags, 'XTickLabel',cellstr(tagLabels), ...
        'XTickLabelRotation',35, 'FontSize',10.5, ...
        'LineWidth',1.4, 'Box','off', 'TickDir','out', ...
        'TickLabelInterpreter','none');
    xlim(ax, [0.65 nTags+0.35]);
    xlabel(ax, 'Spatial location tag');
    ylabel(ax, metrics(m).label, 'Interpreter','tex');
    title(ax, sprintf('(%s)', panelLetters{m}), ...
        'Interpreter','none', 'FontWeight','bold');
    grid(ax,'off');
    if m == 1
        validLegend = isgraphics(hLines);
        legend(ax, hLines(validLegend), ...
            cellstr(catLabels(validLegend)), ...
            'Location','best', 'Box','off', 'FontSize',10);
    end
end
end

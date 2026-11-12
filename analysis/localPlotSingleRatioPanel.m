function localPlotSingleRatioPanel(ax, ratioBank, metric, catList, catClr, showCategoryLabels, ratioSummaryBoxFlag)
    if nargin < 6 || isempty(showCategoryLabels)
        showCategoryLabels = false;
    end
    if nargin < 7 || isempty(ratioSummaryBoxFlag)
        ratioSummaryBoxFlag = false;
    end

    hold(ax, 'on');
    markers = {'s','d','o'};
    dotSize = 105;
    jitter = 0.07;
    barWidth = 0.18;
    nCats = numel(catList);
    Ygroups = cell(1, nCats);

    for c = 1:nCats
        catName = catList{c};
        if ~isfield(ratioBank, catName) || ~isfield(ratioBank.(catName), metric.field)
            Ygroups{c} = [];
            continue
        end

        y = ratioBank.(catName).(metric.field)(:);
        y = y(isfinite(y));
        Ygroups{c} = y;
        if isempty(y)
            continue
        end

        clr = catClr(catName);
        if ratioSummaryBoxFlag
            localDrawRatioSummaryBar(ax, c, y, 0.60);
        end

        x = c + jitter*randn(numel(y), 1);
        scatter(ax, x, y, dotSize, ...
            'Marker', markers{c}, ...
            'MarkerFaceColor', clr, ...
            'MarkerEdgeColor', clr, ...
            'HandleVisibility','off');

        mu = mean(y, 'omitnan');
        sd = std(y, 'omitnan');
        errorbar(ax, c, mu, sd, ...
            'Color', 'k', ...
            'LineWidth', 2.2, ...
            'CapSize', 11, ...
            'LineStyle', 'none', ...
            'HandleVisibility','off');
        line(ax, [c-barWidth c+barWidth], [mu mu], ...
            'Color', 'k', ...
            'LineWidth', 2.2, ...
            'HandleVisibility','off');
    end

    set(ax, 'Box','off', ...
        'LineWidth',2.8, ...
        'XAxisLocation','bottom', ...
        'YAxisLocation','left', ...
        'XTick',1:nCats, ...
        'XTickLabel',localCategoryShortLabels(showCategoryLabels), ...
        'FontSize',17, ...
        'FontName','Arial');
    xlim(ax, [0.5 3.5]);
    ylabel(ax, metric.label, 'Interpreter','tex', 'FontSize',18);

    yall = vertcat(Ygroups{:});
    yall = yall(isfinite(yall));
    if ~isempty(yall)
        yMin = min(yall);
        yMax = max(yall);
        yRange = max(yMax - yMin, eps);
        ylim(ax, [yMin - 0.10*yRange, yMax + 0.55*yRange]);
        addPairwiseSignificance(ax, Ygroups, 1:nCats, ...
            'lineWidth', 2.4, ...
            'fontSizeNS', 20, ...
            'fontSizeStar', 34, ...
            'starYOffset', 0);
    end
end


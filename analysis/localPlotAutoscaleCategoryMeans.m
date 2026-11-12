function localPlotAutoscaleCategoryMeans(ax, xAxis, X, cats, catList, catClr)
    hold(ax,'on');
    for c = 1:numel(catList)
        idx = strcmpi(cats, catList{c});
        if ~any(idx)
            continue
        end
        mu = mean(X(idx,:), 1, 'omitnan');
        plot(ax, xAxis, mu, 'Color', catClr(catList{c}), ...
            'LineWidth',2.4, 'DisplayName', sprintf('%s train mean (n=%d)', ...
            char(localShortCategoryLabel(catList{c})), sum(idx)));
    end
    legend(ax, 'Location','best', 'Box','off');
end


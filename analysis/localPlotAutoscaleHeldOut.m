function localPlotAutoscaleHeldOut(ax, xAxis, Xtest, catsTest, catList, catClr, testID)
    hold(ax,'on');
    for c = 1:numel(catList)
        idx = strcmpi(catsTest, catList{c});
        if ~any(idx)
            continue
        end
        mu = mean(Xtest(idx,:), 1, 'omitnan');
        plot(ax, xAxis, mu, 'Color', catClr(catList{c}), ...
            'LineWidth',2.4, 'DisplayName', sprintf('%s %s mean (n=%d)', ...
            char(testID), char(localShortCategoryLabel(catList{c})), sum(idx)));
    end
    legend(ax, 'Location','best', 'Box','off', 'Interpreter','none');
end


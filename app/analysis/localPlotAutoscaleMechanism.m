function localPlotAutoscaleMechanism(xAxis, xLabel, Xtrain, Xtest, catsTest, catList, catClr, testID, axisMode)
    mu = mean(Xtrain, 1, 'omitnan');
    sigma = std(Xtrain, 0, 1, 'omitnan');
    sigma(~isfinite(sigma) | sigma == 0) = 1;

    xHeld = mean(Xtest, 1, 'omitnan');
    centered = xHeld - mu;
    zHeld = centered ./ sigma;

    figure('Name','Autoscaling mechanism - easier view', ...
        'Color','w', 'Units','inches', 'Position',[0 0 13 8]);
    tiledlayout(2,2, 'TileSpacing','compact', 'Padding','compact');

    ax1 = nexttile;
    plot(ax1, xAxis, mu, 'k', 'LineWidth',2.3);
    title(ax1, 'A. Training mean spectrum/feature vector');
    ylabel(ax1, '\mu_{train}');

    ax2 = nexttile;
    plot(ax2, xAxis, sigma, 'Color',[0.35 0.35 0.35], 'LineWidth',2.3);
    title(ax2, 'B. Training SD used as divisor');
    ylabel(ax2, '\sigma_{train}');

    ax3 = nexttile;
    plot(ax3, xAxis, centered, 'Color',[0.85 0 0], 'LineWidth',2.1);
    yline(ax3, 0, ':k', 'LineWidth',1.5);
    title(ax3, sprintf('C. Held-out %s minus training mean', char(testID)), ...
        'Interpreter','none');
    xlabel(ax3, xLabel);
    ylabel(ax3, 'x_{test} - \mu_{train}');

    ax4 = nexttile;
    hold(ax4,'on');
    testColor = [0.85 0 0];
    for c = 1:numel(catList)
        if any(strcmpi(catsTest, catList{c}))
            testColor = catClr(catList{c});
            break
        end
    end
    plot(ax4, xAxis, zHeld, 'Color',testColor, 'LineWidth',2.1);
    yline(ax4, 0, ':k', 'LineWidth',1.5);
    yline(ax4, 2, '--', 'Color',[0.55 0.55 0.55], 'LineWidth',1.2);
    yline(ax4, -2, '--', 'Color',[0.55 0.55 0.55], 'LineWidth',1.2);
    title(ax4, 'D. Held-out after autoscaling');
    xlabel(ax4, xLabel);
    ylabel(ax4, '(x_{test} - \mu_{train}) / \sigma_{train}');

    allAx = findall(gcf, 'Type','axes');
    for a = allAx.'
        set(a, 'FontSize',16, 'LineWidth',2, 'Box','off');
        xlim(a, [min(xAxis) max(xAxis)]);
        if strcmp(axisMode, "wavenumber")
            set(a, 'XDir','normal');
        end
    end
end


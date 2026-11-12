function localPlotConfusionPanel(ax, yTrue, yPred, cats, panelTitle)
    catList = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
    catShort = {'N','OPE','OP'};
    trueCats = string(cats);
    predCats = localTscoreToCategory(yPred);
    [C, orderUsed] = confusionmat(trueCats, predCats, 'Order', string(catList));

    hold(ax,'on');
    nClass = size(C,1);
    imagesc(ax, zeros(nClass));
    colormap(ax, [1 1 1]);
    caxis(ax, [0 1]);
    axis(ax,'image');
    set(ax,'XLim',[0.5 nClass+0.5], 'YLim',[0.5 nClass+0.5], 'YDir','reverse');

    diagColor = [0.80 0.90 1.00];
    for k = 1:nClass
        rectangle(ax, 'Position',[k-0.5, k-0.5, 1, 1], ...
            'FaceColor',diagColor, 'EdgeColor','none');
    end

    gridColor = [0.80 0.80 0.80];
    for g = 0.5 : 1 : (nClass+0.5)
        line(ax, [0.5 nClass+0.5], [g g], 'Color',gridColor, 'LineWidth',2);
        line(ax, [g g], [0.5 nClass+0.5], 'Color',gridColor, 'LineWidth',2);
    end
    rectangle(ax, 'Position',[0.5 0.5 nClass nClass], ...
        'EdgeColor','k','LineWidth',4,'FaceColor','none');

    for i = 1:nClass
        for j = 1:nClass
            text(ax, j, i, num2str(C(i,j)), ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','middle', ...
                'FontSize',24, ...
                'FontWeight','bold', ...
                'Color','k');
        end
    end

    set(ax,'XTick',1:nClass, ...
        'YTick',1:nClass, ...
        'XTickLabel',catShort, ...
        'YTickLabel',catShort, ...
        'FontSize',17, ...
        'LineWidth',3, ...
        'XAxisLocation','top', ...
        'TickLength',[0 0]);
    xtickangle(ax, 0);
    ytickangle(ax, 0);
    xlabel(ax,'Predicted','FontSize',20);
    ylabel(ax,'Actual','FontSize',20);
    title(ax, panelTitle, 'Interpreter','none', 'FontSize',20, 'FontWeight','bold');
    hold(ax,'off');
end


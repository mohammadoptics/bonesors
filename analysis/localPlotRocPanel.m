function localPlotRocPanel(ax, yPred, cats, panelTitle)
    pairs = { ...
        'NORMAL', 'OSTEOPENIA', 'N vs OPE', 'b'; ...
        'NORMAL', 'OSTEOPOROSIS', 'N vs OP', 'r'; ...
        'OSTEOPENIA', 'OSTEOPOROSIS', 'OPE vs OP', 'g'};

    hold(ax,'on');
    plot(ax, [0 1], [0 1], 'k--', 'LineWidth',1.5, 'HandleVisibility','off');

    trueCats = string(cats(:));
    for p = 1:size(pairs, 1)
        positiveClass = string(pairs{p, 1});
        negativeClass = string(pairs{p, 2});
        keep = strcmpi(trueCats, positiveClass) | strcmpi(trueCats, negativeClass);
        labels = strcmpi(trueCats(keep), positiveClass);
        scores = yPred(keep);

        if positiveClass == "OSTEOPOROSIS"
            scores = -scores;
        elseif positiveClass == "OSTEOPENIA" && negativeClass == "OSTEOPOROSIS"
            scores = yPred(keep);
        elseif positiveClass == "NORMAL"
            scores = yPred(keep);
        end

        [fpr, tpr, aucVal] = localBinaryRoc(labels, scores);
        plot(ax, fpr, tpr, '-', ...
            'Color', pairs{p, 4}, ...
            'LineWidth',2.5, ...
            'DisplayName', sprintf('%s  AUC=%.2f', pairs{p, 3}, aucVal));
    end

    axis(ax,'square');
    xlim(ax,[0 1]);
    ylim(ax,[0 1]);
    xlabel(ax,'False positive rate');
    ylabel(ax,'True positive rate');
    title(ax, panelTitle, 'Interpreter','none', 'FontSize',20, 'FontWeight','bold');
    legend(ax, 'Location','southeast', 'Box','off', 'FontSize',14);
    set(ax,'FontSize',17,'LineWidth',3,'Box','off');
    hold(ax,'off');
end


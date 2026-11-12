function localPlotTscoreConfusionMatrix(yTrue, yPred, cats, featureLabel)
    catList = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};

    trueCats = string(cats);
    predCats = localTscoreToCategory(yPred);

    [C, orderUsed] = confusionmat(trueCats, predCats, 'Order', string(catList));
    metricsTable = localComputeMulticlassMetrics(C, orderUsed);

    metricsTableFmt = metricsTable;
    numVars = varfun(@isnumeric, metricsTableFmt, 'OutputFormat','uniform');
    numVarNames = metricsTableFmt.Properties.VariableNames(numVars);
    for k = 1:numel(numVarNames)
        v = numVarNames{k};
        metricsTableFmt.(v) = round(metricsTableFmt.(v), 2);
    end

    fprintf('\nConfusion matrix for %s:\n', featureLabel);
    disp(array2table(C, 'VariableNames', cellstr(orderUsed), ...
        'RowNames', cellstr(orderUsed)));
    disp(metricsTableFmt);

    figure('Name', sprintf('Classification - %s', featureLabel), ...
        'Color','w','Units','inches','Position',[0 0 12 6]);
    tl = tiledlayout(1, 2, 'TileSpacing','compact', 'Padding','compact');

    ax1 = nexttile(tl);
    localPlotConfusionPanel(ax1, yTrue, yPred, cats, ...
        sprintf('A (Confusion matrix)'));

    ax2 = nexttile(tl);
    localPlotRocPanel(ax2, yPred, cats, ...
        sprintf('B (Pairwise ROC)'));
end


function localPrintClassificationSummaryTable(yTrue, yPred, cats, tableTitle)
    catList = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
    trueCats = string(cats);
    predCats = localTscoreToCategory(yPred);
    [C, orderUsed] = confusionmat(trueCats, predCats, 'Order', string(catList));
    metricsTable = localComputeMulticlassMetrics(C, orderUsed);

    classShort = ["Normal"; "Osteopenia"; "Osteoporosis"];
    T = table(classShort, ...
        round(metricsTable.Precision, 2), ...
        round(metricsTable.Sensitivity, 2), ...
        round(metricsTable.Specificity, 2), ...
        round(metricsTable.Accuracy, 2), ...
        'VariableNames', {'WHO_Class','Precision','Sensitivity','Specificity','Accuracy'});

    fprintf('\nTable. Summary of classification performance metrics - %s\n', tableTitle);
    disp(T);
end


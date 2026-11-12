function [overallAcc, balancedAcc, macroF1] = localTscoreClassificationSummary(yTrue, yPred, cats)
    catList = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
    trueCats = string(cats);
    predCats = localTscoreToCategory(yPred);
    [C, orderUsed] = confusionmat(trueCats, predCats, 'Order', string(catList));
    metricsTable = localComputeMulticlassMetrics(C, orderUsed);

    overallAcc = sum(diag(C)) / max(sum(C(:)), eps);
    balancedAcc = mean(metricsTable.Sensitivity, 'omitnan');
    macroF1 = mean(metricsTable.F1score, 'omitnan');
end


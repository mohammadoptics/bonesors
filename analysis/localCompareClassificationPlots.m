function localCompareClassificationPlots(recordsActual, recordsPredicted, spectrumNumber, maxRank, featureSettings, tissueA, tissueB)
    resultE = localComputeTscorePrediction(recordsActual, tissueA, spectrumNumber, maxRank, featureSettings);
    resultP = localComputeTscorePrediction(recordsPredicted, tissueB, spectrumNumber, maxRank, featureSettings);
    labelA = analysisTissueLabel(tissueA); labelB = analysisTissueLabel(tissueB);

    if ~resultE.ok || ~resultP.ok
        return
    end

    figure('Name',sprintf('%s vs %s classification',labelA,labelB), ...
        'Color','w','Units','inches','Position',[0 0 11 10]);
    tl = tiledlayout(2, 2, 'TileSpacing','tight', 'Padding','compact');
    offsetTitle = localSpectrumSelectionTitle(spectrumNumber);

    ax1 = nexttile(tl);
    localPlotConfusionPanel(ax1, resultE.y, resultE.yPred, resultE.cats, ...
        sprintf('A (%s, %s)', labelA, offsetTitle));

    ax2 = nexttile(tl);
    localPlotRocPanel(ax2, resultE.yPred, resultE.cats, ...
        sprintf('B (%s, %s)', labelA, offsetTitle));

    ax3 = nexttile(tl);
    localPlotConfusionPanel(ax3, resultP.y, resultP.yPred, resultP.cats, ...
        sprintf('C (%s, %s)', labelB, offsetTitle));

    ax4 = nexttile(tl);
    localPlotRocPanel(ax4, resultP.yPred, resultP.cats, ...
        sprintf('D (%s, %s)', labelB, offsetTitle));

    fprintf('\n=== Classification comparison: %s vs %s =============\n',labelA,labelB);
    fprintf('%s: %s   r = %.3f   RMSE_CV = %.3f\n', labelA, ...
        resultE.modelText, resultE.rVal, resultE.rmseVal);
    localPrintClassificationSummaryTable(resultE.y, resultE.yPred, resultE.cats, ...
        labelA);
    fprintf('%s: %s   r = %.3f   RMSE_CV = %.3f\n', labelB, ...
        resultP.modelText, resultP.rVal, resultP.rmseVal);
    localPrintClassificationSummaryTable(resultP.y, resultP.yPred, resultP.cats, ...
        labelB);
    fprintf('==========================================================\n\n');
end

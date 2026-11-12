function localCompareTscorePlots(recordsActual, recordsPredicted, spectrumNumber, maxRank, featureSettings, tissueA, tissueB)
    resultE = localComputeTscorePrediction(recordsActual, tissueA, spectrumNumber, maxRank, featureSettings);
    resultP = localComputeTscorePrediction(recordsPredicted, tissueB, spectrumNumber, maxRank, featureSettings);
    labelA = analysisTissueLabel(tissueA); labelB = analysisTissueLabel(tissueB);

    if ~resultE.ok || ~resultP.ok
        return
    end

    fprintf('\n=== T-score comparison: %s vs %s ===================\n', labelA, labelB);
    fprintf('%s: %s   r = %.3f   RMSE_CV = %.3f\n', labelA, ...
        resultE.modelText, resultE.rVal, resultE.rmseVal);
    fprintf('%s: %s   r = %.3f   RMSE_CV = %.3f\n', labelB, ...
        resultP.modelText, resultP.rVal, resultP.rmseVal);
    fprintf('==========================================================\n\n');

    figure('Name',sprintf('%s vs %s T-score prediction',labelA,labelB), ...
        'Color','w','Units','inches','Position',[0 0 14 7]);
    tl = tiledlayout(1, 2, 'TileSpacing','loose', 'Padding','compact');
    offsetTitle = localSpectrumSelectionTitle(spectrumNumber);

    ax1 = nexttile(tl);
    localPlotTscorePredictionPanel(ax1, resultE.y, resultE.yPred, resultE.cats, ...
        resultE.bestRank, sprintf('A (%s, %s)', labelA, offsetTitle), ...
        resultE.modelText, spectrumNumber, featureSettings);

    ax2 = nexttile(tl);
    localPlotTscorePredictionPanel(ax2, resultP.y, resultP.yPred, resultP.cats, ...
        resultP.bestRank, sprintf('B (%s, %s)', labelB, offsetTitle), ...
        resultP.modelText, spectrumNumber, featureSettings);
end

function localCompareRatioPlots(recordsActual, recordsPredicted, spectrumNumber, priorityTags, featureSettings, ratioSummaryBoxFlag, plotFWHMFlag, tissueA, tissueB)
    if nargin < 6 || isempty(ratioSummaryBoxFlag)
        ratioSummaryBoxFlag = false;
    end
    if nargin < 7 || isempty(plotFWHMFlag)
        plotFWHMFlag = false;
    end

    catList = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
    catClr  = containers.Map(catList, {'b','g','r'});
    metrics = localRatioMetricDefinitions();
    labelA = analysisTissueLabel(tissueA); labelB = analysisTissueLabel(tissueB);

    ratioBankActual = localBuildRatioBankFromRecords(recordsActual, catList, featureSettings);
    ratioBankPredicted = localBuildRatioBankFromRecords(recordsPredicted, catList, featureSettings);

    figureName = sprintf('%s vs %s Raman ratios - spectrum %s', labelA, labelB, mat2str(spectrumNumber));
    if numel(spectrumNumber) > 1 && isfield(featureSettings,'spectrumCombineMode')
        figureName = sprintf('%s %s', figureName, featureSettings.spectrumCombineMode);
    end

    rowNames = {labelA, labelB};
    localPlotMeasuredPredictedMetricGrid({ratioBankActual, ratioBankPredicted}, metrics, ...
        catList, catClr, rowNames, figureName, spectrumNumber, ratioSummaryBoxFlag);

    fprintf('\n=== Raman-ratio comparison: %s vs %s =====================\n',labelA,labelB);
    fprintf('Tag: %s   spectra: %s   combine: %s\n', ...
        strjoin(string(priorityTags), ', '), mat2str(spectrumNumber), ...
        string(featureSettings.spectrumCombineMode));
    fprintf('Top row: %s. Bottom row: %s.\n',labelA,labelB);
    fprintf('==========================================================\n\n');
    localPrintRatioPlotSignificanceDiagnostics(ratioBankActual, ratioBankPredicted, ...
        metrics, catList, rowNames);

    if plotFWHMFlag
        if numel(spectrumNumber) > 1 && localIsRatioLevelCombineMode(featureSettings)
            warning(['compareRatioPlots FWHM figure was skipped because ratio-level ', ...
                'combine modes do not create a physical spectrum for FWHM calculation.']);
            return
        end

        fwhmMetrics = localFWHMMetricDefinitions();
        fwhmBankActual = localBuildFWHMBankFromRecords(recordsActual, catList, featureSettings);
        fwhmBankPredicted = localBuildFWHMBankFromRecords(recordsPredicted, catList, featureSettings);

        fwhmFigureName = sprintf('%s vs %s FWHM features - spectrum %s', labelA, labelB, mat2str(spectrumNumber));
        if numel(spectrumNumber) > 1 && isfield(featureSettings,'spectrumCombineMode')
            fwhmFigureName = sprintf('%s %s', fwhmFigureName, featureSettings.spectrumCombineMode);
        end

        localPlotMeasuredPredictedMetricGrid({fwhmBankActual, fwhmBankPredicted}, fwhmMetrics, ...
            catList, catClr, rowNames, fwhmFigureName, spectrumNumber, ratioSummaryBoxFlag);

        fprintf('\n=== FWHM comparison: %s vs %s ======================\n',labelA,labelB);
        fprintf('Tag: %s   spectra: %s   combine: %s\n', ...
            strjoin(string(priorityTags), ', '), mat2str(spectrumNumber), ...
            string(featureSettings.spectrumCombineMode));
        fprintf('Top row: %s. Bottom row: %s.\n',labelA,labelB);
        fprintf('==========================================================\n\n');
    end
end

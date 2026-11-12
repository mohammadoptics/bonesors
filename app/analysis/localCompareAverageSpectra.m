function localCompareAverageSpectra(recordsActual, recordsPredicted, spectrumNumber, priorityTags, featureSettings, useIanitaJ, textSettings)
    if nargin < 6 || isempty(useIanitaJ)
        useIanitaJ = false;
    end
    if nargin < 7 || isempty(textSettings)
        textSettings = localDefaultCompareTextSettings();
    end
    textSettings = localFillCompareTextSettings(textSettings);
    if isempty(recordsActual) || isempty(recordsPredicted)
        errordlg(sprintf('Both %s and %s records are required for this comparison.', ...
            textSettings.primaryLabel, textSettings.secondaryLabel), ...
            'Missing comparison spectra','modal');
        return
    end

    combineMode = lower(string(featureSettings.spectrumCombineMode));
    useCombinedSpectrum = numel(spectrumNumber) > 1 && ...
        any(combineMode == ["mean","add","sum","diff","ratio"]);

    if ~useCombinedSpectrum && strcmpi(string(textSettings.averagePlotMode), "allCadavers")
        localCompareAverageSpectraAllCadavers(recordsActual, recordsPredicted, spectrumNumber, ...
            priorityTags, featureSettings, useIanitaJ, textSettings);
        localPlotIndividualSpectralAgreement(recordsActual, recordsPredicted, spectrumNumber, ...
            priorityTags, featureSettings, useIanitaJ, textSettings);
        return
    end

    if ~useCombinedSpectrum && strcmpi(string(textSettings.averagePlotMode), "categoryOffset")
        localCompareAverageSpectraCategoryOffset(recordsActual, recordsPredicted, spectrumNumber, ...
            priorityTags, featureSettings, useIanitaJ, textSettings);
        localPlotIndividualSpectralAgreement(recordsActual, recordsPredicted, spectrumNumber, ...
            priorityTags, featureSettings, useIanitaJ, textSettings);
        return
    end

    if numel(spectrumNumber) > 1 && ~useCombinedSpectrum
        localCompareAverageSpectraGrid(recordsActual, recordsPredicted, spectrumNumber, ...
            priorityTags, featureSettings, useIanitaJ, textSettings);
        return
    end

    catList = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
    catClr = containers.Map(catList, {'b','g','r'});
    panelLetters = {'A','B','C'};

    for c = 1:numel(catList)
        catName = catList{c};
        actualCat = recordsActual(strcmpi(string({recordsActual.Category}), catName));
        predictedCat = recordsPredicted(strcmpi(string({recordsPredicted.Category}), catName));

        if isempty(actualCat) && isempty(predictedCat)
            continue
        end

        [wnA, XActual] = localSpectraMatrixForRecords(actualCat, featureSettings, useIanitaJ);
        [wnP, XPredicted] = localSpectraMatrixForRecords(predictedCat, featureSettings, useIanitaJ);
        meanActual = localMeanSpectrumFromMatrix(XActual);
        meanPredicted = localMeanSpectrumFromMatrix(XPredicted);
        nActual = size(XActual, 1);
        nPredicted = size(XPredicted, 1);

        if isempty(meanActual) && isempty(meanPredicted)
            continue
        end

        if ~isempty(wnA)
            wn = wnA;
        else
            wn = wnP;
        end

        figure('Name', sprintf('%s: %s vs %s average spectrum', catName, ...
            textSettings.primaryLabel, textSettings.secondaryLabel), ...
            'Color','w','Position',[350 200 700 420]);
        ax = gca;
        hold(ax,'on');

        measuredColor = catClr(catName);
        yLimitData = [];
        if ~isempty(meanPredicted)
            [~, yPredicted] = localPlotMeanSpectrumWithUncertainty(ax, wn, XPredicted, 'k', textSettings.errMode, ...
                'LineStyle', '--', ...
                'LineWidth', 2.5, ...
                'DisplayName', sprintf('%s (n=%d)', textSettings.secondaryLabel, nPredicted));
            yLimitData = [yLimitData; yPredicted(:)]; %#ok<AGROW>
        end
        if ~isempty(meanActual)
            [~, yActual] = localPlotMeanSpectrumWithUncertainty(ax, wn, XActual, measuredColor, textSettings.errMode, ...
                'LineStyle', '-', ...
                'LineWidth', 2.5, ...
                'DisplayName', sprintf('%s (n=%d)', textSettings.primaryLabel, nActual));
            yLimitData = [yLimitData; yActual(:)]; %#ok<AGROW>
        end

        xlabel(ax, 'Wavenumber (cm^{-1})');
        ylabel(ax, 'Normalized intensity (a.u.)');
        title(ax, sprintf('%s (%s)', panelLetters{c}, localTitleCaseCategory(catName)));
        xlim(ax, [min(wn) max(wn)]);
        yLimitData = yLimitData(isfinite(yLimitData));
        if ~isempty(yLimitData)
            yMin = min(yLimitData);
            yMax = max(yLimitData);
            yPadTop = 0.04 * max(yMax - yMin, eps);
            ylim(ax, [yMin yMax + yPadTop]);
        end

        localAddPeakLabels(ax, wn);

        legend(ax, 'Location','northwest', 'Box','off');
        set(ax, 'FontSize',36, 'LineWidth',7, 'Box','off', ...
            'XAxisLocation','bottom', 'YAxisLocation','left');
    end

    fprintf('\n=== Average spectra: %s vs %s ================\n', ...
        textSettings.primaryLabel, textSettings.secondaryLabel);
    fprintf('Tag: %s   spectrum: %s   normalization: %s/%s   combine: %s\n', ...
        strjoin(string(priorityTags), ', '), mat2str(spectrumNumber), ...
        string(featureSettings.normalizationRegion), ...
        string(featureSettings.normalizationMethod), ...
        string(featureSettings.spectrumCombineMode));
    fprintf('Primary: %s; comparison: %s.\n', ...
        textSettings.primaryLabel, textSettings.secondaryLabel);
    fprintf('==========================================================\n\n');
end

function localCompareAverageSpectraGrid(recordsActual, recordsPredicted, spectrumNumber, priorityTags, featureSettings, useIanitaJ, textSettings)
    if nargin < 7 || isempty(textSettings)
        textSettings = localDefaultCompareTextSettings();
    end
    textSettings = localFillCompareTextSettings(textSettings);

    catList = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
    catClr = containers.Map(catList, {'b','g','r'});
    panelLetters = {'A','B','C','D','E','F'};

    nRows = numel(catList);
    nCols = numel(spectrumNumber);

    figure('Name', sprintf('%s vs %s average spectra - combined', ...
        textSettings.primaryLabel, textSettings.secondaryLabel), ...
        'Color','w','Position',[100 50 1450 1150]);
    tl = tiledlayout(nRows, nCols, 'TileSpacing','compact', 'Padding','compact');

    panelIdx = 0;
    for c = 1:nRows
        catName = catList{c};
        actualCat = recordsActual(strcmpi(string({recordsActual.Category}), catName));
        predictedCat = recordsPredicted(strcmpi(string({recordsPredicted.Category}), catName));

        for s = 1:nCols
            panelIdx = panelIdx + 1;
            ax = nexttile(tl);
            hold(ax,'on');

            [wnA, XActual] = localSpectraMatrixForRecordsColumn(actualCat, featureSettings, s, useIanitaJ);
            [wnP, XPredicted] = localSpectraMatrixForRecordsColumn(predictedCat, featureSettings, s, useIanitaJ);
            meanActual = localMeanSpectrumFromMatrix(XActual);
            meanPredicted = localMeanSpectrumFromMatrix(XPredicted);
            nActual = size(XActual, 1);
            nPredicted = size(XPredicted, 1);

            if isempty(meanActual) && isempty(meanPredicted)
                title(ax, sprintf('%s %s, spectrum %d', panelLetters{panelIdx}, ...
                    localTitleCaseCategory(catName), spectrumNumber(s)));
                continue
            end

            if ~isempty(wnA)
                wn = wnA;
            else
                wn = wnP;
            end

            measuredColor = catClr(catName);
            yLimitData = [];
            if ~isempty(meanPredicted)
                [~, yPredicted] = localPlotMeanSpectrumWithUncertainty(ax, wn, XPredicted, 'k', textSettings.errMode, ...
                    'LineStyle', '--', ...
                    'LineWidth', 2.0, ...
                    'DisplayName', sprintf('%s (n=%d)', textSettings.secondaryLabel, nPredicted));
                yLimitData = [yLimitData; yPredicted(:)]; %#ok<AGROW>
            end
            if ~isempty(meanActual)
                [~, yActual] = localPlotMeanSpectrumWithUncertainty(ax, wn, XActual, measuredColor, textSettings.errMode, ...
                    'LineStyle', '-', ...
                    'LineWidth', 2.0, ...
                    'DisplayName', sprintf('%s (n=%d)', textSettings.primaryLabel, nActual));
                yLimitData = [yLimitData; yActual(:)]; %#ok<AGROW>
            end

            title(ax, sprintf('%s (%s, %s)', panelLetters{panelIdx}, ...
                localTitleCaseCategory(catName), localSpectrumDepthLabel(spectrumNumber(s))));
            xlim(ax, [min(wn) max(wn)]);
            localSetSpectrumYLimits(ax, yLimitData);

            if c == 1
                localAddPeakLabelsNearPeaks(ax, wn, [meanActual(:); meanPredicted(:)], 15);
            end

            if ~isempty(meanActual) && ~isempty(meanPredicted)
                if textSettings.showResidualTrace
                    localPlotResidualTrace(ax, wn, abs(meanPredicted - meanActual), ...
                        textSettings.residualPosition);
                end
                [rmseVal, mapeVal, rVal] = localSpectrumErrorMetrics(meanActual, meanPredicted);
                text(ax, textSettings.metricsPosition(1), textSettings.metricsPosition(2), ...
                    sprintf('r = %.4f\nRMSE = %.3f\nMAPE = %.1f%%', ...
                    rVal, rmseVal, mapeVal), ...
                    'Units','normalized', ...
                    'HorizontalAlignment','right', ...
                    'VerticalAlignment','top', ...
                    'FontSize',15, ...
                    'Color',[0.15 0.15 0.15]);
            end

            if c == nRows
                xlabel(ax, 'Wavenumber (cm^{-1})');
            end
            if s == 1
                ylabel(ax, 'Normalized intensity (a.u.)');
            end
            legend(ax, 'Location','northeast', 'Box','off', 'FontSize',15);

            set(ax, 'FontSize',15, 'LineWidth',2.5, 'Box','off', ...
                'XAxisLocation','bottom');
        end
    end

    fprintf('\n=== Combined average spectra: %s vs %s ========\n', ...
        textSettings.primaryLabel, textSettings.secondaryLabel);
    fprintf('Tag: %s   spectra: %s   IanitaJ: %d\n', ...
        strjoin(string(priorityTags), ', '), mat2str(spectrumNumber), useIanitaJ);
    fprintf('Panels are WHO categories by selected spectrum number.\n');
    fprintf('==========================================================\n\n');

    localPlotIndividualSpectralAgreement(recordsActual, recordsPredicted, spectrumNumber, ...
        priorityTags, featureSettings, useIanitaJ, textSettings);
end

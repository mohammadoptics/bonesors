function localCompareAverageSpectraAllCadavers(recordsActual, recordsPredicted, spectrumNumber, priorityTags, featureSettings, useIanitaJ, textSettings)
    if nargin < 7 || isempty(textSettings)
        textSettings = localDefaultCompareTextSettings();
    end
    textSettings = localFillCompareTextSettings(textSettings);

    nCols = numel(spectrumNumber);
    if nCols < 1
        warning('No spectrum numbers were selected for all-cadaver average comparison.');
        return
    end

    figWidth = max(8, 6.2*nCols);
    figure('Name', sprintf('%s vs %s average spectra - all cadavers', ...
        textSettings.primaryLabel, textSettings.secondaryLabel), ...
        'Color','w','Units','inches','Position',[0 0 figWidth 5.2]);
    tl = tiledlayout(1, nCols, 'TileSpacing','none', 'Padding','compact');

    panelLetters = localPanelLetters(nCols);
    for s = 1:nCols
        ax = nexttile(tl);
        hold(ax,'on');

        [wnA, XActual] = localSpectraMatrixForRecordsColumn(recordsActual, ...
            featureSettings, s, useIanitaJ);
        [wnP, XPredicted] = localSpectraMatrixForRecordsColumn(recordsPredicted, ...
            featureSettings, s, useIanitaJ);
        meanActual = localMeanSpectrumFromMatrix(XActual);
        meanPredicted = localMeanSpectrumFromMatrix(XPredicted);
        nActual = size(XActual, 1);
        nPredicted = size(XPredicted, 1);

        if isempty(meanActual) && isempty(meanPredicted)
            title(ax, sprintf('%s (All cadavers, %s)', panelLetters{s}, ...
                localSpectrumDepthLabel(spectrumNumber(s))));
            continue
        end

        if ~isempty(wnA)
            wn = wnA;
        else
            wn = wnP;
        end

        yLimitData = [];
        if ~isempty(meanPredicted)
            [~, yPredicted] = localPlotMeanSpectrumWithUncertainty(ax, wn, XPredicted, 'k', textSettings.errMode, ...
                'LineStyle', '--', ...
                'LineWidth', 2.4, ...
                'DisplayName', sprintf('%s (n=%d)', textSettings.secondaryLabel, nPredicted));
            yLimitData = [yLimitData; yPredicted(:)]; %#ok<AGROW>
        end
        if ~isempty(meanActual)
            [~, yActual] = localPlotMeanSpectrumWithUncertainty(ax, wn, XActual, 'b', textSettings.errMode, ...
                'LineStyle', '-', ...
                'LineWidth', 2.4, ...
                'DisplayName', sprintf('%s (n=%d)', textSettings.primaryLabel, nActual));
            yLimitData = [yLimitData; yActual(:)]; %#ok<AGROW>
        end

        title(ax, sprintf('%s (All cadavers, %s)', panelLetters{s}, ...
            localSpectrumDepthLabel(spectrumNumber(s))), ...
            'FontSize',18, 'FontWeight','bold');
        xlabel(ax, 'Wavenumber (cm^{-1})');
        if s == 1
            ylabel(ax, 'Normalized intensity (a.u.)');
        end
        xlim(ax, [min(wn) max(wn)]);
        localSetSpectrumYLimits(ax, yLimitData);
        localAddPeakLabelsNearPeaks(ax, wn, [meanActual(:); meanPredicted(:)], 15);

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

        legend(ax, 'Location','northeast', 'Box','off', 'FontSize',14);
        set(ax, 'FontSize',15, 'LineWidth',2.5, 'Box','off', ...
            'XAxisLocation','bottom');
    end

    fprintf('\n=== All-cadaver average spectra: %s vs %s =====\n', ...
        textSettings.primaryLabel, textSettings.secondaryLabel);
    fprintf('Tag: %s   spectra: %s   IanitaJ: %d\n', ...
        strjoin(string(priorityTags), ', '), mat2str(spectrumNumber), useIanitaJ);
    fprintf('Each panel averages all cadavers together, without WHO category grouping.\n');
    fprintf('Primary: %s; comparison: %s.\n', ...
        textSettings.primaryLabel, textSettings.secondaryLabel);
    fprintf('==========================================================\n\n');
end

function localPlotIndividualSpectralAgreement(recordsActual, recordsPredicted, spectrumNumber, priorityTags, featureSettings, useIanitaJ, textSettings)
    if isempty(recordsActual) || isempty(recordsPredicted)
        return
    end
    if nargin < 7 || isempty(textSettings)
        textSettings = localDefaultCompareTextSettings();
    end
    textSettings = localFillCompareTextSettings(textSettings);

    catList = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
    catClr = containers.Map(catList, {'b','g','r'});
    catMarks = containers.Map(catList, {'s','d','o'});

    metricRows = localIndividualAgreementTable(recordsActual, recordsPredicted, spectrumNumber, ...
        featureSettings, useIanitaJ, textSettings.residualReferenceMode);
    if isempty(metricRows)
        warning('No matched %s/%s spectra were available for individual-level agreement plotting.', ...
            textSettings.primaryLabel, textSettings.secondaryLabel);
        return
    end

    T = struct2table(metricRows);
    specLabels = strings(numel(spectrumNumber), 1);
    for s = 1:numel(spectrumNumber)
        specLabels(s) = string(localSpectrumDepthLabel(spectrumNumber(s)));
    end

    if textSettings.showResidualAgreementPanel
        nMetricPanels = 3;
        figureWidth = 14;
    else
        nMetricPanels = 2;
        figureWidth = 9.5;
    end
    figure('Name', sprintf('Individual spectral agreement: %s vs %s', ...
        textSettings.primaryLabel, textSettings.secondaryLabel), ...
        'Color','w','Units','inches','Position',[0 0 figureWidth 5.2]);
    tl = tiledlayout(1, nMetricPanels, 'TileSpacing','compact', 'Padding','compact');

    metricNames = {'RawR','RMSE'};
    yLabels = {'r', 'RMSE'};
    yRanges = {[NaN NaN], [0 NaN]};
    if textSettings.showResidualAgreementPanel
        if strcmpi(string(textSettings.individualAgreementMetric), "MAPE")
            metricNames{end+1} = 'MAPE';
            yLabels{end+1} = 'MAPE (%)';
            yRanges{end+1} = [0 NaN];
        elseif strcmpi(string(textSettings.individualAgreementMetric), "residualRMSE")
            metricNames{end+1} = 'ResidualRMSE';
            yLabels{end+1} = 'Relative residual RMSE';
            yRanges{end+1} = [0 NaN];
        else
            metricNames{end+1} = 'ResidualR';
            yLabels{end+1} = 'Mean-centered r_{res}';
            yRanges{end+1} = [-1.05 1.05];
        end
    end

    for m = 1:numel(metricNames)
        ax = nexttile(tl);
        hold(ax,'on');
        metricName = metricNames{m};

        for s = 1:numel(spectrumNumber)
            idxS = T.SpectrumNumber == spectrumNumber(s);
            vals = T.(metricName)(idxS);
            vals = vals(isfinite(vals));
            if isempty(vals)
                continue
            end

            medVal = median(vals, 'omitnan');
            q = prctile(vals, [25 75]);
            bar(ax, s, medVal, 0.58, ...
                'FaceColor',[0.88 0.88 0.88], ...
                'EdgeColor','k', ...
                'LineWidth',2.2, ...
                'HandleVisibility','off');
            line(ax, [s s], q, 'Color','k', 'LineWidth',2.5, 'HandleVisibility','off');
            line(ax, [s-0.16 s+0.16], [q(1) q(1)], 'Color','k', 'LineWidth',2.5, 'HandleVisibility','off');
            line(ax, [s-0.16 s+0.16], [q(2) q(2)], 'Color','k', 'LineWidth',2.5, 'HandleVisibility','off');

            idxRows = find(idxS);
            for rr = 1:numel(idxRows)
                rowIdx = idxRows(rr);
                catName = upper(string(T.Category(rowIdx)));
                if ~isKey(catClr, char(catName))
                    continue
                end
                xPos = s + localCategoryOffsetWithinGroup(catName) + localDeterministicJitter(rowIdx, 0.018);
                plot(ax, xPos, T.(metricName)(rowIdx), char(catMarks(char(catName))), ...
                    'MarkerFaceColor', catClr(char(catName)), ...
                    'MarkerEdgeColor', catClr(char(catName)), ...
                    'MarkerSize',10, ...
                    'LineStyle','none', ...
                    'HandleVisibility','off');
            end
        end

        legendPanel = 1;
        if textSettings.showResidualAgreementPanel
            legendPanel = numel(metricNames);
        end
        if m == legendPanel
            legendSpectrumIdx = T.SpectrumNumber == spectrumNumber(1);
            for c = 1:numel(catList)
                classCount = sum(legendSpectrumIdx & strcmpi(string(T.Category), string(catList{c})));
                plot(ax, nan, nan, char(catMarks(catList{c})), ...
                    'MarkerFaceColor', catClr(catList{c}), ...
                    'MarkerEdgeColor', catClr(catList{c}), ...
                    'MarkerSize',10, ...
                    'LineStyle','none', ...
                    'DisplayName', sprintf('%s (n=%d)', localShortClassLabel(catList{c}), classCount));
            end
            lgd = legend(ax, 'Location','northoutside', 'Box','off', ...
                'FontSize',14, 'Orientation','horizontal');
            lgd.Layout.Tile = 'north';
        end

        xlim(ax, [0.45 numel(spectrumNumber)+0.55]);
        set(ax, 'XTick', 1:numel(spectrumNumber), ...
            'XTickLabel', specLabels, ...
            'FontSize',17, ...
            'LineWidth',2.8, ...
            'Box','off');
        ylabel(ax, yLabels{m}, 'FontSize',18);
        title(ax, sprintf('%s', char('A' + m - 1)), ...
            'FontSize',20, 'FontWeight','bold');
        if strcmpi(metricName, 'RawR')
            metricVals = T.(metricName);
            metricVals = metricVals(isfinite(metricVals));
            if ~isempty(metricVals)
                yMin = min(metricVals);
                yMax = max(metricVals);
                yPad = max(0.005, 0.08 * max(yMax - yMin, eps));
                yLower = max(-1, yMin - yPad);
                yUpper = min(1, max(1, yMax + yPad));
                if yUpper <= yLower
                    yUpper = yLower + 0.01;
                end
                ylim(ax, [yLower yUpper]);
            end
        elseif ~isnan(yRanges{m}(2))
            ylim(ax, yRanges{m});
        elseif yRanges{m}(1) == 0
            yl = ylim(ax);
            ylim(ax, [0 yl(2)]);
        end
    end

    fprintf('\n=== Individual spectral agreement: %s vs %s ===\n', ...
        textSettings.primaryLabel, textSettings.secondaryLabel);
    fprintf('Tag: %s   spectra: %s\n', strjoin(string(priorityTags), ', '), mat2str(spectrumNumber));
    for s = 1:numel(spectrumNumber)
        idxS = T.SpectrumNumber == spectrumNumber(s);
        if strcmpi(string(textSettings.individualAgreementMetric), "MAPE")
            fprintf('%s: median RMSE = %.4f, mean RMSE = %.4f, median raw r = %.4f, mean raw r = %.4f, median MAPE = %.2f%%, mean MAPE = %.2f%%, n = %d\n', ...
                localSpectrumDepthLabel(spectrumNumber(s)), ...
                median(T.RMSE(idxS), 'omitnan'), ...
                mean(T.RMSE(idxS), 'omitnan'), ...
                median(T.RawR(idxS), 'omitnan'), ...
                mean(T.RawR(idxS), 'omitnan'), ...
                median(T.MAPE(idxS), 'omitnan'), ...
                mean(T.MAPE(idxS), 'omitnan'), ...
                sum(idxS));
        elseif strcmpi(string(textSettings.individualAgreementMetric), "residualRMSE")
            fprintf('%s: median RMSE = %.4f, mean RMSE = %.4f, median raw r = %.4f, mean raw r = %.4f, median relative residual RMSE = %.4f, mean relative residual RMSE = %.4f, n = %d\n', ...
                localSpectrumDepthLabel(spectrumNumber(s)), ...
                median(T.RMSE(idxS), 'omitnan'), ...
                mean(T.RMSE(idxS), 'omitnan'), ...
                median(T.RawR(idxS), 'omitnan'), ...
                mean(T.RawR(idxS), 'omitnan'), ...
                median(T.ResidualRMSE(idxS), 'omitnan'), ...
                mean(T.ResidualRMSE(idxS), 'omitnan'), ...
                sum(idxS));
        else
            fprintf('%s: median RMSE = %.4f, mean RMSE = %.4f, median raw r = %.4f, mean raw r = %.4f, median r_res = %.4f, mean r_res = %.4f, n = %d\n', ...
            localSpectrumDepthLabel(spectrumNumber(s)), ...
            median(T.RMSE(idxS), 'omitnan'), ...
            mean(T.RMSE(idxS), 'omitnan'), ...
            median(T.RawR(idxS), 'omitnan'), ...
            mean(T.RawR(idxS), 'omitnan'), ...
            median(T.ResidualR(idxS), 'omitnan'), ...
            mean(T.ResidualR(idxS), 'omitnan'), ...
            sum(idxS));
        end
    end
    fprintf('==========================================================\n\n');
end

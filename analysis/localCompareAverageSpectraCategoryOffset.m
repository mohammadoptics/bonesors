function localCompareAverageSpectraCategoryOffset(recordsActual, recordsPredicted, spectrumNumber, priorityTags, featureSettings, useIanitaJ, textSettings)
    if nargin < 7 || isempty(textSettings)
        textSettings = localDefaultCompareTextSettings();
    end
    textSettings = localFillCompareTextSettings(textSettings);

    nCols = numel(spectrumNumber);
    if nCols < 1
        warning('No spectrum numbers were selected for category-offset average comparison.');
        return
    end

    catList = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
    catClr = containers.Map(catList, {'b','g','r'});
    panelLetters = localPanelLetters(nCols);

    figWidth = max(8.5, 5.35*nCols);
    figure('Name', sprintf('%s vs %s average spectra - vertically offset categories', ...
        textSettings.primaryLabel, textSettings.secondaryLabel), ...
        'Color','w','Units','inches','Position',[0 0 figWidth 5.8]);

    leftMargin = 0.07;
    rightMargin = 0.025;
    bottomMargin = 0.16;
    topMargin = 0.12;
    panelGap = 0.023;
    panelWidth = (1 - leftMargin - rightMargin - panelGap*(nCols-1)) / nCols;
    panelHeight = 1 - bottomMargin - topMargin;

    for s = 1:nCols
        ax = axes('Position', [leftMargin + (s-1)*(panelWidth + panelGap), ...
            bottomMargin, panelWidth, panelHeight]);
        hold(ax,'on');

        categoryData = struct('Name', {}, 'Wavenumber', {}, 'Measured', {}, ...
            'Predicted', {}, 'MeasuredMatrix', {}, 'PredictedMatrix', {}, ...
            'NMeasured', {}, 'NPredicted', {});
        panelValues = [];
        wn = [];

        for c = 1:numel(catList)
            catName = catList{c};
            actualCat = recordsActual(strcmpi(string({recordsActual.Category}), catName));
            predictedCat = recordsPredicted(strcmpi(string({recordsPredicted.Category}), catName));

            [wnA, XActual] = localSpectraMatrixForRecordsColumn(actualCat, featureSettings, s, useIanitaJ);
            [wnP, XPredicted] = localSpectraMatrixForRecordsColumn(predictedCat, featureSettings, s, useIanitaJ);
            meanActual = localMeanSpectrumFromMatrix(XActual);
            meanPredicted = localMeanSpectrumFromMatrix(XPredicted);
            nActual = size(XActual, 1);
            nPredicted = size(XPredicted, 1);

            if isempty(meanActual) && isempty(meanPredicted)
                continue
            end

            if isempty(wn)
                if ~isempty(wnA)
                    wn = wnA;
                else
                    wn = wnP;
                end
            end

            categoryData(end+1).Name = catName; %#ok<AGROW>
            categoryData(end).Wavenumber = wn;
            categoryData(end).Measured = meanActual;
            categoryData(end).Predicted = meanPredicted;
            categoryData(end).MeasuredMatrix = XActual;
            categoryData(end).PredictedMatrix = XPredicted;
            categoryData(end).NMeasured = nActual;
            categoryData(end).NPredicted = nPredicted;

            panelValues = [panelValues; meanActual(:); meanPredicted(:)]; %#ok<AGROW>
        end

        if isempty(categoryData) || isempty(wn)
            title(ax, sprintf('%s (%s)', panelLetters{s}, ...
                localSpectrumDepthLabel(spectrumNumber(s))), ...
                'FontSize',18, 'FontWeight','bold');
            continue
        end

        panelValues = panelValues(isfinite(panelValues));
        if isempty(panelValues)
            yRange = 1;
        else
            yRange = max(panelValues) - min(panelValues);
            if ~isfinite(yRange) || yRange <= 0
                yRange = 1;
            end
        end

        rowSpacing = 0.78 * yRange;
        rowSpacing = max(rowSpacing, 0.12);
        offsets = (numel(catList)-1:-1:0) * rowSpacing;
        xRange = max(wn) - min(wn);
        labelX = min(wn) + 0.003 * xRange;
        rowTextLift = 0.18 * yRange;

        hMeasured = plot(ax, nan, nan, 'k-', 'LineWidth',1.8, ...
            'DisplayName', textSettings.primaryLabel);
        hPredicted = plot(ax, nan, nan, 'k:', 'LineWidth',1.8, ...
            'DisplayName', textSettings.secondaryLabel);
        shiftedForLabels = [];
        shiftedAll = [];

        for c = 1:numel(catList)
            catName = catList{c};
            dataIdx = find(strcmpi(string({categoryData.Name}), catName), 1, 'first');
            offset = offsets(c);
            yline(ax, offset, ':', 'Color',[0.82 0.82 0.82], ...
                'LineWidth',0.9, 'HandleVisibility','off');

            if isempty(dataIdx)
                continue
            end

            thisData = categoryData(dataIdx);
            thisColor = catClr(catName);
            nLabel = max(thisData.NMeasured, thisData.NPredicted);
            text(ax, labelX, offset + rowTextLift, ...
                sprintf('%s (n=%d)', localShortClassLabel(catName), nLabel), ...
                'Color','k', 'FontSize',10, 'FontWeight','bold', ...
                'HorizontalAlignment','left', 'VerticalAlignment','middle');

            if ~isempty(thisData.Measured)
                [~, yMeasured] = localPlotMeanSpectrumWithUncertainty(ax, wn, thisData.MeasuredMatrix, thisColor, textSettings.errMode, ...
                    'LineStyle', '-', ...
                    'LineWidth', 1.8, ...
                    'YOffset', offset, ...
                    'HandleVisibility','off');
                shiftedAll = [shiftedAll; yMeasured(:)]; %#ok<AGROW>
                shiftedForLabels = [shiftedForLabels; thisData.Measured(:) + offset]; %#ok<AGROW>
            end
            if ~isempty(thisData.Predicted)
                [~, yPredicted] = localPlotMeanSpectrumWithUncertainty(ax, wn, thisData.PredictedMatrix, 'k', textSettings.errMode, ...
                    'LineStyle', ':', ...
                    'LineWidth', 1.8, ...
                    'YOffset', offset, ...
                    'HandleVisibility','off');
                shiftedAll = [shiftedAll; yPredicted(:)]; %#ok<AGROW>
                shiftedForLabels = [shiftedForLabels; thisData.Predicted(:) + offset]; %#ok<AGROW>
            end

        end

        title(ax, sprintf('%s (%s)', panelLetters{s}, ...
            localSpectrumDepthLabel(spectrumNumber(s))), ...
            'FontSize',18, 'FontWeight','bold');
        xlabel(ax, 'Wavenumber (cm^{-1})');
        if s == 1
            if strcmpi(string(featureSettings.normalizationRegion),"none")
                ylabel(ax, 'Vertically offset intensity (a.u.)');
            else
                ylabel(ax, 'Vertically offset normalized intensity (a.u.)');
            end
        end
        xlim(ax, [min(wn) max(wn)]);
        set(ax, 'YTick', []);

        shiftedAll = shiftedAll(isfinite(shiftedAll));
        if ~isempty(shiftedAll)
            yPad = 0.06 * max(max(shiftedAll) - min(shiftedAll), eps);
            ylim(ax, [min(shiftedAll)-yPad, max(shiftedAll)+yPad]);
        end
        if ~isempty(shiftedForLabels)
            localAddPeakLabelsNearPeaks(ax, wn, shiftedForLabels, 13);
        end

        legend(ax, [hMeasured hPredicted], 'Location','northeast', ...
            'Box','off', 'FontSize',13);
        set(ax, 'FontSize',14, 'LineWidth',2.4, 'Box','off', ...
            'XAxisLocation','bottom', 'TickDir','out');
    end

    fprintf('\n=== Category-offset average spectra: %s vs %s ==\n', ...
        textSettings.primaryLabel, textSettings.secondaryLabel);
    fprintf('Tag: %s   spectra: %s   IanitaJ: %d\n', ...
        strjoin(string(priorityTags), ', '), mat2str(spectrumNumber), useIanitaJ);
    fprintf('Each selected spectrum is one panel; WHO categories are vertically offset.\n');
    fprintf('%s spectra are solid lines; %s spectra are dotted lines.\n', ...
        textSettings.primaryLabel, textSettings.secondaryLabel);
    fprintf('==========================================================\n\n');
end

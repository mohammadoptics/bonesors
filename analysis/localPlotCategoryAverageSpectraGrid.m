function localPlotCategoryAverageSpectraGrid(recordsActual, recordsPredicted, spectrumNumber, priorityTags, featureSettings, useIanitaJ, plotSettings)
    if nargin < 6 || isempty(useIanitaJ)
        useIanitaJ = false;
    end
    if nargin < 7 || isempty(plotSettings)
        plotSettings = struct();
    end
    if ~isfield(plotSettings, 'xlim')
        plotSettings.xlim = [];
    end
    if ~isfield(plotSettings, 'showDSValues') || isempty(plotSettings.showDSValues)
        plotSettings.showDSValues = true;
    end
    if isempty(recordsActual) && isempty(recordsPredicted)
        errordlg(['No measured exposed spectra (E) or predicted spectra (P) were available. ', ...
            'Load a predictedCadavers.mat that contains both E and P.'], ...
            'Missing spectra','modal');
        return
    end
    if isempty(spectrumNumber)
        spectrumNumber = [1 2];
    end
    if numel(spectrumNumber) > 2
        spectrumNumber = spectrumNumber(1:2);
        warning('categoryAverageSpectra uses the first two selected spectrum numbers only.');
    end

    catList = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
    catClr = containers.Map(catList, {'b','g','r'});
    if numel(spectrumNumber) == 1
        panelLetters = {'A','B'};
        panelRecords = {recordsActual, recordsPredicted};
        panelTissue = {'Measured exposed bone', 'ML-predicted bone'};
        panelShort = {'E', 'P'};
        panelSpecIdx = [spectrumNumber(1) spectrumNumber(1)];
        nRows = 1;
        nCols = 2;
        figPosition = [120 180 1150 500];
    else
        panelLetters = {'A','B','C','D'};
        panelRecords = {recordsActual, recordsActual, recordsPredicted, recordsPredicted};
        panelTissue = {'Measured exposed bone', 'Measured exposed bone', ...
            'ML-predicted bone', 'ML-predicted bone'};
        panelShort = {'E', 'E', 'P', 'P'};
        panelSpecIdx = [1 2 1 2];
        nRows = 2;
        nCols = 2;
        figPosition = [120 60 1150 900];
    end
    nPanels = numel(panelRecords);
    panelSepStats = repmat(struct('NOPE', NaN, 'NOP', NaN, 'OPEOP', NaN, ...
        'Within', NaN), 1, nPanels);

    figure('Name', 'Category-average spectral discrimination - E and P', ...
        'Color','w','Position', figPosition);
    tl = tiledlayout(nRows, nCols, 'TileSpacing','compact', 'Padding','compact');

    for p = 1:nPanels
        ax = nexttile(tl);
        hold(ax,'on');

        recordsThis = panelRecords{p};
        specCol = panelSpecIdx(p);
        if numel(spectrumNumber) == 1
            specNumber = spectrumNumber(1);
            specCol = localResolveCategoryAverageSpectrumColumn(recordsThis, specNumber);
        else
            specNumber = spectrumNumber(min(specCol, numel(spectrumNumber)));
        end
        sepStats = localCategorySeparationStats(recordsThis, catList, ...
            featureSettings, specCol, useIanitaJ, plotSettings.xlim);
        panelSepStats(p) = sepStats;
        yMinAll = inf;
        yMaxAll = -inf;
        wnPanel = [];
        yRefAll = [];
        meanSpecsForLimits = {};

        for c = 1:numel(catList)
            catName = catList{c};
            catRecords = recordsThis(strcmpi(string({recordsThis.Category}), catName));
            [wn, meanSpec, nRecords] = localMeanSpectrumForRecordsColumn(catRecords, ...
                featureSettings, specCol, useIanitaJ);
            if isempty(meanSpec)
                continue
            end

            wnPanel = wn;
            plot(ax, wn, meanSpec, 'Color', catClr(catName), ...
                'LineWidth', 2.0, ...
                'DisplayName', sprintf('%s (n=%d)', catName, nRecords));

            yMinAll = min(yMinAll, min(meanSpec, [], 'omitnan'));
            yMaxAll = max(yMaxAll, max(meanSpec, [], 'omitnan'));
            yRefAll = [yRefAll; meanSpec(:)]; %#ok<AGROW>
            meanSpecsForLimits{end+1} = meanSpec(:); %#ok<AGROW>
        end

        if isempty(wnPanel)
            title(ax, sprintf('%s (%s, %s)', panelLetters{p}, panelShort{p}, ...
                localSpectrumDepthLabel(specNumber)));
            text(ax, 0.5, 0.52, sprintf('%s %s not available', ...
                panelShort{p}, localSpectrumDepthLabel(specNumber)), ...
                'Units','normalized', 'HorizontalAlignment','center', ...
                'FontSize',13, 'FontWeight','bold', 'Color',[0.35 0.35 0.35], ...
                'Interpreter','none');
            set(ax, 'FontSize',15, 'LineWidth',2.5, 'Box','off', ...
                'XAxisLocation','bottom', 'YAxisLocation','left');
            continue
        end

        title(ax, sprintf('%s (%s, %s)', panelLetters{p}, panelTissue{p}, ...
            localSpectrumDepthLabel(specNumber)), 'Interpreter','none');
        if isempty(plotSettings.xlim)
            xLimits = [min(wnPanel) max(wnPanel)];
        else
            xLimits = plotSettings.xlim;
        end
        xlim(ax, xLimits);
        [yMinVisible, yMaxVisible] = localVisibleYRange(wnPanel, meanSpecsForLimits, xLimits);
        if isfinite(yMinVisible) && isfinite(yMaxVisible)
            yRange = max(yMaxVisible - yMinVisible, eps);
            ylim(ax, [yMinVisible - 0.04*yRange, yMaxVisible + 0.12*yRange]);
        elseif isfinite(yMinAll) && isfinite(yMaxAll)
            yRange = max(yMaxAll - yMinAll, eps);
            ylim(ax, [yMinAll, yMaxAll + 0.06*yRange]);
        end

        localAddPeakLabelsNearPeaks(ax, wnPanel, yRefAll, 15);
        if plotSettings.showDSValues && ...
                (isfinite(sepStats.NOPE) || isfinite(sepStats.NOP) || isfinite(sepStats.OPEOP))
            text(ax, 0.98, 0.72, sprintf('DS_{N-OPE} = %.2f\nDS_{N-OP} = %.2f\nDS_{OPE-OP} = %.2f', ...
                sepStats.NOPE, sepStats.NOP, sepStats.OPEOP), ...
                'Units','normalized', 'FontSize',13, 'FontWeight','bold', ...
                'Color',[0.15 0.15 0.15], 'VerticalAlignment','top', ...
                'HorizontalAlignment','right', 'Interpreter','tex');
        end

        if nRows == 1 || p > nCols
            xlabel(ax, 'Wavenumber (cm^{-1})');
        end
        if mod(p - 1, nCols) == 0
            ylabel(ax, 'Normalized intensity (a.u.)');
        end

        legend(ax, 'Location','northeast', 'Box','off', 'FontSize',13);
        set(ax, 'FontSize',15, 'LineWidth',2.5, 'Box','off', ...
            'XAxisLocation','bottom', 'YAxisLocation','left');
    end

    fprintf('\n=== Category-average spectral discrimination ==============\n');
    fprintf('Tag: %s   spectra: %s   IanitaJ: %d\n', ...
        strjoin(string(priorityTags), ', '), mat2str(spectrumNumber), useIanitaJ);
    if isempty(plotSettings.xlim)
        fprintf('X-axis: full spectrum.\n');
    else
        fprintf('X-axis: %.0f to %.0f cm^-1.\n', plotSettings.xlim(1), plotSettings.xlim(2));
    end
    if numel(spectrumNumber) == 1
        fprintf('Panels: measured E and predicted P for selected spectrum.\n');
    else
        fprintf('Panels: measured E 0/3-mm and predicted P 0/3-mm.\n');
    end
    for p = 1:nPanels
        if numel(spectrumNumber) == 1
            specNumber = spectrumNumber(1);
        else
            specNumber = spectrumNumber(min(panelSpecIdx(p), numel(spectrumNumber)));
        end
        fprintf('%s %-22s %-4s: N-OPE = %.2f   N-OP = %.2f   OPE-OP = %.2f\n', ...
            panelLetters{p}, panelTissue{p}, char(localSpectrumDepthLabel(specNumber)), ...
            panelSepStats(p).NOPE, panelSepStats(p).NOP, panelSepStats(p).OPEOP);
    end
    fprintf('==========================================================\n\n');
end


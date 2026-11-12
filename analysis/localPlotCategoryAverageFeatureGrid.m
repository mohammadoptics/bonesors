function localPlotCategoryAverageFeatureGrid(records, tissueToUse, spectrumNumber, priorityTags, featureSettings, useIanitaJ, plotSettings, groups)
    if nargin < 8 || isempty(groups)
        groups=struct('Tissue',tissueToUse,'Records',records);
    end
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
    if ~isfield(plotSettings, 'normalizationRegions') || isempty(plotSettings.normalizationRegions)
        plotSettings.normalizationRegions = "useFeatureSettings";
    end
    if ~isfield(plotSettings, 'normalizationMethod') || isempty(plotSettings.normalizationMethod)
        plotSettings.normalizationMethod = "useFeatureSettings";
    end
    if ~isfield(plotSettings, 'finalNormalizationRegion') || isempty(plotSettings.finalNormalizationRegion)
        plotSettings.finalNormalizationRegion = "none";
    end
    if ~isfield(plotSettings, 'finalNormalizationMethod') || isempty(plotSettings.finalNormalizationMethod)
        plotSettings.finalNormalizationMethod = "peak";
    end

    spectrumNumber = spectrumNumber(:).';
    tissueToUse = upper(string(tissueToUse));
    if isempty(records)
        errordlg(sprintf('No %s spectra were available for the selected tags.', char(tissueToUse)), ...
            'Missing spectra','modal');
        return
    end

    separateOffsets = string(featureSettings.spectrumCombineMode)=="separate";
    if numel(spectrumNumber) > 1 && ~separateOffsets && ~localIsPlottableSpectrumCombineMode(featureSettings.spectrumCombineMode)
        errordlg({sprintf('categoryAverageSpectra cannot draw spectrumCombineMode "%s" on a single wavenumber axis.', ...
            string(featureSettings.spectrumCombineMode)), ...
            'Use "mean", "add", "sum", "diff", or "ratio" for this plotting mode.', ...
            'Modes such as "concat" and "meanDiff" are still valid for T-score features because they create multi-block feature vectors.'}, ...
            'Non-plottable feature mode','modal');
        return
    end

    normRegions = string(plotSettings.normalizationRegions);
    normRegions = normRegions(:).';
    normRegions = normRegions(strlength(normRegions) > 0);
    if isempty(normRegions) || any(strcmpi(normRegions, "useFeatureSettings"))
        normRegions = string(featureSettings.normalizationRegion);
    end
    if strcmpi(string(plotSettings.normalizationMethod), "useFeatureSettings")
        normMethod = validatestring(char(string(featureSettings.normalizationMethod)), {'peak','peakBaseline','area'});
    else
        normMethod = validatestring(char(string(plotSettings.normalizationMethod)), {'peak','peakBaseline','area'});
    end
    finalNormRegion = validatestring(char(string(plotSettings.finalNormalizationRegion)), ...
        {'none','PO4','CO3','CH2','AmideI','AmideIII','FullSpectrum'});
    finalNormMethod = validatestring(char(string(plotSettings.finalNormalizationMethod)), {'peak','peakBaseline','area'});

    validNorms = {'none','PO4','CO3','CH2','AmideI','AmideIII','FullSpectrum'};
    catList = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
    catClr = containers.Map(catList, {'b','g','r'});
    panels=localCategoryAveragePanelPlan(groups,spectrumNumber,featureSettings.spectrumCombineMode,normRegions);
    panelLetters = localPanelLetters(numel(panels));
    panelSepStats = repmat(struct('NOPE', NaN, 'NOP', NaN, 'OPEOP', NaN, ...
        'Within', NaN), 1, numel(panels));

    nPanels = numel(panels);
    if separateOffsets
        nCols=numel(spectrumNumber);
    elseif numel(groups)>1
        nCols=1;
    else
        nCols=min(2,nPanels);
    end
    nRows = ceil(nPanels / nCols);
    figure('Name', 'Category-average selected spectral-feature comparison', ...
        'Color','w','Position',[120 60 max(700,550*nCols) max(520,420*nRows)]);
    tl = tiledlayout(nRows, nCols, 'TileSpacing','compact', 'Padding','compact');

    for p = 1:nPanels
        normRegion = validatestring(char(panels(p).Normalization), validNorms);
        panelRecords=panels(p).Records;
        fs = featureSettings;
        fs.spectrumCombineMode=panels(p).CombineMode;
        fs.normalizationRegion = string(normRegion);
        fs.normalizationMethod = string(normMethod);

        ax = nexttile(tl);
        hold(ax,'on');
        yline(ax, 0, ':', 'Color',[0.55 0.55 0.55], ...
            'LineWidth',1.2, 'HandleVisibility','off');

        sepStats = localCategorySeparationStatsCombined(panelRecords, catList, fs, ...
            useIanitaJ, plotSettings.xlim);
        panelSepStats(p) = sepStats;
        yMinAll = inf;
        yMaxAll = -inf;
        wnPanel = [];
        yRefAll = [];
        meanSpecsForLimits = {};

        for c = 1:numel(catList)
            catName = catList{c};
            catRecords = panelRecords(strcmpi(string({panelRecords.Category}), catName));
            [wn, meanSpec, nRecords] = localMeanSpectrumForRecordsCombined(catRecords, ...
                fs, useIanitaJ, string(finalNormRegion), string(finalNormMethod));
            if isempty(meanSpec)
                continue
            end

            wnPanel = wn;
            plot(ax, wn, meanSpec, 'Color', catClr(catName), ...
                'LineWidth', 2.2, ...
                'DisplayName', sprintf('%s (n=%d)', catName, nRecords));

            yMinAll = min(yMinAll, min(meanSpec, [], 'omitnan'));
            yMaxAll = max(yMaxAll, max(meanSpec, [], 'omitnan'));
            yRefAll = [yRefAll; meanSpec(:)]; %#ok<AGROW>
            meanSpecsForLimits{end+1} = meanSpec(:); %#ok<AGROW>
        end

        if isempty(wnPanel)
            title(ax, sprintf('%s (no %s spectra)', panelLetters{p}, char(panels(p).Tissue)));
            continue
        end

        featureLabel = localSelectedSpectrumFeatureLabel(panels(p).Tissue, panels(p).Columns, ...
            fs.spectrumCombineMode);
        if isscalar(panels(p).Columns)
            switch upper(string(panels(p).Tissue))
                case "E", sourceLabel='Measured exposed bone';
                case "P", sourceLabel='ML-predicted bone';
                case "T", sourceLabel='Intact/transcutaneous';
                otherwise, sourceLabel=char(panels(p).Tissue);
            end
            featureLabel=sprintf('%s, %s',sourceLabel,localSpectrumDepthLabel(panels(p).Columns));
        end
        if strcmpi(finalNormRegion, 'none')
            normText = sprintf('%s/%s', normRegion, normMethod);
        else
            normText = sprintf('%s/%s, final %s/%s', ...
                normRegion, normMethod, finalNormRegion, finalNormMethod);
        end
        if numel(normRegions)>1
            featureLabel=sprintf('%s, %s',featureLabel,normText);
        end
        title(ax, sprintf('%s (%s)', panelLetters{p}, featureLabel), 'Interpreter','none');

        if isempty(plotSettings.xlim)
            xLimits = [min(wnPanel) max(wnPanel)];
        else
            xLimits = plotSettings.xlim;
        end
        xlim(ax, xLimits);
        [yMinVisible, yMaxVisible] = localVisibleYRange(wnPanel, meanSpecsForLimits, xLimits);
        if isfinite(yMinVisible) && isfinite(yMaxVisible)
            yRange = max(yMaxVisible - yMinVisible, eps);
            % Reserve a top band for category counts without covering peaks.
            ylim(ax, [yMinVisible - 0.08*yRange, yMaxVisible + 0.40*yRange]);
        elseif isfinite(yMinAll) && isfinite(yMaxAll)
            yRange = max(yMaxAll - yMinAll, eps);
            ylim(ax, [yMinAll - 0.08*yRange, yMaxAll + 0.40*yRange]);
        end

        localAddPeakLabelsNearPeaks(ax, wnPanel, yRefAll, 13);
        if plotSettings.showDSValues && ...
                (isfinite(sepStats.NOPE) || isfinite(sepStats.NOP) || isfinite(sepStats.OPEOP))
            text(ax, 0.98, 0.72, sprintf('DS_{N-OPE} = %.2f\nDS_{N-OP} = %.2f\nDS_{OPE-OP} = %.2f', ...
                sepStats.NOPE, sepStats.NOP, sepStats.OPEOP), ...
                'Units','normalized', 'FontSize',13, 'FontWeight','bold', ...
                'Color',[0.15 0.15 0.15], 'VerticalAlignment','top', ...
                'HorizontalAlignment','right', 'Interpreter','tex');
        end

        if p > nCols * (nRows - 1)
            xlabel(ax, 'Wavenumber (cm^{-1})');
        end
        if mod(p - 1, nCols) == 0
            if strcmpi(normRegion,'none') && strcmpi(finalNormRegion,'none')
                ylabel(ax, 'Intensity (a.u.)');
            else
                ylabel(ax, 'Normalized intensity (a.u.)');
            end
        end

        lgd=legend(ax, 'Location','northeast', 'Box','off', 'FontSize',9);
        if isprop(lgd,'ItemTokenSize'), lgd.ItemTokenSize=[18 10]; end
        if isprop(lgd,'IconColumnWidth'), lgd.IconColumnWidth=18; end
        set(ax, 'FontSize',15, 'LineWidth',2.5, 'Box','off', ...
            'XAxisLocation','bottom', 'YAxisLocation','left');
    end

    fprintf('\n=== Category-average selected spectra/features =============\n');
    fprintf('Tissue: %s   Tag: %s   spectra: %s   combine: %s   IanitaJ: %d\n', ...
        char(tissueToUse), char(strjoin(string(priorityTags), ', ')), mat2str(spectrumNumber), ...
        char(string(featureSettings.spectrumCombineMode)), useIanitaJ);
    if isempty(plotSettings.xlim)
        fprintf('X-axis: full spectrum.\n');
    else
        fprintf('X-axis: %.0f to %.0f cm^-1.\n', plotSettings.xlim(1), plotSettings.xlim(2));
    end
    if strcmpi(finalNormRegion, 'none')
        fprintf('Final display normalization after combine: none.\n');
    else
        fprintf('Final display normalization after combine: %s/%s.\n', ...
            finalNormRegion, finalNormMethod);
    end
    for p = 1:nPanels
        fprintf('%s %s spectra %s, %s/%s: N-OPE = %.2f   N-OP = %.2f   OPE-OP = %.2f\n', ...
            panelLetters{p}, char(panels(p).Tissue), mat2str(panels(p).Columns), char(panels(p).Normalization), normMethod, ...
            panelSepStats(p).NOPE, panelSepStats(p).NOP, panelSepStats(p).OPEOP);
    end
    fprintf('==========================================================\n\n');
end


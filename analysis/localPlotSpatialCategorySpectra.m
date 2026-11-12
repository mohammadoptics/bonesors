function hFig = localPlotSpatialCategorySpectra(records, tissueToUse, ...
        spectrumNumber, requestedTags, matchMode, featureSettings, ...
        useIanitaJ, plotSettings)
%LOCALPLOTSPATIALCATEGORYSPECTRA Three panels with stacked tag means.

[tagOrder, tagLabels] = localResolveSpatialTagOrder(records, ...
    requestedTags, matchMode);
catList = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
catLabels = ["N","OPE","OP"];
panelLetters = localPanelLetters(numel(catList));
tagColors = lines(numel(tagOrder));

hFig = figure('Name', sprintf('%s spatial spectra by diagnosis', ...
    analysisTissueLabel(tissueToUse)), 'Color','w', ...
    'Units','inches','Position',[0.5 0.5 15.2 5.5]);
tl = tiledlayout(hFig, 1, 3, 'TileSpacing','compact', 'Padding','compact');

for c = 1:numel(catList)
    ax = nexttile(tl);
    hold(ax,'on');
    meanSpectra = cell(numel(tagOrder),1);
    tagCounts = zeros(numel(tagOrder),1);
    wnPanel = [];

    for t = 1:numel(tagOrder)
        idx = strcmpi(string({records.Category}), catList{c}) & ...
            strcmpi(string({records.Tag}), tagOrder(t));
        [wn, X] = localSpectraMatrixForRecordsCombined(records(idx), ...
            featureSettings, useIanitaJ);
        if isempty(X), continue, end
        tagCounts(t) = size(X,1);
        for row = 1:size(X,1)
            [normalizedSpectrum,~,~,~,~] = normalizeSpectra(wn, X(row,:).', ...
                "PO4", "peak");
            X(row,:) = normalizedSpectrum(:).';
        end
        meanSpectra{t} = mean(X, 1, 'omitnan').';
        wnPanel = wn(:);
    end

    if isempty(wnPanel)
        title(ax, sprintf('(%s) %s - no data', panelLetters{c}, catLabels(c)));
        axis(ax,'off');
        continue
    end

    stackStep = plotSettings.stackOffset;
    offsets = (numel(tagOrder)-1:-1:0).' * stackStep;
    plottedValues = [];

    for t = 1:numel(tagOrder)
        if isempty(meanSpectra{t}), continue, end
        shifted = meanSpectra{t} + offsets(t);
        plot(ax, wnPanel, shifted, 'Color',tagColors(t,:), ...
            'LineWidth',plotSettings.lineWidth);
        plottedValues = [plottedValues; shifted(:)]; %#ok<AGROW>
    end

    xLimits = localSpatialXLimits(wnPanel, plotSettings.xlim);
    xlim(ax, xLimits);
    countLabels = strings(numel(tagOrder),1);
    for t = 1:numel(tagOrder)
        countLabels(t) = sprintf('%s (n=%d)', tagLabels(t), tagCounts(t));
    end
    set(ax, 'YColor',[0 0 0], ...
        'YTick',flipud(offsets), ...
        'YTickLabel',cellstr(flipud(countLabels)), ...
        'FontSize',11, 'LineWidth',1.5, 'Box','off', 'TickDir','out');
    xlabel(ax, 'Wavenumber (cm^{-1})');
    if c == 1
        ylabel(ax, 'Stacked normalized intensity (a.u.)');
    end
    title(ax, sprintf('(%s) %s', panelLetters{c}, catLabels(c)), ...
        'FontWeight','bold');

    mask = isfinite(plottedValues);
    if any(mask)
        yMin = min(plottedValues(mask));
        yMax = max(plottedValues(mask));
        pad = 0.04 * max(yMax-yMin, eps);
        ylim(ax, [yMin-pad yMax+pad]);
    end

end
end

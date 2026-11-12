function localPlotAverageSpectraPerCategory(wn, X, cats, catList, catClr, priorityTags, errMode, useIanitaJ)
    if nargin < 8 || isempty(useIanitaJ)
        useIanitaJ = false;
    end
    errMode = localValidateAverageErrMode(errMode);

    wn = wn(:);
    cats = upper(strtrim(string(cats(:))));
    X = localApplyAverageSpectrumPreprocessing(wn, X, useIanitaJ);
    for k = 1:size(X, 1)
        [thisSpec,~,~,~,~] = normalizeSpectra(wn, X(k,:).', "PO4", "peak");
        X(k,:) = thisSpec(:).';
    end

    figure('Name','Mean spectra per WHO category', ...
        'Color','w','Position',[350 200 700 420]);
    ax = gca;
    hold(ax,'on');

    yLimitData = [];

    for j = 1:numel(catList)
        catName = upper(string(catList{j}));
        idx = strcmpi(cats, catName);
        if ~any(idx)
            continue
        end

        clr = catClr(catList{j});
        [~, yThis] = localPlotMeanSpectrumWithUncertainty(ax, wn, X(idx,:), clr, errMode, ...
            'DisplayName', sprintf('%s (n=%d)', catList{j}, sum(idx)), ...
            'LineWidth', 2.5, ...
            'FaceAlpha', 0.15);
        yLimitData = [yLimitData; yThis(:)]; %#ok<AGROW>
    end

    xlabel(ax, 'Wavenumber (cm^{-1})');
    ylabel(ax, 'Normalized intensity (a.u.)');
    title(ax, sprintf('Average spectra for tag %s', strjoin(string(priorityTags), ', ')), ...
        'Interpreter','none');
    xlim(ax, [wn(1) wn(end)]);
    yLimitData = yLimitData(isfinite(yLimitData));
    if ~isempty(yLimitData)
        yMinAll = min(yLimitData);
        yMaxAll = max(yLimitData);
        yPadTop = 0.04 * max(yMaxAll - yMinAll, eps);
        ylim(ax, [yMinAll yMaxAll + yPadTop]);
    end

    yl = ylim(ax);
    yTextTop = yl(1) + 0.95 * diff(yl);
    yTextMid = yl(1) + 0.70 * diff(yl);
    yTextLow = yl(1) + 0.45 * diff(yl);
    xPos = @(v) wn(interp1(wn, 1:numel(wn), v, 'nearest', 'extrap'));

    text(ax, xPos(1005), yTextTop, 'PO_4^{3-}', ...
        'HorizontalAlignment','center', 'FontSize',30, 'Interpreter','tex');
    text(ax, xPos(1445), yTextMid, 'CH_2', ...
        'HorizontalAlignment','center', 'FontSize',30, 'Interpreter','tex');
    text(ax, xPos(1070), yTextLow, 'CO_3^{2-}', ...
        'HorizontalAlignment','center', 'FontSize',30, 'Interpreter','tex');
    text(ax, xPos(1260), yTextLow, 'Amide III', ...
        'HorizontalAlignment','center', 'FontSize',30);
    text(ax, xPos(1660), yTextLow, 'Amide I', ...
        'HorizontalAlignment','center', 'FontSize',30);

    legend(ax, 'show', 'Location','northeast', 'Box','off');
    set(ax, 'FontSize',36, 'Box','off', 'LineWidth',7, ...
        'XAxisLocation','bottom', 'YAxisLocation','left');
end


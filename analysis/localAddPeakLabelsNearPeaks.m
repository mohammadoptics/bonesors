function localAddPeakLabelsNearPeaks(ax, wn, yReference, labelFontSize)
    if nargin < 4 || isempty(labelFontSize)
        labelFontSize = 15;
    end

    wn = wn(:);
    yReference = yReference(:);
    if numel(yReference) ~= numel(wn) && mod(numel(yReference), numel(wn)) == 0
        yReference = max(reshape(yReference, numel(wn), []), [], 2, 'omitnan');
    end
    if numel(yReference) ~= numel(wn)
        return
    end

    yl = ylim(ax);
    yRange = diff(yl);
    labelPad = 0.035 * yRange;
    maxLabelY = yl(2) - 0.04 * yRange;

    labels = struct( ...
        'x', {960, 1070, 1260, 1445, 1660}, ...
        'text', {'PO_4^{3-}', 'CO_3^{2-}', 'Amide III', 'CH_2', 'Amide I'}, ...
        'interp', {'tex', 'tex', 'none', 'tex', 'none'});

    for k = 1:numel(labels)
        x0 = labels(k).x;
        if x0 < min(xlim(ax)) || x0 > max(xlim(ax))
            continue
        end

        mask = wn >= (x0 - 35) & wn <= (x0 + 35) & isfinite(yReference);
        if any(mask)
            y0 = max(yReference(mask), [], 'omitnan') + labelPad;
        else
            y0 = yl(1) + 0.7 * yRange;
        end
        y0 = min(y0, maxLabelY);

        xPlot = wn(interp1(wn, 1:numel(wn), x0, 'nearest', 'extrap'));
        text(ax, xPlot, y0, labels(k).text, ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','bottom', ...
            'FontSize',labelFontSize, ...
            'Color',[0.35 0.35 0.35], ...
            'Interpreter',labels(k).interp);
    end
end


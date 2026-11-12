function localPlotResidualTrace(ax, wn, residual, residualTextPosition)
    if nargin < 4 || isempty(residualTextPosition)
        residualTextPosition = [0.04 0.69];
    end

    residual = residual(:);
    wn = wn(:);
    keep = isfinite(wn) & isfinite(residual);
    if nnz(keep) < 3
        return
    end

    yl = ylim(ax);
    yRange = diff(yl);
    if ~isfinite(yRange) || yRange <= 0
        return
    end

    maxResidual = max(residual(keep));
    if ~isfinite(maxResidual) || maxResidual <= 0
        return
    end

    residualScaleFactor = 0.22*yRange / maxResidual;
    residualScaled = yl(1) + 0.48*yRange + residualScaleFactor * residual;
    plot(ax, wn(keep), residualScaled(keep), '-', ...
        'Color',[0.45 0.45 0.45], ...
        'LineWidth',1.0, ...
        'HandleVisibility','off');

    if residualScaleFactor >= 10
        residualLabel = sprintf('|Residual| x%.0f', residualScaleFactor);
    else
        residualLabel = sprintf('|Residual| x%.1f', residualScaleFactor);
    end

    text(ax, residualTextPosition(1), residualTextPosition(2), residualLabel, ...
        'Units','normalized', ...
        'HorizontalAlignment','left', ...
        'VerticalAlignment','top', ...
        'FontSize',13, ...
        'Color',[0.35 0.35 0.35]);
end


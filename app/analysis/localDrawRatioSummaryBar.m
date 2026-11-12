function localDrawRatioSummaryBar(ax, xCenter, y, barWidth)
    y = y(isfinite(y));
    if isempty(y)
        return
    end
    if nargin < 4 || isempty(barWidth)
        barWidth = 0.60;
    end

    mu = mean(y, 'omitnan');
    if ~isfinite(mu)
        return
    end

    bar(ax, xCenter, mu, barWidth, ...
        'FaceColor', [0.88 0.88 0.88], ...
        'EdgeColor', 'k', ...
        'LineWidth', 2.0, ...
        'HandleVisibility','off');
end


function localSetSpectrumYLimits(ax, varargin)
    yAll = [];
    for k = 1:numel(varargin)
        y = varargin{k};
        if ~isempty(y)
            yAll = [yAll; y(:)]; %#ok<AGROW>
        end
    end
    yAll = yAll(isfinite(yAll));
    if isempty(yAll)
        return
    end

    yMin = min(yAll);
    yMax = max(yAll);
    yPadTop = 0.04 * max(yMax - yMin, eps);
    ylim(ax, [yMin yMax + yPadTop]);
end


function [yMin, yMax] = localVisibleYRange(wn, spectraList, xLimits)
    yMin = NaN;
    yMax = NaN;
    if isempty(wn) || isempty(spectraList) || isempty(xLimits)
        return
    end

    wn = wn(:);
    visible = wn >= min(xLimits) & wn <= max(xLimits);
    if ~any(visible)
        return
    end

    yAll = [];
    for k = 1:numel(spectraList)
        y = spectraList{k};
        if isempty(y) || numel(y) ~= numel(wn)
            continue
        end
        yAll = [yAll; y(visible)]; %#ok<AGROW>
    end
    yAll = yAll(isfinite(yAll));
    if isempty(yAll)
        return
    end

    yMin = min(yAll);
    yMax = max(yAll);
end


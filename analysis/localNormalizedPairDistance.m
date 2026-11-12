function dNorm = localNormalizedPairDistance(catMeans, idxA, idxB, within)
    dNorm = NaN;
    if isempty(idxA) || isempty(idxB) || ~isfinite(within) || within <= 0
        return
    end
    if isempty(catMeans{idxA}) || isempty(catMeans{idxB}) || ...
            numel(catMeans{idxA}) ~= numel(catMeans{idxB})
        return
    end

    d = sqrt(mean((catMeans{idxA} - catMeans{idxB}).^2, 'omitnan'));
    dNorm = d / within;
end


function q = localPO4VisibilityIndex(wn, spec, po4Band)
    po4Peak = localBandMax(wn, spec, po4Band);
    denom = max(abs(spec(:)), [], 'omitnan');
    if ~isfinite(po4Peak) || ~isfinite(denom) || denom <= 0
        q = NaN;
    else
        q = po4Peak / denom;
    end
end


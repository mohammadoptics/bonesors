function peakVal = localBandMax(wn, spec, bandRange)
    wn = wn(:);
    spec = spec(:);
    mask = wn >= bandRange(1) & wn <= bandRange(2) & isfinite(spec);
    if ~any(mask)
        peakVal = NaN;
    else
        peakVal = max(spec(mask), [], 'omitnan');
    end
end


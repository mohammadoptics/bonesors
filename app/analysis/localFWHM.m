function [fwhm, ok] = localFWHM(wn, spec, bandRange)
    fwhm = NaN;
    ok = false;

    wn = wn(:);
    spec = spec(:);

    mask = (wn >= bandRange(1)) & (wn <= bandRange(2));
    if nnz(mask) < 5
        return
    end

    x = wn(mask);
    y = spec(mask);
    y = y - min(y);

    [peakHeight, idxMax] = max(y);
    if ~isfinite(peakHeight) || peakHeight <= 0
        return
    end

    halfHeight = peakHeight / 2;

    iL = find(y(1:idxMax) <= halfHeight, 1, 'last');
    if isempty(iL) || iL >= idxMax
        return
    end
    xL = interp1(y(iL:iL+1), x(iL:iL+1), halfHeight, 'linear', 'extrap');

    iRrel = find(y(idxMax:end) <= halfHeight, 1, 'first');
    if isempty(iRrel)
        return
    end
    iR = idxMax - 1 + iRrel;
    if iR <= idxMax
        return
    end
    xR = interp1(y(iR-1:iR), x(iR-1:iR), halfHeight, 'linear', 'extrap');

    fwhm = xR - xL;
    ok = isfinite(fwhm) && fwhm > 0;
end


function fwhmFeatures = localCalcFWHMFeatures(wn, spec)
    wn = wn(:);
    spec = spec(:);

    bands = struct( ...
        'name',  {'FWHM_PO4', 'FWHM_CO3', 'FWHM_AmideIII', 'FWHM_CH2', 'FWHM_AmideI'}, ...
        'range', {[930 990], [1000 1140], [1200 1360], [1360 1500], [1600 1700]});

    for k = 1:numel(bands)
        [fwhm, ok] = localFWHM(wn, spec, bands(k).range);
        if ok && isfinite(fwhm) && fwhm > 0
            fwhmFeatures.(bands(k).name) = fwhm;
        else
            fwhmFeatures.(bands(k).name) = NaN;
        end
    end
end


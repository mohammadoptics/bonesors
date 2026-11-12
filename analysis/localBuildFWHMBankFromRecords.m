function fwhmBank = localBuildFWHMBankFromRecords(records, catList, featureSettings)
    emptyC = struct('FWHM_PO4',[], 'FWHM_CO3',[], ...
        'FWHM_AmideIII',[], 'FWHM_CH2',[], 'FWHM_AmideI',[]);
    fwhmBank = initCategoryBank(catList, emptyC);

    for r = 1:numel(records)
        if isempty(records(r).Spectrum)
            continue
        end

        plotSpectrum = localBuildRatioSpectrum(records(r).Wavenumber, ...
            records(r).Spectrum, featureSettings);
        fwhmStruct = localCalcFWHMFeatures(records(r).Wavenumber, plotSpectrum);
        fwhmFields = fieldnames(fwhmStruct);

        for k = 1:numel(fwhmFields)
            fld = fwhmFields{k};
            val = fwhmStruct.(fld);
            if isfinite(val)
                fwhmBank.(records(r).Category).(fld)(end+1,1) = val; %#ok<AGROW>
            else
                fwhmBank.(records(r).Category).(fld)(end+1,1) = NaN; %#ok<AGROW>
            end
        end
    end
end


function ratioStruct = localBuildRatioStruct(wn, spectra, featureSettings)
    if size(spectra, 2) == 1 || ~localIsRatioLevelCombineMode(featureSettings)
        ratioSpectrum = localBuildRatioSpectrum(wn, spectra, featureSettings);
        ratioStruct = localCalcRatios(wn, ratioSpectrum);
        return
    end

    if size(spectra, 2) ~= 2
        error('Ratio-level combination modes require exactly two selected spectra.');
    end

    ratio1 = localCalcRatios(wn, spectra(:,1));
    ratio2 = localCalcRatios(wn, spectra(:,2));
    ratioStruct = localCombineRatioStructs(ratio1, ratio2, featureSettings.spectrumCombineMode);
end


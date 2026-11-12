function ratioVectors = localRatioVectorsForSpectra(wn, spectra, featureSettings)
    ratioNames = localNormalizeTscoreRatioSelection(featureSettings);
    ratioVectors = nan(numel(ratioNames), size(spectra, 2));
    for s = 1:size(spectra, 2)
        ratioVectors(:,s) = localRatioStructToVector(localCalcRatios(wn, spectra(:,s)), ratioNames).';
    end
end


function specFeatures = localBuildTscoreRamanFeatures(wn, spectra, featureSettings)
    switch char(featureSettings.tscoreFeatureMode)
        case 'spectrum'
            specFeatures = localBuildSpectrumFeatures(wn, spectra, featureSettings);

        case 'ratios'
            ratioStruct = localBuildRatioStruct(wn, spectra, featureSettings);
            specFeatures = localRatioStructToVector(ratioStruct, featureSettings);

        case 'ratiosConcat'
            ratioVectors = localRatioVectorsForSpectra(wn, spectra, featureSettings);
            specFeatures = reshape(ratioVectors, 1, []);

        case 'ratiosMeanDiff'
            ratioVectors = localRatioVectorsForSpectra(wn, spectra, featureSettings);
            if size(ratioVectors, 2) ~= 2
                error('tscoreFeatureMode "ratiosMeanDiff" requires exactly two selected spectra.');
            end
            meanRatios = mean(ratioVectors, 2, 'omitnan');
            diffRatios = ratioVectors(:,1) - ratioVectors(:,2);
            specFeatures = [meanRatios(:).' diffRatios(:).'];

        case 'ratiosNormDiff'
            ratioVectors = localRatioVectorsForSpectra(wn, spectra, featureSettings);
            if size(ratioVectors, 2) ~= 2
                error('tscoreFeatureMode "ratiosNormDiff" requires exactly two selected spectra.');
            end
            normDiff = (ratioVectors(:,1) - ratioVectors(:,2)) ./ (abs(ratioVectors(:,2)) + eps);
            specFeatures = normDiff(:).';
    end
end

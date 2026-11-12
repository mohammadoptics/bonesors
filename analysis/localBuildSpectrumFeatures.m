function specFeatures = localBuildSpectrumFeatures(wn, spectra, featureSettings)
    specNorm = [];
    for s = 1:size(spectra, 2)
        [thisSpec,~,~,~,~] = normalizeSpectra(wn, spectra(:,s), ...
            featureSettings.normalizationRegion, featureSettings.normalizationMethod);
        specNorm(:,s) = thisSpec(:); %#ok<AGROW>
    end

    if size(specNorm,2) == 1
        specFeatures = specNorm(:,1).';
        return
    end

    switch char(featureSettings.spectrumCombineMode)
        case 'concat'
            specFeatures = reshape(specNorm, 1, []);

        case 'mean'
            specFeatures = mean(specNorm, 2).';

        case {'add','sum'}
            specFeatures = sum(specNorm, 2).';

        case 'diff'
            if size(specNorm,2) ~= 2
                error('spectrumCombineMode "diff" requires exactly two selected spectra.');
            end
            diffSpec = specNorm(:,1) - specNorm(:,2);
            specFeatures = diffSpec(:).';

        case 'ratio'
            if size(specNorm,2) ~= 2
                error('spectrumCombineMode "ratio" requires exactly two selected spectra.');
            end
            ratioSpec = specNorm(:,1) ./ (specNorm(:,2) + eps);
            specFeatures = ratioSpec(:).';

        case 'meanDiff'
            if size(specNorm,2) ~= 2
                error('spectrumCombineMode "meanDiff" requires exactly two selected spectra.');
            end
            meanSpec = mean(specNorm, 2);
            diffSpec = specNorm(:,1) - specNorm(:,2);
            specFeatures = [meanSpec(:).' diffSpec(:).'];

        case 'meanRatio'
            if size(specNorm,2) ~= 2
                error('spectrumCombineMode "meanRatio" requires exactly two selected spectra.');
            end
            meanSpec = mean(specNorm, 2);
            ratioSpec = specNorm(:,1) ./ (specNorm(:,2) + eps);
            specFeatures = [meanSpec(:).' ratioSpec(:).'];

        otherwise
            error('spectrumCombineMode "%s" is not supported for full-spectrum T-score features.', ...
                char(featureSettings.spectrumCombineMode));
    end
end

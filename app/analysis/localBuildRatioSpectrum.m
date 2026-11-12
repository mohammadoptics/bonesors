function ratioSpectrum = localBuildRatioSpectrum(wn, spectra, featureSettings)
    specNorm = [];
    for s = 1:size(spectra, 2)
        [thisSpec,~,~,~,~] = normalizeSpectra(wn, spectra(:,s), ...
            featureSettings.normalizationRegion, featureSettings.normalizationMethod);
        specNorm(:,s) = thisSpec(:); %#ok<AGROW>
    end

    if size(specNorm,2) == 1
        ratioSpectrum = specNorm(:,1);
        return
    end

    switch char(featureSettings.spectrumCombineMode)
        case 'mean'
            ratioSpectrum = mean(specNorm, 2);

        case {'add','sum'}
            ratioSpectrum = sum(specNorm, 2);

        case 'diff'
            if size(specNorm,2) ~= 2
                error('Ratio display mode "diff" requires exactly two selected spectra.');
            end
            ratioSpectrum = specNorm(:,1) - specNorm(:,2);

        case 'ratio'
            if size(specNorm,2) ~= 2
                error('Ratio display mode "ratio" requires exactly two selected spectra.');
            end
            ratioSpectrum = specNorm(:,1) ./ (specNorm(:,2) + eps);

        otherwise
            error(['Ratio display with multiple selected spectra requires ', ...
                'spectrumCombineMode "mean", "add", "sum", "diff", or "ratio". ', ...
                'Use analysisMode = "predictTscore" when spectrumCombineMode = "concat".']);
    end
end

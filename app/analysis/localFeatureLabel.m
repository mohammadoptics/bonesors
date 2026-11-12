function label = localFeatureLabel(featureSettings, tissueToUse, spectrumNumber)
    parts = strings(0,1);

    if featureSettings.useRaman
        ramanLabel = sprintf('%s spectrum %s', tissueToUse, mat2str(spectrumNumber));
        if isfield(featureSettings,'tscoreFeatureMode') && ...
                ~strcmpi(string(featureSettings.tscoreFeatureMode), "spectrum")
            ramanLabel = sprintf('%s %s', ramanLabel, featureSettings.tscoreFeatureMode);
            if any(strcmpi(string(featureSettings.tscoreFeatureMode), ...
                    ["ratios","ratiosConcat","ratiosMeanDiff","ratiosNormDiff"]))
                ratioNames = localNormalizeTscoreRatioSelection(featureSettings);
                if numel(ratioNames) < 5
                    ramanLabel = sprintf('%s [%s]', ramanLabel, strjoin(ratioNames, ','));
                end
            end
        elseif numel(spectrumNumber) > 1 && isfield(featureSettings,'spectrumCombineMode')
            ramanLabel = sprintf('%s %s', ramanLabel, featureSettings.spectrumCombineMode);
        end
        if isfield(featureSettings,'tscoreModel')
            ramanLabel = sprintf('%s %s', ramanLabel, upper(string(featureSettings.tscoreModel)));
        end
        parts(end+1) = ramanLabel; %#ok<AGROW>
    end
    if featureSettings.useAge
        parts(end+1) = "Age"; %#ok<AGROW>
    end
    if featureSettings.useSex
        parts(end+1) = "Sex"; %#ok<AGROW>
    end
    if featureSettings.useBMI
        parts(end+1) = "BMI"; %#ok<AGROW>
    end
    if isfield(featureSettings,'useWeight') && featureSettings.useWeight
        parts(end+1) = "Weight"; %#ok<AGROW>
    end

    if isempty(parts)
        label = "No predictors";
    else
        label = strjoin(parts, ' + ');
    end
    if isfield(featureSettings,'blockScaleRamanDemographics') && ...
            featureSettings.blockScaleRamanDemographics
        label = label + " (block-scaled)";
    end
    if isfield(featureSettings,'locationCombineMode') && featureSettings.locationCombineMode~="records"
        label=label+newline+featureSettings.locationCombineMode+" locations: "+strjoin(featureSettings.locationTags,", ");
    end
end

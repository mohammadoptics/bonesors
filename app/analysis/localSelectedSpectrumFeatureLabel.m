function label = localSelectedSpectrumFeatureLabel(tissueToUse, spectrumNumber, combineMode)
    tissueLabel = char(upper(string(tissueToUse)));
    spectrumNumber = spectrumNumber(:).';
    depthLabels = cell(1, numel(spectrumNumber));
    for s = 1:numel(spectrumNumber)
        depthLabels{s} = char(localSpectrumDepthLabel(spectrumNumber(s)));
    end

    if numel(spectrumNumber) == 1
        label = sprintf('%s %s', tissueLabel, depthLabels{1});
        return
    end

    mode = char(lower(string(combineMode)));
    switch mode
        case 'mean'
            label = sprintf('%s mean of %s', tissueLabel, strjoin(depthLabels, ', '));

        case {'add','sum'}
            label = sprintf('%s sum of %s', tissueLabel, strjoin(depthLabels, ', '));

        case 'diff'
            label = sprintf('%s %s minus %s', tissueLabel, depthLabels{1}, depthLabels{2});

        case 'ratio'
            label = sprintf('%s %s/%s', tissueLabel, depthLabels{1}, depthLabels{2});

        otherwise
            label = sprintf('%s %s of %s', tissueLabel, char(string(combineMode)), ...
                strjoin(depthLabels, ', '));
    end
end

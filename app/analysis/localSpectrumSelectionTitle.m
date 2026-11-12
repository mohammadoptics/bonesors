function label = localSpectrumSelectionTitle(spectrumNumber)
    spectrumNumber = spectrumNumber(:).';
    if isempty(spectrumNumber)
        label = 'selected offset';
    elseif numel(spectrumNumber) == 1
        label = sprintf('%s offset', localSpectrumDepthLabel(spectrumNumber));
    else
        labels = arrayfun(@(s) string(localSpectrumDepthLabel(s)), spectrumNumber);
        label = sprintf('%s offsets', char(strjoin(labels, ' and ')));
    end
end


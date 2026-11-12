function contextText = localTscorePlotContextText(spectrumNumber, featureSettings)
%LOCALTSCOREPLOTCONTEXTTEXT Offset and normalization annotation header.

if isfield(featureSettings,'useRaman') && ~featureSettings.useRaman
    contextText = sprintf('Offset = n/a\nNormalization = n/a');
    return
end

spectrumNumber = spectrumNumber(:).';
if isempty(spectrumNumber)
    offsetLine = 'Offset = selected';
elseif isscalar(spectrumNumber)
    offsetLine = sprintf('Offset = %s', localSpectrumDepthLabel(spectrumNumber));
else
    labels = arrayfun(@(s) string(localSpectrumDepthLabel(s)), spectrumNumber);
    offsetLine = sprintf('Offsets = %s', char(strjoin(labels, ' and ')));
end

normalization = "none";
if isfield(featureSettings,'normalizationRegion') && ...
        ~isempty(featureSettings.normalizationRegion)
    normalization = string(featureSettings.normalizationRegion);
end
switch lower(normalization)
    case "po4"
        normalizationLabel = 'PO_{4}^{3-}';
    case "ch2"
        normalizationLabel = 'CH_{2}';
    case "co3"
        normalizationLabel = 'CO_{3}';
    case "amidei"
        normalizationLabel = 'Amide I';
    case "amideiii"
        normalizationLabel = 'Amide III';
    case "fullspectrum"
        normalizationLabel = 'Full spectrum';
    otherwise
        normalizationLabel = char(normalization);
end

contextText = sprintf('%s\nNormalization = %s', ...
    offsetLine, normalizationLabel);
end

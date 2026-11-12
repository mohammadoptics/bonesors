function label = localSpectrumDepthLabel(spectrumNumber)
    switch spectrumNumber
        case 1
            label = '0-mm';
        case 2
            label = '3-mm';
        case 3
            label = '6-mm';
        otherwise
            label = sprintf('spectrum %d', spectrumNumber);
    end
end


function values = parseSpectrumNumbers(value)
%PARSESPECTRUMNUMBERS Parse entries such as "2" or "1, 2" safely.

if isnumeric(value)
    values = double(value(:).');
else
    textValue = strtrim(string(value));
    if strlength(textValue) == 0
        error('MainGUI:MissingSpectrumNumber', 'Enter a spectrum column number.');
    end
    parts = regexp(char(textValue), '[,;\s]+', 'split');
    parts = parts(~cellfun('isempty', parts));
    values = cellfun(@str2double, parts);
end
if isempty(values) || any(~isfinite(values)) || any(values < 1) || ...
        any(values ~= fix(values))
    error('MainGUI:InvalidSpectrumNumber', ...
        'Spectrum columns must be positive whole numbers, for example 2 or 1,2.');
end
values = unique(values, 'stable');
end

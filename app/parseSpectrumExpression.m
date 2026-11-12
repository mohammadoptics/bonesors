function [columns, combineMode, canonicalExpression] = parseSpectrumExpression(value)
%PARSESPECTRUMEXPRESSION Parse an ordered spectrum-column expression.
%   Supported forms are:
%     2       one spectrum column
%     3-2     normalized column 3 minus normalized column 2
%     3+2+1   sum of the normalized columns in the written order
%     3|2|1   concatenate the normalized columns in the written order
%   A comma/space-separated list is also treated as concatenation.

if isnumeric(value)
    columns = localValidateColumns(double(value(:).'));
    if isscalar(columns)
        combineMode = "single";
        canonicalExpression = string(columns);
    else
        combineMode = "concat";
        canonicalExpression = strjoin(string(columns), "|");
    end
    return
end

textValue = strtrim(string(value));
if strlength(textValue) == 0
    error('MainGUI:MissingSpectrumNumber', 'Enter a spectrum column or expression.');
end

compact = regexprep(char(textValue), '\s+', '');
if startsWith(lower(string(compact)), "concat(") && endsWith(string(compact), ")")
    compact = char(extractBetween(string(compact), 8, strlength(string(compact))-1));
    compact = strrep(compact, ',', '|');
end

hasMinus = contains(compact, '-');
hasPlus = contains(compact, '+');
hasConcat = contains(compact, '|');
operatorCount = sum([hasMinus hasPlus hasConcat]);
if operatorCount > 1
    error('MainGUI:InvalidSpectrumExpression', [ ...
        'Use one operation per spectrum expression: subtraction (-), addition (+), ' ...
        'or concatenation (|).']);
end

if operatorCount == 0
    columns = parseSpectrumNumbers(textValue);
    if isscalar(columns)
        combineMode = "single";
        canonicalExpression = string(columns);
    else
        combineMode = "concat";
        canonicalExpression = strjoin(string(columns), "|");
    end
    return
end

if hasMinus
    operator = '-';
    combineMode = "diff";
elseif hasPlus
    operator = '+';
    combineMode = "add";
else
    operator = '|';
    combineMode = "concat";
end

parts = strsplit(compact, operator);
if any(cellfun('isempty', parts))
    localInvalidExpression(textValue);
end
columns = localValidateColumns(cellfun(@str2double, parts));
if numel(columns) < 2
    localInvalidExpression(textValue);
end
if combineMode == "diff" && numel(columns) ~= 2
    error('MainGUI:InvalidSpectrumExpression', ...
        'Subtraction requires exactly two columns, for example 3-2.');
end

canonicalExpression = strjoin(string(columns), string(operator));
end

function columns = localValidateColumns(columns)
if isempty(columns) || any(~isfinite(columns)) || any(columns < 1) || ...
        any(columns ~= fix(columns))
    error('MainGUI:InvalidSpectrumNumber', ...
        'Spectrum columns must be positive whole numbers.');
end
columns = double(columns(:).');
end

function localInvalidExpression(value)
error('MainGUI:InvalidSpectrumExpression', ...
    'Invalid spectrum expression "%s". Use forms such as 2, 3-2, 3+2, or 3|2.', ...
    char(string(value)));
end

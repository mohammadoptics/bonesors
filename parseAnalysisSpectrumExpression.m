function [columns, combineMode, expression] = parseAnalysisSpectrumExpression(value, analysisMode)
%PARSEANALYSISSPECTRUMEXPRESSION Distinguish display panels from feature fusion.
% In average-spectrum analyses, a plain list selects independent offset panels.
% Explicit +, -, and | retain their existing arithmetic/feature meanings.
[columns, combineMode, expression] = parseSpectrumExpression(value);
if ~any(string(analysisMode) == ["compareAverageSpectra","categoryAverageSpectra"])
    return
end
plainList = isnumeric(value) || ...
    isempty(regexp(char(strtrim(string(value))), '[+|\-()]', 'once'));
if ~plainList
    return
end
if numel(columns) > 3 || any(~ismember(columns, 1:3)) || ...
        numel(unique(columns)) ~= numel(columns)
    error('MainGUI:InvalidAverageOffsets', ...
        'Choose up to three distinct offset columns: 1 = 0 mm, 2 = 3 mm, 3 = 6 mm. For example: 1,2,3.');
end
if numel(columns) > 1
    combineMode = "separate";
    expression = strjoin(string(columns), ',');
end
end

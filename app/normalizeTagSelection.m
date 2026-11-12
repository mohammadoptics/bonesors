function tags = normalizeTagSelection(tags)
%NORMALIZETAGSELECTION Return trimmed, stable, unique tag names as cellstr.

if nargin == 0 || isempty(tags), tags = {}; return, end
if ischar(tags)
    tags = {tags};
elseif isstring(tags)
    tags = cellstr(tags(:));
elseif ~iscell(tags)
    error('MainGUI:InvalidTags', 'Tags must be text or a cell array of text.');
end
tags = cellfun(@(x) char(strtrim(string(x))), tags(:), 'UniformOutput', false);
tags = tags(~cellfun('isempty', tags));
if isempty(tags), return, end
[~, keep] = unique(upper(string(tags)), 'stable');
tags = tags(sort(keep));
tags = tags(:).';
end

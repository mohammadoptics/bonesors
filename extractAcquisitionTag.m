function tag = extractAcquisitionTag(value)
%EXTRACTACQUISITIONTAG Convert a process-list entry to a canonical tag.

textValue = string(value);
[~, stem, ~] = fileparts(char(textValue));
textValue = string(stem);
token = regexp(textValue, '^[^_]+_[ETP]_(.*)$', 'tokens', 'once');
if ~isempty(token)
    tag = string(token{1});
else
    tag = textValue;
end
tag = regexprep(strtrim(tag), '_r\d+$', '');
end

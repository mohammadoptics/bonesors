function rows = selectTagRows(availableTags, requestedTags, selectionMode, matchMode)
%SELECTTAGROWS Resolve one or many requested tags deterministically.
% selectionMode is "single", "priority", or "all". matchMode is
% "exact" (recommended) or "prefix".

availableTags = string(availableTags(:));
availableTags = regexprep(strtrim(availableTags), '_r\d+$', '');
requestedTags = string(normalizeTagSelection(requestedTags));
selectionMode = lower(string(selectionMode));
matchMode = lower(string(matchMode));
if ~any(selectionMode == ["single", "priority", "all"])
    error('MainGUI:InvalidTagSelectionMode', 'Invalid tag selection mode.');
end
if ~any(matchMode == ["exact", "prefix"])
    error('MainGUI:InvalidTagMatchMode', 'Invalid tag match mode.');
end
if selectionMode == "single" && numel(requestedTags) ~= 1
    error('MainGUI:SingleTagRequired', ...
        'Single-tag mode requires exactly one selected tag.');
end
if isempty(requestedTags)
    if selectionMode == "all"
        rows = find(strlength(availableTags) > 0).';
    else
        rows = [];
    end
    return
end
rows = [];
for k = 1:numel(requestedTags)
    wanted = requestedTags(k);
    if matchMode == "exact"
        hit = find(strcmpi(availableTags, wanted));
    else
        hit = find(startsWith(availableTags, wanted, 'IgnoreCase', true));
    end
    if selectionMode == "all"
        rows = [rows; hit(:)]; %#ok<AGROW>
    elseif ~isempty(hit)
        rows = hit(1);
        return
    end
end
if selectionMode == "all" && ~isempty(rows)
    rows = unique(rows, 'stable').';
end
end

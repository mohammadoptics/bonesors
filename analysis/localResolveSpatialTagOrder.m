function [tagOrder, tagLabels] = localResolveSpatialTagOrder(records, requestedTags, matchMode)
%LOCALRESOLVESPATIALTAGORDER Resolve actual tags while preserving GUI order.

actualTags = string({records.Tag});
actualTags = actualTags(strlength(actualTags) > 0);
actualTags = unique(actualTags, 'stable');
requestedTags = string(normalizeTagSelection(requestedTags));
matchMode = lower(string(matchMode));
tagOrder = strings(0,1);

for k = 1:numel(requestedTags)
    if matchMode == "prefix"
        hits = actualTags(startsWith(actualTags, requestedTags(k), ...
            'IgnoreCase', true));
        if numel(hits) > 1
            coordinates = arrayfun(@localSpatialTagCoordinate, hits);
            [~, order] = sort(coordinates, 'descend', 'MissingPlacement','last');
            hits = hits(order);
        end
    else
        idx = find(strcmpi(actualTags, requestedTags(k)), 1);
        if isempty(idx), hits = strings(0,1); else, hits = actualTags(idx); end
    end
    tagOrder = [tagOrder; hits(:)]; %#ok<AGROW>
end

tagOrder = unique(tagOrder, 'stable');
if isempty(tagOrder)
    error('MainGUI:NoSpatialTagsMatched', ...
        'None of the selected tags matched usable records.');
end

tagLabels = arrayfun(@localShortTagLabel, tagOrder);
lowerLabels = lower(tagLabels);
for k = 1:numel(tagLabels)
    if sum(lowerLabels == lowerLabels(k)) > 1
        tagLabels(k) = replace(tagOrder(k), "_", "-");
    end
end
end

function refreshAvailableTags(fig)
%REFRESHAVAILABLETAGS Discover acquisition tags in all loaded data files.

if nargin < 1 || isempty(fig) || ~ishandle(fig), return, end
ud = fig.UserData;
tags = strings(0,1);
for k = 1:numel(ud.data)
    item = ud.data{k};
    if ~isfield(item, 'process') || ~isfield(item.process, 'list')
        continue
    end
    list = string(item.process.list(:));
    for j = 1:numel(list)
        tag = extractAcquisitionTag(list(j));
        if strlength(tag) > 0, tags(end+1,1) = tag; end %#ok<AGROW>
    end
end

if isempty(tags)
    tags = string(ud.config.analysis.tags(:));
end
tags = unique(tags, 'stable');
tags = sort(tags);
ud.availableTags = cellstr(tags);

if isfield(ud, 'controls') && isfield(ud.controls, 'availableTags') && ...
        ishandle(ud.controls.availableTags)
    if isempty(tags)
        set(ud.controls.availableTags, 'String', {'No tags discovered'}, 'Value', 1);
    else
        set(ud.controls.availableTags, 'String', cellstr(tags), 'Value', 1);
    end
end
fig.UserData = ud;
end

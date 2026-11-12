function refreshAnalysisTags(fig)
%REFRESHANALYSISTAGS Discover tags only from the loaded analysis dataset.

ud = fig.UserData;
tags = strings(0,1);
if isfield(ud, 'analysisData') && ~isempty(ud.analysisData)
    loaded = ud.analysisData;
    if isfield(loaded, 'cads'), values = loaded.cads;
    elseif isfield(loaded, 'cadavers'), values = loaded.cadavers;
    elseif isfield(loaded, 'pairedCadavers'), values = loaded.pairedCadavers;
    else, values = []; end

    if ~isempty(values) && isstruct(values)
        for c = 1:numel(values)
            if ~isfield(values(c), 'list') || isempty(values(c).list), continue, end
            entries = string(values(c).list(:));
            for k = 1:numel(entries)
                tag = extractAcquisitionTag(entries(k));
                if strlength(tag) > 0, tags(end+1,1) = tag; end %#ok<AGROW>
            end
        end
    elseif isfield(loaded, 'tbl') && istable(loaded.tbl) && ...
            ismember('Tag', loaded.tbl.Properties.VariableNames)
        tags = string(loaded.tbl.Tag);
    elseif isfield(loaded, 'TblPred') && istable(loaded.TblPred) && ...
            ismember('Tag', loaded.TblPred.Properties.VariableNames)
        tags = string(loaded.TblPred.Tag);
    end
end

tags = sort(unique(regexprep(strtrim(tags), '_r\d+$', ''), 'stable'));
tags = tags(strlength(tags) > 0);
ud.analysisAvailableTags = cellstr(tags);

if isfield(ud, 'controls') && isfield(ud.controls, 'analysisAvailableTags')
    control = ud.controls.analysisAvailableTags;
    if isempty(tags)
        set(control, 'String', {'No tags found'}, 'Value', 1);
    else
        set(control, 'String', cellstr(tags), 'Value', 1);
    end
end

if ~isempty(tags) && isfield(ud, 'controls') && ...
        isfield(ud.controls, 'analysisSelectedTags')
    requested = string(ud.config.analysis.tags);
    keep = tags(ismember(upper(tags), upper(requested)));
    if isempty(keep), keep = tags(1); end
    set(ud.controls.analysisSelectedTags, 'String', cellstr(keep), 'Value', 1);
end
fig.UserData = ud;
end

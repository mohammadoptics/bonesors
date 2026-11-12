function groupMode = localResolveOutlierGroupMode(outlierSettings, tissueToUse)
    if isfield(outlierSettings, 'groupMode') && ~isempty(outlierSettings.groupMode)
        groupMode = validatestring(outlierSettings.groupMode, {'auto','category','all'});
    elseif isfield(outlierSettings, 'groupWithinCategory')
        if outlierSettings.groupWithinCategory
            groupMode = 'category';
        else
            groupMode = 'all';
        end
    else
        groupMode = 'category';
    end

    if strcmpi(groupMode, 'auto')
        if strcmpi(tissueToUse, 'T')
            groupMode = 'all';
        else
            groupMode = 'category';
        end
    end
end


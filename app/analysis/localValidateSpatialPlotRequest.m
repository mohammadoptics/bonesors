function localValidateSpatialPlotRequest(options)
if isempty(options.tags)
    error('MainGUI:SpatialTagsRequired', ...
        'Select at least one tag for the spatial plot.');
end
if options.tagSelectionMode ~= "all"
    error('MainGUI:SpatialPlotRequiresAllTags', ...
        'Spatial plots require the All selected tag policy.');
end
end

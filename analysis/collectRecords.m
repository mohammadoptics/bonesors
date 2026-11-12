function records = collectRecords(context, tissue, requireRaman)
%COLLECTRECORDS Shared E/P/T record collector for analysis modules.

o = context.options;
if o.mode=="predictTscore" && isfield(context.settings.feature,'locationCombineMode') && ...
        context.settings.feature.locationCombineMode~="records"
    % These effective tags come from Analysis and the selected figure panels.
    % Fusion needs every requested location, not priority/first-tag fallback.
    o.tags=cellstr(context.settings.feature.locationTags);
    o.tagSelectionMode="all"; o.tagMatchMode="exact"; requireRaman=true;
end
records = localCollectPairedSpectra(context.cads, context.ud.statusMap, ...
    context.Tcat, tissue, o.spectrumNumbers, o.tags, requireRaman, ...
    o.tagSelectionMode, o.tagMatchMode);
end

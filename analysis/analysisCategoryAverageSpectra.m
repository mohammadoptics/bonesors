function analysisCategoryAverageSpectra(context)
o = context.options; s = context.settings;
records = collectRecords(context, o.tissue, true);
groups = struct('Tissue',o.tissue,'Records',records);
if isfield(o,'categoryAverageIncludeComparison') && o.categoryAverageIncludeComparison
    if o.tissue == o.comparisonTissue
        error('MainGUI:DuplicateAverageTissue','Choose a different comparison tissue, or disable the second row.');
    end
    secondary = collectRecords(context, o.comparisonTissue, true);
    if isempty(secondary)
        error('MainGUI:MissingAverageComparison', ...
            'No %s spectra match the selected offsets and tags. Choose available offsets or disable the second row.', ...
            analysisTissueLabel(o.comparisonTissue));
    end
    groups(2) = struct('Tissue',o.comparisonTissue,'Records',secondary);
end
localPlotCategoryAverageFeatureGrid(records, o.tissue, o.spectrumNumbers, ...
    o.tags, s.feature, s.plot.useIanitaJForAverageSpectra, s.categoryAverage, groups);
end

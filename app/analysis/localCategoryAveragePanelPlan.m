function panels = localCategoryAveragePanelPlan(groups, columns, combineMode, norms)
% Rows are tissue/normalization groups; columns are independently selected offsets.
separate = string(combineMode)=="separate";
if separate
    if numel(columns)>3 || any(~ismember(columns,1:3)) || numel(unique(columns))~=numel(columns)
        error('MainGUI:InvalidAverageOffsets','Select up to three distinct offset columns (1, 2, 3).');
    end
    count=numel(columns);
else
    count=1;
end
panels=struct('Records',{},'Tissue',{},'Columns',{},'CombineMode',{},'Normalization',{});
for g=1:numel(groups)
    for n=1:numel(norms)
        for s=1:count
            records=groups(g).Records;
            selected=columns; mode=string(combineMode);
            if separate
                selected=columns(s); mode="single";
                for r=1:numel(records)
                    if size(records(r).Spectrum,2)<s
                        error('MainGUI:MissingAverageOffset','A selected offset is missing from the collected spectra.');
                    end
                    % Records already contain the selected columns, in selection order.
                    records(r).Spectrum=records(r).Spectrum(:,s);
                end
            end
            panels(end+1)=struct('Records',records,'Tissue',groups(g).Tissue, ...
                'Columns',selected,'CombineMode',mode,'Normalization',norms(n)); %#ok<AGROW>
        end
    end
end
end

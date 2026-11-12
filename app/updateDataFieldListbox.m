% =========================================================
% === 1) updateDataFieldListbox – build & remember mapping
% =========================================================
function updateDataFieldListbox(fig,~)
    ud       = fig.UserData;
    selFiles = get(ud.fileListBox,'Value');
    if isempty(selFiles)
        set(ud.dataFieldListbox,'String',{'No Data Fields'});
        return
    end

    dataFields  = {};
    origNames   = {};
    fileIdxVec  = {};         % <-- NEW – remembers the source file

    for idx = selFiles
        dStruct = fig.UserData.data{idx};
        flds    = extractDataFields(dStruct);

        for i = 1:numel(flds)
            dataFields{end+1} = buildDisplayFieldName(flds{i},dStruct); %#ok<AGROW>
            origNames {end+1} = flds{i};                        %#ok<AGROW>
            fileIdxVec{end+1} = idx;                            %#ok<AGROW>
        end
    end

    % A field path should appear once even when it exists in many selected
    % files. The old behavior duplicated plots and lost the source mapping.
    [~, uniqueIndex] = unique(origNames, 'stable');
    dataFields = dataFields(uniqueIndex);
    origNames = origNames(uniqueIndex);
    fileIdxVec = fileIdxVec(uniqueIndex);

    [sortedDisp , sortedOrig] = sortDataFieldsByIndex(dataFields,origNames);
    [~,sortOrd] = ismember(sortedOrig , origNames);   % gives numeric idx
    sortedFile  = fileIdxVec(sortOrd);

    set(ud.dataFieldListbox,'String',sortedDisp,'Value',1);
    ud.dataFieldOriginalNames = sortedOrig;
    ud.dataFieldFileIdx       = sortedFile;
    fig.UserData              = ud;            % write back
    updateSpectrumListbox(fig);                % <-- pass fig here as well
end

function [sortedDataFields, sortedOriginalFieldNames] = sortDataFieldsByIndex(dataFields, originalFieldNames)
    % Initialize cell arrays for sorting
    dataWithIndices = {};
    
    % Extract the numeric index and type (anitaspec, spec, or other) for each field
    for i = 1:length(dataFields)
        field = dataFields{i};
        originalField = originalFieldNames{i};
        
        % Look for the index inside {} for anitaspec and spec
        fieldTokens = regexp(field, 'process\.(anitaspec|spec)\{(\d+)\}', 'tokens');
        if ~isempty(fieldTokens)
            % Extract the type (anitaspec or spec) and numeric index
            type = fieldTokens{1}{1};  % anitaspec or spec
            index = str2double(fieldTokens{1}{2});  % Extract the numeric index
            typePriority = 1;  % Default priority (1 = top for anitaspec)
            if strcmp(type, 'spec')
                typePriority = 2;  % Give 'spec' lower priority than 'anitaspec'
            end
            % Store the field along with the numeric index and type priority for sorting
            dataWithIndices{end+1, 1} = field; %#ok<AGROW>
            dataWithIndices{end, 2} = index;  %#ok<AGROW>
            dataWithIndices{end, 3} = typePriority;  %#ok<AGROW>
            dataWithIndices{end, 4} = originalField; %#ok<AGROW>
        else
            % Store other fields without a specific type at the bottom
            dataWithIndices{end+1, 1} = field; %#ok<AGROW>
            dataWithIndices{end, 2} = Inf;   % Assign a high number for sorting later
            dataWithIndices{end, 3} = 3;     % Give them the lowest priority (other fields)
            dataWithIndices{end, 4} = originalField; %#ok<AGROW>
        end
    end
    
    % Sort first by type priority (anitaspec -> spec -> other), then by numeric index
    sortedDataWithIndices = sortrows(dataWithIndices, [3 2]);
    
    % Extract sorted data fields and original field names
    sortedDataFields = sortedDataWithIndices(:, 1);
    sortedOriginalFieldNames = sortedDataWithIndices(:, 4);
end



% helper that appends process.list name for display only
function out = buildDisplayFieldName(in,dStruct)
    out = in;
    if contains(in,'process.anitaspec') || contains(in,'process.spec')
        tok = regexp(in,'\{(\d+)\}','tokens','once');
        if ~isempty(tok)
            idx = str2double(tok{1});
            if idx <= numel(dStruct.process.list)
                out = sprintf('%s%s',in,dStruct.process.list{idx});
            end
        end
    end
end


function dataFields = extractDataFields(dataStruct)
    % Recursively extract all numeric fields from a data structure
    dataFields = {};
    fields = fieldnames(dataStruct);
    for i = 1:length(fields)
        field = fields{i};
        value = dataStruct.(field);
        if isnumeric(value) || islogical(value)
            dataFields{end+1} = field; %#ok<AGROW>
        elseif isstruct(value)
            subFields = extractDataFields(value);
            for j = 1:length(subFields)
                dataFields{end+1} = sprintf('%s.%s', field, subFields{j}); %#ok<AGROW>
            end
        elseif iscell(value)
            for k = 1:length(value)
                if isnumeric(value{k}) || islogical(value{k})
                    dataFields{end+1} = sprintf('%s{%d}', field, k); %#ok<AGROW>
                elseif isstruct(value{k})
                    subSubFields = extractDataFields(value{k});
                    for jj = 1:length(subSubFields)
                        dataFields{end+1} = sprintf('%s{%d}.%s', field, k, subSubFields{jj}); %#ok<AGROW>
                    end
                end
            end
        end
    end
end


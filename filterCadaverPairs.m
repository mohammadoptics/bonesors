function cadsOut = filterCadaverPairs(cadsIn, allowTags)
% filterCadaverPairs
% Keep only spectra whose tag is in allowTags.
%
% Supports:
%   (1) Paired rows:   list{j,1} = 'ID_E_TAG.mat', list{j,2} = 'ID_T_TAG.mat'
%   (2) T-only rows:   list{j,1} = '' (or missing), list{j,2} = 'ID_T_TAG.mat'
%                      with E{j} = [].
%
% Note:
%   This function does NOT decide whether cadavers should allow T-only.
%   That policy should be enforced upstream (e.g., in collectPairs).
%   Here we only filter by allowTags and keep any surviving rows.

    if nargin < 2 || isempty(allowTags)
        cadsOut = cadsIn;  % nothing to filter
        return;
    end

    %--- create an empty struct with the same fields as input --------------
    cadsOut = struct('id',{},'wn',{},'E',{},'T',{},'list',{});

    for c = 1:numel(cadsIn)

        if ~isfield(cadsIn(c),'list') || isempty(cadsIn(c).list)
            continue
        end

        keepE = {};  keepT = {};  keepL = {};

        nRows = size(cadsIn(c).list, 1);

        for j = 1:nRows

            % Prefer parsing tag from E-name, but if it's empty (T-only),
            % parse from T-name.
            nameForTag = "";
            if size(cadsIn(c).list,2) >= 1 && ~isempty(cadsIn(c).list{j,1})
                nameForTag = string(cadsIn(c).list{j,1});
            elseif size(cadsIn(c).list,2) >= 2 && ~isempty(cadsIn(c).list{j,2})
                nameForTag = string(cadsIn(c).list{j,2});
            end

            if strlength(nameForTag) == 0
                % nothing to parse → skip
                continue
            end

            % Extract TAG from 'ID_E_TAG.mat' or 'ID_T_TAG.mat'
            m = regexp(nameForTag, '^[^_]+_[ET]_(.*)\.mat$', 'tokens', 'once');

            if ~isempty(m)
                tag = m{1};
            else
                % If parsing fails, skip this row (safer than guessing)
                continue
            end

            % Keep only allowed tags and _r## 
            baseTag = regexprep(tag, '_r\d+$', '');   % remove _r##
            if ismember(baseTag, allowTags)

                % Guard indexing (E/T cells should match list rows)
                if isfield(cadsIn(c),'E') && numel(cadsIn(c).E) >= j
                    keepE{end+1} = cadsIn(c).E{j}; %#ok<AGROW>
                else
                    keepE{end+1} = []; %#ok<AGROW>
                end

                if isfield(cadsIn(c),'T') && numel(cadsIn(c).T) >= j
                    keepT{end+1} = cadsIn(c).T{j}; %#ok<AGROW>
                else
                    keepT{end+1} = []; %#ok<AGROW>
                end

                keepL(end+1,1:2) = cadsIn(c).list(j,1:2); %#ok<AGROW>
            end
        end

        % Keep this subject only if something survived in either channel
        hasAny = ~isempty(keepE) || ~isempty(keepT);
        if hasAny
            tmp      = cadsIn(c);
            tmp.E    = keepE;
            tmp.T    = keepT;
            tmp.list = keepL;
            cadsOut(end+1) = tmp; %#ok<AGROW>
        end
    end
end

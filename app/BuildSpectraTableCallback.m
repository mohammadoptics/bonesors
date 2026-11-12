%% ------------------------------------------------------------------------
%%IntactOrExposedSpectraTableCallback  — save every intact spectrum + T-score
% -------------------------------------------------------------------------
function BuildSpectraTableCallback(fig,~)

    % 0) ensure WHO-category sheet (with T-score) is loaded
    if isempty(fig.UserData.statusMap)
        chooseCategoryFile(fig);
        if isempty(fig.UserData.statusMap), return, end
    end
    Tcat = readtable(fig.UserData.statusFilename, ...
                     'VariableNamingRule','preserve','TextType','string');

    % 1) ask once whether to load a bad-spectra sheet
    if ~isfield(fig.UserData,'badMap') || fig.UserData.badMap.Count==0
        q = questdlg('Load a bad-spectra sheet to filter spectra?', ...
                     'Bad spectra','Yes','No','Yes');
        if strcmp(q,'Yes');  loadBadSpectraSheet(fig);  end
    end
    badMap = [];   % may stay empty
    if isfield(fig.UserData,'badMap');  badMap = fig.UserData.badMap;  end

    % 2) build the table
    tbl = local_collectAllSpectra(fig, Tcat, badMap);

    if isempty(tbl)
        errordlg('No spectra passed the filters.','Nothing saved');  return
    end

    % 3) ask where to save
    defName = sprintf('SpectraTable_%s.mat', datestr(now,'yyyymmdd_HHMM'));
    [f,p] = uiputfile(defName,'Save spectra table as');
    if f==0, return, end
    save(fullfile(p,f),'tbl');        % variable name = tbl
    msgbox(sprintf('Saved %d spectra from %d cadavers.', ...
           height(tbl), numel(unique(tbl.CadaverID))), ...
           'Table saved');
end


% ======================================================================
% helper – collect *every* intact spectrum (+ T-score) into one table
%          bad-spectra rows are skipped via isBadSpectrum
% ======================================================================
function tbl = local_collectAllSpectra(fig, Tcat, badMap)

    wnAxis = [];                        % remembered once for reference

    % map AGR-ID  →  T-score
    idVec     = upper(strrep(Tcat.('AGR-ID'),' ',''));
    tscoreVec = Tcat.('Distal Radius T-Score (1/3)');
    id2T      = containers.Map(idVec , tscoreVec);

    CadaverID = string.empty(0,1);
    Tag       = string.empty(0,1);
    Tissue    = string.empty(0,1); 
    SpecMat   = {};                     % 499×3 double per cell
    Tscore    = [];

    for idx = 1:numel(fig.UserData.data)

        dStruct = fig.UserData.data{idx};
        fname   = fig.UserData.fileNames{idx};
        cadID   = upper(regexp(fname,'^[^_]+','match','once'));   % e.g. DEMO001

        if ~isKey(id2T,cadID) || ...
           ~isfield(dStruct,'process') || ~iscell(dStruct.process.list)
            continue
        end

        wnAxis = dStruct.process.wavenum(:);                      % save once

        % ---------- loop over every intact spectrum ---------------------------
        for s = 1:numel(dStruct.process.anitaspec)

            rawTag = dStruct.process.list{s};          % e.g.  'DEMO001_T_D2P1_MM00.mat'

            % --- accept ONLY  …_E_… or …_T_…  ----------------------------------
            %   token{1} = 'E'  or  'T'
            %   token{2} =        'D2P1_MM00'   (the display tag you want)
            token = regexp(rawTag, '^[^_]+_([ET])_(.*)\.mat$', ...
                'tokens', 'once', 'ignorecase');

            if isempty(token)
                continue                     % <-- skip "SoftTissue_…", "Tendon…", etc.
            end

            tag          = token{2};         % clean tag (D2P1_MM00, …)

            % --- skip if listed in bad-spectra sheet ---------------------------
            if isBadSpectrum(cadID, tag, badMap)
                continue
            end

            % --- retrieve intact matrix (499×3) --------------------------------
            Tmat = dStruct.process.anitaspec{s};

            % -----Optional: Decide to normalize or no
            %%Tmat      = normalize_PO4(wnAxis, Tmat);   % 499×3


            if isempty(Tmat) || size(Tmat,1) ~= numel(wnAxis)
                continue
            end

            % --- append a new row to the output vectors ------------------------
            CadaverID(end+1,1) = cadID;          %#ok<AGROW>
            Tag      (end+1,1) = tag;            %#ok<AGROW>
            if token{1} == 'T'
                Tissue(end+1,1) = "Intact";
            else                 % token{1} == 'E'
                Tissue(end+1,1) = "Exposed";
            end
            
            SpecMat  {end+1,1} = Tmat;           %#ok<AGROW>
            Tscore   (end+1,1) = id2T(cadID);    %#ok<AGROW>
        end

    end

    % final table
    tbl = table(CadaverID, Tag, Tissue, SpecMat, Tscore, ...
                'VariableNames',{'CadaverID','Tag','Tissue','Spectra','Tscore'});
    tbl.Properties.UserData.wavenumber = wnAxis;       % attach axis once


    % % %%-----------------Optional: Filter Tags before saving
    % % 
    % % allowTags = {'D2P1'};                           % ← any location of D2P1
    % % %allowTags = {'D2P1','D3P1','D4P1'};        % ← mix of both styles
    % % %allowTags = {};   % leave empty → keep every tag
    % % 
    % % if ~isempty(allowTags)
    % %     keep = false(height(tbl),1);                  % initialise logical mask
    % % 
    % %     for k = 1:numel(allowTags)
    % %         tok = upper(string(allowTags{k}));
    % % 
    % %         if contains(tok,'_')                      % has "_"  → exact tag
    % %             keep = keep | strcmpi(tbl.Tag, tok);
    % % 
    % %         else                                      % no "_" → treat as prefix
    % %             % match tokens like "D2P1" to any "D2P1_XXXX"
    % %             keep = keep | startsWith(upper(tbl.Tag), tok + "_");
    % %         end
    % %     end
    % % 
    % %     tbl = tbl(keep,:);                            % apply filter
    % % 
    % %     if isempty(tbl)
    % %         errordlg('No spectra left after tag filter.'); return
    % %     end
    % % end


end

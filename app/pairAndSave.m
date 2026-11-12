% -------------------------------------------------------------------------
% Pair all loaded _E / _T files and write them to disk
% -------------------------------------------------------------------------
function pairAndSave(~,~)

    fig = gcbf;                           % main GUI figure
    ud  = fig.UserData;

    % Choose what this save should contain:
    %   "paired"      -> current paired E/T behavior
    %   "exposedOnly" -> save only E spectra, using the exposed cohort policy
    %   "intactOnly"  -> save only T spectra
    saveMode = "exposedOnly";
    if isfield(ud, 'config') && isfield(ud.config, 'preparation') && ...
            isfield(ud.config.preparation, 'saveMode')
        saveMode = string(ud.config.preparation.saveMode);
    end

    % Choose spectrum normalization before saving:
    %   false -> save spectra without normalization
    %   true  -> normalize using normalizationRegion and normalizationMethod
    doNormalizeSpectra = 0;
    normalizationRegion = "none";    % "none" | "PO4" | "CO3" | "CH2" | "AmideI" | "AmideIII" | "FullSpectrum"
    normalizationMethod = "peak";        % "peak" | "peakBaseline" | "area"

    % bad-spectra filtering:
    %   "askFile" -> ask for the Excel bad-spectra sheet
    %   "manual"  -> use manualFilterSpectra below and do not ask for a file
    %   "none"    -> do not filter bad or outlier spectra
    filterSpectraSource = "none";

    % Optional study-specific list for manual filtering.
    % Each row has a specimen ID and a cell array of tags to remove.
    % An empty tag list removes all spectra for that ID.
    % Add _T or _E to restrict an entry to one tissue type.
    manualFilterSpectra = cell(0,2);

   %Filter unwanted Tags before saving
   %--------------------------------------------------------------
   allowTags = {};  % keep all tags

   % For BOE Intact paper
   %allowTags = {'D2P1_MM00','D3P1_MM00'};

   % allowTags = { ...
   %     'D2P1_MM00','D2P1_MP05','D2P1_MD05','D2P1_MP03','D2P1_MD03',...
   %     'D3P1_MM00','D3P1_MP05','D3P1_MD05','D3P1_MP03','D3P1_MD03'};


    % Choose category-sheet columns to copy into each saved cadaver.
    % Edit this list to save different Excel columns, for example:
    %   "Distal Radius BMD (g/cm2; 1/3)"
    %or
    % [ ...
    %     Distal Radius T-Score (1/3)", ...
    %     "WHO Classification (Distal Radius; 1/3)"];
    % categoryColumnsToSave = [ ...
    %     "WHO Classification (Distal Radius; 1/3)"];
    categoryColumnsToSave = [];

    % Save a LaTeX settings report next to the paired-cadaver .mat file.
    % The report records the input options used for this pair-and-save run.
    saveSettingsTex = true;
    settingsTexFileName = "pairAndSave_settings.tex";

    exposedPolicy = localGetExposedSavePolicy();
    saveMode = validatestring(saveMode, {'paired','exposedOnly','intactOnly'});
    normalizationRegion = validatestring(normalizationRegion, ...
        {'none','PO4','CO3','CH2','AmideI','AmideIII','FullSpectrum'});
    normalizationMethod = validatestring(normalizationMethod, {'peak','peakBaseline','area'});
    filterSpectraSource = validatestring(filterSpectraSource, {'askFile','manual','none'});

    needsCategorySheet = ~isempty(categoryColumnsToSave) || ...
        (exposedPolicy.enabled && ~strcmpi(saveMode, "intactOnly"));

    if needsCategorySheet
        if isempty(ud.statusMap)
            chooseCategoryFile(fig);
            ud = fig.UserData;
            if isempty(ud.statusMap)
                warndlg({'A category sheet is required for the selected save options.', ...
                    'Click "Load Category Sheet" and try again.'}, ...
                    'Category sheet needed','modal');
                return
            end
        end

        Tcat = readtable(ud.statusFilename, ...
            'VariableNamingRule','preserve', ...
            'TextType','string');
    else
        Tcat = [];
    end

    %--------------------------------------------------------------
    % 0)  TAKE **ALL** LOADED FILES
    %--------------------------------------------------------------
    nFiles = numel(ud.fileNames);
    if nFiles == 0
        errordlg('Load some _E / _T .mat files first.','No data');
        return
    end
    selFiles = 1 : nFiles;                % <--- every file, no list-selection

    %--------------------------------------------------------------
    % 1)  Configure bad-spectra filtering
    %--------------------------------------------------------------
    ud.badMap = containers.Map('KeyType','char','ValueType','any');
    ud.hasBadSpectraSheet = false;
    fig.UserData = ud;

    switch lower(string(filterSpectraSource))
        case "manual"
            ud.badMap = localBuildManualBadSpectraMap(manualFilterSpectra);
            ud.hasBadSpectraSheet = ud.badMap.Count > 0;
            fig.UserData = ud;
            if ud.hasBadSpectraSheet
                fprintf('Using manual bad-spectra list with %d cadaver ID(s).\n', ud.badMap.Count);
            else
                fprintf('Manual bad-spectra filtering selected, but manualBadSpectra is empty. No bad spectra will be filtered.\n');
            end

        case "askfile"
            q = questdlg(['Do you want to load a bad-spectra sheet now ' ...
                          'to filter out spectra?'], ...
                         'Bad spectra filtering','Yes','No','Yes');
            if strcmp(q,'Yes')
                okBadSheet = false;
                while ~okBadSheet
                    drawnow;
                    okBadSheet = loadBadSpectraSheet(fig);     % pass the GUI figure
                    ud = fig.UserData;                         % refresh, in case user cancelled

                    if ~okBadSheet
                        retry = questdlg({'No bad-spectra sheet was loaded.', ...
                            'Do you want to try selecting it again?'}, ...
                            'Bad spectra sheet needed', ...
                            'Try Again','Cancel Pairing','Try Again');
                        if ~strcmp(retry,'Try Again')
                            return
                        end
                    end
                end
            elseif isempty(q)
                return
            end

        case "none"
            fprintf('Bad-spectra filtering is disabled.\n');
    end

    %--------------------------------------------------------------
    % 2)  Build the paired-cadaver struct
    %--------------------------------------------------------------
    [cads,warnMsg] = collectPairs(fig, selFiles, Tcat, exposedPolicy, saveMode, ...
        doNormalizeSpectra, normalizationRegion, normalizationMethod);
    if isempty(cads)
        errordlg(['Nothing saved.' newline warnMsg],'Pair error');
        return
    end
    if ~isempty(warnMsg)
        uiwait(warndlg(warnMsg,'Skipped spectra'));
    end

    %--------------------------------------------------------------
    % 3)  Filter unwanted Tags before saving
    %--------------------------------------------------------------

   % allowTags = {};


   %allowTags = {'D2P1_MM00','D3P1_MM00'};

    % tested and verified r > 0.7 for 1st_2nd
    % % allowTags = { ...
    % %     'D2P1_MM00','D2P1_MP05','D2P1_MD05','D2P1_MP03','D2P1_MD03','D2P1_MP06','D2P1_MD06',...
    % %     'D3P1_MM00','D3P1_MP05','D3P1_MD05',...
    % %     'D4P1_MM00','D4P1_MP05','D4P1_MD05',...
    % %     'D2P2_MM00','D2P2_MP03','D2P2_MD03','D2P2_MP05','D2P2_MD05',...
    % %     'D3P2_MM00','D3P2_MP05','D3P2_MD05'};



    % % allowTags = {'D2P1_MM00','D2P1_MP05','D2P1_MD05','D2P1_MP03','D2P1_MD03','D2P1_MP06','D2P1_MD06'};

    % % allowTags = { ...
    % %     'D2P1_MM00','D2P1_MP05','D2P1_MD05','D2P1_MP03','D2P1_MD03','D2P1_MP06','D2P1_MD06',...
    % %     'D3P1_MM00','D3P1_MP05','D3P1_MD05','D3P1_MP03','D3P1_MD03',...
    % %     'D4P1_MM00','D4P1_MP05','D4P1_MD05',...
    % %     'D3P2_MM00','D3P2_MP05','D3P2_MD05','D3P2_MP03','D3P2_MD03'};


    % % allowTags = { ...
    % %     'D2P1_MM00','D2P1_MP05','D2P1_MD05','D2P1_MP03','D2P1_MD03','D2P1_MP06','D2P1_MD06',...
    % %     'D3P1_MM00','D3P1_MP05','D3P1_MD05','D3P1_MP03','D3P1_MD03',...
    % %     'D4P1_MM00','D4P1_MP05','D4P1_MD05'};

    % % allowTags = { ...
    % %     'D2P1_MM00',...
    % %     'D3P1_MM00',...
    % %     'D4P1_MM00',...
    % %     'D2P2_MM00',...
    % %     'D3P2_MM00'};


    % % allowTags = { ...
    % %     'D2P1_MM00','D2P1_MP05','D2P1_MD05',...
    % %     'D3P1_MM00','D3P1_MP05','D3P1_MD05',...
    % %     'D4P1_MM00','D4P1_MP05','D4P1_MD05',...
    % %     'D2P2_MM00',...
    % %     'D3P2_MM00'};

    %'D3P2_MP05','D3P2_MD05'

    % % allowTags = { ...
    % %     'D2P1_MM00','D2P1_MD05','D2P1_MD03','D2P1_MD06',...
    % %     'D3P1_MM00','D3P1_MD05',...
    % %     'D4P1_MM00','D4P1_MD05',...
    % %     'D2P2_MM00','D2P2_MD03',...
    % %     'D3P2_MM00','D3P2_MD05'};


    cads  = filterCadaverPairs(cads, allowTags);

    if ~isempty(categoryColumnsToSave)
        [cads, metaWarnMsg] = localAttachCategoryColumns(cads, Tcat, categoryColumnsToSave);
        if ~isempty(metaWarnMsg)
            uiwait(warndlg(metaWarnMsg,'Category columns'));
        end
    end


    %--------------------------------------------------------------
    % 4)  Let the user choose the output *.mat*
    %--------------------------------------------------------------
    defaultName = localDefaultOutputName(saveMode);
    [f,p] = uiputfile(defaultName,'Save cadaver struct as');
    if f==0,  return,  end
    outputFile = fullfile(p,f);
    save(outputFile,'cads','-v7');          % variable name = cads

    if saveSettingsTex
        categorySheetFile = "";
        if isfield(ud,'statusFilename') && ~isempty(ud.statusFilename)
            categorySheetFile = string(ud.statusFilename);
        end

        settingsReport = struct();
        settingsReport.saveMode = saveMode;
        settingsReport.doNormalizeSpectra = doNormalizeSpectra;
        settingsReport.normalizationRegion = normalizationRegion;
        settingsReport.normalizationMethod = normalizationMethod;
        settingsReport.filterSpectraSource = filterSpectraSource;
        settingsReport.manualFilterSpectra = manualFilterSpectra;
        settingsReport.allowTags = allowTags;
        settingsReport.categoryColumnsToSave = categoryColumnsToSave;
        settingsReport.exposedPolicy = exposedPolicy;
        settingsReport.categorySheetFile = categorySheetFile;
        settingsReport.loadedInputFileCount = nFiles;
        settingsReport.loadedInputFiles = string(ud.fileNames(selFiles));
        settingsReport.outputFile = outputFile;
        settingsReport.savedCadaverCount = numel(cads);
        settingsReport.settingsTexFileName = settingsTexFileName;

        texPath = fullfile(p, char(settingsTexFileName));
        localWritePairAndSaveSettingsTex(texPath, settingsReport);
    end

    msgbox('Cadaver struct saved.','Done','modal');

    % remember the last file so "Run NN" can default to it
    ud.lastPairedFile = fullfile(p,f);
    fig.UserData      = ud;
end




% -------------------------------------------------------------------------
%  collectPairs – build cadaver-wise, *paired* E/T spectra list
%  + optionally keeps unpaired T-only spectra (e.g., in-vivo intact)
% -------------------------------------------------------------------------
function [cadavers , warnMsg] = collectPairs(fig , fileIdxList, Tcat, exposedPolicy, saveMode, ...
    doNormalizeSpectra, normalizationRegion, normalizationMethod)
% -------------------------------------------------------------------------
%  Build cadaver-wise, paired E/T spectra list
%  – removes spectra listed in the optional "bad-spectra" sheet
% -------------------------------------------------------------------------

warnMsg  = {};
cadavers = struct('id',{},'wn',{},'E',{},'T',{},'list',{});    % output
ud       = fig.UserData;                                      % shortcut

% -------------------------------------------------------------------------
% 0)  Is a bad-spectra sheet loaded?
% -------------------------------------------------------------------------
doFilter = false;                    % default → keep everything
badMap   = [];                       % placeholder (empty)

if isfield(ud,'hasBadSpectraSheet') && ud.hasBadSpectraSheet ...
        && isfield(ud,'badMap')
    doFilter = true;
    badMap   = ud.badMap;            % local alias for quick access
end


% -------------------------------------------------------------------------
% NEW: keep unpaired T-only spectra?
% (Set true to keep in-vivo intact spectra that have no exposed pair)
% -------------------------------------------------------------------------
%keepUnpairedT = 0;

% -------------------------------------------------------------------------
% Filename parsing
% OLD (strict cadaver IDs only):  'AA12_T_....mat'
% NEW (more general): any ID up to first underscore
% -------------------------------------------------------------------------
%expr = '(?i)^(?<id>[^_]+)_(?<ET>[ET])(?:_(?<rest>.*))?\.mat$';


% OLD (strict cadaver IDs only):  'AA12_T_....mat'
expr = '(?i)^(?<id>[A-Z]{2}\d+)_(?<ET>[ET])(?:_(?<rest>.*))?\.mat$';
%       ↑ allow upper / lower case            ↑ rest tag optional
% -------------------------------------------------------------------------
% iterate over every selected file
% -------------------------------------------------------------------------
for f = fileIdxList(:).'

    fname = ud.fileNames{f};
    tok   = regexp(fname,expr,'names','once');
    if isempty(tok)
        warnMsg{end+1} = sprintf('%s  – ignored (pattern mismatch).',fname);
        continue
    end

    if strcmpi(saveMode, "exposedOnly") && upper(tok.ET) ~= 'E'
        continue
    elseif strcmpi(saveMode, "intactOnly") && upper(tok.ET) ~= 'T'
        continue
    end

    % ---- locate / create cadaver entry -----------------------------------
    cIdx = find(strcmp({cadavers.id},tok.id),1);
    if isempty(cIdx)
        cIdx = numel(cadavers)+1;
        cadavers(cIdx).id   = tok.id;
        cadavers(cIdx).wn   = [];
        cadavers(cIdx).pairs= containers.Map('KeyType','char','ValueType','any');
    end
    C = cadavers(cIdx);                                  % convenience alias

    % ---- load struct & wavenumber ----------------------------------------
    dStruct = ud.data{f};
    %wn      = extractWavenumber(dStruct);
    wn = dStruct.process.wavenum;
    if isempty(wn)
        warnMsg{end+1} = sprintf('%s  – no wavenumber.',fname);  continue
    end
    C.wn = wn;                                           % identical for all files

    % ---- spectra ---------------------------------------------------------
    S = getFieldData(dStruct,'process.anitaspec');
    if isempty(S) || ~iscell(S)
        warnMsg{end+1} = sprintf('%s  – no process.anitaspec.',fname);  continue
    end

    nSpec = numel(S);                % keep *every* spectrum (no mask now)

    % ---------- loop over spectra -----------------------------------------
    for s = 1:nSpec

        spec = S{s};
        if ~ismatrix(spec) || size(spec,1)~=numel(wn) || size(spec,2)~=3
            warnMsg{end+1} = sprintf('%s  – spectrum %d not 499×3.',fname,s);
            continue
        end

        if doNormalizeSpectra
            [specNorm,~,~,~,~] = normalizeSpectra(wn, spec, ...
                normalizationRegion, normalizationMethod);
            spec = specNorm;
        end

        if upper(tok.ET)=='E'
            spec = localSelectExposedColumns(spec, tok.id, Tcat, exposedPolicy);
            if isempty(spec)
                warnMsg{end+1} = sprintf('%s  - spectrum %d has no valid exposed columns after cohort split.',fname,s);
                continue
            end
        end


        % -------- build display tag --------------------------------------
        tag = '';
        if isfield(dStruct,'process') && isfield(dStruct.process,'list') ...
                && numel(dStruct.process.list) >= s
            rawTag = dStruct.process.list{s};                    % full name
            m = regexp(rawTag,'^[^_]+_(?<ET>[ET])_(?<tag>.*)\.mat$', ...
                'names','once','ignorecase');
            if isempty(m) || upper(m.ET) ~= upper(tok.ET)
                continue
            end
            tag = m.tag;
        end
        if isempty(tag), tag = sprintf('spec%02d',s); end

        % -------- skip if listed in bad-spectra sheet ---------------------
        if doFilter && isBadSpectrum(tok.id, tag, badMap, upper(tok.ET))
            continue                                               % <-- skip
        end

        dispName = sprintf('%s_%c_%s.mat', tok.id, upper(tok.ET), tag);

        % -------- insert / update entry keyed by tag ---------------------
        if ~isKey(C.pairs,tag)
            C.pairs(tag) = struct('E',[],'T',[],'Ename','','Tname','');
        end
        entry = C.pairs(tag);
        if upper(tok.ET)=='E'
            entry.E     = spec;
            entry.Ename = dispName;
        else                                   % 'T'
            entry.T     = spec;
            entry.Tname = dispName;
        end
        C.pairs(tag) = entry;
    end

    cadavers(cIdx) = C;                         % write back
end

% -------------------------------------------------------------------------
% final pass – convert map to aligned cell arrays
% -------------------------------------------------------------------------
for c = numel(cadavers):-1:1
    keys = cadavers(c).pairs.keys;
    E   = {};  T = {};  L = {};

    isInVivoID = startsWith(upper(cadavers(c).id), "IV");   % or "XX"

    for k = 1:numel(keys)
        e = cadavers(c).pairs(keys{k});

        hasE = ~isempty(e.E);
        hasT = ~isempty(e.T);

        switch lower(saveMode)
            case 'paired'
                % Keep paired always.
                if hasE && hasT
                    E{end+1} = e.E;                     %#ok<AGROW>
                    T{end+1} = e.T;                     %#ok<AGROW>
                    L(end+1,1:2) = {e.Ename , e.Tname}; %#ok<AGROW>

                % Keep T-only for in-vivo intact subjects.
                elseif isInVivoID && hasT && ~hasE
                    E{end+1} = [];                      %#ok<AGROW>
                    T{end+1} = e.T;                     %#ok<AGROW>
                    L(end+1,1:2) = {'' , e.Tname};      %#ok<AGROW>
                end

            case 'exposedonly'
                if hasE
                    E{end+1} = e.E;                     %#ok<AGROW>
                    T{end+1} = [];                      %#ok<AGROW>
                    L(end+1,1:2) = {e.Ename , ''};      %#ok<AGROW>
                end

            case 'intactonly'
                if hasT
                    E{end+1} = [];                      %#ok<AGROW>
                    T{end+1} = e.T;                     %#ok<AGROW>
                    L(end+1,1:2) = {'' , e.Tname};      %#ok<AGROW>
                end
        end
    end

    if isempty(E) && isempty(T)
        warnMsg{end+1} = sprintf('ID %s: no spectra kept.', cadavers(c).id);
        % cadavers(c) = [];
    else
        cadavers(c).E    = E;
        cadavers(c).T    = T;
        cadavers(c).list = L;
    end
end

% strip the auxiliary map
if ~isempty(cadavers) && isfield(cadavers,'pairs')
    cadavers = rmfield(cadavers,'pairs');
end

end


function [cadavers, warnMsg] = localAttachCategoryColumns(cadavers, Tcat, categoryColumnsToSave)
    warnMsg = {};

    if isempty(cadavers) || isempty(categoryColumnsToSave)
        return
    end

    if isempty(Tcat) || ~istable(Tcat)
        warnMsg{end+1} = 'Category columns were not saved because no category sheet table was available.';
        return
    end

    varNames = string(Tcat.Properties.VariableNames);
    idCol = localFindTableColumn(varNames, "AGR-ID");
    if strlength(idCol) == 0
        warnMsg{end+1} = 'Category columns were not saved because the category sheet has no "AGR-ID" column.';
        return
    end

    [selectedCols, missingCols] = localResolveCategoryColumns(varNames, categoryColumnsToSave);
    if ~isempty(missingCols)
        warnMsg{end+1} = sprintf('These category-sheet columns were not found and were skipped:%s%s', ...
            newline, strjoin(cellstr(missingCols), newline));
    end
    if isempty(selectedCols)
        return
    end

    fieldNames = matlab.lang.makeValidName(cellstr(selectedCols));
    fieldNames = matlab.lang.makeUniqueStrings(fieldNames);

    ids = upper(strrep(string(Tcat{:, char(idCol)}), ' ', ''));

    for c = 1:numel(cadavers)
        cadID = upper(strrep(string(cadavers(c).id), ' ', ''));
        row = find(ids == cadID, 1);

        if isempty(row)
            warnMsg{end+1} = sprintf('ID %s was not found in the category sheet; saved category fields are empty.', ...
                char(cadID));
            for k = 1:numel(selectedCols)
                cadavers(c).(fieldNames{k}) = [];
            end
            continue
        end

        for k = 1:numel(selectedCols)
            cadavers(c).(fieldNames{k}) = localGetTableValue(Tcat, row, selectedCols(k));
        end
    end
end


function [selectedCols, missingCols] = localResolveCategoryColumns(varNames, requestedCols)
    selectedCols = strings(1,0);
    missingCols = strings(1,0);

    for k = 1:numel(requestedCols)
        colName = localFindTableColumn(varNames, requestedCols(k));
        if strlength(colName) == 0
            missingCols(end+1) = requestedCols(k); %#ok<AGROW>
        else
            selectedCols(end+1) = colName; %#ok<AGROW>
        end
    end
end


function colName = localFindTableColumn(varNames, requestedCol)
    requestedCol = string(requestedCol);
    match = find(varNames == requestedCol, 1);
    if isempty(match)
        match = find(strcmpi(cellstr(varNames), char(requestedCol)), 1);
    end

    if isempty(match)
        colName = "";
    else
        colName = varNames(match);
    end
end


function value = localGetTableValue(Tcat, row, colName)
    value = Tcat{row, char(colName)};

    if iscell(value) && numel(value) == 1
        value = value{1};
    end

    if isstring(value) && isscalar(value)
        value = char(value);
    end
end


function defaultName = localDefaultOutputName(saveMode)
    switch lower(saveMode)
        case 'exposedonly'
            defaultName = 'exposedCadavers.mat';
        case 'intactonly'
            defaultName = 'intactCadavers.mat';
        otherwise
            defaultName = 'pairedCadavers.mat';
    end
end


function policy = localGetExposedSavePolicy()
% Switch "enabled" to false to return to the legacy saved exposed layout.
    policy = struct( ...
        'enabled', false, ...
        'firstCohortLastRow', 14, ...
        'firstCohortCols', [2 3], ...
        'secondCohortCols', [1 2]);
end


function specOut = localSelectExposedColumns(specIn, cadID, Tcat, policy)
    specOut = specIn;

    if ~policy.enabled
        return
    end

    colsWanted = localGetExposedColumnsForCadaver(cadID, Tcat, policy);
    colsWanted = colsWanted(colsWanted <= size(specIn,2));

    if isempty(colsWanted)
        specOut = [];
        return
    end

    specOut = specIn(:, colsWanted);
end


function colsWanted = localGetExposedColumnsForCadaver(cadID, Tcat, policy)
    if isempty(Tcat)
        colsWanted = [];
        return
    end

    cadID = upper(strrep(string(cadID), ' ', ''));
    agrID = upper(strrep(string(Tcat{:,'AGR-ID'}), ' ', ''));
    row = find(agrID == cadID, 1);

    if isempty(row)
        colsWanted = [];
    elseif row <= policy.firstCohortLastRow
        colsWanted = policy.firstCohortCols;
    else
        colsWanted = policy.secondCohortCols;
    end
end


function badMap = localBuildManualBadSpectraMap(manualBadSpectra)
    badMap = containers.Map('KeyType','char','ValueType','any');

    if isempty(manualBadSpectra)
        return
    end

    if istable(manualBadSpectra)
        varNames = manualBadSpectra.Properties.VariableNames;
        if numel(varNames) < 2
            error('manualBadSpectra table must contain at least two columns: cadaver ID and tag(s).');
        end
        ids = manualBadSpectra{:,1};
        tags = manualBadSpectra{:,2};
        manualBadSpectra = [num2cell(ids), num2cell(tags)];
    end

    if ~iscell(manualBadSpectra) || size(manualBadSpectra,2) < 2
        error(['manualBadSpectra must be a cell array with rows like ', ...
            '{''CadaverID'', {''Tag1'',''Tag2''}}.']);
    end

    for r = 1:size(manualBadSpectra,1)
        cadID = upper(strrep(string(manualBadSpectra{r,1}), ' ', ''));
        if strlength(cadID) == 0 || ismissing(cadID)
            continue
        end

        rawTags = manualBadSpectra{r,2};
        tags = localNormalizeManualBadTags(rawTags);

        key = char(cadID);
        if isKey(badMap, key)
            oldTags = string(badMap(key));
            tags = unique([oldTags(:); tags(:)], 'stable');
        end
        badMap(key) = tags(:).';
    end
end


function tags = localNormalizeManualBadTags(rawTags)
    tags = strings(0,1);

    if isempty(rawTags)
        tags = "__ALL__";
        return
    end

    if ischar(rawTags) || isstring(rawTags)
        tags = string(rawTags);
        if isscalar(tags) && contains(tags, {',',';'})
            tags = split(tags, {',',';'});
        end
    elseif iscell(rawTags)
        tags = string(rawTags(:));
    else
        tags = string(rawTags(:));
    end

    tags = strtrim(tags);
    tags = tags(tags ~= "" & tags ~= "<missing>" & ~ismissing(tags));
    if isempty(tags)
        tags = "__ALL__";
    end
end


function localWritePairAndSaveSettingsTex(texPath, settingsReport)
    fid = fopen(texPath, 'w');
    if fid < 0
        warning('Could not write pairAndSave settings TeX file: %s', texPath);
        return
    end
    cleanupObj = onCleanup(@() fclose(fid));
    generatedText = char(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss"));

    fprintf(fid, '%% Auto-generated by pairAndSave.m. Do not edit by hand.\n');
    fprintf(fid, '%% Generated: %s\n\n', generatedText);
    fprintf(fid, '\\section*{pairAndSave input settings}\n');
    fprintf(fid, '\\begin{verbatim}\n');
    fprintf(fid, 'Generated                 : %s\n', generatedText);

    names = fieldnames(settingsReport);
    maxNameLen = max(cellfun(@numel, names));
    for k = 1:numel(names)
        name = names{k};
        valueText = localSettingValueToText(settingsReport.(name));
        fprintf(fid, '%-*s : %s\n', maxNameLen, name, valueText);
    end

    fprintf(fid, '\\end{verbatim}\n');
end


function txt = localSettingValueToText(value)
    if ischar(value)
        txt = value;
    elseif isstring(value)
        if isempty(value)
            txt = '[]';
        else
            txt = strjoin(cellstr(value(:).'), ', ');
        end
    elseif isnumeric(value) || islogical(value)
        if isempty(value)
            txt = '[]';
        else
            txt = mat2str(value);
        end
    elseif iscell(value)
        txt = localCellSettingToText(value);
    elseif isstruct(value)
        txt = localStructSettingToText(value);
    elseif isa(value, 'function_handle')
        txt = func2str(value);
    else
        txt = sprintf('[%s %s]', class(value), mat2str(size(value)));
    end
end


function txt = localCellSettingToText(value)
    if isempty(value)
        txt = '{}';
        return
    end

    rowText = cell(size(value, 1), 1);
    for r = 1:size(value, 1)
        colText = cell(1, size(value, 2));
        for c = 1:size(value, 2)
            colText{c} = localSettingValueToText(value{r,c});
        end
        rowText{r} = ['{', strjoin(colText, ', '), '}'];
    end
    txt = strjoin(rowText, '; ');
end


function txt = localStructSettingToText(value)
    if isempty(value)
        txt = 'struct([])';
        return
    end

    if numel(value) > 1
        txt = sprintf('[%d-element struct]', numel(value));
        return
    end

    fields = fieldnames(value);
    parts = cell(1, numel(fields));
    for k = 1:numel(fields)
        fieldName = fields{k};
        parts{k} = sprintf('%s=%s', fieldName, localSettingValueToText(value.(fieldName)));
    end
    txt = strjoin(parts, ', ');
end

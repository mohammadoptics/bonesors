% ======================================================================
% plotSavedLOCOscatter – choose priority list / best RMSE / best-by-region
% ======================================================================
function plotSavedLOCOscatter(fig,~)

% ---------------- 1) use LOCO results loaded in Analysis tab ------------
if ~isfield(fig.UserData, 'analysisData') || ...
        ~isfield(fig.UserData, 'analysisDatasetType') || ...
        string(fig.UserData.analysisDatasetType) ~= "locoResults"
    error('MainGUI:LocoResultsRequired', ...
        'Load saved LOCO results in the Analysis tab first.');
end
S = fig.UserData.analysisData;
[~, baseName, extension] = fileparts(fig.UserData.analysisFile);
f = [baseName extension];
if ~isfield(S,'TblPred')
    errordlg('File lacks TblPred.','Bad file'); return
end
Tbl = S.TblPred;                       % shorthand

% ---------------- 2) ask the user what to plot -------------------------
choice = menu('Scatter-plot option', ...
              'Priority-tag list', ...
              'Average RMSE (all tags)', ...
              'Best RMSE in a REGION');

switch choice
% -----------------------------------------------------------------------
%  A) PRIORITY TAG LIST  -------------------------------------------------
% -----------------------------------------------------------------------
case 1
    %priorityTags = {'D2P1_MM00','D3P1_MM00','D3P2_MM00','D2P2_MM00'};
    priorityTags = {'D2P1_MM00'};
    scatterTscoreWHO(fig,Tbl,priorityTags, ...
        sprintf('LOCO scatter – %s (priority)',f));

% -----------------------------------------------------------------------
%  B) BEST RMSE ACROSS **ALL** TAGS  ------------------------------------
% -----------------------------------------------------------------------
case 2
    makeScatterMeanTscore(fig,Tbl, f, 'all tags');
    %%makeScatterBestRMSE(Tbl, f, 'all tags');

% -----------------------------------------------------------------------
%  C) BEST RMSE **WITHIN A REGION**  ------------------------------------
% -----------------------------------------------------------------------
% % case 3
% %     % ---- ask which region & cut-off -----------------------------------
% %     [regIdx,ok] = listdlg('ListString',{'Mid-shaft','Distal','Proximal'}, ...
% %                           'SelectionMode','single', ...
% %                           'PromptString','Choose anatomical region:', ...
% %                           'ListSize',[160 80]);
% %     if ~ok,  return, end
% %     regions   = ["mid","distal","proximal"];
% %     regionSel = regions(regIdx);
% % 
% %     cutOff = inputdlg({'Cut-off in mm (e.g. 7):'}, ...
% %                       'Region definition',1,{'7'});
% %     if isempty(cutOff), return, end
% %     cutOff = str2double(cutOff{1});
% %     if isnan(cutOff) || cutOff<=0
% %         errordlg('Cut-off must be a positive number.'); return
% %     end
% % 
% %     % ---- keep only spectra in the chosen region -----------------------
% %     keep = regionMask(Tbl.Tag, regionSel, cutOff);
% %     if ~any(keep)
% %         warndlg(sprintf('No spectra in the %s region (±%.0f mm).', ...
% %                 regionSel,cutOff),'Nothing to plot');  return
% %     end
% %     TblReg = Tbl(keep,:);
% % 
% %     makeScatterBestRMSE(TblReg, f, sprintf('%s (±%.0f mm)',regionSel,cutOff));
% % end

% -----------------------------------------------------------------------
%  C)  REGION-AVERAGED  (mean of all spectra inside a region) -----------
% -----------------------------------------------------------------------
case 3
    % ----  Ask for region and offset cut-off  ---------------------------
    [regIdx,ok] = listdlg('ListString',{'Mid-shaft','Distal','Proximal'}, ...
                          'SelectionMode','single', ...
                          'PromptString','Choose anatomical region:', ...
                          'ListSize',[160 80]);
    if ~ok,  return, end
    regions   = ["mid","distal","proximal"];
    regionSel = regions(regIdx);

    cutOff = inputdlg({'Cut-off in mm (e.g. 7):'}, ...
                      'Region definition',1,{'7'});
    if isempty(cutOff), return, end
    cutOff = str2double(cutOff{1});
    if isnan(cutOff) || cutOff<=0
        errordlg('Cut-off must be a positive number.'); return
    end

    % ----  Keep only spectra that fall into that region  ----------------
    keep = regionMask(Tbl.Tag, regionSel, cutOff);   % <-- your helper
    if ~any(keep)
        warndlg(sprintf('No spectra in the %s region (±%.0f mm).', ...
                regionSel,cutOff),'Nothing to plot');  return
    end
    TblReg = Tbl(keep,:);                            % spectra in region

    % ----  ➊  Compute CADAVER-WISE means  -------------------------------
    [G,cadKey]  = findgroups(TblReg.CadaverID);      % group id per row
    yTrueMean   = splitapply(@mean, TblReg.TscoreTrue,  G);
    yPredMean   = splitapply(@mean, TblReg.TscorePred,  G);

    TblAvg = table( cadKey,  repmat(regionSel+"_AVG",numel(cadKey),1), ...
                    yTrueMean, yPredMean, ...
                    'VariableNames',{'CadaverID','Tag','TscoreTrue','TscorePred'});

    % ----  ➋  Show what went into the averages  -------------------------
    fprintf('\nAveraged %s region (±%.0f mm)\n', regionSel, cutOff);
    disp( groupsummary(TblReg,{'CadaverID','Tag'},'mean',{'TscoreTrue','TscorePred'}) )

    % ----  ➌  WHO-style scatter with *averaged* points  -----------------
    scatterTscoreWHO(fig,TblAvg, {}, ...
        sprintf('LOCO scatter – %s  (mean %s, ±%.0f mm)', ...
                f, regionSel, cutOff));

end

end   % -------- end main function ---------------------------------------



% ======================================================================
% Helper – build WHO scatter from *best RMSE* rows and print table
% ======================================================================
function makeScatterBestRMSE(fig,Tbl, fileLabel, extraTxt)

    [G,~]   = findgroups(Tbl.CadaverID);           % group id per row
    idxBest = splitapply(@(rm,idx) idx(rm==min(rm),1), ...
                         Tbl.RMSEtag,(1:height(Tbl))',G);
    TblBest = Tbl(idxBest,:);

    fprintf('\nBest tag per cadaver (%s)\n',extraTxt);
    disp(TblBest(:,{'CadaverID','Tag','RMSEtag'}))

    scatterTscoreWHO(fig,TblBest,{}, ...
        sprintf('LOCO scatter – %s (%s)',fileLabel,extraTxt));
end

function makeScatterMeanTscore(fig,Tbl, fileLabel, extraTxt)
    % ---------- 1. group by cadaver & average ---------------------------
    [G, cadKey] = findgroups(Tbl.CadaverID);

    meanTrue = splitapply(@mean, Tbl.TscoreTrue,  G);
    meanPred = splitapply(@mean, Tbl.TscorePred, G);

    % build 1-row-per-cadaver table expected by scatterTscoreWHO
    TblMean = table( ...
        cadKey, ...
        repmat("MEAN",numel(cadKey),1), ...   % dummy Tag
        meanTrue, ...
        meanPred, ...
        'VariableNames',{'CadaverID','Tag','TscoreTrue','TscorePred'});

    % ---------- 2. print summary to Command Window ----------------------
    fprintf('\nAverage T-score per cadaver (%s)\n', extraTxt);
    disp(TblMean(:,{'CadaverID','TscoreTrue','TscorePred'}))

    % ---------- 3. WHO-style scatter (no priority tags) -----------------
    scatterTscoreWHO(fig,TblMean, {}, ...
        sprintf('LOCO scatter – %s (mean per cadaver)', fileLabel));
end




% ======================================================================
% Helper – TRUE for rows whose Tag falls into the wanted region
%   regionWanted : "mid", "distal", "proximal"
%   cutOff       : positive scalar (mm)
% ======================================================================
function mask = regionMask(tagVec, regionWanted, cutOff)
    offs = arrayfun(@offsetFromTag, tagVec);    % signed mm offset
    switch regionWanted
        case "mid",     mask = abs(offs) <=  cutOff;
        case "distal",  mask = offs <  -cutOff;
        case "proximal",mask = offs >   cutOff;
    end
end



% ======================================================================
% Helper – convert a tag such as "MD05" →  -5   ;  "MP12" → +12 ; "MM00" → 0
% ======================================================================
function mm = offsetFromTag(tag)
    % look for MD / MP / MM followed by 1–3 digits
    m = regexp(tag,'M([DMP])0*([0-9]{1,3})','tokens','once','ignorecase');
    if isempty(m), mm = NaN; return, end          % unknown → NaN

    val = str2double(m{2});                       % numeric part
    switch upper(m{1})
        case 'D',  mm = -val;                     % distal = negative
        case 'P',  mm =  val;                     % proximal = positive
        otherwise, mm = 0;                        % mid-shaft
    end
end


%locoTscoreCallback – LOCO PLS-R  +  region/offset location features
%  locoTscoreCallback – LOCO PLS-R  +  MID / DISTAL / PROXIMAL features
% ======================================================================
function locoTscoreCallback(fig,~)

%% ---------- 0. use spectra table loaded in Analysis tab ----------------
if ~isfield(fig.UserData, 'analysisData') || ...
        ~isfield(fig.UserData, 'analysisDatasetType') || ...
        string(fig.UserData.analysisDatasetType) ~= "spectraTable"
    error('MainGUI:SpectraTableRequired', ...
        'Load a generated spectra-table MAT file in the Analysis tab first.');
end
S = fig.UserData.analysisData;
if ~isfield(S,'tbl'), errordlg('File lacks variable ''tbl''.'); return, end
tbl = S.tbl;
wn  = tbl.Properties.UserData.wavenumber;

%% ---------- 1. save in the Analysis-tab output folder -------------------
defOut = sprintf('LOCO_Tscore_%s.mat', datestr(now,'yyyymmdd_HHMM'));
outputDirectory = string(fig.UserData.config.analysisOutputDirectory);
if strlength(outputDirectory) == 0 || ~isfolder(outputDirectory)
    error('MainGUI:OutputDirectoryRequired', ...
        'Choose an analysis output folder before running LOCO prediction.');
end
outFile = fullfile(outputDirectory, defOut);

%% ---------- 2.  OPTIONAL tag allow-list ---------------------------------
% EXAMPLES
% allowTags = {'D2P1_MM00','D3P2_MM00'};          % ← exact only
allowTags = {'D2P1'};                           % ← any location of D2P1
%allowTags = {'D2P1','D3P1','D4P1'};        % ← mix of both styles
%allowTags = {};   % leave empty → keep every tag

if ~isempty(allowTags)
    keep = false(height(tbl),1);                  % initialise logical mask

    for k = 1:numel(allowTags)
        tok = upper(string(allowTags{k}));

        if contains(tok,'_')                      % has "_"  → exact tag
            keep = keep | strcmpi(tbl.Tag, tok);

        else                                      % no "_" → treat as prefix
            % match tokens like "D2P1" to any "D2P1_XXXX"
            keep = keep | startsWith(upper(tbl.Tag), tok + "_");
        end
    end

    tbl = tbl(keep,:);                            % apply filter

    if isempty(tbl)
        errordlg('No spectra left after tag filter.'); return
    end
end

%% ---------- 3.  DESIGN MATRIX  (spectra + region one-hot) ---------------
N     = height(tbl);

% --- 3a. spectra (here only the 6-mm column) -----------------------------
Xsp = zeros(N,499);
%Xsp = zeros(N,499*3);                % spectral part
for i = 1:N
    % % Tmat      = normalize_PO4(wn, tbl.Spectra{i});   % 499×3
    % % Xsp(i,:)  = Tmat(:,3).';                        % ← 6-mm column


    % % [specNorm,~,~,~,~] = normalizeSpectra(wn , spec , "AmideIII", "peak");
    % %     spec = specNorm; 

    Tmat   = normalize_PO4(wn,tbl.Spectra{i});
    %Xsp(i,:) = reshape(Tmat(:,[1 2 3]),1,[]);   % 0→3→6 mm order
    Xsp(i,:) = reshape(Tmat(:,3),1,[]);   % 0→3→6 mm order
end

% --- 3b. REGION one-hot ---------------------------------------------------
% cut-off ±7 mm → MD03, MD05, MD06, MM00, MP03, MP05, MP06  ⇒  MIDSHAFT
[OHEreg, regNames, regionLabel] = encodeRegion(tbl.Tag, 6);   % new helper
Xfull   = [Xsp  OHEreg];                                       % final matrix

%% ---------- 4.  LOCO PLS-R  (exactly as before) -------------------------
y         = tbl.Tscore;
cadIDvec  = tbl.CadaverID;
uniqCad   = unique(cadIDvec);   Ncad = numel(uniqCad);

yHat      = nan(size(y));
rankUsed  = zeros(Ncad,1);
rmseCad   = zeros(Ncad,1);

fprintf('\nLeave-one-cadaver-out PLS-R  (+ region features)\n');
for k = 1:Ncad
    te = cadIDvec==uniqCad(k);   tr = ~te;
    Xtr = Xfull(tr,:);  ytr = y(tr);
    Xte = Xfull(te,:);

    maxR = min([10, size(Xtr,1)-2, size(Xtr,2)]);      % safety

    % ---- inner LOCO-CV on the TRAINING set -----------------------------
    cadIDtr   = cadIDvec(tr);
    cadUniTr  = unique(cadIDtr,'stable');
    nInnerCad = numel(cadUniTr);
    rmse      = inf(maxR,1);

    for r = 1:maxR
        yTmp = nan(size(ytr));
        for j = 1:nInnerCad
            te2 = cadIDtr==cadUniTr(j);  tr2 = ~te2;
            [~,~,~,~,b] = plsregress(Xtr(tr2,:), ytr(tr2), r);
            yTmp(te2)  = [ones(sum(te2),1)  Xtr(te2,:)] * b;
        end
        rmse(r) = sqrt(mean((yTmp - ytr).^2));
    end
    [~,rk] = min(rmse);  rankUsed(k)=rk;

    [~,~,~,~,b] = plsregress(Xtr,ytr,rk);
    yHat(te)    = [ones(sum(te),1)  Xte] * b;

    rmseCad(k)  = sqrt(mean((yHat(te) - y(te)).^2));
    fprintf('  %-10s : rank %d   RMSE %.3f\n', uniqCad(k), rk, rmseCad(k));
end

overallRMSE = sqrt(mean((yHat - y).^2));
fprintf('Overall RMSE = %.3f  (%d spectra)\n', overallRMSE, N);

%% ---------- 5.  add per-spectrum RMSE & build tables --------------------
G = findgroups(cadIDvec, tbl.Tag);
rmseTag = splitapply(@(t,p) sqrt(mean((t-p).^2)), y, yHat, G);
rmsePerSpec = rmseTag(G);

TblPred = table(cadIDvec, tbl.Tag, regionLabel, y, yHat, rmsePerSpec, ...
    'VariableNames', {'CadaverID','Tag','Region','TscoreTrue','TscorePred','RMSEtag'});

TblCadRMSE = table(uniqCad, rmseCad, rankUsed, ...
    'VariableNames', {'CadaverID','RMSEcad','RankUsed'});

save(outFile,'TblPred','TblCadRMSE','wn','allowTags','regNames');
fprintf('Saved results to  %s\n', outFile);

%% ---------- 6.  pick a REGION & plot best-RMSE scatter -------------------
choice = questdlg('Which region do you want to view?', ...
                  'Pick region','MIDSHAFT','DISTAL','PROXIMAL','MIDSHAFT');
if isempty(choice), return, end

TblReg = TblPred(strcmpi(TblPred.Region,choice),:);
if isempty(TblReg)
    errordlg(sprintf('No spectra labelled "%s".',choice)); return
end

% ---------- pick lowest-RMSE row within the chosen region ---------------
[G,~] = findgroups(TblReg.CadaverID);          % group‐id per row

absIdx = splitapply(@(rows,rm) rows( find(rm==min(rm),1,'first') ), ...
                    (1:height(TblReg))', TblReg.RMSEtag, G);

TblBest = TblReg(absIdx,:);                    % best spectrum per cadaver

fprintf('\nBest tag per cadaver in %s region\n', upper(choice));
disp(TblBest(:,{'CadaverID','Tag','RMSEtag'}))

scatterTscoreWHO(TblBest, {}, ...
    sprintf('LOCO scatter – %s region (best RMSE)', choice));

end  % locoTscoreCallback




% ======================================================================
% encodeRegion  – convert tag strings to REGION one-hot matrix
%
%  INPUT:
%     tagList   : N×1 string / char array of full tags  (…_MD05, …_MM00 …)
%     cutMm     : numeric scalar, e.g. 7  →  |offset| ≤ 7 ⇒ MIDSHAFT
%
%  OUTPUT:
%     OHE       : N × 3   (col-order: MIDSHAFT • DISTAL • PROXIMAL)
%     names     : 1×3 cell  {'MIDSHAFT' 'DISTAL' 'PROXIMAL'}
%     regionLbl : N×1 string holding the region name for each tag
% ======================================================================
function [OHE,names,regionLbl] = encodeRegion(tagList, cutMm)

n  = numel(tagList);
off = nan(n,1);                       % signed offsets (mm)
for i = 1:n
    t = char(tagList(i));             % make sure it is char
    if contains(t,'_MM','IgnoreCase',true)            % exact mid (MM00 / MM0)
        off(i) = 0;
    else
        m = regexp(t,'_M([DP])(\d+)', 'tokens','once','ignorecase');
        if ~isempty(m)
            mm  = str2double(m{2});
            sgn = +1;                           % default = PROXIMAL (MP…)
            if upper(m{1})=='D',  sgn = -1; end % DISTAL
            off(i) = sgn*mm;
        else
            off(i) = NaN;                       % unrecognised → NaN
        end
    end
end

regionLbl = strings(n,1);
regionLbl(abs(off) <= cutMm)      = "MIDSHAFT";
regionLbl(off < -cutMm)           = "DISTAL";
regionLbl(off >  cutMm)           = "PROXIMAL";
regionLbl(isnan(off))             = "UNKNOWN";   % fallback

names = {'MIDSHAFT','DISTAL','PROXIMAL'};
OHE   = dummyvar(categorical(regionLbl,names,names));  % N×3

end  % encodeRegion

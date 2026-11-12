function dialog = configureStrictTscoreDialog(parent)
%CONFIGURESTRICTTSCOREDIALOG Independent, visible E/P/reconstruction settings.
u=parent.UserData;
if ~isfield(u.config,'strict'),u.config.strict=strictTscoreDefaultConfig();end
c=validateStrictTscoreConfiguration(u.config.strict);
dialog=figure('Name','Configure strict end-to-end T-score prediction', ...
    'NumberTitle','off','MenuBar','none','ToolBar','none','Color',[.95 .95 .95], ...
    'Position',[150 100 1000 735],'Tag','StrictTscoreDialog');
uicontrol(dialog,'Style','text','Units','normalized','Position',[.04 .90 .92 .075], ...
    'String',{'Analysis location and P spectrum expression come from the main Analysis page.', ...
    'Each outer donor stays outside reconstruction, training-feature generation, scaling, and T-score fitting.'}, ...
    'HorizontalAlignment','left','BackgroundColor',[.95 .95 .95],'FontSize',11);
group=uitabgroup(dialog,'Units','normalized','Position',[.04 .12 .92 .77]);
handles=struct();types=struct();choicesByField=struct();
regions={'none','PO4','CO3','CH2','AmideI','AmideIII','FullSpectrum'};
methods={'peak','peakBaseline','area'};
recon={
 'reconTagsToUse','Reconstruction training tags','tags',{}
 'intactSpectraToUse','Intact columns (2 = 3 mm; 3 = 6 mm)','numbers',{}
 'reconCombineMode','Combination (diff = second minus first)','choice',{'diff','concat','mean','meanDiff'}
 'exposedSpectrumToPredict','Exposed target columns','numbers',{}
 'reconNormalizationRegion','Reconstruction normalization region','choice',regions
 'reconNormalizationMethod','Reconstruction normalization method','choice',methods
 'normalizePredictors','Normalize each intact spectrum first','check',{}
 'normalizeResponse','Normalize each exposed spectrum first','check',{}
 'reconNComponents','Fixed reconstruction PLS components','number',{}
 'standardizeBeforeReconstructionPLS','Training-fold standardization for X and Y','check',{}
 'plsAlgorithm','PLS2 algorithm','choice',{'NIPALS','SIMPLS'}};
e={
 'measuredAnalysisSpectrumNumber','Measured E analysis columns','numbers',{}
 'measuredAnalysisSpectrumCombineMode','E column combination (diff = second minus first)','choice',{'concat','mean','diff','meanDiff'}
 'measuredTscoreNormalizationRegion','E normalization region','choice',regions
 'measuredTscoreNormalizationMethod','E normalization method','choice',methods
 'measuredTscoreModel','Measured E model','choice',{'SVR','PLS'}
 'measuredStandardizeTscorePredictors','E training-fold predictor standardization','check',{}
 'measuredSvrBoxConstraint','E SVR C (fixed)','number',{}
 'measuredSvrEpsilon','E SVR epsilon (fixed)','number',{}
 'measuredSvrKernelScale','E SVR kernel width (selected convention)','number',{}
 'measuredMaxTscoreRank','E maximum PLS rank (inner LOCO)','number',{}
 'measuredFixedTscoreRank','E fixed PLS rank (auto = inner LOCO)','auto',{}};
p={
 'tscoreNormalizationRegion','P normalization region','choice',regions
 'tscoreNormalizationMethod','P normalization method','choice',methods
 'tscoreModel','Reconstructed P model','choice',{'SVR','PLS'}
 'standardizeTscorePredictors','P training-fold predictor standardization','check',{}
 'svrBoxConstraint','P SVR C (fixed)','number',{}
 'svrEpsilon','P SVR epsilon (fixed)','number',{}
 'svrKernelScale','P SVR kernel width (selected convention)','number',{}
 'maxTscoreRank','P maximum PLS rank (inner LOCO)','number',{}
 'fixedTscoreRank','P fixed PLS rank (auto = inner LOCO)','auto',{}};
n={
 'plsMaxIterations','NIPALS maximum iterations','number',{}
 'plsTolerance','NIPALS squared-weight convergence tolerance','number',{}
 'scalingDDOF','Scaling ddof (0 = population; 1 = sample)','number',{}
 'svrKernelConvention','SVR width convention (Python uses exp(-d^2/(2*s^2)))','choice',{'python','matlab'}
 'svrSolverTolerance','MATLAB SMO convergence tolerance','number',{}
 'plotClassification','Plot confusion matrices and pairwise ROC curves','check',{}
 'saveStrictPredictedCadavers','Save LOCO reconstructed dataset for ratio plots','check',{}};
addTab('1. Reconstruction',recon);addTab('2. Measured E',e);
addTab('3. Reconstructed P',p);addTab('4. Numerics and output',n);
status=uicontrol(dialog,'Style','text','Units','normalized','Position',[.04 .025 .67 .065], ...
    'String','Apply saves these settings. Cancel leaves the configuration unchanged.', ...
    'HorizontalAlignment','left','BackgroundColor',[.95 .95 .95],'ForegroundColor',[.05 .4 .4]);
uicontrol(dialog,'Style','pushbutton','Units','normalized','Position',[.74 .035 .10 .055], ...
    'String','Cancel','Callback',@(s,e)delete(dialog));
uicontrol(dialog,'Style','pushbutton','Units','normalized','Position',[.85 .035 .11 .055], ...
    'String','Apply','Callback',@(s,e)apply());
dialog.UserData=struct('controls',handles,'parent',parent);
updateModelControls();
    function addTab(title,specs)
        tab=uitab(group,'Title',title);
        for j=1:size(specs,1)
            name=specs{j,1};kind=specs{j,3};options=specs{j,4};y=.92-(j-1)*.078;
            uicontrol(tab,'Style','text','Units','normalized','Position',[.025 y .52 .046], ...
                'String',specs{j,2},'HorizontalAlignment','left','FontSize',10);
            h=uicontrol(tab,'Units','normalized','Position',[.56 y .41 .048], ...
                'BackgroundColor','white','Tag',name,'FontSize',10);
            types.(name)=kind;choicesByField.(name)=options;
            if strcmp(kind,'choice')
                set(h,'Style','popupmenu','String',options,'Value',find(strcmpi(options,string(c.(name))),1), ...
                    'Callback',@(s,e)updateModelControls());
            elseif strcmp(kind,'check')
                set(h,'Style','checkbox','String','','Value',logical(c.(name)));
            else
                if strcmp(kind,'tags'),value=strjoin(string(c.(name)),', ');
                elseif strcmp(kind,'auto') && isempty(c.(name)),value="auto";
                else,value=mat2str(c.(name));end
                set(h,'Style','edit','String',char(value),'HorizontalAlignment','left');
            end
            handles.(name)=h;
        end
    end
    function updateModelControls()
        if ~isfield(handles,'tscoreModel'),return,end
        for prefix=["measured",""]
            if prefix=="measured"
                model=handles.measuredTscoreModel;svr=["measuredSvrBoxConstraint","measuredSvrEpsilon","measuredSvrKernelScale"];
                rank=["measuredMaxTscoreRank","measuredFixedTscoreRank"];
            else
                model=handles.tscoreModel;svr=["svrBoxConstraint","svrEpsilon","svrKernelScale"];
                rank=["maxTscoreRank","fixedTscoreRank"];
            end
            isSVR=model.Value==1;
            for field=svr,handles.(field).Enable=onOff(isSVR);end
            for field=rank,handles.(field).Enable=onOff(~isSVR);end
        end
    end
    function apply()
        try
            updated=c;
            for field=string(fieldnames(handles)).'
                h=handles.(field);kind=types.(field);
                if strcmp(kind,'choice'),options=choicesByField.(field);value=string(options{h.Value});
                elseif strcmp(kind,'check'),value=logical(h.Value);
                elseif strcmp(kind,'tags'),value=normalizeTagSelection(strsplit(h.String,','));
                elseif strcmp(kind,'auto') && any(strcmpi(strtrim(h.String),{'auto','[]',''})),value=[];
                else
                    cleaned=strtrim(regexprep(h.String,'[\[\],;]',' '));
                    value=str2double(strsplit(cleaned));
                    if isempty(value)||any(~isfinite(value)),error('MainGUI:StrictSettings','Invalid numeric value for %s.',field);end
                end
                updated.(field)=value;
            end
            updated=validateStrictTscoreConfiguration(updated);
            u=parent.UserData;u.config.strict=updated;parent.UserData=u;
            if isfield(u.controls,'strictSummaryText')
                u.controls.strictSummaryText.String=formatStrictTscoreConfigSummary(updated);
            end
            delete(dialog);
        catch err
            status.String=err.message;status.ForegroundColor=[.75 0 0];
        end
    end
end

function value = onOff(flag)
if flag,value='on';else,value='off';end
end

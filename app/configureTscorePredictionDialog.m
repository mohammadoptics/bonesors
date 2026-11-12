function dialogFig=configureTscorePredictionDialog(parentFig,waitForClose)
% Independent predictor, preprocessing, model and validation controls.
if nargin<2, waitForClose=true; end
analysis=analysisLocationSelection(parentFig);
config=resolveTscoreAnalysisConfig(parentFig.UserData.config.tscore,analysis);
availability=tscoreModelAvailability();
[demographicAvailable,demographicKnown]=tscoreDemographicAvailability(parentFig.UserData);
selectedTags=upper(strtrim(string(analysis.tags(:).')));
h=struct; numeric=struct; vectors=struct; bg=[.96 .97 .98];
screen=get(groot,'ScreenSize'); sz=[min(940,screen(3)-40) min(800,screen(4)-80)];
dialogFig=figure('Name','Configure T-score prediction','NumberTitle','off', ...
    'MenuBar','none','ToolBar','none','Color',bg,'Resize','off', ...
    'Position',[max(10,(screen(3)-sz(1))/2) max(35,(screen(4)-sz(2))/2) sz], ...
    'Tag','TscoreConfigurationDialog','CloseRequestFcn',@onCancel);
label(dialogFig,'Choose inputs, preprocessing, models, and validation independently.',[.03 .945 .94 .035]);
label(dialogFig,char("Locations from Analysis: "+strjoin(selectedTags,', ')),[.03 .895 .94 .04]);
tabs=uitabgroup(dialogFig,'Units','normalized','Position',[.03 .235 .94 .635],'Tag','TscoreMainTabs');
pt=uitab(tabs,'Title','1. Predictors'); nt=uitab(tabs,'Title','2. Preprocessing');
mt=uitab(tabs,'Title','3. Models'); vt=uitab(tabs,'Title','4. Validation');
ft=uitab(tabs,'Title','5. Figure');
label(ft,'Figure output',[.04 .85 .30 .07]);
h.figureMode=popup(ft,{'Individual prediction and classification plots','Multi-panel comparison: choose panels below'},[.35 .85 .60 .075],'TscoreFigureMode');
h.baseline=check(ft,'Include demographics-only panel (top center)',[.04 .74 .91 .07],'TscoreFigureDemographics');
rowNames=cellstr(selectedTags);
if numel(selectedTags)>1, rowNames{end+1}=char("["+strjoin(selectedTags,', ')+"] (concatenated)"); end
panelData=[rowNames(:),num2cell(true(numel(rowNames),2))];
h.panelTable=uitable(ft,'Units','normalized','Position',[.04 .34 .91 .36], ...
    'Data',panelData,'ColumnName',{'Locations (from Analysis)','Raman only','Raman + demographics'}, ...
    'ColumnFormat',{'char','logical','logical'},'ColumnEditable',[false true true], ...
    'ColumnWidth',{390 110 180},'RowName',[],'Tag','TscoreFigurePanels','CellEditCallback',@refresh);
label(ft,['Only checked panels are fitted. All panels use the same eligible donors, axes, models and validation recipe. ' ...
    'Select demographics under Predictors; with none selected, demographic panels are unavailable.'],[.04 .18 .91 .13]);
label(ft,['Figure choices never load or change model settings. Combined panels alone use the selected block scaling. ' ...
    'Missing selected locations or demographics exclude a donor from the common cohort.'],[.04 .04 .91 .12]);
label(pt,'Predictor source',[.04 .87 .26 .06]);
h.source=popup(pt,{'Raman only','Demographics only','Raman + demographics'},[.33 .87 .62 .065],'TscorePredictorSource');
label(pt,'Raman representation',[.04 .76 .27 .06]);
h.feature=popup(pt,{'Full spectrum','Selected ratios','Ratios concatenated across spectra', ...
    'Ratios: mean and difference across spectra','Ratios: normalized difference across spectra'}, ...
    [.33 .76 .62 .065],'TscoreRamanFeatureMode');
rp=uipanel(pt,'Title','Select Raman ratios','Units','normalized','Position',[.04 .37 .91 .32], ...
    'BackgroundColor','white','Tag','TscoreRatioPanel');
ratioNames=["PO4_CO3","PO4_AmideIII","PO4_CH2","PO4_AmideI","CO3_AmideIII"];
ratioLabels={'PO4 / CO3','PO4 / Amide III','PO4 / CH2','PO4 / Amide I','CO3 / Amide III'};
ratioTags={'TscoreRatioPO4CO3','TscoreRatioPO4AmideIII','TscoreRatioPO4CH2','TscoreRatioPO4AmideI','TscoreRatioCO3AmideIII'};
ratioChecks=gobjects(1,5);
for k=1:5
    ratioChecks(k)=check(rp,ratioLabels{k},[.04+.48*mod(k-1,2) .68-.29*floor((k-1)/2) .44 .22],ratioTags{k});
end
dp=uipanel(pt,'Title','Select demographic predictors','Units','normalized','Position',[.04 .15 .91 .17],'BackgroundColor','white');
demoFields={'useAge','useSex','useBMI','useWeight'}; demoLabels={'Age','Sex','BMI','Weight'};
for k=1:4, h.(demoFields{k})=check(dp,demoLabels{k},[.04+.24*(k-1) .30 .22 .40],['TscoreUse' demoLabels{k}]); end
label(pt,'Tissue, offsets, spectrum expression, and location tags are selected in the main analysis window.',[.04 .025 .91 .09]);

label(nt,'Spectrum normalization',[.04 .85 .30 .065]);
h.norm=popup(nt,{'PO4','CH2','AmideI','AmideIII','CO3','FullSpectrum','none'},[.37 .85 .29 .07],'TscoreNormalizationRegion');
h.normMethod=popup(nt,{'peak','peakBaseline','area'},[.69 .85 .26 .07],'TscoreNormalizationMethod');
label(nt,['Each selected spectrum is normalized separately before a spectrum expression is applied. ' ...
    'None leaves spectral intensities unchanged. Ratio-concatenation and ratio-level differences use per-spectrum ratios directly.'],[.04 .70 .91 .105]);
h.standardize=check(nt,'Standardize predictor columns within each training fold',[.04 .57 .91 .075],'TscoreStandardize');
h.block=check(nt,'Enable block scaling: Raman + demographics',[.04 .45 .91 .075],'TscoreBlockScale');
label(nt,['After column standardization, divide each block by sqrt(number of columns in that block). ' ...
    'Available for full spectra or ratios combined with demographics, using PLS, SVR, Ridge, or MLP.'],[.07 .28 .86 .135]);
label(nt,['Block scaling requires standardization. Neither option changes your selected models. ' ...
    'Training-derived preprocessing is re-estimated inside each inner and outer training fold.'],[.04 .07 .91 .13]);

label(mt,'Select all models you want to run with these predictor settings.',[.04 .89 .91 .06]);
modelNames=["PLS","SVR","RIDGE","MLP","CNN"]; modelChecks=gobjects(1,5);
for k=1:5
    modelChecks(k)=check(mt,char(modelNames(k)),[.04+.19*(k-1) .79 .18 .07],['TscoreModel' char(modelNames(k))]);
    if ~availability.(char(modelNames(k))), set(modelChecks(k),'Enable','off','TooltipString','Required MATLAB toolbox is unavailable.'); end
end
modelTabs=uitabgroup(mt,'Units','normalized','Position',[.04 .06 .91 .69],'Tag','TscoreModelTabs');
mp=gobjects(1,5); for k=1:5, mp(k)=uitab(modelTabs,'Title',char(modelNames(k))); end
label(mp(1),'Component selection',[.04 .76 .31 .09]);
h.rankMode=popup(mp(1),{'Nested selection','Fixed (pre-specified)'},[.38 .76 .56 .10],'TscorePLSRankMode');
rankLabel=label(mp(1),'Maximum components',[.04 .56 .31 .09]);
h.rank=edit(mp(1),[.38 .56 .22 .10],'TscorePLSRankValue');
label(mp(1),'Nested mode chooses components using only outer-training cadavers. Fixed mode uses your specified count in every outer fold.',[.04 .22 .91 .22]);
label(mp(2),'Parameter selection',[.04 .82 .29 .08]);
h.svrMode=popup(mp(2),{'Bayesian nested','Random-grid nested','Fixed parameters'},[.36 .82 .59 .10],'TscoreSvrTuningMode');
svrFields={'svrBoxConstraint','svrEpsilon','svrKernelScale'};
svrGridFields={'svrBoxConstraintGrid','svrEpsilonGrid','svrKernelScaleGrid'};
svrTags={'TscoreSvrC','TscoreSvrEpsilon','TscoreSvrScale'};
gridTags={'TscoreSvrCGrid','TscoreSvrEpsilonGrid','TscoreSvrScaleGrid'};
svrLabels={'C','Epsilon','Kernel scale'};
for k=1:3
    x=.30+(k-1)*.225; label(mp(2),svrLabels{k},[x .66 .21 .08]);
    numeric.(svrFields{k})=edit(mp(2),[x .53 .21 .10],svrTags{k});
    vectors.(svrGridFields{k})=edit(mp(2),[x .34 .21 .10],gridTags{k});
end
label(mp(2),'Fixed / initial values',[.04 .53 .24 .10]); label(mp(2),'Grid / search bounds',[.04 .34 .24 .10]);
label(mp(2),['Bayesian uses grid bounds plus initial values. Random-grid uses the evaluation budget; matched uses the complete grid. ' ...
    'Kernel scales must cover both unblocked Raman and block-scaled combined inputs when comparing them.'],[.04 .05 .91 .20]);
field(mp(3),'Alpha grid','ridgeAlphaGrid','TscoreRidgeAlphaGrid',.76,true);
label(mp(3),'Ridge selects regularization by grouped inner K-fold validation. Smaller alpha means less shrinkage.',[.04 .40 .91 .23]);
field(mp(4),'Hidden-layer sizes','mlpHiddenLayers','TscoreMlpLayers',.76,true);
field(mp(4),'Iteration / epoch limit','mlpMaxEpochs','TscoreMlpEpochs',.54,false);
field(mp(4),'Regularization','mlpRegularization','TscoreMlpRegularization',.32,false);
field(mp(5),'Epoch limit','cnnMaxEpochs','TscoreCnnEpochs',.76,false);
field(mp(5),'Mini-batch size','cnnMiniBatchSize','TscoreCnnBatch',.54,false);
field(mp(5),'Regularization','cnnRegularization','TscoreCnnRegularization',.32,false);
label(mp(5),'CNN supports full Raman spectra only; no demographic block.',[.04 .07 .91 .13]);

label(vt,'Outer validation: leave one cadaver out (all models)',[.04 .89 .91 .06]);
label(vt,'All records from the test cadaver stay outside fitting and inner tuning. Models share outer held-out cadavers when their eligible records match.',[.04 .77 .91 .10]);
label(vt,'PLS / SVR validation recipe',[.04 .66 .32 .065]);
h.protocol=popup(vt,{'Original: PLS inner LOCO / MATLAB SVR','Matched: PLS K-fold / Python SVR full grid'},[.38 .66 .57 .07],'TscoreValidationProtocol');
field(vt,'Matched PLS / SVR inner folds','matchedInnerFolds','TscoreMatchedInnerFolds',.55,false);
field(vt,'Original SVR inner folds','svrInnerFolds','TscoreSvrInnerFolds',.45,false);
field(vt,'Original SVR evaluation budget','svrMaxCandidates','TscoreSvrMaxCandidates',.35,false);
field(vt,'Ridge inner folds','ridgeInnerFolds','TscoreRidgeInnerFolds',.25,false);
field(vt,'Random seed','randomSeed','TscoreRandomSeed',.15,false);
label(vt,'Matched SVR Python',[.04 .05 .31 .065]);
h.python=edit(vt,[.38 .05 .57 .065],'TscoreMatchedSVRPython');
set(h.python,'TooltipString','Matched SVR uses fresh scikit-learn fits; original SVR uses MATLAB. Ridge keeps its own inner folds. MLP/CNN use fixed settings.');
summary=uicontrol(dialogFig,'Style','text','Units','normalized','Position',[.035 .092 .93 .12], ...
    'HorizontalAlignment','left','BackgroundColor',bg,'FontSize',10,'Tag','TscoreDialogSummary');
status=uicontrol(dialogFig,'Style','text','Units','normalized','Position',[.035 .015 .69 .065], ...
    'HorizontalAlignment','left','BackgroundColor',bg,'ForegroundColor',[.55 .15 .08],'Tag','TscoreDialogStatus');
button(dialogFig,'Cancel',[.75 .025 .10 .05],'TscoreCancel',@onCancel);
applyButton=button(dialogFig,'Apply',[.86 .025 .105 .05],'TscoreApply',@onApply);
writeControls(); refresh();
if waitForClose, set(dialogFig,'WindowStyle','modal'); uiwait(dialogFig); end

    function field(parent,name,key,tag,y,isVector)
        label(parent,name,[.04 y .32 .07]); c=edit(parent,[.38 y .57 .07],tag);
        if isVector, vectors.(key)=c; else, numeric.(key)=c; end
    end
    function c=edit(parent,pos,tag)
        c=uicontrol(parent,'Style','edit','Units','normalized','Position',pos,'BackgroundColor','white', ...
            'HorizontalAlignment','left','FontSize',10,'Tag',tag,'Callback',@refresh);
    end
    function c=check(parent,name,pos,tag)
        c=uicontrol(parent,'Style','checkbox','Units','normalized','Position',pos, ...
            'String',name,'BackgroundColor','white','FontSize',10,'Tag',tag,'Callback',@refresh);
    end
    function c=popup(parent,items,pos,tag)
        c=uicontrol(parent,'Style','popupmenu','Units','normalized','Position',pos, ...
            'String',items,'BackgroundColor','white','FontSize',10,'Tag',tag,'Callback',@refresh);
    end
    function c=label(parent,name,pos)
        c=uicontrol(parent,'Style','text','Units','normalized','Position',pos, ...
            'String',name,'BackgroundColor','white','HorizontalAlignment','left','FontSize',10);
    end
    function c=button(parent,name,pos,tag,callback)
        c=uicontrol(parent,'Style','pushbutton','Units','normalized','Position',pos, ...
            'String',name,'FontSize',9,'Tag',tag,'Callback',callback);
    end
    function writeControls()
        set(h.figureMode,'Value',idx(["individual","locationComparison"],config.figureMode));
        set(h.baseline,'Value',config.figureIncludeDemographics);
        data=get(h.panelTable,'Data');
        for j=1:numel(selectedTags)
            data{j,2}=~config.figureSelectionConfigured || ismember(selectedTags(j),config.figureRamanTags);
            data{j,3}=~config.figureSelectionConfigured || ismember(selectedTags(j),config.figureCombinedTags);
        end
        if numel(selectedTags)>1
            data{end,2}=config.figureIncludeConcatenatedRaman;
            data{end,3}=config.figureIncludeConcatenatedCombined;
        end
        set(h.panelTable,'Data',data);
        set(h.source,'Value',idx(["raman","demographics","combined"],config.predictorSource));
        set(h.feature,'Value',idx(["spectrum","ratios","ratiosConcat","ratiosMeanDiff","ratiosNormDiff"],config.ramanFeatureMode));
        set(h.norm,'Value',idx(string(get(h.norm,'String')),config.normalizationRegion));
        set(h.normMethod,'Value',idx(string(get(h.normMethod,'String')),config.normalizationMethod));
        for j=1:4, set(h.(demoFields{j}),'Value',config.(demoFields{j})); end
        for j=1:5
            set(ratioChecks(j),'Value',any(string(config.ramanRatioNames)==ratioNames(j)));
            set(modelChecks(j),'Value',any(config.models==modelNames(j)));
        end
        set(h.standardize,'Value',config.standardizePredictors); set(h.block,'Value',config.blockScaleRamanDemographics);
        set(h.protocol,'Value',1+(config.validationProtocol=="matchedKFold"));
        set(h.svrMode,'Value',idx(["bayesian","nested","fixed"],config.svrOptimizationMode));
        set(h.rankMode,'Value',1+~isempty(config.fixedPLSRank));
        rank=config.maxPLSRank; if ~isempty(config.fixedPLSRank), rank=config.fixedPLSRank; end
        set(h.rank,'String',num2str(rank)); set(h.python,'String',char(config.matchedSVRPython));
        keys=fieldnames(numeric);
        for j=1:numel(keys), set(numeric.(keys{j}),'String',num2str(config.(keys{j}))); end
        keys=fieldnames(vectors);
        for j=1:numel(keys), set(vectors.(keys{j}),'String',strjoin(string(config.(keys{j})),', ')); end
    end
    function c=readControls()
        c=config; sources=["raman","demographics","combined"]; c.predictorSource=sources(get(h.source,'Value'));
        outputs=["individual","locationComparison"]; c.figureMode=outputs(get(h.figureMode,'Value'));
        c=resolveTscoreAnalysisConfig(c,analysis);
        data=get(h.panelTable,'Data'); nTags=numel(selectedTags);
        c.figureSelectionConfigured=true;
        c.figureRamanTags=selectedTags(cell2mat(data(1:nTags,2)));
        c.figureCombinedTags=selectedTags(cell2mat(data(1:nTags,3)));
        c.figureIncludeDemographics=logical(get(h.baseline,'Value'));
        c.figureIncludeConcatenatedRaman=false; c.figureIncludeConcatenatedCombined=false;
        if nTags>1
            c.figureIncludeConcatenatedRaman=logical(data{end,2});
            c.figureIncludeConcatenatedCombined=logical(data{end,3});
        end
        modes=["spectrum","ratios","ratiosConcat","ratiosMeanDiff","ratiosNormDiff"]; c.ramanFeatureMode=modes(get(h.feature,'Value'));
        for j=1:4, c.(demoFields{j})=logical(get(h.(demoFields{j}),'Value')); end
        c.ramanRatioNames=ratioNames(arrayfun(@(x)logical(get(x,'Value')),ratioChecks));
        c.models=modelNames(arrayfun(@(x)logical(get(x,'Value')),modelChecks));
        c.normalizationRegion=string(popvalue(h.norm)); c.normalizationMethod=string(popvalue(h.normMethod));
        c.standardizePredictors=logical(get(h.standardize,'Value'));
        c.blockScaleRamanDemographics=logical(get(h.block,'Value')) && (c.predictorSource=="combined" || c.figureMode=="locationComparison");
        protocols=["legacy","matchedKFold"]; c.validationProtocol=protocols(get(h.protocol,'Value'));
        c.matchedSVRPython=string(get(h.python,'String'));
        modes=["bayesian","nested","fixed"]; c.svrOptimizationMode=modes(get(h.svrMode,'Value'));
        rank=str2double(get(h.rank,'String'));
        if get(h.rankMode,'Value')==2, c.fixedPLSRank=rank; c.maxPLSRank=max(config.maxPLSRank,rank);
        else, c.fixedPLSRank=[]; c.maxPLSRank=rank; end
        keys=fieldnames(numeric);
        for j=1:numel(keys), c.(keys{j})=str2double(get(numeric.(keys{j}),'String')); end
        keys=fieldnames(vectors);
        for j=1:numel(keys), c.(keys{j})=str2double(regexp(strtrim(get(vectors.(keys{j}),'String')),'[,;\s]+','split')); end
    end
    function refresh(varargin)
        publication=get(h.figureMode,'Value')==2; enable(h.source,~publication);
        hasRaman=publication || get(h.source,'Value')~=2; hasDemo=publication || get(h.source,'Value')~=1;
        enable(h.feature,hasRaman); enable(ratioChecks,hasRaman && get(h.feature,'Value')~=1);
        for j=1:4
            enable(h.(demoFields{j}),hasDemo && demographicAvailable(j));
            if demographicKnown && ~demographicAvailable(j)
                set(h.(demoFields{j}),'Value',0,'TooltipString','No finite values in the loaded donor/category metadata.');
            end
        end
        demoSelected=any(cellfun(@(key)logical(get(h.(key),'Value')),demoFields));
        enable(h.baseline,publication && demoSelected);
        set(h.panelTable,'Enable',onoff(publication),'ColumnEditable',[false publication publication && demoSelected]);
        if ~demoSelected
            data=get(h.panelTable,'Data'); data(:,3)={false};
            set(h.panelTable,'Data',data); set(h.baseline,'Value',0);
        end
        normalizeActive=hasRaman && get(h.feature,'Value')<=2;
        enable(h.norm,normalizeActive); enable(h.normMethod,normalizeActive && ~strcmp(popvalue(h.norm),'none'));
        enable(h.block,publication || get(h.source,'Value')==3);
        matched=get(h.protocol,'Value')==2; selected=arrayfun(@(x)logical(get(x,'Value')),modelChecks);
        for j=1:5, enable(findobj(mp(j),'Type','uicontrol','-not','Style','text'),selected(j)); end
        fixed=get(h.rankMode,'Value')==2;
        if fixed, set(rankLabel,'String','Fixed components'); else, set(rankLabel,'String','Maximum components'); end
        if matched, set(h.svrMode,'String',{'Bayesian nested (original only)','Complete-grid nested','Fixed (original only)'});
        else, set(h.svrMode,'String',{'Bayesian nested','Random-grid nested','Fixed parameters'}); end
        svrFixed=get(h.svrMode,'Value')==3;
        for j=1:3
            enable(numeric.(svrFields{j}),selected(2) && ~matched);
            enable(vectors.(svrGridFields{j}),selected(2) && ~svrFixed);
        end
        enable(numeric.matchedInnerFolds,matched && ((selected(1) && ~fixed)||selected(2)));
        enable(numeric.svrInnerFolds,~matched && selected(2) && ~svrFixed);
        enable(numeric.svrMaxCandidates,~matched && selected(2) && ~svrFixed);
        enable(numeric.ridgeInnerFolds,selected(3)); enable(h.python,matched && selected(2));
        try
            c=readControls(); description=char(formatTscoreConfigSummary(c));
            normalization=char(c.normalizationRegion+" / "+c.normalizationMethod);
            if c.normalizationRegion=="none", normalization='none'; end
            if ~normalizeActive, normalization='not used for these features'; end
            detail=sprintf('Features: %s | Normalization: %s | Standardize: %s | Block scale: %s | Seed: %.0f', ...
                popvalue(h.feature),normalization,onoff(c.standardizePredictors),onoff(c.blockScaleRamanDemographics),c.randomSeed);
            note=char("Analysis locations: "+strjoin(selectedTags,', ')+". Model settings are independent of figure output.");
            if publication, note=char(string(numel(tscoreFigurePlan(c,selectedTags)))+" selected panels. "+string(note)); end
            set(summary,'String',{description;detail;note}); validateTscoreConfiguration(c);
            set(status,'String','Ready. Apply saves these settings; Cancel keeps the previous configuration.', ...
                'ForegroundColor',[.15 .38 .25]);
            set(applyButton,'Enable','on');
        catch ME
            set(status,'String',ME.message,'ForegroundColor',[.55 .15 .08]); set(applyButton,'Enable','off');
        end
    end
    function onApply(~,~)
        try
            updated=validateTscoreConfiguration(readControls()); ud=parentFig.UserData; ud.config.tscore=updated;
            parentFig.UserData=ud; onCancel([],[]);
        catch ME, set(status,'String',ME.message);
        end
    end
    function onCancel(~,~)
        if waitForClose && isgraphics(dialogFig), uiresume(dialogFig); end
        if isgraphics(dialogFig), delete(dialogFig); end
    end
end
function enable(h,flag)
set(h,'Enable',onoff(flag));
end
function v=onoff(flag)
if flag, v='on'; else, v='off'; end
end
function i=idx(values,value)
i=find(values==string(value),1); if isempty(i), i=1; end
end
function s=popvalue(h)
items=get(h,'String'); s=items{get(h,'Value')};
end

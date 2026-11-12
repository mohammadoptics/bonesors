function dialogFig = configureReconstructionDialog(parentFig, waitForClose)
%CONFIGURERECONSTRUCTIONDIALOG Edit all reconstruction inputs and model options.
if nargin < 2, waitForClose = true; end
ud = parentFig.UserData;
c = reconstructionDefaultConfig();
if isfield(ud.config,'reconstruction'), c = validateReconstructionConfiguration(ud.config.reconstruction); end
dialogFig = figure('Name','Configure spectral reconstruction','NumberTitle','off', ...
    'MenuBar','none','ToolBar','none','Position',[100 80 1050 760], ...
    'Color','white','Tag','ReconstructionConfigurationDialog','CloseRequestFcn',@cancel);
tabs = uitabgroup(dialogFig,'Units','normalized','Position',[.02 .16 .96 .82]);
inputTab = uitab(tabs,'Title','1. Spectra and normalization');
modelTab = uitab(tabs,'Title','2. Model and validation');
plsTab = uitab(tabs,'Title','3. PLS algorithm');
compactTab = uitab(tabs,'Title','4. Compact PCA + MLP');
outputTab = uitab(tabs,'Title','5. Output');
controls = struct();
editField(inputTab,1,'Intact columns, in order (1=0, 2=3, 3=6 mm)','intactSpectraToUse');
popupField(inputTab,2,'Combine input spectra','combineMode', ...
    {'concat','mean','add','diff','meanDiff'}, ...
    {'Concatenate','Mean','Add','Difference (second - first)','Mean + difference (second - first)'});
editField(inputTab,3,'Exposed columns to reconstruct jointly','exposedSpectrumToPredict');
editField(inputTab,4,'Exact tags (comma separated; blank = all)','tagsToUse');
editField(inputTab,5,'Categories (comma separated; blank = all)','categoriesToUse');
regions = {'none','PO4','CO3','CH2','AmideI','AmideIII','FullSpectrum'};
methods = {'peak','peakBaseline','area'};
popupField(inputTab,6,'Intact normalization region','normalizationRegion',regions,regions);
popupField(inputTab,7,'Intact normalization method','normalizationMethod',methods,methods);
popupField(inputTab,8,'Exposed target normalization region','responseNormalizationRegion',regions,regions);
popupField(inputTab,9,'Exposed target normalization method','responseNormalizationMethod',methods,methods);
uicontrol(inputTab,'Style','text','Units','normalized','Position',[.03 .14 .94 .09], ...
    'String','Choose none to skip normalization. Otherwise each spectrum column is normalized separately before combination.', ...
    'HorizontalAlignment','left');
available = "Load a dataset to discover tags.";
if isfield(ud,'analysisAvailableTags') && ~isempty(ud.analysisAvailableTags)
    available = "Available tags: " + strjoin(string(ud.analysisAvailableTags),', ');
end
uicontrol(inputTab,'Style','text','Units','normalized','Position',[.03 .01 .94 .065], ...
    'String',char(available),'TooltipString',char(available),'HorizontalAlignment','left');
popupField(modelTab,1,'Reconstruction model','reconstructionModel', ...
    {'PLS','MLP','KRR_RBF','PCA_MLP'}, ...
    {'PLS','Original full-spectrum MLP (fitnet)','Kernel ridge (RBF)','Compact PCA + MLP (nested tuning)'});
checkField(modelTab,2,'PLS: select components by inner cadaver-wise LOCO','useInnerCVForNComponents');
editField(modelTab,3,'PLS fixed component count','fixedNComponents');
editField(modelTab,4,'PLS maximum components for inner LOCO','maxComponentsForCV');
checkField(modelTab,5,'PLS: standardize inputs and targets within training folds','standardizeBeforePLS');
editField(modelTab,6,'MLP hidden layer sizes (e.g. 24 or 24,12)','mlpHiddenLayerSizes');
popupField(modelTab,7,'MLP training function (fitnet required)','mlpTrainFcn', ...
    {'trainscg','trainlm','trainbr'},{'trainscg','trainlm','trainbr'});
editField(modelTab,8,'MLP maximum epochs','mlpMaxEpochs');
editField(modelTab,9,'MLP regularization (0 to 1)','mlpRegularization');
editField(modelTab,10,'Random seed','randomSeed');
editField(modelTab,11,'Kernel ridge alpha (>0)','krrAlpha');
editField(modelTab,12,'Kernel ridge gamma multiplier (>0)','krrGammaMultiplier');
editField(compactTab,1,'Input PCA component grid','compactInputPCGrid');
editField(compactTab,2,'Response PCA components (fixed)','compactOutputPCs');
editField(compactTab,3,'Hidden-neuron grid (one tanh layer)','compactHiddenGrid');
editField(compactTab,4,'Weight penalty alpha grid','compactAlphaGrid');
editField(compactTab,5,'Inner donor-grouped folds','compactInnerFolds');
editField(compactTab,6,'Inner-fold shuffle seed','compactInnerSeed');
editField(compactTab,7,'Initialization seeds (first used for tuning)','compactSeeds');
editField(compactTab,8,'L-BFGS-B maximum iterations','compactMaxIterations');
editField(compactTab,9,'Python executable (NumPy, SciPy, threadpoolctl)','compactPython');
uicontrol(compactTab,'Style','text','Units','normalized','Position',[.03 .04 .94 .27], ...
    'String',sprintf(['All scaling and PCA are fitted on training data only. Inner tuning minimizes donor-weighted spectral MSE, not category p-values.\n\n' ...
    'The selected network is refitted with every initialization seed; predictions are averaged. No seed is selected by test performance.\n\n' ...
    'This is a separate model from the original full-spectrum MLP. Defaults reproduce the compact-model analysis; significance is not guaranteed on other data. ' ...
    'Per-fold choices, losses, convergence and software versions are saved in reconstruction_tuning.json.']), ...
    'HorizontalAlignment','left');
uicontrol(modelTab,'Style','text','Units','normalized','Position',[.03 .01 .94 .065], ...
    'String','Only settings for the selected model are enabled. Outer validation holds out whole cadavers. MLP/KRR use training-fold standardization.', ...
    'HorizontalAlignment','left');
popupField(plsTab,1,'PLS algorithm','plsAlgorithm',{'NIPALS','SIMPLS'}, ...
    {'NIPALS (Python-compatible)','SIMPLS (previous MATLAB method)'});
editField(plsTab,2,'NIPALS maximum iterations per component','plsMaxIterations');
editField(plsTab,3,'NIPALS convergence tolerance','plsTolerance');
uicontrol(plsTab,'Style','text','Units','normalized','Position',[.03 .30 .94 .39], ...
    'String',sprintf(['Use NIPALS to reproduce Python PLSRegression reconstruction. R04191 uses 5000 maximum iterations and tolerance 1e-6.\n\n' ...
    'Both algorithms are PLS, but joint multi-output spectral predictions can differ even at the same component count. ' ...
    'SIMPLS is retained to reproduce earlier MATLAB outputs.\n\n' ...
    'The selected algorithm is also used inside component-selection folds. Neither algorithm uses the held-out cadaver for fitting.']), ...
    'HorizontalAlignment','left');
popupField(outputTab,1,'Save format','saveOutputMode',{'single','individual','both'}, ...
    {'Combined cadaver dataset','Individual cadaver files','Both formats'});
editField(outputTab,2,'Combined dataset filename','combinedOutputFileName');
editField(outputTab,3,'Metrics filename','metricsFileName');
checkField(outputTab,4,'Verify reconstructed spectra after saving','verifySavedFiles');
checkField(outputTab,5,'Create a new run subfolder (recommended)','createRunSubfolder');
uicontrol(outputTab,'Style','text','Units','normalized','Position',[.04 .26 .92 .26], ...
    'String',sprintf(['Outputs go to the analysis output directory selected in the main GUI:\n%s\n\n' ...
    'The combined MAT file preserves measured E and intact T; reconstructed spectra are in P at their physical column numbers. ' ...
    'Settings and source-dataset details are saved alongside the spectra.\n\n' ...
    'Saved LOCO spectra alone are not sufficient for strict end-to-end T-score validation; reconstruction must also be repeated within T-score folds.'], ...
    char(ud.config.analysisOutputDirectory)), 'HorizontalAlignment','left');
status = uicontrol(dialogFig,'Style','text','Units','normalized','Position',[.03 .085 .94 .06], ...
    'String','Only the settings of the selected model are used.','HorizontalAlignment','left');
uicontrol(dialogFig,'Style','pushbutton','Units','normalized','Position',[.55 .02 .2 .05], ...
    'String','Apply','Tag','ReconstructionApply','Callback',@apply);
uicontrol(dialogFig,'Style','pushbutton','Units','normalized','Position',[.77 .02 .2 .05], ...
    'String','Cancel','Callback',@cancel);
dialogFig.UserData = struct('controls',controls,'status',status);
for key = ["reconstructionModel","normalizationRegion","responseNormalizationRegion","useInnerCVForNComponents","plsAlgorithm"]
    controls.(key).Callback = @refreshControls;
end
refreshControls();
if waitForClose, uiwait(dialogFig); end

    function h = label(tab,row,txt)
        h = uicontrol(tab,'Style','text','Units','normalized', ...
            'Position',[.03 1-row*.071 .52 .049],'String',txt,'HorizontalAlignment','left');
    end
    function editField(tab,row,txt,key)
        label(tab,row,txt);
        value = c.(key);
        if isnumeric(value), value = strjoin(string(value),', ');
        elseif iscell(value), value = strjoin(string(value),', '); end
        controls.(key) = uicontrol(tab,'Style','edit','Units','normalized', ...
            'Position',[.56 1-row*.071 .41 .055],'String',char(value), ...
            'BackgroundColor','white','Tag',['Recon_' key]);
    end
    function popupField(tab,row,txt,key,values,labels)
        label(tab,row,txt);
        controls.(key) = uicontrol(tab,'Style','popupmenu','Units','normalized', ...
            'Position',[.56 1-row*.071 .41 .055],'String',labels, ...
            'Value',find(strcmp(values,c.(key)),1),'UserData',values, ...
            'BackgroundColor','white','Tag',['Recon_' key]);
    end
    function checkField(tab,row,txt,key)
        controls.(key) = uicontrol(tab,'Style','checkbox','Units','normalized', ...
            'Position',[.03 1-row*.071 .94 .055],'String',txt,'Value',c.(key), ...
            'Tag',['Recon_' key]);
    end
    function refreshControls(varargin)
        model = string(controls.reconstructionModel.UserData{controls.reconstructionModel.Value});
        for key = ["useInnerCVForNComponents","standardizeBeforePLS","plsAlgorithm"]
            enable(key,model=="PLS");
        end
        nipals = model=="PLS" && controls.plsAlgorithm.Value==1;
        enable("plsMaxIterations",nipals); enable("plsTolerance",nipals);
        enable("fixedNComponents",model=="PLS" && ~controls.useInnerCVForNComponents.Value);
        enable("maxComponentsForCV",model=="PLS" && controls.useInnerCVForNComponents.Value);
        for key = ["mlpHiddenLayerSizes","mlpTrainFcn","mlpMaxEpochs","mlpRegularization","randomSeed"]
            enable(key,model=="MLP");
        end
        for key = ["krrAlpha","krrGammaMultiplier"], enable(key,model=="KRR_RBF"); end
        for key = ["compactInputPCGrid","compactOutputPCs","compactHiddenGrid","compactAlphaGrid", ...
                "compactInnerFolds","compactInnerSeed","compactSeeds","compactMaxIterations","compactPython"]
            enable(key,model=="PCA_MLP");
        end
        enable("normalizationMethod",controls.normalizationRegion.Value~=1);
        enable("responseNormalizationMethod",controls.responseNormalizationRegion.Value~=1);
    end
    function enable(key,on)
        state='off'; if on, state='on'; end
        controls.(key).Enable=state;
    end
    function apply(~,~)
        try
            updated = c;
            names = fieldnames(controls);
            for k = 1:numel(names)
                key = names{k}; h = controls.(key);
                switch h.Style
                    case 'checkbox', value = logical(h.Value);
                    case 'popupmenu', value = string(h.UserData{h.Value});
                    otherwise
                        value = strtrim(string(h.String));
                        if any(strcmp(key,{'tagsToUse','categoriesToUse'}))
                            value = cellstr(split(value,{',',';',' '}));
                        elseif isnumeric(c.(key))
                            parts = regexp(char(value),'[,;\s]+','split');
                            value = cellfun(@str2double,parts);
                        end
                end
                updated.(key) = value;
            end
            updated = validateReconstructionConfiguration(updated);
            temp = parentFig.UserData;
            temp.config.reconstruction = updated;
            parentFig.UserData = temp;
            if isfield(temp,'controls') && isfield(temp.controls,'reconstructionSummaryText')
                temp.controls.reconstructionSummaryText.String = formatReconstructionConfigSummary(updated);
            end
            delete(dialogFig);
        catch ME
            status.String = ME.message;
            status.ForegroundColor = [0.8 0 0];
        end
    end
    function cancel(~,~)
        delete(dialogFig);
    end
end

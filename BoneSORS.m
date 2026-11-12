function BoneSORS
%BONESORS Two-stage interface for individual files and generated datasets.

appFolder = fullfile(fileparts(mfilename('fullpath')), 'app');
addpath(appFolder, fullfile(appFolder, 'analysis'));

config = guiDefaultConfig();
screenSize = get(groot, 'ScreenSize');
windowWidth = min(1540, max(1180, screenSize(3) - 100));
windowHeight = min(920, max(760, screenSize(4) - 120));

fig = figure('Name', 'BoneSORS', 'NumberTitle', 'off', ...
    'Color', [0.96 0.97 0.98], 'Position', [40 50 windowWidth windowHeight], ...
    'Resize', 'on', 'WindowStyle', 'normal', 'Tag', 'MainGUI_Ver2');

ud = struct();
ud.statusMap = containers.Map();
ud.statusFilename = '';
ud.data = {};
ud.fileNames = {};
ud.filePaths = {};
ud.dataFieldOriginalNames = {};
ud.dataFieldFileIdx = {};
ud.badMap = containers.Map();
ud.availableTags = {};
ud.analysisFile = '';
ud.analysisData = [];
ud.analysisDatasetType = '';
ud.analysisSummary = '';
ud.analysisAvailableTags = {};
ud.config = config;
ud.controls = struct();
fig.UserData = ud;

tabs = uitabgroup('Parent', fig, 'Units', 'normalized', ...
    'Position', [0.012 0.06 0.976 0.925]);
individualTab = uitab('Parent', tabs, 'Title', '1. Individual Cadavers');
analysisTab = uitab('Parent', tabs, 'Title', '2. Dataset Analysis');

%% Tab 1: individual-cadaver preparation ---------------------------------
dataPanel = uipanel('Parent', individualTab, 'Units', 'normalized', ...
    'Position', [0.012 0.02 0.275 0.965], 'Title', '', ...
    'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', 'white');
plotPanel = uipanel('Parent', individualTab, 'Units', 'normalized', ...
    'Position', [0.298 0.02 0.69 0.965], 'Title', '', ...
    'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', 'white');

uicontrol('Parent', dataPanel, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [0.05 0.94 0.57 0.05], 'String', 'Load individual MAT files...', ...
    'FontWeight', 'bold', 'Callback', @(s,e)onLoadIndividualFiles());
uicontrol('Parent', dataPanel, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [0.64 0.94 0.31 0.05], 'String', 'Category...', ...
    'Callback', @(s,e)onChooseCategory());

fileListBox = uicontrol('Parent', dataPanel, 'Style', 'listbox', ...
    'Units', 'normalized', 'Position', [0.05 0.69 0.90 0.21], ...
    'String', {'No files loaded'}, 'Value', 1, 'Min', 0, 'Max', 100, ...
    'BackgroundColor', 'white', 'Callback', @(s,e)updateDataFieldListbox(fig));

dataFieldListbox = uicontrol('Parent', dataPanel, 'Style', 'listbox', ...
    'Units', 'normalized', 'Position', [0.05 0.405 0.90 0.245], ...
    'String', {'No data fields'}, 'Value', 1, 'Min', 0, 'Max', 100, ...
    'BackgroundColor', 'white', 'Callback', @(s,e)updateSpectrumListbox(fig));

spectrumListbox = uicontrol('Parent', dataPanel, 'Style', 'listbox', ...
    'Units', 'normalized', 'Position', [0.05 0.25 0.90 0.115], ...
    'String', {'No spectra'}, 'Value', 1, 'Min', 0, 'Max', 100, ...
    'BackgroundColor', 'white');

uicontrol('Parent', dataPanel, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [0.05 0.185 0.43 0.047], 'String', 'Plot raw', ...
    'Callback', @(s,e)onAction(@()displayData(fig,false), 'Plotting raw spectra...'));
uicontrol('Parent', dataPanel, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [0.52 0.185 0.43 0.047], 'String', 'Plot normalized', ...
    'Callback', @(s,e)onAction(@()displayData(fig,true), 'Plotting normalized spectra...'));
uicontrol('Parent', dataPanel, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [0.05 0.13 0.43 0.047], 'String', 'Clear plot', ...
    'Callback', @(s,e)clearCurrentDisplay());
uicontrol('Parent', dataPanel, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [0.52 0.13 0.43 0.047], 'String', 'Open plot', ...
    'Callback', @(s,e)onAction(@()openDisplayInNewWindow(fig), 'Opening plot...'));

datasetModePopup = uicontrol('Parent', dataPanel, 'Style', 'popupmenu', ...
    'Units', 'normalized', 'Position', [0.05 0.060 0.90 0.045], ...
    'String', {'Exposed only','Paired exposed/intact','Intact only'}, ...
    'Value', 1, 'BackgroundColor', 'white');
uicontrol('Parent', dataPanel, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [0.05 0.005 0.43 0.045], 'String', 'Create MAT dataset', ...
    'FontWeight', 'bold', 'Callback', @(s,e)onCreateDataset());
uicontrol('Parent', dataPanel, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [0.52 0.005 0.43 0.045], 'String', 'Build spectra table', ...
    'FontWeight', 'bold', 'Callback', @(s,e)onAction(@()BuildSpectraTableCallback(fig), ...
    'Creating spectra table...'));

ax = axes('Parent', plotPanel, 'Units', 'normalized', ...
    'Position', [0.075 0.09 0.90 0.86], 'Box', 'on');
grid(ax, 'on'); hold(ax, 'on');
xlabel(ax, 'Wavenumber (cm^{-1})'); ylabel(ax, 'Intensity (a.u.)');
title(ax, '');

%% Tab 2: generated-dataset analysis -------------------------------------
datasetPanel = uipanel('Parent', analysisTab, 'Units', 'normalized', ...
    'Position', [0.012 0.02 0.275 0.965], 'Title', 'Generated dataset', ...
    'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', 'white');
settingsPanel = uipanel('Parent', analysisTab, 'Units', 'normalized', ...
    'Position', [0.298 0.02 0.69 0.965], 'Title', 'Analysis', ...
    'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', 'white');

uicontrol('Parent', datasetPanel, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [0.05 0.925 0.90 0.06], 'String', 'Load generated MAT dataset...', ...
    'FontWeight', 'bold', 'Callback', @(s,e)onLoadAnalysisDataset());
makeLabel(datasetPanel, 'File', [0.05 0.87 0.90 0.035]);
analysisFileName = valueText(datasetPanel, 'No dataset loaded', [0.05 0.815 0.90 0.055]);
makeLabel(datasetPanel, 'Detected type', [0.05 0.755 0.90 0.035]);
analysisDatasetType = valueText(datasetPanel, '-', [0.05 0.705 0.90 0.05]);
makeLabel(datasetPanel, 'Contents', [0.05 0.645 0.90 0.035]);
analysisSummary = valueText(datasetPanel, '-', [0.05 0.595 0.90 0.05]);

uicontrol('Parent', datasetPanel, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [0.05 0.515 0.90 0.055], 'String', 'Load category sheet...', ...
    'Callback', @(s,e)onChooseCategory());
makeLabel(datasetPanel, 'Category sheet', [0.05 0.46 0.90 0.035]);
categoryFileText = valueText(datasetPanel, 'Not loaded', [0.05 0.405 0.90 0.055]);

uicontrol('Parent', datasetPanel, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [0.05 0.325 0.90 0.055], 'String', 'Choose analysis output folder...', ...
    'Callback', @(s,e)onChooseOutputDirectory());
makeLabel(datasetPanel, 'Analysis output folder', [0.05 0.275 0.90 0.035]);
outputDirectoryText = valueText(datasetPanel, 'Not selected', [0.05 0.22 0.90 0.055]);

uicontrol('Parent', datasetPanel, 'Style', 'text', 'Units', 'normalized', ...
    'Position', [0.05 0.025 0.90 0.16], ...
    'String', {'This tab uses only the generated dataset loaded above.', '', ...
    'Individual cadaver files from Tab 1 are never used directly by analysis.', '', ...
    'Create or update a dataset in Tab 1, save it, and then load it here.'}, ...
    'HorizontalAlignment', 'left', 'FontSize', 10, ...
    'ForegroundColor', [0.28 0.36 0.44], 'BackgroundColor', 'white');

modes = analysisModeRegistry();
makeLabel(settingsPanel, 'Select analysis', [0.04 0.92 0.92 0.035]);
modePopup = uicontrol('Parent', settingsPanel, 'Style', 'popupmenu', ...
    'Units', 'normalized', 'Position', [0.04 0.855 0.92 0.065], ...
    'String', {modes.label}, 'Value', 1, 'BackgroundColor', 'white', ...
    'FontSize', 10, 'Callback', @(s,e)onAnalysisModeChanged());
analysisRequirement = uicontrol('Parent', settingsPanel, 'Style', 'text', ...
    'Units', 'normalized', 'Position', [0.04 0.79 0.92 0.055], ...
    'String', 'Requires a generated cadaver dataset.', ...
    'HorizontalAlignment', 'left', 'FontSize', 9, ...
    'ForegroundColor', [0.20 0.38 0.55], 'BackgroundColor', 'white');

optionsPanel = uipanel('Parent', settingsPanel, 'Units', 'normalized', ...
    'Position', [0.04 0.30 0.92 0.48], 'Title', 'Analysis options', ...
    'BackgroundColor', [0.985 0.99 1.0]);
makeLabel(optionsPanel, 'Primary tissue', [0.035 0.88 0.25 0.06]);
tissuePopup = uicontrol('Parent', optionsPanel, 'Style', 'popupmenu', ...
    'Units', 'normalized', 'Position', [0.035 0.80 0.27 0.08], ...
    'String', {'E - exposed','T - intact','P - predicted'}, ...
    'Value', 1, 'BackgroundColor', 'white');
makeLabel(optionsPanel, 'Compare with', [0.365 0.88 0.25 0.06]);
comparisonTissuePopup = uicontrol('Parent', optionsPanel, 'Style', 'popupmenu', ...
    'Units', 'normalized', 'Position', [0.365 0.80 0.27 0.08], ...
    'String', {'E - exposed','T - intact','P - predicted'}, ...
    'Value', 3, 'BackgroundColor', 'white');
spectrumLabel = uicontrol('Parent',optionsPanel,'Style','text', ...
    'Units','normalized','Position',[0.695 0.88 0.27 0.06], ...
    'String','Spectrum expression','HorizontalAlignment','left', ...
    'FontSize',9,'FontWeight','bold', ...
    'BackgroundColor',get(optionsPanel,'BackgroundColor'));
spectrumEdit = uicontrol('Parent', optionsPanel, 'Style', 'edit', ...
    'Units', 'normalized', 'Position', [0.695 0.80 0.27 0.08], ...
    'String', char(config.analysis.spectrumExpression), 'BackgroundColor', 'white', ...
    'TooltipString', ['Normalize first, then combine. Examples: 2; ' ...
        '3-2 (subtract); 3+2 (add); 3|2 (concatenate).']);

makeLabel(optionsPanel, 'Tag policy', [0.035 0.70 0.40 0.06]);
tagModePopup = uicontrol('Parent', optionsPanel, 'Style', 'popupmenu', ...
    'Units', 'normalized', 'Position', [0.035 0.62 0.52 0.08], ...
    'String', {'Single exact tag','Priority fallback','All selected locations'}, ...
    'Value', 1, 'BackgroundColor', 'white', ...
    'Callback', @(s,e)onTagModeChanged());
makeLabel(optionsPanel, 'Match', [0.64 0.70 0.31 0.06]);
tagMatchPopup = uicontrol('Parent', optionsPanel, 'Style', 'popupmenu', ...
    'Units', 'normalized', 'Position', [0.64 0.62 0.31 0.08], ...
    'String', {'Exact','Prefix'}, 'Value', 1, 'BackgroundColor', 'white');

makeLabel(optionsPanel, 'Tags in loaded dataset', [0.035 0.53 0.40 0.06]);
makeLabel(optionsPanel, 'Selected / priority order', [0.56 0.53 0.39 0.06]);
analysisAvailableTags = uicontrol('Parent', optionsPanel, 'Style', 'listbox', ...
    'Units', 'normalized', 'Position', [0.035 0.25 0.40 0.28], ...
    'String', {'No tags found'}, 'Value', 1, 'Min', 0, 'Max', 100, ...
    'BackgroundColor', 'white');
analysisSelectedTags = uicontrol('Parent', optionsPanel, 'Style', 'listbox', ...
    'Units', 'normalized', 'Position', [0.56 0.25 0.39 0.28], ...
    'String', config.analysis.tags, 'Value', 1, 'Min', 0, 'Max', 100, ...
    'BackgroundColor', 'white');
uicontrol('Parent', optionsPanel, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [0.455 0.39 0.085 0.09], 'String', '>', 'Callback', @(s,e)addTags());
uicontrol('Parent', optionsPanel, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [0.455 0.27 0.085 0.09], 'String', '<', 'Callback', @(s,e)removeTags());
uicontrol('Parent', optionsPanel, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [0.56 0.025 0.18 0.08], 'String', 'Move up', 'Callback', @(s,e)moveTag(-1));
uicontrol('Parent', optionsPanel, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [0.77 0.025 0.18 0.08], 'String', 'Move down', 'Callback', @(s,e)moveTag(1));
tagHelp = uicontrol('Parent', optionsPanel, 'Style', 'text', 'Units', 'normalized', ...
    'Position', [0.035 0.015 0.48 0.09], 'String', 'One exact tag per cadaver.', ...
    'HorizontalAlignment', 'left', 'FontSize', 8, ...
    'ForegroundColor', [0.25 0.35 0.45], 'BackgroundColor', [0.985 0.99 1.0]);
locationCombinePopup=uicontrol('Parent',optionsPanel,'Style','popupmenu', ...
    'Units','normalized','Position',[.035 .135 .915 .09], ...
    'String',{'T-score: use single / priority tag','T-score: concatenate selected locations','T-score: mean selected locations'}, ...
    'Value',1,'BackgroundColor','white','Tag','AnalysisLocationCombineMode', ...
    'TooltipString','For individual T-score plots. Multi-panel comparisons use the panel checklist and one row per donor.', ...
    'Callback',@(s,e)onAnalysisModeChanged());
categoryComparisonCheck=uicontrol('Parent',optionsPanel,'Style','checkbox', ...
    'Units','normalized','Position',[.035 .135 .915 .09], ...
    'String','Include comparison tissue as a second row', ...
    'Value',config.analysis.categoryAverageIncludeComparison, ...
    'Visible','off','Tag','CategoryAverageIncludeComparison', ...
    'BackgroundColor',get(optionsPanel,'BackgroundColor'), ...
    'TooltipString','Use Primary tissue for the top row and Compare with for the bottom row.', ...
    'Callback',@(s,e)onAnalysisModeChanged());

tscoreConfigButton = uicontrol('Parent', settingsPanel, 'Style', 'pushbutton', ...
    'Units', 'normalized', 'Position', [0.04 0.215 0.30 0.065], ...
    'String', 'Configure T-score prediction...', 'FontWeight', 'bold', ...
    'Visible', 'off', 'Callback', @(s,e)onConfigureTscore());
tscoreSummaryText = uicontrol('Parent', settingsPanel, 'Style', 'text', ...
    'Units', 'normalized', 'Position', [0.36 0.205 0.60 0.08], ...
    'String', formatTscoreConfigSummary(config.tscore), ...
    'HorizontalAlignment', 'left', 'FontSize', 9, 'Visible', 'off', ...
    'ForegroundColor', [0.18 0.34 0.48], 'BackgroundColor', 'white');

strictConfigButton = uicontrol('Parent',settingsPanel,'Style','pushbutton', ...
    'Units','normalized','Position',[.04 .215 .30 .065], ...
    'String','Configure strict validation...','FontWeight','bold','Visible','off', ...
    'Callback',@(s,e)configureStrictTscoreDialog(fig));
strictSummaryText = uicontrol('Parent',settingsPanel,'Style','text', ...
    'Units','normalized','Position',[.36 .205 .60 .08], ...
    'String',formatStrictTscoreConfigSummary(config.strict), ...
    'HorizontalAlignment','left','FontSize',9,'Visible','off','BackgroundColor','white');
reconstructionConfigButton = uicontrol('Parent',settingsPanel,'Style','pushbutton', ...
    'Units','normalized','Position',[.04 .215 .30 .065], ...
    'String','Configure reconstruction...','FontWeight','bold','Visible','off', ...
    'Callback',@(s,e)configureReconstructionDialog(fig));
reconstructionSummaryText = uicontrol('Parent',settingsPanel,'Style','text', ...
    'Units','normalized','Position',[.36 .205 .60 .08], ...
    'String',formatReconstructionConfigSummary(config.reconstruction), ...
    'HorizontalAlignment','left','FontSize',9,'Visible','off','BackgroundColor','white');

ratioRegions = ["PO4","CO3","CH2","AmideI","AmideIII","FullSpectrum","none"];
ratioMethods = ["peak","peakBaseline","area"];
ratioNormLabel = uicontrol('Parent', settingsPanel, 'Style', 'text', ...
    'Units', 'normalized', 'Position', [0.04 0.255 0.92 0.03], ...
    'String', 'Ratio display: normalize each spectrum BEFORE applying the expression', ...
    'HorizontalAlignment', 'left', 'BackgroundColor', 'white', 'Visible', 'off');
ratioRegionPopup = uicontrol('Parent', settingsPanel, 'Style', 'popupmenu', ...
    'Units', 'normalized', 'Position', [0.04 0.205 0.43 0.045], ...
    'String', {'PO4','CO3','CH2','Amide I','Amide III','Full spectrum','None'}, ...
    'Value', find(ratioRegions == config.ratioDisplay.normalizationRegion), ...
    'BackgroundColor', 'white', 'Visible', 'off', ...
    'Callback', @(s,e)onDisplayNormalizationChanged(), ...
    'TooltipString', 'Reference region for individual-spectrum normalization; None keeps loaded intensities. Independent of T-score settings.');
ratioMethodPopup = uicontrol('Parent', settingsPanel, 'Style', 'popupmenu', ...
    'Units', 'normalized', 'Position', [0.51 0.205 0.45 0.045], ...
    'String', {'Peak height','Baseline-corrected peak','Band area'}, ...
    'Value', find(ratioMethods == config.ratioDisplay.normalizationMethod), ...
    'BackgroundColor', 'white', 'Visible', 'off', ...
    'TooltipString', 'Normalization method. Displayed Raman ratios still use baseline-corrected band areas.');

runButton = uicontrol('Parent', settingsPanel, 'Style', 'pushbutton', ...
    'Units', 'normalized', 'Position', [0.20 0.11 0.60 0.085], ...
    'String', 'Run selected analysis', 'FontSize', 12, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.16 0.45 0.68], 'ForegroundColor', 'white', ...
    'Callback', @(s,e)onRunAnalysis());
uicontrol('Parent', settingsPanel, 'Style', 'text', 'Units', 'normalized', ...
    'Position', [0.10 0.035 0.80 0.05], ...
    'String', 'All analytical workflows are launched using this single button.', ...
    'HorizontalAlignment', 'center', 'FontSize', 9, ...
    'ForegroundColor', [0.35 0.35 0.35], 'BackgroundColor', 'white');

statusText = uicontrol('Parent', fig, 'Style', 'text', 'Units', 'normalized', ...
    'Position', [0.012 0.012 0.976 0.036], ...
    'String', '', ...
    'HorizontalAlignment', 'left', 'FontSize', 10, ...
    'ForegroundColor', [0.18 0.28 0.38], 'BackgroundColor', [0.90 0.93 0.96]);

ud = fig.UserData;
ud.fileListBox = fileListBox;
ud.dataFieldListbox = dataFieldListbox;
ud.spectrumListbox = spectrumListbox;
ud.ax = ax;
ud.controls = struct('modePopup', modePopup, 'tissuePopup', tissuePopup, ...
    'spectrumEdit', spectrumEdit, 'tagModePopup', tagModePopup, ...
    'tagMatchPopup', tagMatchPopup, ...
    'analysisAvailableTags', analysisAvailableTags, ...
    'analysisSelectedTags', analysisSelectedTags, 'tagHelp', tagHelp, ...
    'locationCombinePopup',locationCombinePopup, ...
    'categoryComparisonCheck',categoryComparisonCheck, ...
    'analysisRequirement', analysisRequirement, 'runButton', runButton, ...
    'tscoreConfigButton', tscoreConfigButton, ...
    'tscoreSummaryText', tscoreSummaryText, ...
    'strictConfigButton',strictConfigButton,'strictSummaryText',strictSummaryText, ...
    'reconstructionConfigButton', reconstructionConfigButton, ...
    'reconstructionSummaryText', reconstructionSummaryText, ...
    'ratioRegionPopup', ratioRegionPopup, 'ratioMethodPopup', ratioMethodPopup, ...
    'analysisFileName', analysisFileName, ...
    'analysisDatasetType', analysisDatasetType, ...
    'analysisSummary', analysisSummary, 'categoryFileText', categoryFileText, ...
    'comparisonTissuePopup', comparisonTissuePopup, ...
    'outputDirectoryText', outputDirectoryText, ...
    'statusText', statusText);
fig.UserData = ud;

optionsMenu = uimenu(fig, 'Label', 'Options');
uimenu(optionsMenu, 'Label', 'Load category sheet...', 'Accelerator', 'C', ...
    'Callback', @(s,e)onChooseCategory());
uimenu(optionsMenu, 'Label', 'Load analysis dataset...', ...
    'Callback', @(s,e)onLoadAnalysisDataset());

onAnalysisModeChanged();

    function onLoadIndividualFiles()
        onAction(@()loadMatFiles(fig), 'Loading individual MAT files...');
        if ishandle(fig)
            setStatus(sprintf('%d individual file(s) loaded.', numel(fig.UserData.fileNames)));
        end
    end

    function onLoadAnalysisDataset()
        onAction(@()loadAnalysisDataset(fig), 'Loading generated analysis dataset...');
        if ishandle(fig) && ~isempty(fig.UserData.analysisFile)
            setStatus(sprintf('Analysis dataset loaded: %s.', fig.UserData.analysisSummary));
        end
    end

    function onCreateDataset()
        saveModes = ["exposedOnly", "paired", "intactOnly"];
        temp = fig.UserData;
        temp.config.preparation.saveMode = saveModes(get(datasetModePopup, 'Value'));
        fig.UserData = temp;
        onAction(@()pairAndSave(fig), 'Creating cadaver dataset...');
    end

    function onChooseCategory()
        onAction(@()chooseCategoryFile(fig), 'Loading category sheet...');
        if ishandle(fig) && ~isempty(fig.UserData.statusFilename)
            [~, name, ext] = fileparts(fig.UserData.statusFilename);
            set(categoryFileText, 'String', [name ext], ...
                'TooltipString', fig.UserData.statusFilename);
            setStatus(sprintf('Category sheet loaded: %s%s.', name, ext));
        end
    end

    function onChooseOutputDirectory()
        startFolder = pwd;
        if strlength(string(fig.UserData.config.analysisOutputDirectory)) > 0 && ...
                isfolder(fig.UserData.config.analysisOutputDirectory)
            startFolder = fig.UserData.config.analysisOutputDirectory;
        elseif ~isempty(fig.UserData.analysisFile)
            startFolder = fileparts(fig.UserData.analysisFile);
        end
        selectedFolder = uigetdir(startFolder, 'Choose analysis output folder');
        if isequal(selectedFolder, 0), return, end
        temp = fig.UserData;
        temp.config.analysisOutputDirectory = string(selectedFolder);
        fig.UserData = temp;
        [~, shortName] = fileparts(selectedFolder);
        set(outputDirectoryText, 'String', shortName, 'TooltipString', selectedFolder);
        setStatus(['Analysis output folder: ' selectedFolder]);
    end

    function onRunAnalysis()
        if ~applyAnalysisSettings(), return, end
        if ~ensureAnalysisOutputDirectory(fig)
            setStatus('Analysis cancelled: choose an output folder to run and save results.');
            return
        end
        options = getGuiAnalysisOptions(fig);
        onAction(@()runSelectedAnalysis(fig), ...
            sprintf('Running %s...', char(options.mode)));
    end

    function onConfigureTscore()
        configureTscorePredictionDialog(fig);
        if ~ishandle(fig), return, end
        set(tscoreSummaryText, 'String', ...
            formatTscoreConfigSummary(fig.UserData.config.tscore));
        onAnalysisModeChanged();
    end

    function ok = applyAnalysisSettings()
        ok = false;
        try
            registry = analysisModeRegistry();
            analysis = fig.UserData.config.analysis;
            analysis.mode = string(registry(get(modePopup, 'Value')).value);
            tissues = ["E", "T", "P"];
            analysis.tissue = tissues(get(tissuePopup, 'Value'));
            analysis.comparisonTissue = tissues(get(comparisonTissuePopup, 'Value'));
            [analysis.spectrumNumbers, analysis.spectrumCombineMode, ...
                analysis.spectrumExpression] = parseAnalysisSpectrumExpression( ...
                get(spectrumEdit, 'String'), analysis.mode);
            tagModes = ["single", "priority", "all"];
            analysis.tagSelectionMode = tagModes(get(tagModePopup, 'Value'));
            matchModes = ["exact", "prefix"];
            analysis.tagMatchMode = matchModes(get(tagMatchPopup, 'Value'));
            analysis.tags = normalizeTagSelection(get(analysisSelectedTags, 'String'));
            locModes=["records","concat","mean"];
            analysis.locationCombineMode=locModes(get(locationCombinePopup,'Value'));
            analysis.categoryAverageIncludeComparison=logical(get(categoryComparisonCheck,'Value'));
            temp = fig.UserData;
            temp.config.analysis = analysis;
            temp.config.ratioDisplay.normalizationRegion = ratioRegions(get(ratioRegionPopup, 'Value'));
            temp.config.ratioDisplay.normalizationMethod = ratioMethods(get(ratioMethodPopup, 'Value'));
            if any(analysis.mode == ["predictTscore" "groupTscore" "ratioGroupTscore"])
                if analysis.mode=="predictTscore"
                    temp.config.tscore=resolveTscoreAnalysisConfig(temp.config.tscore,analysis);
                end
                temp.config.tscore = validateTscoreConfiguration(temp.config.tscore);
                if analysis.mode == "ratioGroupTscore" && ...
                        isempty(string(temp.config.tscore.ramanRatioNames))
                    error('MainGUI:RatioGroupTscoreRatiosRequired', ...
                        ['Select at least one ratio in the T-score ', ...
                         'Feature representation section.']);
                end
            end
            fig.UserData = temp;
            getGuiAnalysisOptions(fig);
            ok = true;
        catch ME
            showError(ME);
        end
    end

    function onAnalysisModeChanged()
        registry = analysisModeRegistry();
        selected = registry(get(modePopup, 'Value'));
        switch selected.datasetType
            case 'cadaverDataset', requirement = 'Requires a generated cadaver dataset.';
            case 'spectraTable', requirement = 'Requires a generated spectra table containing variable tbl.';
            case 'locoResults', requirement = 'Requires saved LOCO results containing variable TblPred.';
        end
        set(analysisRequirement, 'String', requirement);
        isTscore = any(strcmp(selected.value, ...
            {'predictTscore','groupTscore','ratioGroupTscore'}));
        isStrict = strcmp(selected.value,'strictPredictTscore');
        set([strictConfigButton strictSummaryText],'Visible',onOff(isStrict));
        if isStrict
            set(strictSummaryText,'String',formatStrictTscoreConfigSummary(fig.UserData.config.strict));
            requirement=[requirement ' Select one exact analysis location and the P spectrum expression here; configure E, P and reconstruction below.'];
            set(analysisRequirement,'String',requirement);
        end
        isTagGroupTscore = strcmp(selected.value, 'groupTscore');
        isRatioGroupTscore = strcmp(selected.value, 'ratioGroupTscore');
        isGroupTscore = isTagGroupTscore || isRatioGroupTscore;
        set([tscoreConfigButton tscoreSummaryText], 'Visible', onOff(isTscore));
        isReconstruction = strcmp(selected.kind,'reconstruction');
        set([reconstructionConfigButton reconstructionSummaryText], 'Visible', onOff(isReconstruction));
        if isReconstruction
            requirement = [requirement ' Set spectra, tags, normalization, model and saving options in Configure reconstruction below.'];
            set(analysisRequirement,'String',requirement);
        end
        isCategoryAverage = strcmp(selected.value, 'categoryAverageSpectra');
        isCompareAverage = strcmp(selected.value, 'compareAverageSpectra');
        if isCompareAverage || isCategoryAverage
            set(spectrumLabel,'String','Offset columns / expression');
            set(spectrumEdit,'TooltipString', ...
                ['Separate panels: 1,2 or 1,2,3 (1 = 0 mm; 2 = 3 mm; 3 = 6 mm). ', ...
                 'Maximum three distinct offsets. 3-2 still means subtraction, not two panels.']);
            requirement = [requirement ' Enter 1,2,3 for separate 0-, 3-, and 6-mm panels; 1,2 selects 0 and 3 mm.'];
            set(analysisRequirement,'String',requirement);
        else
            set(spectrumLabel,'String','Spectrum expression');
            set(spectrumEdit,'TooltipString', ...
                'Normalize first, then combine. Examples: 2; 3-2 (subtract); 3+2 (add); 3|2 (concatenate).');
        end
        isFWHMDisplay = strcmp(selected.value, 'displayFWHM');
        isRatioDisplay = any(strcmp(selected.value, {'displayRatios','compareRatioPlots'})) || isFWHMDisplay || isCategoryAverage || isCompareAverage;
        set([ratioNormLabel ratioRegionPopup ratioMethodPopup], 'Visible', onOff(isRatioDisplay));
        if isCompareAverage
            set(ratioNormLabel,'String','Average comparison: normalize each offset separately before averaging');
            set(ratioMethodPopup,'TooltipString','Normalization applies independently to every selected offset.');
        elseif isCategoryAverage
            set(ratioNormLabel, 'String', ...
                'Category averages: normalize each spectrum BEFORE the expression and averaging');
            set(ratioMethodPopup, 'TooltipString', ...
                'Normalize each selected spectrum, apply the expression per cadaver, then average by category.');
        elseif isFWHMDisplay
            set(ratioNormLabel, 'String', ...
                'FWHM display: normalize each spectrum BEFORE applying the expression');
            set(ratioMethodPopup, 'TooltipString', ...
                'FWHM is calculated in each Raman band window above its local minimum baseline, in cm^-1.');
        else
            set(ratioNormLabel, 'String', ...
                'Ratio display: normalize each spectrum BEFORE applying the expression');
            set(ratioMethodPopup, 'TooltipString', ...
                'Normalization method. Displayed Raman ratios still use baseline-corrected band areas.');
        end
        if isTscore
            set(tscoreSummaryText, 'String', ...
                formatTscoreConfigSummary(fig.UserData.config.tscore));
            source = string(fig.UserData.config.tscore.predictorSource);
            if source == "demographics"
                if isGroupTscore
                    requirement = [requirement ' Group analysis requires Raman only or Raman + demographics; change the predictor source below.'];
                else
                    requirement = [requirement ' Demographic-only mode uses one row per cadaver; Raman tissue, spectrum, and tag selections are ignored.'];
                end
                set(analysisRequirement, 'String', requirement);
            elseif isRatioGroupTscore
                requirement = [requirement ' Each checked Raman ratio is evaluated separately using the selected tag or priority-tag fallback.'];
                set(analysisRequirement, 'String', requirement);
            else
                requirement = [requirement ' Configure Raman/demographic predictors and models below.'];
                set(analysisRequirement, 'String', requirement);
            end
        end
        onDisplayNormalizationChanged();
        tissueState = onOff(selected.usesTissue);
        comparisonState = onOff(selected.usesComparison);
        tagState = onOff(strcmp(selected.kind, 'datasetAnalysis') && ...
            ~strcmp(selected.value, 'printDemographicsTable'));
        publication=strcmp(selected.value,'predictTscore') && ...
            string(fig.UserData.config.tscore.figureMode)=="locationComparison";
        if isTscore && ~isGroupTscore && ~publication && ...
                string(fig.UserData.config.tscore.predictorSource) == "demographics"
            tissueState = 'off';
            tagState = 'off';
        end
        set(tissuePopup, 'Enable', tissueState);
        set(categoryComparisonCheck,'Visible',onOff(isCategoryAverage));
        set(locationCombinePopup,'Visible',onOff(~isCategoryAverage));
        if isCategoryAverage
            comparisonState=onOff(logical(get(categoryComparisonCheck,'Value')));
        end
        set(comparisonTissuePopup, 'Enable', comparisonState);
        set([spectrumEdit tagMatchPopup ...
            analysisAvailableTags analysisSelectedTags], 'Enable', tagState);
        set(locationCombinePopup,'Enable',onOff(strcmp(selected.value,'predictTscore') && ~publication));
        fusionActive=strcmp(selected.value,'predictTscore') && ...
            (get(locationCombinePopup,'Value')~=1 || publication);
        if fusionActive
            set(tagModePopup,'Value',3,'Enable','off');
            set(tagMatchPopup,'Value',1,'Enable','off');
            set([analysisAvailableTags analysisSelectedTags],'Enable','on');
            set(tagHelp,'String','Select all locations here. Complete donors only; panel choices are in Figure settings.');
        elseif selected.requiresAllTags
            set(tagModePopup, 'Value', 3, 'Enable', 'off');
            set(tagHelp, 'String', ...
                'Every selected tag is used; the selected-tag order controls the spatial axis.');
            set(analysisRequirement, 'String', ...
                [requirement ' Select and order the spatial tags to plot.']);
        elseif isTagGroupTscore
            set(tagModePopup, 'Value', 2, 'Enable', 'off');
            set(tagHelp, 'String', ...
                'Each selected tag is analyzed separately; priority order controls table order.');
            set(analysisRequirement, 'String', ...
                [requirement ' Select one or more priority tags for the command-window table.']);
        else
            set(tagModePopup, 'Enable', tagState);
            onTagModeChanged();
        end
        if isTscore
            set(runButton, 'String', 'Run configured T-score prediction');
        elseif strcmp(selected.kind, 'datasetAnalysis')
            set(runButton, 'String', 'Run selected analysis');
        elseif strcmp(selected.kind, 'reconstruction')
            set(runButton, 'String', 'Run spectral reconstruction');
        elseif strcmp(selected.kind, 'spectraTable')
            set(runButton, 'String', 'Run LOCO T-score prediction');
        else
            set(runButton, 'String', 'Plot saved LOCO results');
        end
    end

    function onDisplayNormalizationChanged()
        noNormalization = ratioRegions(get(ratioRegionPopup, 'Value')) == "none";
        set(ratioMethodPopup, 'Enable', onOff(~noNormalization));
        registry = analysisModeRegistry();
        selectedMode = string(registry(get(modePopup, 'Value')).value);
        if selectedMode == "compareAverageSpectra"
            if noNormalization
                label = 'Average comparison: use loaded intensities separately for each offset';
            else
                label = 'Average comparison: normalize each offset separately before averaging';
            end
        elseif selectedMode == "displayFWHM"
            if noNormalization
                label = 'FWHM display: use loaded intensities, apply the expression, then calculate widths';
            else
                label = 'FWHM display: normalize each spectrum BEFORE applying the expression';
            end
        elseif selectedMode == "categoryAverageSpectra"
            if noNormalization
                label = 'Category averages: use loaded intensities, apply the expression, then average';
            else
                label = 'Category averages: normalize each spectrum BEFORE the expression and averaging';
            end
        else
            if noNormalization
                label = 'Ratio display: use loaded intensities, apply the expression, then calculate ratios';
            else
                label = 'Ratio display: normalize each spectrum BEFORE applying the expression';
            end
        end
        set(ratioNormLabel, 'String', label);
    end

    function addTags()
        source = cellstr(string(get(analysisAvailableTags, 'String')));
        if isempty(source) || isequal(source, {'No tags found'}), return, end
        idx = get(analysisAvailableTags, 'Value');
        idx = idx(idx <= numel(source));
        chosen = source(idx);
        if get(tagModePopup, 'Value') == 1
            chosen = chosen(1);
        else
            chosen = [cellstr(string(get(analysisSelectedTags, 'String'))); chosen(:)];
        end
        chosen = normalizeTagSelection(chosen);
        set(analysisSelectedTags, 'String', chosen, 'Value', max(1,numel(chosen)));
    end

    function removeTags()
        current = cellstr(string(get(analysisSelectedTags, 'String')));
        if isempty(current), return, end
        idx = get(analysisSelectedTags, 'Value');
        idx = idx(idx <= numel(current));
        current(idx) = [];
        if isempty(current)
            set(analysisSelectedTags, 'String', {}, 'Value', 1);
        else
            set(analysisSelectedTags, 'String', current, ...
                'Value', min(idx(1),numel(current)));
        end
    end

    function moveTag(direction)
        current = cellstr(string(get(analysisSelectedTags, 'String')));
        idx = get(analysisSelectedTags, 'Value');
        if numel(current) < 2 || numel(idx) ~= 1, return, end
        target = idx + direction;
        if target < 1 || target > numel(current), return, end
        current([idx target]) = current([target idx]);
        set(analysisSelectedTags, 'String', current, 'Value', target);
    end

    function onTagModeChanged()
        messages = {'One exact tag is used for each cadaver.', ...
            'The first available tag in this ordered list is used.', ...
            'Every selected tag is used; the selected-tag order controls spatial plots.'};
        set(tagHelp, 'String', messages{get(tagModePopup, 'Value')});
        if get(tagModePopup, 'Value') == 1
            current = cellstr(string(get(analysisSelectedTags, 'String')));
            if numel(current) > 1
                set(analysisSelectedTags, 'String', current(1), 'Value', 1);
            end
        end
    end

    function clearCurrentDisplay()
        cla(ax); grid(ax, 'on'); hold(ax, 'on');
        xlabel(ax, 'Wavenumber (cm^{-1})'); ylabel(ax, 'Intensity (a.u.)');
        title(ax, '');
        setStatus('Individual spectrum plot cleared.');
    end

    function onAction(action, message)
        setStatus(message); drawnow;
        try
            action();
            if ishandle(fig), setStatus('Ready.'); end
        catch ME
            showError(ME);
        end
    end

    function showError(ME)
        setStatus(['Error: ' ME.message]);
        errordlg(ME.message, 'Bone Raman Workflow', 'modal');
    end

    function setStatus(message)
        if ishandle(statusText), set(statusText, 'String', message); drawnow limitrate; end
    end
end

function makeLabel(parent, textValue, position)
uicontrol('Parent', parent, 'Style', 'text', 'Units', 'normalized', ...
    'Position', position, 'String', textValue, 'HorizontalAlignment', 'left', ...
    'FontSize', 9, 'FontWeight', 'bold', 'BackgroundColor', get(parent,'BackgroundColor'));
end

function control = valueText(parent, textValue, position)
control = uicontrol('Parent', parent, 'Style', 'text', 'Units', 'normalized', ...
    'Position', position, 'String', textValue, 'HorizontalAlignment', 'left', ...
    'FontSize', 10, 'ForegroundColor', [0.18 0.28 0.38], ...
    'BackgroundColor', [0.94 0.96 0.98]);
end

function value = onOff(tf)
if tf, value = 'on'; else, value = 'off'; end
end

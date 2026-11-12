function context = buildAnalysisContext(fig)
%BUILDANALYSISCONTEXT Validate GUI state and assemble shared analysis input.

options = getGuiAnalysisOptions(fig);
validateAnalysisRequest(options);
settings = analysisDefaultSettings();
ud = fig.UserData;
if options.mode == "strictPredictTscore" && isfield(ud.config,'strict')
    settings.strict = validateStrictTscoreConfiguration(ud.config.strict);
end
if options.mode=="predictTscore"
    ud.config.tscore=resolveTscoreAnalysisConfig(ud.config.tscore,options);
end
if options.mode == "ratioGroupTscore" && ...
        isempty(string(ud.config.tscore.ramanRatioNames))
    error('MainGUI:RatioGroupTscoreRatiosRequired', ...
        'Select at least one ratio in the T-score Feature representation section.');
end
if any(options.mode == ["predictTscore" "groupTscore" "ratioGroupTscore"])
    settings = applyTscoreConfigToSettings(settings, ud.config.tscore);
end
if options.mode=="predictTscore" && ud.config.tscore.figureMode=="locationComparison"
    plan=tscoreFigurePlan(ud.config.tscore,options.tags);
    panelTags=unique([plan.tags],'stable');
    settings.feature.locationTags=panelTags;
    if isempty(panelTags)
        settings.feature.locationCombineMode="records";
        settings.feature.useRaman=false;
    else
        settings.feature.useRaman=true;
    end
end
settings.feature.spectrumCombineMode = options.spectrumCombineMode;
if any(options.mode == ["displayRatios" "displayFWHM" "compareRatioPlots" "categoryAverageSpectra" "compareAverageSpectra"])
    defaults = guiDefaultConfig();
    ratioConfig = defaults.ratioDisplay;
    if isfield(ud.config, 'ratioDisplay')
        ratioConfig = ud.config.ratioDisplay;
    end
    settings = applyRatioDisplayConfigToSettings(settings, ratioConfig);
end
settings.feature.normalizationRegion = validatestring(settings.feature.normalizationRegion, ...
    {'none','PO4','CO3','CH2','AmideI','AmideIII','FullSpectrum'});
settings.feature.normalizationMethod = validatestring(settings.feature.normalizationMethod, ...
    {'peak','peakBaseline','area'});
settings.feature.tscoreRatioNames = localNormalizeTscoreRatioSelection(settings.feature);
validateSpectrumCombinationSettings(options, settings.feature);

if ~isfield(ud,'statusMap') || isempty(ud.statusMap)
    chooseCategoryFile(fig);
    ud = fig.UserData;
end
if ~isfield(ud,'statusMap') || isempty(ud.statusMap)
    error('MainGUI:CategorySheetRequired', ...
        'Load a category sheet before running this analysis.');
end

Tcat = readtable(ud.statusFilename, 'VariableNamingRule','preserve', ...
    'TextType','string');
[cads, datasetFile] = localLoadCadaverStruct(ud);
if isempty(cads)
    error('MainGUI:EmptyCadaverDataset', 'The loaded cadaver dataset is empty.');
end

outputDirectory = "";
if isfield(ud.config, 'analysisOutputDirectory')
    outputDirectory = string(ud.config.analysisOutputDirectory);
end
context = struct('fig',fig, 'options',options, 'settings',settings, ...
    'ud',ud, 'Tcat',Tcat, 'cads',cads, 'datasetFile',datasetFile, ...
    'outputDirectory',outputDirectory, 'records',[]);

recordModes = ["displayRatios","displayFWHM","detectOutliers","predictTscore", ...
    "compareAverageSpectra","categoryAverageSpectra","compareRatioPlots", ...
    "visualizeAutoscaling","compareTscorePlots", ...
    "compareClassificationPlots","sweepTscoreSettings", ...
    "spatialCategorySpectra","spatialMetricProfiles"];
if any(options.mode == recordModes)
    requireRaman = true;
    if options.mode == "predictTscore"
        requireRaman = settings.feature.useRaman;
    end
    context.records = collectRecords(context, options.tissue, requireRaman);
    if isempty(context.records)
        if requireRaman
            error('MainGUI:NoUsableRecords', ...
                'No usable %s records matched spectrum expression %s and the selected tags.', ...
                options.tissue, options.spectrumExpression);
        else
            error('MainGUI:NoUsableRecords', ...
                'No cadavers with usable T-score and demographic records were found.');
        end
    end
end
end

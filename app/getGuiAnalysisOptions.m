function options = getGuiAnalysisOptions(fig)
%GETGUIANALYSISOPTIONS Return validated analysis options from GUI state.

defaults = guiDefaultConfig();
options = defaults.analysis;
expressionSource = options.spectrumExpression;
if nargin >= 1 && ~isempty(fig) && ishandle(fig)
    ud = fig.UserData;
    if isfield(ud, 'config') && isfield(ud.config, 'analysis')
        userAnalysis = ud.config.analysis;
        names = fieldnames(ud.config.analysis);
        for k = 1:numel(names), options.(names{k}) = ud.config.analysis.(names{k}); end
        if isfield(userAnalysis, 'spectrumExpression') && ...
                strlength(strtrim(string(userAnalysis.spectrumExpression))) > 0
            expressionSource = userAnalysis.spectrumExpression;
        else
            expressionSource = userAnalysis.spectrumNumbers;
        end
    end
end
options.mode = string(options.mode);
options.tissue = upper(string(options.tissue));
options.comparisonTissue = upper(string(options.comparisonTissue));
[options.spectrumNumbers, options.spectrumCombineMode, ...
    options.spectrumExpression] = parseAnalysisSpectrumExpression(expressionSource, options.mode);
options.tags = normalizeTagSelection(options.tags);
options.tagSelectionMode = lower(string(options.tagSelectionMode));
options.tagMatchMode = lower(string(options.tagMatchMode));
options.locationFusionEnabled=false;
if nargin>=1 && ~isempty(fig) && ishandle(fig) && options.mode=="predictTscore"
    tc=resolveTscoreAnalysisConfig(ud.config.tscore,options);
    if tc.locationCombineMode~="records"
        options.locationFusionEnabled=true;
        options.tagSelectionMode="all"; options.tagMatchMode="exact";
    end
end
registry = analysisModeRegistry();
if ~any(options.mode == string({registry.value}))
    error('MainGUI:InvalidAnalysisMode', 'Unknown analysis mode: %s', options.mode);
end
if ~any(options.tissue == ["E", "T", "P"])
    error('MainGUI:InvalidTissue', 'Tissue must be E, T, or P.');
end
if ~any(options.comparisonTissue == ["E", "T", "P"])
    error('MainGUI:InvalidComparisonTissue', ...
        'Comparison tissue must be E, T, or P.');
end
if ~any(options.tagSelectionMode == ["single", "priority", "all"])
    error('MainGUI:InvalidTagSelectionMode', 'Invalid tag selection mode.');
end
if ~any(options.tagMatchMode == ["exact", "prefix"])
    error('MainGUI:InvalidTagMatchMode', 'Invalid tag match mode.');
end
if options.tagSelectionMode == "single" && numel(options.tags) ~= 1
    error('MainGUI:SingleTagRequired', ...
        'Single-tag mode requires exactly one selected tag.');
end
end

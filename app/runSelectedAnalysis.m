function runSelectedAnalysis(fig)
%RUNSELECTEDANALYSIS Dispatch the Analysis tab's single Run button.

options = getGuiAnalysisOptions(fig);
registry = analysisModeRegistry();
index = find(strcmp({registry.value}, char(options.mode)), 1);
if isempty(index)
    error('MainGUI:InvalidAnalysisMode', 'Unknown analysis mode: %s', options.mode);
end
definition = registry(index);

ud = fig.UserData;
if ~isfield(ud, 'analysisFile') || ~isfile(ud.analysisFile) || ...
        ~isfield(ud, 'analysisDatasetType')
    error('MainGUI:NoAnalysisDataset', ...
        'Load a generated MAT dataset in the Analysis tab first.');
end
if string(ud.analysisDatasetType) ~= string(definition.datasetType)
    error('MainGUI:WrongDatasetType', ...
        'This analysis requires %s, but the loaded file is %s.', ...
        localTypeLabel(definition.datasetType), localTypeLabel(ud.analysisDatasetType));
end
% Also guard direct dispatcher calls, not only the main Run-button callback.
if ~ensureAnalysisOutputDirectory(fig), return, end

switch definition.kind
    case 'datasetAnalysis'
        validateAnalysisRequest(options);
        runCadaverDatasetAnalysis(fig);
    case 'reconstruction'
        runReconstructionAnalysis(fig);
    case 'spectraTable'
        locoTscoreCallback(fig);
    case 'locoResults'
        plotSavedLOCOscatter(fig);
    otherwise
        error('MainGUI:UnknownAnalysisKind', ...
            'No dispatcher is registered for %s.', definition.kind);
end
end

function label = localTypeLabel(value)
switch string(value)
    case "cadaverDataset", label = 'a cadaver dataset';
    case "spectraTable", label = 'a spectra table';
    case "locoResults", label = 'saved LOCO results';
    otherwise, label = char(string(value));
end
end

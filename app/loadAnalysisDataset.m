function loadAnalysisDataset(fig, ~)
%LOADANALYSISDATASET Load one generated dataset for the Analysis tab.

if nargin < 1 || isempty(fig) || ~ishandle(fig)
    error('MainGUI:InvalidFigure', 'A valid GUI figure is required.');
end

startFolder = pwd;
ud = fig.UserData;
if isfield(ud, 'analysisFile') && isfile(ud.analysisFile)
    startFolder = fileparts(ud.analysisFile);
end
[fileName, folder] = uigetfile({'*.mat','MAT datasets (*.mat)'}, ...
    'Select generated analysis dataset', startFolder);
if isequal(fileName, 0), return, end

fullName = fullfile(folder, fileName);
loaded = load(fullName);
[datasetType, summary] = localIdentifyDataset(loaded);

ud.analysisFile = fullName;
ud.analysisData = loaded;
ud.analysisDatasetType = datasetType;
ud.analysisSummary = summary;
ud.lastPairedFile = fullName;
fig.UserData = ud;

localUpdateLabels(fig, fileName, datasetType, summary);
refreshAnalysisTags(fig);
end

function [datasetType, summary] = localIdentifyDataset(loaded)
if isfield(loaded, 'cads')
    values = loaded.cads;
    datasetType = "cadaverDataset";
elseif isfield(loaded, 'cadavers')
    values = loaded.cadavers;
    datasetType = "cadaverDataset";
elseif isfield(loaded, 'pairedCadavers')
    values = loaded.pairedCadavers;
    datasetType = "cadaverDataset";
elseif isfield(loaded, 'tbl') && istable(loaded.tbl)
    values = loaded.tbl;
    datasetType = "spectraTable";
elseif isfield(loaded, 'TblPred') && istable(loaded.TblPred)
    values = loaded.TblPred;
    datasetType = "locoResults";
else
    error('MainGUI:UnsupportedDataset', [ ...
        'The selected MAT file is not a recognized generated dataset. ' ...
        'Expected cads/cadavers/pairedCadavers, tbl, or TblPred.']);
end

switch datasetType
    case "cadaverDataset"
        nCadavers = numel(values);
        if nCadavers == 0
            error('MainGUI:EmptyDataset', 'The cadaver dataset is empty.');
        end
        summary = sprintf('%d cadaver record(s)', nCadavers);
    case "spectraTable"
        summary = sprintf('%d spectrum row(s)', height(values));
    case "locoResults"
        summary = sprintf('%d prediction row(s)', height(values));
end
end

function localUpdateLabels(fig, fileName, datasetType, summary)
ud = fig.UserData;
if ~isfield(ud, 'controls'), return, end
if isfield(ud.controls, 'analysisFileName') && ishandle(ud.controls.analysisFileName)
    set(ud.controls.analysisFileName, 'String', fileName, 'TooltipString', ud.analysisFile);
end
if isfield(ud.controls, 'analysisDatasetType') && ishandle(ud.controls.analysisDatasetType)
    labels = struct('cadaverDataset','Cadaver dataset', ...
        'spectraTable','Spectra table', 'locoResults','LOCO results');
    set(ud.controls.analysisDatasetType, 'String', labels.(char(datasetType)));
end
if isfield(ud.controls, 'analysisSummary') && ishandle(ud.controls.analysisSummary)
    set(ud.controls.analysisSummary, 'String', summary);
end
end

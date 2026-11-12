function runReconstructionAnalysis(fig, model)
%RUNRECONSTRUCTIONANALYSIS Run modifiedPLS with the selected model.

ud = fig.UserData;
if ~isfield(ud, 'analysisData') || ...
        string(ud.analysisDatasetType) ~= "cadaverDataset"
    error('MainGUI:CadaverDatasetRequired', ...
        'Load a generated cadaver dataset in the Analysis tab first.');
end
if ~isfield(ud.config, 'analysisOutputDirectory') || ...
        strlength(string(ud.config.analysisOutputDirectory)) == 0
    error('MainGUI:OutputDirectoryRequired', ...
        'Choose an analysis output folder before running reconstruction.');
end

loaded = ud.analysisData;
if isfield(loaded,'cads'), cads = loaded.cads;
elseif isfield(loaded,'cadavers'), cads = loaded.cadavers;
elseif isfield(loaded,'pairedCadavers'), cads = loaded.pairedCadavers;
else, error('MainGUI:InvalidCadaverDataset','No cadaver variable was found.');
end

config = reconstructionDefaultConfig();
if isfield(ud.config,'reconstruction'), config = ud.config.reconstruction; end
config = validateReconstructionConfiguration(config);
if nargin < 2 || strlength(string(model)) == 0
    model = config.reconstructionModel;
else
    model = string(validatestring(model,{'PLS','MLP','KRR_RBF','PCA_MLP'}));
    config.reconstructionModel = model; % Compatibility for direct callers.
end
outputFolder = char(ud.config.analysisOutputDirectory);
if config.createRunSubfolder
    [~,suffix] = fileparts(tempname);
    runName = sprintf('reconstruction_%s_%s_%s',model, ...
        char(datetime('now','Format','yyyyMMdd_HHmmss')),suffix(end-5:end));
    outputFolder = fullfile(outputFolder,runName);
end
settingsFile = fullfile(outputFolder,'reconstruction_settings.json');
targets = {settingsFile, fullfile(outputFolder,char(config.metricsFileName))};
if model=="PCA_MLP", targets{end+1}=fullfile(outputFolder,'reconstruction_tuning.json'); end
if any(config.saveOutputMode == ["single","both"])
    targets{end+1} = fullfile(outputFolder,char(config.combinedOutputFileName));
end
if any(config.saveOutputMode == ["individual","both"])
    for k = 1:numel(cads)
        id = char(string(cads(k).id));
        if isempty(regexp(id,'^[A-Za-z0-9_-]+$','once'))
            error('MainGUI:ReconstructionFilename','Cadaver ID is not safe for an individual filename: %s',id);
        end
        targets{end+1} = fullfile(outputFolder,[id '_P.mat']); %#ok<AGROW>
    end
end
if any(cellfun(@isfile,targets))
    error('MainGUI:ReconstructionOutputExists', ...
        'Output files already exist. Enable a new run subfolder or choose another output directory.');
end
if ~isfolder(outputFolder), mkdir(outputFolder); end
metadata = struct('settings',config,'model',string(model), ...
    'sourceDataset',string(ud.analysisFile),'outputDirectory',string(outputFolder), ...
    'matlabVersion',string(version),'validation',"leave-one-cadaver-out", ...
    'note',"Reconstruction-only validation; saved P spectra do not replace reconstruction inside downstream T-score folds.", ...
    'status',"running");
writeMetadata(settingsFile,metadata);
try
    modifiedPLS(cads, outputFolder, model, config);
    metadata.status = "complete";
catch ME
    metadata.status = "failed";
    metadata.error = string(ME.message);
    writeMetadata(settingsFile,metadata);
    rethrow(ME);
end
writeMetadata(settingsFile,metadata);
ud.lastReconstructionOutputDirectory = outputFolder;
fig.UserData = ud;
fprintf('Reconstruction saved in: %s\n',outputFolder);
end

function writeMetadata(filename,metadata)
fid = fopen(filename,'w');
if fid<0, error('MainGUI:ReconstructionSave','Cannot write settings file: %s',filename); end
cleanup = onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s',jsonencode(metadata,'PrettyPrint',true));
end

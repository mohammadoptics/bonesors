function ready=ensureAnalysisOutputDirectory(fig,chooseFolder)
% Ask before computation; retain an existing folder and stop on cancellation.
% Optional picker injection permits testing without opening a native dialog.
if nargin<2, chooseFolder=@uigetdir; end
ready=false; ud=fig.UserData;
folder="";
if isfield(ud.config,'analysisOutputDirectory')
    folder=strtrim(string(ud.config.analysisOutputDirectory));
end
if isscalar(folder) && ~ismissing(folder) && strlength(folder)>0 && isfolder(folder)
    ready=true; return
end
startFolder=pwd;
if isfield(ud,'analysisFile') && isfile(string(ud.analysisFile))
    startFolder=fileparts(char(ud.analysisFile));
end
selected=chooseFolder(startFolder,'Choose where to save analysis results before running');
if isequal(selected,0) || isempty(selected)
    fprintf('Analysis cancelled: no output folder was selected.\n');
    return
end
folder=string(selected);
if ~isscalar(folder) || ismissing(folder) || ~isfolder(folder)
    error('MainGUI:InvalidOutputDirectory','Select an existing folder for analysis results.');
end
% Read current state again after the modal folder chooser closes.
ud=fig.UserData; ud.config.analysisOutputDirectory=folder;
if isfield(ud,'controls') && isfield(ud.controls,'outputDirectoryText') && ...
        isgraphics(ud.controls.outputDirectoryText)
    [~,name]=fileparts(char(folder)); if isempty(name), name=char(folder); end
    set(ud.controls.outputDirectoryText,'String',name,'TooltipString',char(folder));
end
fig.UserData=ud; ready=true;
fprintf('Analysis results folder: %s\n',folder);
end

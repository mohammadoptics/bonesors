% ----------------- new loadMatFiles.m -----------------
function loadMatFiles(src, ~)
% Accept either the GUI figure or a child control.
if strcmpi(get(src, 'Type'), 'figure')
    fig = src;
else
    fig = ancestor(src, 'figure');
end

ud = fig.UserData;
[oldPointer, cleanupPointer] = localBusyPointer(fig); %#ok<ASGLU>
% ------------------------------------------------------------------
[files,path] = uigetfile('*.mat','Select MATLAB .mat files', ...
                         'MultiSelect','on');
if isequal(files,0),  return, end
if ischar(files),     files = {files}; end   % force cell array
% ------------------------------------------------------------------
if ~isfield(ud, 'filePaths'), ud.filePaths = {}; end
for k = 1:numel(files)
    try
        full = fullfile(path, files{k});
        if isfield(ud, 'config') && ud.config.files.skipDuplicatePaths && ...
                any(strcmpi(ud.filePaths, full))
            warning('Skipping already-loaded file: %s', files{k});
            continue
        end
        loaded = load(full);
        if isempty(fieldnames(loaded))
            warning('Skipping empty MAT file: %s', files{k});
            continue
        end
        ud.data{end+1}      = loaded;
        ud.fileNames{end+1} = files{k};
        ud.filePaths{end+1} = full;
    catch ME
        warning('Failed to load %s: %s', files{k}, ME.message);
    end
end
fig.UserData = ud;                     % write changes back
refreshLists(fig);                     % see below
end

function refreshLists(fig)
ud = fig.UserData;
if ~isempty(ud.fileNames)
    set(ud.fileListBox,'String',ud.fileNames,'Value',1);
    updateDataFieldListbox(fig);       % now you pass FIG
    refreshAvailableTags(fig);
else
    set(ud.fileListBox,'String',{'No Files Loaded'});
    set(ud.dataFieldListbox,'String',{'No Data Fields'});
    set(ud.spectrumListbox,'String',{'No Spectra'});
end
end

function [oldPointer, cleanupPointer] = localBusyPointer(fig)
oldPointer = get(fig, 'Pointer');
set(fig, 'Pointer', 'watch');
drawnow;
cleanupPointer = onCleanup(@()localRestorePointer(fig, oldPointer));
end

function localRestorePointer(fig, pointer)
if ishandle(fig), set(fig, 'Pointer', pointer); end
end








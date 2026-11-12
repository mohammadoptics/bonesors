function [predictions, diagnostics] = predictCompactReconstruction(X,Y,rowIDs,c,saveDir)
% Fresh nested donor-wise compact PCA/MLP reconstruction via checked backend.
python = char(c.compactPython);
target = fullfile(saveDir,'reconstruction_tuning.json');
if isfile(target), error('MainGUI:ReconstructionOutputExists','Tuning file already exists; choose a new output folder.'); end
if ~isfile(python)
    error('MainGUI:CompactPythonUnavailable', ...
        'Compact PCA + MLP requires Python with NumPy, SciPy and threadpoolctl. Set its executable in Configure reconstruction > Compact PCA + MLP.');
end
backend = fullfile(fileparts(mfilename('fullpath')),'compact_mlp_reconstruct.py');
inputFile = [tempname '.mat']; outputFile = [tempname '.mat']; metaFile = [tempname '.json'];
cleanup = onCleanup(@()cleanFiles({inputFile,outputFile,metaFile})); %#ok<NASGU>
rowIDs = cellstr(string(rowIDs(:)));
configJson = jsonencode(c);
save(inputFile,'X','Y','rowIDs','configJson','-v7');
paths = {python,backend,inputFile,outputFile,metaFile};
if any(cellfun(@(s)~isempty(regexp(s,'["\r\n%]','once')),paths))
    error('MainGUI:CompactPath','Backend paths cannot contain quotes, percent signs or line breaks.');
end
command = sprintf('"%s" -I -u "%s" --input "%s" --output "%s" --metadata "%s"',paths{:});
fprintf('Compact PCA + MLP: fitting fresh nested donor folds; this may take several minutes.\n');
drawnow;
[status,message] = system(command,'-echo');
if status~=0 || ~isfile(outputFile) || ~isfile(metaFile)
    error('MainGUI:CompactBackend','Compact MLP failed (no fallback used): %s',message);
end
saved = load(outputFile,'predictions'); predictions = saved.predictions;
if ~isequal(size(predictions),size(Y)) || any(~isfinite(predictions),'all')
    error('MainGUI:CompactPrediction','Compact backend returned invalid prediction dimensions or values.');
end
diagnostics = jsondecode(fileread(metaFile));
if diagnostics.final_nonconverged_fits>0 || diagnostics.inner_nonconverged_fits>0
    warning('MainGUI:CompactConvergence','Compact MLP has convergence warnings. Inspect reconstruction_tuning.json before interpreting results.');
end
[ok,msg] = copyfile(metaFile,target);
if ~ok, error('MainGUI:ReconstructionSave','Cannot save tuning diagnostics: %s',msg); end
end

function cleanFiles(paths)
for i=1:numel(paths)
    if isfile(paths{i}), delete(paths{i}); end
end
end

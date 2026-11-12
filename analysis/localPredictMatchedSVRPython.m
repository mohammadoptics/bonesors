function [yPred,tuning] = localPredictMatchedSVRPython(X,y,cadIDs,settings,blockSizes)
% MATLAB owns feature extraction/plotting; sklearn owns the matched SVR fit.
% Dedicated temporary input/output files; no historical predictions are read.
python=char(settings.matchedSVRPython);
if ~isfile(python)
    error('MainGUI:MatchedPython','Matched SVR needs Python with numpy/scipy/scikit-learn. Set its executable on the Validation tab. See MATCHED_TSCORE_README.md.');
end
if contains(python,'"'), error('MainGUI:MatchedPython','Invalid Python executable path.'); end
ids=unique(string(cadIDs(:)),'stable'); [~,groups]=ismember(string(cadIDs(:)),ids);
K=settings.matchedInnerFolds; seed=settings.randomSeed;
standardize=settings.standardizePredictors;
cGrid=settings.svrBoxConstraintGrid; eGrid=settings.svrEpsilonGrid; sGrid=settings.svrKernelScaleGrid;
inputFile=[tempname '.mat']; outputFile=[tempname '.json'];
cleanup=onCleanup(@()removeTemporary(inputFile,outputFile)); %#ok<NASGU>
save(inputFile,'X','y','groups','K','seed','standardize','blockSizes','cGrid','eGrid','sGrid','-v7');
script=fullfile(fileparts(mfilename('fullpath')),'matched_svr.py');
command=sprintf('"%s" -I -u "%s" --input "%s" --output "%s"',python,script,inputFile,outputFile);
fprintf('Matched SVR: fresh scikit-learn nested CV; Python: %s\n',python);
drawnow;
[status,output]=system(command,'-echo');
if status~=0 || ~isfile(outputFile)
    error('MainGUI:MatchedPython','Matched SVR failed. Check the configured Python environment.\n%s',output);
end
raw=jsondecode(fileread(outputFile)); yPred=raw.predictions(:);
if numel(yPred)~=numel(y) || any(~isfinite(yPred))
    error('MainGUI:MatchedPython','Python returned invalid predictions.');
end
tuning=raw.tuning;
for k=1:numel(tuning)
    tuning(k).CadaverID=ids(tuning(k).Group);
    tuning(k).InnerCadaverIDs=ids(tuning(k).InnerGroups);
    tuning(k).Rank=NaN;
    tuning(k).Environment=raw.environment; tuning(k).Solver=raw.solver;
end
end
function removeTemporary(varargin)
for k=1:nargin
    if isfile(varargin{k}), delete(varargin{k}); end
end
end

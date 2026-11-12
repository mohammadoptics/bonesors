function folder = localSaveRidgeTscoreRun(context,result,feature)
%LOCALSAVERIDGETSCORERUN Save auditable predictions without overwriting a run.
root=char(context.outputDirectory);
if ~isfolder(root), mkdir(root); end
[~,suffix]=fileparts(tempname(root));
folder=fullfile(root,['tscore_RIDGE_' datestr(now,'yyyymmdd_HHMMSS') '_' suffix]);
mkdir(folder);
ids=result.cadIDs; alpha=nan(numel(ids),1);
for k=1:numel(result.tuning), alpha(ids==result.tuning(k).CadaverID)=result.tuning(k).Alpha; end
predictedCategory=localTscoreToCategory(result.yPred);
predictions=table(ids,result.cats,result.y,result.yPred,predictedCategory,alpha, ...
    'VariableNames',{'CadaverID','Category','MeasuredTscore','PredictedTscore','PredictedCategory','Alpha'});
writetable(predictions,fullfile(folder,'predictions.csv'));
configuration=struct('datasetFile',context.datasetFile,'categoryFile',context.ud.statusFilename, ...
    'analysis',context.options,'feature',feature, ...
    'validation','Outer donor LOCO; inner grouped K-fold; NumPy-compatible shuffle on input donor order');
save(fullfile(folder,'result.mat'),'result','configuration');
fid=fopen(fullfile(folder,'settings.json'),'w');
if fid<0, error('MainGUI:RidgeSave','Cannot write ridge settings.'); end
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s',jsonencode(configuration,'PrettyPrint',true));
fprintf('Ridge results saved: %s\n',folder);
end

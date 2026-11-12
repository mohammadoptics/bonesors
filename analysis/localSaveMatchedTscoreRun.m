function folder=localSaveMatchedTscoreRun(context,result,feature)
% Save each matched PLS/SVR run independently; do not overwrite older runs.
root=char(context.outputDirectory); if ~isfolder(root), mkdir(root); end
[~,suffix]=fileparts(tempname(root));
folder=fullfile(root,['tscore_' char(upper(string(feature.tscoreModel))) '_' ...
    datestr(now,'yyyymmdd_HHMMSS') '_' suffix]); mkdir(folder);
ids=result.cadIDs; count=numel(ids);
rank=nan(count,1); C=rank; epsilon=rank; scale=rank;
for k=1:numel(result.tuning)
    rows=ids==result.tuning(k).CadaverID;
    rank(rows)=result.tuning(k).Rank; C(rows)=result.tuning(k).BoxConstraint;
    epsilon(rows)=result.tuning(k).Epsilon; scale(rows)=result.tuning(k).KernelScale;
end
predictedCategory=localTscoreToCategory(result.yPred);
predictions=table(ids,result.cats,result.y,result.yPred,predictedCategory,rank,C,epsilon,scale, ...
    'VariableNames',{'CadaverID','Category','MeasuredTscore','PredictedTscore', ...
    'PredictedCategory','PLSComponents','C','Epsilon','KernelSigma'});
writetable(predictions,fullfile(folder,'predictions.csv'));
configuration=struct('datasetFile',context.datasetFile,'categoryFile',context.ud.statusFilename, ...
    'analysis',context.options,'feature',feature, ...
    'validation','Outer donor LOCO; complete inner grid; NumPy shuffled K-fold on input donor order; training-only imputation and scaling', ...
    'svrKernel','exp(-squared_distance/(2*sigma^2)); sigma is the grid value');
save(fullfile(folder,'result.mat'),'result','configuration');
fid=fopen(fullfile(folder,'settings.json'),'w');
if fid<0, error('MainGUI:TscoreSave','Cannot write matched-run settings.'); end
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s',jsonencode(configuration,'PrettyPrint',true));
fprintf('%s results saved: %s\n',upper(string(feature.tscoreModel)),folder);
end

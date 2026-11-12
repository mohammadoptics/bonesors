function runs=analysisTscorePublication(context)
% Publication comparison is an output option of Predict T-score.
models=upper(string(context.ud.config.tscore.models)); runs=struct('model',{},'panels',{},'cohort',{},'figure',{},'folder',{});
for model=models
    [panels,cohort]=localComputeTscorePublication(context,model);
    [caption,classification]=localSummarizeTscorePublication(panels,context.options,model);
    fprintf('\nFigure caption (%s)\n%s\n\n',model,caption);
    fprintf('Correct classifications by panel (%s; held-out predictions)\n',model);
    fprintf('Class columns show correct / total within each reference category.\n');
    fprintf('GUI thresholds: Normal > -1; Osteopenia > -2.5 and <= -1; Osteoporosis <= -2.5.\n');
    disp(classification);
    fig=localPlotTscorePublication(panels,context.options,model); folder="";
    if strlength(string(context.outputDirectory))>0
        root=char(context.outputDirectory); if ~isfolder(root), mkdir(root); end
        [~,suffix]=fileparts(tempname(root));
        folder=string(fullfile(root,['tscore_comparison_' char(model) '_' datestr(now,'yyyymmdd_HHMMSS') '_' suffix]));
        mkdir(folder);
        % Save numerical results first, so they survive a graphics-export failure.
        configuration=struct('datasetFile',context.datasetFile,'categoryFile',context.ud.statusFilename, ...
            'analysis',context.options,'tscore',context.ud.config.tscore,'commonDonors',cohort.included, ...
            'note','Requested panels fitted on identical complete donors; panel checklist controls predictors; block scaling only for combined panels.');
        save(fullfile(folder,'comparison.mat'),'panels','cohort','configuration','caption','classification');
        writeJSON(fullfile(folder,'settings.json'),configuration);
        writeText(fullfile(folder,'figure_caption.txt'),caption);
        writetable(classification,fullfile(folder,'classification_summary.csv'));
        predictions=table(); metrics=table();
        for k=1:numel(panels)
            p=panels(k); r=p.result; count=numel(r.y);
            q=table(repmat(string(p.letter),count,1),r.cadIDs,r.y,r.yPred,r.cats, ...
                'VariableNames',{'Panel','CadaverID','MeasuredTscore','PredictedTscore','Category'});
            predictions=[predictions;q]; %#ok<AGROW>
            metrics=[metrics;table(string(p.letter),strjoin(p.tags,', '),p.withDemographics,count,r.rVal,r.rmseVal, ...
                'VariableNames',{'Panel','Locations','Demographics','N','r','RMSECV'})]; %#ok<AGROW>
        end
        writetable(predictions,fullfile(folder,'predictions.csv')); writetable(metrics,fullfile(folder,'metrics.csv'));
        savefig(fig,fullfile(folder,'Tscore_comparison.fig'));
        exportgraphics(fig,fullfile(folder,'Tscore_comparison.png'),'Resolution',600,'BackgroundColor','white');
        exportgraphics(fig,fullfile(folder,'Tscore_comparison.pdf'),'ContentType','vector','BackgroundColor','white');
        fprintf('%d-panel figure and predictions saved: %s\n',numel(panels),folder);
    else
        fprintf('Figure created. Set an analysis output directory to save publication exports and predictions.\n');
    end
    runs(end+1)=struct('model',model,'panels',panels,'cohort',cohort,'figure',fig,'folder',folder); %#ok<AGROW>
end
end
function writeText(file,value)
fid=fopen(file,'w','n','UTF-8'); if fid<0, error('MainGUI:TscoreSave','Cannot write figure caption.'); end
clean=onCleanup(@()fclose(fid)); fprintf(fid,'%s\n',value);
end
function writeJSON(file,value)
fid=fopen(file,'w'); if fid<0, error('MainGUI:TscoreSave','Cannot write settings file.'); end
clean=onCleanup(@()fclose(fid)); fprintf(fid,'%s',jsonencode(value,'PrettyPrint',true));
end

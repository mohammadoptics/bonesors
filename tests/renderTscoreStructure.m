function renderTscoreStructure(output)
% Visual QA of the UI without loading or changing the user's MATLAB session.
old=get(groot,'DefaultFigureVisible'); clean=onCleanup(@()set(groot,'DefaultFigureVisible',old));
set(groot,'DefaultFigureVisible','off'); GUI_Ver2;
f=findobj(groot,'Tag','MainGUI_Ver2'); closeMain=onCleanup(@()delete(f));
h=f.UserData.controls; modes=analysisModeRegistry();
h.modePopup.Value=find(string({modes.value})=="predictTscore"); cb=h.modePopup.Callback; cb(h.modePopup,[]);
h.locationCombinePopup.Value=2; cb=h.locationCombinePopup.Callback; cb(h.locationCombinePopup,[]);
h.analysisAvailableTags.String={'D2P1_MM00','D3P1_MM00'};
h.analysisSelectedTags.String={'D2P1_MM00','D3P1_MM00'};
tabs=findobj(f,'Type','uitabgroup');
for j=1:numel(tabs)
    children=tabs(j).Children;
    for k=1:numel(children)
        if contains(string(children(k).Title),'Analysis','IgnoreCase',true), tabs(j).SelectedTab=children(k); end
    end
end
exportapp(f,fullfile(output,'analysis_locations.png'));
d=configureTscorePredictionDialog(f,false); closeDialog=onCleanup(@()delete(d));
control=findobj(d,'Tag','TscoreFigureMode'); control.Value=2; cb=control.Callback; cb(control,[]);
tabs=findobj(d,'Tag','TscoreMainTabs'); children=tabs.Children;
tabs.SelectedTab=children(contains(string({children.Title}),'Figure'));
drawnow; exportapp(d,fullfile(output,'figure_checklist.png'));
end

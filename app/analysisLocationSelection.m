function analysis=analysisLocationSelection(fig)
% Read main-page location controls, including edits not yet submitted by Run.
analysis=fig.UserData.config.analysis;
if ~isfield(analysis,'locationCombineMode'), analysis.locationCombineMode="records"; end
ud=fig.UserData;
if isfield(ud,'controls')
    h=ud.controls;
    if isfield(h,'analysisSelectedTags') && isgraphics(h.analysisSelectedTags)
        analysis.tags=normalizeTagSelection(get(h.analysisSelectedTags,'String'));
    end
    if isfield(h,'locationCombinePopup') && isgraphics(h.locationCombinePopup)
        modes=["records","concat","mean"];
        analysis.locationCombineMode=modes(get(h.locationCombinePopup,'Value'));
    end
end
end

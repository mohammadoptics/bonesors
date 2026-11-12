% % function openDisplayInNewWindow(~, ~)
% %     % Create new figure and copy existing axes
% %     newFig = figure('Name', 'Current Display');
% %     newAx = copyobj(fig.UserData.ax, newFig);
% %     set(newAx, 'Position', get(groot, 'DefaultAxesPosition'));
% % 
% %     % Fix the legend to ensure underscores are not treated as subscripts
% %     legend(newAx, 'show', 'Interpreter', 'none','Location','best');
% % end


% -------------------------------------------------------------------------
%  openDisplayInNewWindow – clone current axes into a pop-up figure
% -------------------------------------------------------------------------
function openDisplayInNewWindow(fig, ~)

    srcAx = [];
    if isgraphics(fig) && isfield(fig.UserData,'ax') && isgraphics(fig.UserData.ax,'axes')
        srcAx = fig.UserData.ax;
    end
    if isempty(srcAx) || isempty(get(srcAx,'Children'))
        warndlg('No data to display.','Empty plot'); return
    end

    newFig = figure('Name','Current Display','Color','w');
    newAx  = axes('Parent',newFig,'Units','normalized', ...
                  'Position',get(groot,'DefaultAxesPosition'));

    copyobj(allchild(srcAx), newAx);

    set(newAx, ...
        'XLim',get(srcAx,'XLim'), ...
        'YLim',get(srcAx,'YLim'), ...
        'XScale',get(srcAx,'XScale'), ...
        'YScale',get(srcAx,'YScale'), ...
        'XGrid',get(srcAx,'XGrid'), ...
        'YGrid',get(srcAx,'YGrid'));

    xlabel(newAx, get(get(srcAx,'XLabel'),'String'));
    ylabel(newAx, get(get(srcAx,'YLabel'),'String'));
    title (newAx, get(get(srcAx,'Title' ),'String'));

    % Copy legend (simple)
    lgd = legend(srcAx);
    if ~isempty(lgd) && isvalid(lgd) && ~isempty(lgd.String)
        legend(newAx, lgd.String, 'Interpreter','none','Location','best');
    end
end

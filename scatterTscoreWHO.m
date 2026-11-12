% =====================================================================
% scatterTscoreWHO
%   • TblPred      : table with CadaverID, Tag, TscoreTrue, TscorePred
%   • priorityTags : cell-array of tags in high→low priority order
%   • figName      : title for the new figure
%
% Plots ONE dot per cadaver: the first spectrum whose Tag matches
% priorityTags{1}, else priorityTags{2}, etc.
% Colours by WHO category and shows −1 / −2.5 bands.
% =====================================================================
function scatterTscoreWHO(fig,TblPred, priorityTags, figName)
% ---------------------------------------------------------------------
% If priorityTags == {}, plot the table as-is.
% Otherwise keep the FIRST spectrum per cadaver whose Tag matches
% priorityTags{1}, then {2}, etc.
% ---------------------------------------------------------------------

% ---------- 0. short-circuit for "no priority" ------------------------
if isempty(priorityTags) || all(cellfun(@isempty,priorityTags))
    Tbl = TblPred;                                  % use everything
else
    % ---------- tag-filter logic --------------------------------------
    uniqCad = unique(TblPred.CadaverID);
    keep    = false(height(TblPred),1);

    for cad = uniqCad.'
        rows = find(TblPred.CadaverID==cad);
        for k = 1:numel(priorityTags)
            hit = rows( contains(lower(TblPred.Tag(rows)), ...
                                  lower(priorityTags{k})) );
            if ~isempty(hit)
                keep(hit(1)) = true;                % first match
                break
            end
        end
    end
    if ~any(keep)
        errordlg('None of the priority tags found in this table.'); return
    end
    Tbl = TblPred(keep,:);                          % trimmed table
end

% ---------- WHO sheet & colour lookup (unchanged) ---------------------
if isempty(fig.UserData.statusMap)
    chooseCategoryFile(fig);
    if isempty(fig.UserData.statusMap), return, end
end
Tcat  = readtable(fig.UserData.statusFilename, ...
                  'VariableNamingRule','preserve','TextType','string');
id2cat = containers.Map( ...
    upper(strrep(Tcat.('AGR-ID'),' ','')), ...
    upper(string(Tcat.('WHO Classification (Distal Radius; 1/3)'))) );

cats = upper(arrayfun(@(id) id2cat(char(id)), Tbl.CadaverID, ...
                      'UniformOutput',false));

% ---------- draw (identical to your original) -------------------------
catList={'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
clrMap = containers.Map(catList, {'b','m','r'});
marks  = {'s','d','o'}; sz=160;
lims=[min([Tbl.TscoreTrue; Tbl.TscorePred]) ...
      max([Tbl.TscoreTrue; Tbl.TscorePred])];

figure('Name',figName,'Color','w','Position',[460 200 450 420]);
hold on; axis square
patch([lims fliplr(lims)],[lims(1) -2.5 -2.5 lims(1)],'r','FaceAlpha',0.08,'EdgeColor','none');
patch([lims fliplr(lims)],[-2.5 -1 -1 -2.5],[1 0.65 0],'FaceAlpha',0.08,'EdgeColor','none');
patch([lims fliplr(lims)],[-1 lims(2) lims(2) -1],[0 0.7 0],'FaceAlpha',0.08,'EdgeColor','none');
plot(lims,[-1 -1],'k','HandleVisibility','off');
plot(lims,[-2.5 -2.5],'k','HandleVisibility','off');
plot(lims,lims,'k--','DisplayName','45° line');

for j = 1:numel(catList)
    c=catList{j}; idx=strcmpi(cats,c);
    if any(idx)
        scatter(Tbl.TscoreTrue(idx),Tbl.TscorePred(idx),sz, ...
                'Marker',marks{j},'MarkerFaceColor',clrMap(c), ...
                'MarkerEdgeColor',clrMap(c),'DisplayName',c);
    end
end
xlim(lims); ylim(lims);
r    = corr(Tbl.TscoreTrue,Tbl.TscorePred,'rows','pairwise');
rmse = sqrt(mean((Tbl.TscorePred-Tbl.TscoreTrue).^2));
text(0.05,0.95,sprintf('r = %.3f\nRMSE = %.3f',r,rmse), ...
     'Units','normalized','VerticalAlignment','top','FontSize',9,'BackgroundColor','w');
xlabel('Measured T-score','FontSize',12);
ylabel('Predicted T-score','FontSize',12);
title(figName,'FontSize',13);
legend show location best; grid on
end
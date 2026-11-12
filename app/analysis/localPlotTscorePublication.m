function fig=localPlotTscorePublication(panels,options,model)
% Common axes, no clipped points, one shared category legend, editable graphics.
assert(~isempty(panels),'Select at least one comparison panel.');
nPanels=numel(panels);
measured=[]; predicted=[];
for k=1:nPanels
    measured=[measured;panels(k).result.y(:)]; predicted=[predicted;panels(k).result.yPred(:)]; %#ok<AGROW>
end
assert(all(isfinite([measured;predicted])),'Nonfinite predictions cannot be plotted.');
xPad=max(.25,.06*range(measured));
% Preserve the reference figure's lower-x boundary, independently of yMin.
% Keep the additional positive-side padding requested for the newer layout.
xLowerPad=max(.1,.02*range(measured));
xLimits=[min(measured)-xLowerPad ceil(2*(max(measured)+xPad))/2];
yLimits=[floor(min([measured;predicted])-.35) ceil(max([measured;predicted])+.35)];
% Original full-span y=x reference line; do not shorten to the data range.
identityX=xLimits;
% Preserve paired location rows; center unpaired panels and the baseline.
tiles=zeros(1,nPanels); row=0; k=1;
while k<=nPanels
    row=row+1;
    pair=k<nPanels && panels(k).feature.useRaman && panels(k+1).feature.useRaman && ...
        isequal(panels(k).tags,panels(k+1).tags) && panels(k).withDemographics~=panels(k+1).withDemographics;
    if pair
        tiles(k:k+1)=[4*(row-1)+1 4*(row-1)+3]; k=k+2;
    else
        tiles(k)=4*(row-1)+2; k=k+1;
    end
end
fig=figure('Name',sprintf('%d-panel T-score comparison | %s',nPanels,model),'Color','w', ...
    'WindowStyle','normal','Units','inches','Position',[.5 .5 8.3 max(4,3.375*row)],'Tag','TscorePublicationFigure');
tl=tiledlayout(fig,row,4,'TileSpacing','compact','Padding','compact');
[~,~,demographicsHeading]=localSummarizeTscorePublication(panels,options,model);
colors=[0 0 1;0 1 0;1 0 0]; marks={'s','d','o'};
classes=["NORMAL","OSTEOPENIA","OSTEOPOROSIS"]; labels=["Normal","Osteopenia","Osteoporosis"];
axesList=gobjects(nPanels,1); handles=gobjects(3,1);
for k=1:nPanels
    p=panels(k); r=p.result; ax=nexttile(tl,tiles(k),[1 2]); axesList(k)=ax;
    hold(ax,'on');
    plot(ax,identityX,identityX,'k--','LineWidth',1,'HandleVisibility','off', ...
        'Tag','PublicationIdentityLine');
    for j=1:3
        ix=strcmpi(r.cats,classes(j));
        h=scatter(ax,r.y(ix),r.yPred(ix),25,colors(j,:),'filled',marks{j},'MarkerEdgeColor',colors(j,:),'LineWidth',.3);
        if k==1, handles(j)=h; end
    end
    shortTags=replace(regexprep(string(p.tags),'(?i)_?MM00$',''),'_',' / ');
    if ~p.feature.useRaman, where="Demographics only";
    elseif numel(p.tags)==1, where=shortTags;
    else, where="["+strjoin(shortTags,', ')+"]"; end
    title(ax,sprintf('(%s) %s',p.letter,where),'Interpreter','none','FontSize',11,'FontWeight','bold');
    if ~p.feature.useRaman, source=erase(demographicsHeading,"Demographics: ");
    elseif p.withDemographics, source='Raman + demographics'; else, source='Raman only'; end
    text(ax,.045,.95,sprintf('%s\nr = %.3f\nRMSE_{CV} = %.3f',source,r.rVal,r.rmseVal), ...
        'Units','normalized','VerticalAlignment','top','HorizontalAlignment','left', ...
        'FontSize',10,'FontName','Arial','Tag','PublicationPanelAnnotation');
    set(ax,'XLim',xLimits,'YLim',yLimits,'FontName','Arial','FontSize',10, ...
        'LineWidth',1,'Box','off','TickDir','out','Tag',['PublicationPanel' p.letter]);
end
linkaxes(axesList,'xy');
xlabel(tl,'DXA-measured wrist T-score','FontName','Arial','FontSize',12);
ylabel(tl,'Predicted wrist T-score','FontName','Arial','FontSize',12);
lg=legend(axesList(1),handles,labels,'Orientation','horizontal','Box','off','FontSize',10, ...
    'Tag','PublicationCategoryLegend');
if ~panels(1).feature.useRaman
    % The centered demographics panel occupies tiles 2-3. Reserve the empty
    % upper-right tile for the shared legend, outside all prediction axes.
    lg.Orientation='vertical';
    lg.Layout.Tile=4;
else
    % Without a demographics row, the upper-right tile may contain data.
    lg.Layout.Tile='south';
end
fig.UserData=struct('panels',panels,'options',options,'commonXLimits',xLimits,'commonYLimits',yLimits);
end

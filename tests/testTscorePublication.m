function tests=testTscorePublication
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.old=path; root=fileparts(fileparts(mfilename('fullpath'))); addpath(root,fullfile(root,'analysis'));
end
function teardownOnce(t), path(t.TestData.old); end
function testDialogPresetAndRoundTrip(t)
f=figure('Visible','off'); clean=onCleanup(@()delete(f)); f.UserData=struct('config',guiDefaultConfig());
d=configureTscorePredictionDialog(f,false); set(d,'Visible','off');
verifyEmpty(t,findobj(d,'Tag','TscorePublicationPreset'));
h=findobj(d,'Tag','TscoreFigureMode'); h.Value=2; cb=h.Callback; cb(h,[]);
verifyEqual(t,get(findobj(d,'Tag','TscorePredictorSource'),'Enable'),'off');
verifyEqual(t,get(findobj(d,'Tag','TscoreUseAge'),'Enable'),'on');
before=f.UserData.config; press(d,'TscoreApply'); c=f.UserData.config;
verifyEqual(t,c.tscore.figureMode,"locationComparison");
verifyEqual(t,c.analysis,before.analysis); verifyEqual(t,c.tscore.svrKernelScaleGrid,before.tscore.svrKernelScaleGrid);
d=configureTscorePredictionDialog(f,false); set(d,'Visible','off');
verifyEqual(t,get(findobj(d,'Tag','TscoreFigureMode'),'Value'),2); press(d,'TscoreCancel');
end
function testInvalidLocationComparison(t)
c=guiDefaultConfig(); c.tscore.figureMode="locationComparison";
c.tscore.locationTags="D2P1_MM00"; c.tscore.locationCombineMode="concat"; c.tscore.ramanFeatureMode="ratios";
v=validateTscoreConfiguration(c.tscore); verifyEqual(t,v.ramanFeatureMode,"ratios");
c.tscore.figureSelectionConfigured=true; c.tscore.figureIncludeDemographics=false;
verifyError(t,@()validateTscoreConfiguration(c.tscore),'MainGUI:TscorePublication');
end
function testMatchedCohortAndOneFigure(t)
ctx=fixture(); ctx.records(2)=[]; % C01 missing second location
ctx.records(end).Weight=NaN; ctx.records(end-1).Weight=NaN;
[p,cohort]=localComputeTscorePublication(ctx,"PLS");
verifyNumElements(t,p,7); verifyNumElements(t,cohort.included,6);
verifyFalse(t,p(1).feature.useRaman); verifyEqual(t,p(1).result.nFeatures,3);
verifyFalse(t,p(1).feature.blockScaleRamanDemographics);
for k=1:7
    verifyEqual(t,p(k).result.cadIDs,cohort.included);
    verifyEqual(t,p(k).withDemographics,mod(k,2)==1);
    verifyEqual(t,p(k).feature.blockScaleRamanDemographics,k>1 && mod(k,2)==1);
end
verifyEqual(t,p(2).result.nFeatures,499); verifyEqual(t,p(6).result.nFeatures,998);
verifyEqual(t,p(7).result.nFeatures,1001);
fig=localPlotTscorePublication(p,ctx.options,"PLS"); clean=onCleanup(@()delete(fig));
ax=findall(fig,'Type','axes'); verifyNumElements(t,ax,7);
verifyNumElements(t,findall(fig,'Tag','PublicationPanelAnnotation'),7);
verifyEmpty(t,findall(fig,'Tag','PublicationPanelSource'));
annotations=findall(fig,'Tag','PublicationPanelAnnotation');
for j=1:7
    verifyEqual(t,annotations(j).Position(1:2),[.045 .95]);
    verifyEqual(t,annotations(j).FontSize,10);
    verifyFalse(t,any(contains(string(annotations(j).String),'n =')));
end
verifyEqual(t,string(findobj(fig,'Tag','PublicationPanelB').Title.String),"(B) D2P1");
verifyEqual(t,string(findobj(fig,'Tag','PublicationPanelF').Title.String),"(F) [D2P1, D3P1]");
h=findall(fig,'-isa','matlab.graphics.layout.TiledChartLayout');
verifyNumElements(t,h,1);
verifyTrue(t,all(strlength(string(h.Title.String))==0));
baseline=findobj(fig,'Tag','PublicationPanelA');
verifyEqual(t,baseline.Layout.Tile,2); verifyEqual(t,baseline.Layout.TileSpan,[1 2]);
lg=findobj(fig,'Tag','PublicationCategoryLegend');
verifyEqual(t,lg.Layout.Tile,4); verifyEqual(t,lg.Orientation,'vertical');
drawnow;
legendBounds=getpixelposition(lg,true); baselineBounds=getpixelposition(baseline,true);
verifyGreaterThan(t,legendBounds(1),baselineBounds(1)+baselineBounds(3));
verifyEqual(t,string(baseline.Title.String),"(A) Demographics only");
for k=1:7
    verifyEqual(t,ax(k).XLim,ax(1).XLim); verifyEqual(t,ax(k).YLim,ax(1).YLim);
    xPad=max(.25,.06*range(p(k).result.y));
    xLowerPad=max(.1,.02*range(p(k).result.y));
    verifyEqual(t,ax(k).XLim,[min(p(k).result.y)-xLowerPad ceil(2*(max(p(k).result.y)+xPad))/2]);
    verifyEqual(t,ax(k).FontSize,10); verifyEqual(t,ax(k).Title.FontSize,11);
    identity=findall(ax(k),'Tag','PublicationIdentityLine');
    verifyNumElements(t,identity,1);
    verifyEqual(t,identity.XData,identity.YData);
    verifyEqual(t,identity.XData,ax(k).XLim);
    verifyEqual(t,interp1(identity.XData,identity.YData,0),0,'AbsTol',1e-12);
    verifyGreaterThanOrEqual(t,ax(k).YLim(2),max(p(k).result.yPred));
end
end
function testClassificationCountsAndCaption(t)
ctx=fixture(); f=ctx.settings.feature;
r=struct('y',zeros(6,1),'cats',["NORMAL";"NORMAL";"OSTEOPENIA";"OSTEOPENIA";"OSTEOPOROSIS";"OSTEOPOROSIS"], ...
    'yPred',[0;-1;-1;-2.5;-2.5;-.9999]);
p=repmat(struct('letter','A','tags',"D2P1_MM00",'withDemographics',false,'feature',f,'result',r),1,7);
for k=1:7, p(k).letter=char('A'+k-1); p(k).withDemographics=mod(k,2)==1; end
p(1).feature.useRaman=false; p(1).tags=strings(1,0);
p(4).tags="D3P1_MM00";
p(6).tags=["D2P1_MM00","D3P1_MM00"]; p(7).tags=p(6).tags;
[caption,q,heading]=localSummarizeTscorePublication(p,ctx.options,"PLS");
verifyEqual(t,q.Correct,3*ones(7,1)); verifyEqual(t,q.Total,6*ones(7,1));
verifyEqual(t,q.AccuracyPercent,50*ones(7,1));
verifyEqual(t,q.Normal,repmat("1/2",7,1));
verifyEqual(t,q.Osteopenia,repmat("1/2",7,1));
verifyEqual(t,q.Osteoporosis,repmat("1/2",7,1));
verifyEqual(t,q.Predictors(1),"Demographics only");
verifyEqual(t,heading,"Demographics: age, BMI, weight");
verifyTrue(t,contains(caption,"6-mm minus 3-mm"));
verifyTrue(t,contains(caption,"CH2 peak normalization"));
verifyTrue(t,contains(caption,"block-scaled"));
verifyTrue(t,contains(caption,"n = 6 donors"));
verifyTrue(t,contains(caption,"normal: n = 2"));
verifyTrue(t,contains(caption,"horizontal concatenation"));
p(1).feature.normalizationRegion="none";
[caption,~]=localSummarizeTscorePublication(p,ctx.options,"SVR");
verifyTrue(t,contains(caption,"No spectral normalization was applied."));
verifyTrue(t,contains(caption,"SVR regression"));
end
function ctx=fixture()
c=twoDigitDifferencePreset(guiDefaultConfig()); c.tscore.figureMode="locationComparison";
c.tscore.predictorSource="combined"; c.tscore.blockScaleRamanDemographics=true;
c.tscore.fixedPLSRank=2;
s=applyTscoreConfigToSettings(analysisDefaultSettings(),c.tscore); s.feature.spectrumCombineMode='diff';
old=rng; clean=onCleanup(@()rng(old)); rng(41); wn=linspace(800,1750,499).';
r=repmat(struct('CadaverID',"",'Tag',"",'Category',"NORMAL",'Spectrum',[],'Wavenumber',wn, ...
    'Tscore',0,'Age',0,'Sex',0,'BMI',0,'Weight',0),1,16);
for i=1:8
    for j=1:2
        k=2*(i-1)+j; r(k).CadaverID=sprintf('C%02d',i); r(k).Tag=c.tscore.locationTags(j);
        r(k).Spectrum=10+rand(499,2)+i/10; r(k).Tscore=-4+i*.7;
        r(k).Category=localTscoreToCategory(r(k).Tscore);
        r(k).Age=40+i; r(k).BMI=20+i/3; r(k).Weight=50+i*2;
    end
end
ctx=struct('records',r,'options',c.analysis,'settings',s,'ud',struct('config',c));
end
function press(d,tag), h=findobj(d,'Tag',tag); cb=h.Callback; cb(h,[]); end

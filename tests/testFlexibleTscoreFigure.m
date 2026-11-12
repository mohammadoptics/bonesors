function tests=testFlexibleTscoreFigure
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.old=path; p=fileparts(fileparts(mfilename('fullpath'))); addpath(p, fullfile(p,'app'), fullfile(p,'app','analysis'));
t.TestData.visible=get(groot,'DefaultFigureVisible'); set(groot,'DefaultFigureVisible','off');
end
function teardownOnce(t), path(t.TestData.old); set(groot,'DefaultFigureVisible',t.TestData.visible); end
function testDialogNoPresetsAndNoLocationEditor(t)
ctx=fixture(); f=figure('Visible','off'); f.UserData=ctx.ud;
d=configureTscorePredictionDialog(f,false); clean=onCleanup(@()closeBoth(f,d));
verifyEmpty(t,findobj(d,'-regexp','Tag','.*Preset.*'));
verifyEmpty(t,findobj(d,'Tag','TscoreLocationTags'));
tabs=findobj(d,'Tag','TscoreMainTabs'); verifyNumElements(t,tabs.Children,5);
table=findobj(d,'Tag','TscoreFigurePanels'); verifySize(t,table.Data,[3 3]);
before=f.UserData.config; setValue(d,'TscoreFigureMode',1); setValue(d,'TscoreFigureMode',2);
data=table.Data; data{2,2}=false; data{3,3}=false; table.Data=data;
cb=table.CellEditCallback; cb(table,[]);
press(d,'TscoreApply'); after=f.UserData.config;
verifyEqual(t,after.analysis,before.analysis);
keys={'models','svrKernelScaleGrid','svrBoxConstraintGrid','svrEpsilonGrid','randomSeed', ...
    'validationProtocol','normalizationRegion','normalizationMethod','standardizePredictors','fixedPLSRank'};
for key=keys, verifyEqual(t,after.tscore.(key{1}),before.tscore.(key{1})); end
verifyEqual(t,after.tscore.figureRamanTags,"D2P1_MM00");
verifyFalse(t,after.tscore.figureIncludeConcatenatedCombined);
end
function testMainSelectionOverridesStaleConfig(t)
ctx=fixture(); c=ctx.ud.config;
c.analysis.tags={'D4P1_MM00'}; c.analysis.locationCombineMode="mean"; c.tscore.figureMode="individual";
r=resolveTscoreAnalysisConfig(c.tscore,c.analysis);
verifyEqual(t,r.locationTags,"D4P1_MM00"); verifyEqual(t,r.locationCombineMode,"mean");
f=figure('Visible','off'); clean=onCleanup(@()delete(f)); f.UserData=struct('config',c);
o=getGuiAnalysisOptions(f); verifyEqual(t,string(o.tags),"D4P1_MM00"); verifyTrue(t,o.locationFusionEnabled);
end
function testDemographicPanelsDisableWithoutDemographics(t)
ctx=fixture(); f=figure('Visible','off'); f.UserData=ctx.ud;
d=configureTscorePredictionDialog(f,false); clean=onCleanup(@()closeBoth(f,d));
for key={'Age','Sex','BMI','Weight'}, setValue(d,['TscoreUse' key{1}],0); end
table=findobj(d,'Tag','TscoreFigurePanels'); verifyEqual(t,table.ColumnEditable,[false true false]);
verifyFalse(t,any(cell2mat(table.Data(:,3))));
verifyEqual(t,get(findobj(d,'Tag','TscoreFigureDemographics'),'Enable'),'off');
press(d,'TscoreApply'); verifyFalse(t,isgraphics(d));
plan=tscoreFigurePlan(f.UserData.config.tscore,ctx.options.tags);
verifyNumElements(t,plan,3); verifyFalse(t,any([plan.withDemographics]));
end
function testVariablePanelsAndNoUnusedDonorExclusions(t)
ctx=fixture(); c=ctx.ud.config.tscore;
c.figureSelectionConfigured=true; c.figureRamanTags="D2P1_MM00"; c.figureCombinedTags=strings(1,0);
c.figureIncludeConcatenatedRaman=false; c.figureIncludeConcatenatedCombined=false; c.figureIncludeDemographics=false;
ctx.ud.config.tscore=c; ctx.records(2)=[]; % unused D3 missing
for k=1:numel(ctx.records), ctx.records(k).Age=NaN; end % unused demographics
[p,cohort]=localComputeTscorePublication(ctx,"PLS"); verifyNumElements(t,p,1); verifyNumElements(t,cohort.included,8);
fig=localPlotTscorePublication(p,ctx.options,"PLS"); clean=onCleanup(@()delete(fig));
verifyNumElements(t,findall(fig,'Type','axes'),1);
lg=findobj(fig,'Tag','PublicationCategoryLegend');
verifyEqual(t,lg.Layout.Tile,'south');
[caption,q]=localSummarizeTscorePublication(p,ctx.options,"PLS");
verifyEqual(t,height(q),1); verifyTrue(t,contains(caption,"Panel A")); verifyFalse(t,contains(caption,"Panel B"));
end
function testSevenPanelsAndStandaloneSvrParity(t)
ctx=fixture(); ctx.ud.config.tscore.svrOptimizationMode="fixed";
ctx.ud.config.tscore.validationProtocol="legacy";
[p,cohort]=localComputeTscorePublication(ctx,"SVR"); verifyNumElements(t,p,7);
verifyNumElements(t,cohort.included,8);
for k=[2 4 6]
    q=localComputeTscorePrediction(ctx.records,ctx.options.tissue,ctx.options.spectrumNumbers,2,p(k).feature);
    verifyEqual(t,p(k).result.yPred,q.yPred,'AbsTol',1e-12);
    verifyEqual(t,p(k).feature.svrKernelScale,ctx.ud.config.tscore.svrKernelScale);
end
fig=localPlotTscorePublication(p,ctx.options,"SVR"); clean=onCleanup(@()delete(fig));
verifyNumElements(t,findall(fig,'Type','axes'),7);
verifyEqual(t,findobj(fig,'Tag','PublicationPanelA').Layout.Tile,2);
end
function testBaselineOnlyDoesNotNeedSpectra(t)
ctx=fixture(); c=ctx.ud.config.tscore;
c.figureSelectionConfigured=true; c.figureRamanTags=strings(1,0); c.figureCombinedTags=strings(1,0);
c.figureIncludeConcatenatedRaman=false; c.figureIncludeConcatenatedCombined=false;
ctx.ud.config.tscore=c; for k=1:numel(ctx.records), ctx.records(k).Spectrum=[]; end
[p,cohort]=localComputeTscorePublication(ctx,"PLS"); verifyNumElements(t,p,1); verifyNumElements(t,cohort.included,8);
verifyFalse(t,p.feature.useRaman);
end
function testEmptySelectionRejected(t)
ctx=fixture(); c=ctx.ud.config.tscore;
c.figureSelectionConfigured=true; c.figureRamanTags=strings(1,0); c.figureCombinedTags=strings(1,0);
c.figureIncludeConcatenatedRaman=false; c.figureIncludeConcatenatedCombined=false; c.figureIncludeDemographics=false;
verifyError(t,@()validateTscoreConfiguration(c),'MainGUI:TscorePublication');
end
function testMainGuiLocationControls(t)
BoneSORS; f=findobj(groot,'Tag','MainGUI_Ver2'); clean=onCleanup(@()delete(f));
h=f.UserData.controls; modes=analysisModeRegistry();
h.modePopup.Value=find(string({modes.value})=="predictTscore"); cb=h.modePopup.Callback; cb(h.modePopup,[]);
h.locationCombinePopup.Value=2; cb=h.locationCombinePopup.Callback; cb(h.locationCombinePopup,[]);
verifyEqual(t,h.tagModePopup.Value,3); verifyEqual(t,h.tagMatchPopup.Value,1);
verifyEqual(t,h.analysisSelectedTags.Enable,'on'); verifyEqual(t,h.analysisAvailableTags.Enable,'on');
h.analysisSelectedTags.String={'D2P1_MM00','D3P1_MM00'};
a=analysisLocationSelection(f); verifyEqual(t,string(a.tags),["D2P1_MM00","D3P1_MM00"]);
verifyEqual(t,a.locationCombineMode,"concat");
end
function testUnavailableMetadataFields(t)
file=[tempname '.csv']; clean=onCleanup(@()delete(file));
T=table(["C1";"C2"],[60;65],["M";"F"],[NaN;NaN],[NaN;NaN], ...
    'VariableNames',{'AGR-ID','Age','Sex','BMI','Weight (kg)'});
writetable(T,file);
ud=struct('statusFilename',file,'config',guiDefaultConfig());
[available,known]=tscoreDemographicAvailability(ud);
verifyTrue(t,known); verifyEqual(t,available,[true true false false]);
f=figure('Visible','off'); f.UserData=ud; d=configureTscorePredictionDialog(f,false);
close=onCleanup(@()closeBoth(f,d)); setValue(d,'TscorePredictorSource',3);
verifyEqual(t,get(findobj(d,'Tag','TscoreUseBMI'),'Enable'),'off');
verifyEqual(t,get(findobj(d,'Tag','TscoreUseBMI'),'Value'),0);
verifyEqual(t,get(findobj(d,'Tag','TscoreUseAge'),'Enable'),'on');
end
function testOneLocationThreePanelsAndZeroLocationBaseline(t)
ctx=fixture(); ctx.options.tags={'D2P1_MM00'};
[p,c]=localComputeTscorePublication(ctx,"PLS"); verifyNumElements(t,p,3); verifyNumElements(t,c.included,8);
ctx.options.tags={}; ctx.ud.config.tscore.figureSelectionConfigured=true;
ctx.ud.config.tscore.figureRamanTags=strings(1,0); ctx.ud.config.tscore.figureCombinedTags=strings(1,0);
[p,c]=localComputeTscorePublication(ctx,"PLS"); verifyNumElements(t,p,1); verifyNumElements(t,c.included,8);
end
function ctx=fixture()
c=guiDefaultConfig(); c.analysis.mode="predictTscore"; c.analysis.tags={'D2P1_MM00','D3P1_MM00'};
c.analysis.locationCombineMode="concat"; c.analysis.tagSelectionMode="all";
c.analysis.tissue="T"; c.analysis.spectrumNumbers=[3 2]; c.analysis.spectrumCombineMode="diff"; c.analysis.spectrumExpression="3-2";
c.tscore.figureMode="locationComparison"; c.tscore.models="PLS"; c.tscore.fixedPLSRank=2;
c.tscore.useSex=false; c.tscore.useWeight=true; c.tscore.blockScaleRamanDemographics=true;
c.tscore=resolveTscoreAnalysisConfig(c.tscore,c.analysis);
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
function setValue(d,tag,v), h=findobj(d,'Tag',tag); h.Value=v; cb=h.Callback; cb(h,[]); end
function press(d,tag), h=findobj(d,'Tag',tag); cb=h.Callback; cb(h,[]); end
function closeBoth(f,d), if isgraphics(d), delete(d); end, if isgraphics(f), delete(f); end, end

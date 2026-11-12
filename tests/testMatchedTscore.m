function tests=testMatchedTscore
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.OldPath=path;
root=fileparts(fileparts(mfilename('fullpath'))); addpath(root, fullfile(root,'app'), fullfile(root,'app','analysis'));
end
function teardownOnce(t), path(t.TestData.OldPath); end
function testPresetAndMapping(t)
c=intactRatioPlsSvrPreset(guiDefaultConfig()); v=validateTscoreConfiguration(c.tscore);
verifyEqual(t,v.models,["PLS" "SVR"]); verifyEqual(t,c.analysis.tissue,"T");
verifyEqual(t,c.analysis.spectrumNumbers,3); verifyEqual(t,c.analysis.tags,{'D3P1_MM00'});
verifyEqual(t,v.validationProtocol,"matchedKFold"); verifyEqual(t,v.maxPLSRank,8);
verifyEmpty(t,v.fixedPLSRank); verifyEqual(t,v.matchedInnerFolds,5);
verifyEqual(t,v.svrBoxConstraintGrid,[.1 .3 1 3 10 30 100]);
verifyEqual(t,v.svrEpsilonGrid,[.01 .1 .3]);
verifyEqual(t,v.svrKernelScaleGrid,[.3 .7 1.5 3 10 30]);
verifyTrue(t,v.blockScaleRamanDemographics); verifyFalse(t,v.useSex);
s=applyTscoreConfigToSettings(analysisDefaultSettings(),v);
verifyEqual(t,s.feature.validationProtocol,"matchedKFold");
verifyTrue(t,contains(string(formatTscoreConfigSummary(v)),"matched"));
end
function testOriginalModesUnchanged(t)
c=guiDefaultConfig(); verifyEqual(t,c.tscore.validationProtocol,"legacy");
c=intactRatioRidgePreset(intactRatioPlsSvrPreset(c));
verifyEqual(t,c.tscore.validationProtocol,"legacy");
verifyEqual(t,c.tscore.models,"RIDGE"); validateTscoreConfiguration(c.tscore);
end
function testInvalidMatchedOptions(t)
c=intactRatioPlsSvrPreset(guiDefaultConfig());
c.tscore.matchedInnerFolds=1;
verifyError(t,@()validateTscoreConfiguration(c.tscore),'MainGUI:TscoreNumericSetting');
c=intactRatioPlsSvrPreset(guiDefaultConfig()); c.tscore.svrOptimizationMode="fixed";
verifyError(t,@()validateTscoreConfiguration(c.tscore),'MainGUI:MatchedSVRMode');
c=intactRatioPlsSvrPreset(guiDefaultConfig()); c.tscore.models="MLP";
validated=validateTscoreConfiguration(c.tscore); verifyEqual(t,validated.models,"MLP");
end
function testHeldOutTargetAndGroupedFolds(t)
[X,y,ids,s]=fixture(); s.tscoreModel="pls";
[p,tuning]=localPredictTscoreMatchedKFold(X,y,ids,s,3,[3 2]);
y2=y; y2(ids==ids(1))=100+y2(ids==ids(1));
q=localPredictTscoreMatchedKFold(X,y2,ids,s,3,[3 2]);
verifyEqual(t,p(ids==ids(1)),q(ids==ids(1)),'AbsTol',1e-12);
verifyTrue(t,all(isfinite(p)));
for k=1:numel(tuning)
    verifyFalse(t,any(tuning(k).InnerCadaverIDs==tuning(k).CadaverID));
    verifyEqual(t,numel(tuning(k).InnerFold),7);
    verifyEqual(t,unique(tuning(k).InnerFold),(1:5)');
end
end
function testImputationAndFixedRank(t)
[X,y,ids,s]=fixture(); s.tscoreModel="pls"; s.fixedPLSRank=2;
X(1,2)=NaN; X(2,1)=Inf;
[p,~,r]=localPredictTscoreMatchedKFold(X,y,ids,s,3,[3 2]);
verifyTrue(t,all(isfinite(p))); verifyEqual(t,r,2*ones(size(y)));
end
function testSvrHeldOutTargetAndDeterminism(t)
[X,y,ids,s]=fixture(); s.tscoreModel="svr";
assumeTrue(t,isfile(s.matchedSVRPython),'Matched Python environment not installed.');
s.svrBoxConstraintGrid=[1 3]; s.svrEpsilonGrid=.1; s.svrKernelScaleGrid=3;
[p,tuning]=localPredictTscoreMatchedKFold(X,y,ids,s,3,[3 2]);
y2=y; y2(ids==ids(1))=y2(ids==ids(1))+100;
q=localPredictTscoreMatchedKFold(X,y2,ids,s,3,[3 2]);
verifyEqual(t,p(ids==ids(1)),q(ids==ids(1)),'AbsTol',1e-12);
verifyTrue(t,all(isfinite(p))); verifyNumElements(t,tuning,8);
verifyFalse(t,any(tuning(1).InnerCadaverIDs==ids(1)));
end
function testDialogPresetApplyAndReopen(t)
c=intactRatioPlsSvrPreset(guiDefaultConfig());
f=figure('Visible','off'); f.UserData=struct('config',c); clean=onCleanup(@()safeDelete(f));
d=configureTscorePredictionDialog(f,false); set(d,'Visible','off'); cleanD=onCleanup(@()safeDelete(d));
verifyEmpty(t,findobj(d,'Tag','TscoreIntactPlsSvrPreset'));
b=findobj(d,'Tag','TscoreApply'); cb=b.Callback; cb(b,[]);
verifyEqual(t,f.UserData.config.analysis,c.analysis);
verifyEqual(t,f.UserData.config.tscore.validationProtocol,"matchedKFold");
d2=configureTscorePredictionDialog(f,false); set(d2,'Visible','off'); cleanD2=onCleanup(@()safeDelete(d2));
verifyEqual(t,get(findobj(d2,'Tag','TscorePredictorSource'),'Value'),3);
verifyEqual(t,get(findobj(d2,'Tag','TscoreRamanFeatureMode'),'Value'),2);
end
function testDialogCancelDoesNotApply(t)
f=figure('Visible','off'); f.UserData=struct('config',guiDefaultConfig()); clean=onCleanup(@()safeDelete(f));
original=f.UserData.config; d=configureTscorePredictionDialog(f,false); set(d,'Visible','off');
h=findobj(d,'Tag','TscoreFigureMode'); h.Value=2; cb=h.Callback; cb(h,[]);
cb=d.CloseRequestFcn; cb(d,[]); verifyEqual(t,f.UserData.config,original);
end
function [X,y,ids,s]=fixture()
c=intactRatioPlsSvrPreset(guiDefaultConfig());
st=applyTscoreConfigToSettings(analysisDefaultSettings(),c.tscore); s=st.feature;
u=(1:16)'; X=[sin(u) cos(u) u u.^2 sin(u/3)]; y=sin(u)+.1*u;
ids=repelem("D"+string((1:8)'),2);
end
function safeDelete(f), if isgraphics(f), delete(f); end, end

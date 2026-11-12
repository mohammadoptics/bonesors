function tests=testNestedRidge
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.OldPath=path;
root=fileparts(fileparts(mfilename('fullpath'))); addpath(root,fullfile(root,'analysis'));
end
function teardownOnce(t), path(t.TestData.OldPath); end
function testNumpyPermutationAndNoGlobalRandomSideEffect(t)
before=rng;
verifyEqual(t,localNumpyPermutation(10,0),[3 9 5 10 2 7 8 4 1 6]);
verifyEqual(t,rng,before);
verifyEqual(t,sort(localNumpyPermutation(2000,42)),1:2000);
end
function testPresetMappingAndValidation(t)
c=intactRatioRidgePreset(guiDefaultConfig());
v=validateTscoreConfiguration(c.tscore);
verifyEqual(t,v.models,"RIDGE"); verifyEqual(t,c.analysis.tissue,"T");
verifyEqual(t,c.analysis.spectrumNumbers,3); verifyEqual(t,c.analysis.tags,{'D3P1_MM00'});
verifyEqual(t,v.ramanFeatureMode,"ratios"); verifyNumElements(t,v.ramanRatioNames,5);
verifyTrue(t,v.blockScaleRamanDemographics); verifyFalse(t,v.useSex);
verifyEqual(t,v.randomSeed,20260919);
s=applyTscoreConfigToSettings(analysisDefaultSettings(),v);
verifyEqual(t,s.feature.ridgeAlphaGrid,[.01 .1 1 10 100]);
verifyEqual(t,s.feature.ridgeInnerFolds,5);
verifyTrue(t,contains(string(formatTscoreConfigSummary(v)),"Ridge (nested K-fold alpha)"));
end
function testInvalidRidgeSettings(t)
c=intactRatioRidgePreset(guiDefaultConfig()); c.tscore.ridgeAlphaGrid=[1 -2];
verifyError(t,@()validateTscoreConfiguration(c.tscore),'MainGUI:TscoreNumericSetting');
c=intactRatioRidgePreset(guiDefaultConfig()); c.tscore.ridgeInnerFolds=1;
verifyError(t,@()validateTscoreConfiguration(c.tscore),'MainGUI:TscoreNumericSetting');
end
function testGroupedNestedRidgeAndHeldOutTargetIsolation(t)
[X,y,ids,s]=fixture();
[p,tuning]=localPredictTscoreRidge(X,y,ids,s,[3 2]);
y2=y; y2(ids==ids(1))=y2(ids==ids(1))+100;
q=localPredictTscoreRidge(X,y2,ids,s,[3 2]);
verifyEqual(t,p(ids==ids(1)),q(ids==ids(1)),'AbsTol',1e-12);
verifyNumElements(t,tuning,8); verifyTrue(t,all(isfinite(p)));
for k=1:numel(tuning)
    verifyFalse(t,any(tuning(k).InnerCadaverIDs==tuning(k).CadaverID));
    verifyEqual(t,numel(unique(tuning(k).InnerCadaverIDs)),7);
    verifyEqual(t,unique(tuning(k).InnerFold),(1:5)');
end
end
function testMissingAndConstantPredictorsAndWideMatrix(t)
[X,y,ids,s]=fixture();
X(:,1)=NaN; X(1,2)=Inf; X(:,3)=5;
verifyTrue(t,all(isfinite(localPredictTscoreRidge(X,y,ids,s,[3 2]))));
verifyTrue(t,all(isfinite(localPredictTscoreRidge(repmat(X,1,5),y,ids,s,[]))));
end
function testPresetDialogAppliesOnApplyOnly(t)
c=intactRatioRidgePreset(guiDefaultConfig());
f=figure('Visible','off'); f.UserData=struct('config',c); clean=onCleanup(@()delete(f));
d=configureTscorePredictionDialog(f,false); set(d,'Visible','off'); cleanD=onCleanup(@()safeDelete(d));
verifyEmpty(t,findobj(d,'Tag','TscoreIntactRidgePreset'));
verifyEqual(t,get(findobj(d,'Tag','TscoreModelRIDGE'),'Value'),1);
apply=findobj(d,'Tag','TscoreApply'); cb=apply.Callback; cb(apply,[]);
verifyEqual(t,f.UserData.config.analysis,c.analysis); verifyEqual(t,f.UserData.config.tscore.models,"RIDGE");
end
function [X,y,ids,s]=fixture()
c=intactRatioRidgePreset(guiDefaultConfig()); st=applyTscoreConfigToSettings(analysisDefaultSettings(),c.tscore); s=st.feature;
u=(1:16)'; X=[sin(u) cos(u) u u.^2 sin(u/3)]; y=sin(u)+.1*u;
ids=repelem("D"+string((1:8)'),2);
end
function safeDelete(d), if isgraphics(d), delete(d); end, end

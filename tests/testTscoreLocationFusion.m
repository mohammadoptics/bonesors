function tests=testTscoreLocationFusion
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.old=path; p=fileparts(fileparts(mfilename('fullpath'))); addpath(p, fullfile(p,'app'), fullfile(p,'app','analysis'));
end
function teardownOnce(t), path(t.TestData.old); end
function testFeatureOrderAndIncompleteDonors(t)
[r,s]=fixture(); [f,a]=localFuseTscoreLocations(r,s);
verifyEqual(t,string({f.CadaverID}),["A" "B"]);
verifyEqual(t,f(1).RamanFeatures,[1:499 4:502]);
verifyEqual(t,a.excluded,"C");
s.locationCombineMode="mean"; f=localFuseTscoreLocations(r,s);
verifyEqual(t,f(1).RamanFeatures,(1:499)+1.5);
end
function testDuplicateAndGridGuards(t)
[r,s]=fixture(); r(end+1)=r(1);
verifyError(t,@()localFuseTscoreLocations(r,s),'MainGUI:TscoreDuplicateLocation');
[r,s]=fixture(); r(2).Wavenumber=r(2).Wavenumber+1;
verifyError(t,@()localFuseTscoreLocations(r,s),'MainGUI:TscoreLocationGrid');
end
function testDialogTemplateAndIndependentDemographics(t)
c=twoDigitDifferencePreset(guiDefaultConfig()); c.analysis.locationCombineMode="concat";
f=figure('Visible','off'); f.UserData=struct('config',c); clean=onCleanup(@()delete(f));
d=configureTscorePredictionDialog(f,false); set(d,'Visible','off');
verifyEmpty(t,findobj(d,'Tag','TscoreTwoDigitPreset')); verifyEmpty(t,findobj(d,'Tag','TscoreLocationCombineMode'));
setValue(d,'TscorePredictorSource',3); setValue(d,'TscoreBlockScale',1); press(d,'TscoreApply');
verifyEqual(t,f.UserData.config.analysis,c.analysis);
verifyEqual(t,f.UserData.config.tscore.locationCombineMode,"concat");
verifyEqual(t,f.UserData.config.tscore.locationTags,string(c.analysis.tags));
verifyTrue(t,f.UserData.config.tscore.blockScaleRamanDemographics);
end
function testOldPresetsClearLocationFusion(t)
c=twoDigitDifferencePreset(guiDefaultConfig()); c=intactRatioRidgePreset(c);
verifyEqual(t,c.tscore.locationCombineMode,"records");
end
function testFusionRequestIsAllowedButLegacyAllTagsStillGuarded(t)
f=figure('Visible','off'); clean=onCleanup(@()delete(f));
c=twoDigitDifferencePreset(guiDefaultConfig()); c.analysis.locationCombineMode="concat"; f.UserData=struct('config',c);
o=getGuiAnalysisOptions(f); validateAnalysisRequest(o); verifyTrue(t,o.locationFusionEnabled);
o.locationFusionEnabled=false;
verifyError(t,@()validateAnalysisRequest(o),'MainGUI:AllTagsNotAllowedForPrediction');
end
function [r,s]=fixture()
c=twoDigitDifferencePreset(guiDefaultConfig()); st=applyTscoreConfigToSettings(analysisDefaultSettings(),c.tscore); s=st.feature;
s.normalizationRegion='none'; s.spectrumCombineMode='diff';
r=repmat(struct('CadaverID','A','Tag','D2P1_MM00','Wavenumber',linspace(800,1750,499).', ...
    'Spectrum',[],'Tscore',-1,'Category','NORMAL','Age',60,'Sex',0,'BMI',25,'Weight',65),1,5);
r(1).CadaverID='B'; r(2).CadaverID='B'; r(2).Tag='D3P1_MM00';
r(4).Tag='D3P1_MM00'; r(5).CadaverID='C';
for j=1:5, r(j).Spectrum=[(1:499).'+10,10*ones(499,1)]; end
r(4).Spectrum=[(4:502).'+10,10*ones(499,1)];
end
function press(d,tag), h=findobj(d,'Tag',tag); cb=h.Callback; cb(h,[]); end
function setValue(d,tag,v), h=findobj(d,'Tag',tag); h.Value=v; cb=h.Callback; cb(h,[]); end

function tests=testStrictBoeParity
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.OriginalPath=path;
root=fileparts(fileparts(mfilename('fullpath')));addpath(root,fullfile(root,'analysis'));
end
function teardownOnce(t),path(t.TestData.OriginalPath);end
function testHistoricalDefaultsAreExplicit(t)
c=strictTscoreDefaultConfig();g=guiDefaultConfig();s=analysisDefaultSettings();
verifyEqual(t,g.strict,c);verifyEqual(t,s.strict,c);
verifyEqual(t,c.reconNComponents,5);verifyEqual(t,c.exposedSpectrumToPredict,2);
verifyEqual(t,c.plsAlgorithm,"NIPALS");verifyEqual(t,c.scalingDDOF,0);
verifyEqual(t,[c.measuredSvrBoxConstraint c.measuredSvrEpsilon c.measuredSvrKernelScale],[12.5 .3 112.5]);
verifyEqual(t,[c.svrBoxConstraint c.svrEpsilon c.svrKernelScale],[.75 .01 30]);
end
function testOlderConfigGetsIndependentDefaults(t)
c=validateStrictTscoreConfiguration(struct('reconNComponents',4));
verifyEqual(t,c.reconNComponents,4);verifyEqual(t,c.tscoreNormalizationRegion,"CH2");
bad=c;bad.scalingDDOF=2;verifyError(t,@()validateStrictTscoreConfiguration(bad),'MATLAB:notLessEqual');
bad=c;bad.intactSpectraToUse=[1 2 3];verifyError(t,@()validateStrictTscoreConfiguration(bad),'MainGUI:StrictSettings');
end
function testDedicatedGUIControlsAndApply(t)
before=findall(groot,'Type','figure');cleanup=onCleanup(@()delete(setdiff(findall(groot,'Type','figure'),before))); %#ok<NASGU>
GUI_Ver2;f=setdiff(findall(groot,'Type','figure'),before);f=f(1);
controls=f.UserData.controls;modes=analysisModeRegistry();
controls.modePopup.Value=find(strcmp({modes.value},'strictPredictTscore'));
cb=controls.modePopup.Callback;cb(controls.modePopup,[]);
verifyEqual(t,string(controls.strictConfigButton.Visible),"on");
verifyEqual(t,string(controls.tscoreConfigButton.Visible),"off");
d=configureStrictTscoreDialog(f);h=d.UserData.controls;
verifyNumElements(t,findall(d,'Type','uitab'),4);
verifyEqual(t,string(h.fixedTscoreRank.Enable),"off");
h.tscoreModel.Value=2;cb=h.tscoreModel.Callback;cb(h.tscoreModel,[]);
verifyEqual(t,string(h.fixedTscoreRank.Enable),"on");
verifyEqual(t,string(h.svrKernelScale.Enable),"off");
h.tscoreModel.Value=1;cb(h.tscoreModel,[]);
h.svrBoxConstraint.String='2.5';
button=findall(d,'Style','pushbutton','String','Apply');cb=button.Callback;cb(button,[]);
verifyFalse(t,isgraphics(d));verifyEqual(t,f.UserData.config.strict.svrBoxConstraint,2.5);
verifyEqual(t,f.UserData.config.tscore.svrBoxConstraint,.75);
d=configureStrictTscoreDialog(f);h=d.UserData.controls;h.svrBoxConstraint.String='99';
button=findall(d,'Style','pushbutton','String','Cancel');cb=button.Callback;cb(button,[]);
verifyEqual(t,f.UserData.config.strict.svrBoxConstraint,2.5);
end
function testStrictOuterDonorCannotInfluenceOwnPFit(t)
folder=tempname;mkdir(folder);
cleanup=onCleanup(@()removeFixture(folder)); %#ok<NASGU>
state=rng;rngCleanup=onCleanup(@()rng(state)); %#ok<NASGU>
rng(17);wn=(750:15:1750).';ids="DEMO"+string((1:6).');
categories=["NORMAL";"NORMAL";"OSTEOPENIA";"OSTEOPENIA";"OSTEOPOROSIS";"OSTEOPOROSIS"];
y=[.2;-.3;-1.4;-2.1;-3.2;-4];
for i=1:6
    exposed=2+.12*i*sin(wn/29)+.03*randn(numel(wn),3);
    intact=exposed+.08*i*cos(wn/43)+.02*randn(numel(wn),3);
    cads(i)=struct('id',char(ids(i)),'wn',wn,'E',{{exposed}},'T',{{intact}}, ...
        'list',{{char(ids(i)+"_E_D3P1_MM00"),char(ids(i)+"_T_D3P1_MM00")}}); %#ok<AGROW>
end
save(fullfile(folder,'input.mat'),'cads');
tab=table(ids,y,categories,'VariableNames',{'AGR-ID','Distal Radius T-Score (1/3)','WHO Classification (Distal Radius; 1/3)'});
writetable(tab,fullfile(folder,'labels.xlsx'));
s=strictTscoreDefaultConfig();s.reconTagsToUse={'D3P1_MM00'};s.combineMode="diff";
s.reconNComponents=2;s.reconNormalizationRegion="none";s.tscoreNormalizationRegion="none";s.measuredTscoreNormalizationRegion="none";
s.pairedCadaversFile=fullfile(folder,'input.mat');s.workbookFile=fullfile(folder,'labels.xlsx');
s.outputFolder=folder;s.analysisTag="D3P1_MM00";s.analysisSpectrumNumber=2;s.analysisSpectrumCombineMode="concat";
s.makeFigures=false;s.verbose=false;s.saveStrictPredictedCadavers=false;
a=runStrictTscoreValidation(s);
tab{1,2}=500;writetable(tab,s.workbookFile);b=runStrictTscoreValidation(s);
verifyEqual(t,b.yPredPredicted(1),a.yPredPredicted(1),'AbsTol',1e-5);
verifyEqual(t,b.yPredMeasured(1),a.yPredMeasured(1),'AbsTol',1e-5);
cads(1).E{1}=cads(1).E{1}+10*randn(size(cads(1).E{1}));save(s.pairedCadaversFile,'cads');
c=runStrictTscoreValidation(s);
verifyEqual(t,c.yPredPredicted(1),a.yPredPredicted(1),'AbsTol',1e-5);
verifyFalse(t,any(a.foldTrainingIDs{1}==ids(1)));
end
function removeFixture(folder)
% Delete only known test files from the newly created fixture directory.
for file=["input.mat","labels.xlsx","strict_tscore_predictions.csv","strict_tscore_summary.csv","strict_tscore_validation_result.mat"]
    p=fullfile(folder,file);if isfile(p),delete(p);end
end
if isfolder(folder),rmdir(folder);end
end

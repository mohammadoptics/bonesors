function tests = testReconstructionConfiguration
tests = functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.OriginalPath=path;
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'analysis'));
end
function teardownOnce(t)
path(t.TestData.OriginalPath);
end
function testDefaultsAndValidation(t)
c=validateReconstructionConfiguration(reconstructionDefaultConfig());
verifyEqual(t,c.exposedSpectrumToPredict,[1 2 3]);
verifyEqual(t,c.reconstructionModel,"PLS");
verifyEqual(t,c.plsAlgorithm,"NIPALS");
verifyEqual(t,c.plsMaxIterations,5000);
verifyEqual(t,c.plsTolerance,1e-6);
verifyFalse(t,isfield(c,'normalizePredictors'));
verifyFalse(t,isfield(c,'normalizeResponse'));
c.intactSpectraToUse=[3 2]; c=validateReconstructionConfiguration(c);
verifyEqual(t,c.intactSpectraToUse,[3 2]);
c.intactSpectraToUse=3;
verifyError(t,@()validateReconstructionConfiguration(c),'MainGUI:ReconstructionConfig');
c.combineMode="concat"; c=validateReconstructionConfiguration(c);
c.combinedOutputFileName="../bad.mat";
verifyError(t,@()validateReconstructionConfiguration(c),'MainGUI:ReconstructionConfig');
end
function testLegacyNormalizationSwitchMigration(t)
c=reconstructionDefaultConfig();
c.normalizePredictors=false; c.normalizeResponse=true;
c=validateReconstructionConfiguration(c);
verifyEqual(t,c.normalizationRegion,"none");
verifyEqual(t,c.responseNormalizationRegion,"CH2");
verifyFalse(t,isfield(c,'normalizePredictors'));
c.normalizationRegion="PO4";
c=validateReconstructionConfiguration(c);
verifyEqual(t,c.normalizationRegion,"PO4");
end
function testDialogApplyAndCancel(t)
f=figure('Visible','off'); cleanup=onCleanup(@()delete(f)); %#ok<NASGU>
f.UserData=struct('config',guiDefaultConfig(),'analysisAvailableTags',{{'D3P1_MM00'}});
d=configureReconstructionDialog(f,false); dc=onCleanup(@()deleteIfValid(d)); %#ok<NASGU>
h=d.UserData.controls;
verifyFalse(t,isfield(h,'normalizePredictors'));
verifyFalse(t,isfield(h,'normalizeResponse'));
verifyEqual(t,string(h.mlpMaxEpochs.Enable),"off");
verifyEqual(t,string(h.plsMaxIterations.Enable),"on");
h.plsAlgorithm.Value=2;
refreshAlgorithm=h.plsAlgorithm.Callback; refreshAlgorithm();
verifyEqual(t,string(h.plsMaxIterations.Enable),"off");
h.plsAlgorithm.Value=1; refreshAlgorithm();
verifyEqual(t,string(h.plsTolerance.Enable),"on");
h.reconstructionModel.Value=3;
refresh=h.reconstructionModel.Callback; refresh();
verifyEqual(t,string(h.krrAlpha.Enable),"on");
verifyEqual(t,string(h.fixedNComponents.Enable),"off");
verifyEqual(t,string(h.plsAlgorithm.Enable),"off");
h.normalizationRegion.Value=1; refresh();
verifyEqual(t,string(h.normalizationMethod.Enable),"off");
h.normalizationRegion.Value=4; refresh();
verifyEqual(t,string(h.normalizationMethod.Enable),"on");
h.intactSpectraToUse.String='1,3'; h.exposedSpectrumToPredict.String='3';
h.normalizationRegion.Value=4; % CH2
h.responseNormalizationRegion.Value=6; % AmideIII
h.fixedNComponents.String='3';
button=findall(d,'Tag','ReconstructionApply'); cb=button.Callback; cb(button,[]);
verifyFalse(t,isgraphics(d));
c=f.UserData.config.reconstruction;
verifyEqual(t,c.intactSpectraToUse,[1 3]);
verifyEqual(t,c.exposedSpectrumToPredict,3);
verifyEqual(t,c.responseNormalizationRegion,"AmideIII");
verifyEqual(t,c.fixedNComponents,3);
verifyEqual(t,c.reconstructionModel,"KRR_RBF");
d=configureReconstructionDialog(f,false); dc2=onCleanup(@()deleteIfValid(d)); %#ok<NASGU>
d.UserData.controls.fixedNComponents.String='9'; close(d);
verifyEqual(t,f.UserData.config.reconstruction.fixedNComponents,3);
end
function testPLSExportAndHeldOutExclusion(t)
[cads,c,out]=fixture(t);
c.saveOutputMode="both"; c.exposedSpectrumToPredict=[3 2];
c.plsAlgorithm="SIMPLS"; % Independent regression check of the retained legacy path.
c.normalizationRegion="none"; c.responseNormalizationRegion="none";
modifiedPLS(cads,out,"PLS",c);
s=load(fullfile(out,'predictedCadavers.mat'));
verifyNumElements(t,s.cads,numel(cads));
for k=1:numel(cads)
    verifyEqual(t,s.cads(k).Tscore,cads(k).Tscore);
    verifyEqual(t,s.cads(k).E(:),cads(k).E(:));
    verifyTrue(t,all(isnan(s.cads(k).P{1}(:,1))));
    verifyTrue(t,all(isfinite(s.cads(k).P{1}(:,2:3)),'all'));
    verifyFalse(t,any(s.reconstructionInfo{k}.processoptions.trainingCadaverIDs==string(cads(k).id)));
end
% Independent manual fold, including output-column mapping.
X=[]; Y=[];
for k=2:numel(cads)
    for j=1:2
        X(end+1,:)=(cads(k).T{j}(:,3)-cads(k).T{j}(:,2)).'; %#ok<AGROW>
        Y(end+1,:)=reshape(cads(k).E{j}(:,[3 2]),1,[]); %#ok<AGROW>
    end
end
xMu=mean(X); xs=std(X); xs(xs==0)=1;
yMu=mean(Y); ys=std(Y); ys(ys==0)=1;
[~,~,~,~,beta]=plsregress((X-xMu)./xs,(Y-yMu)./ys,2);
q=(cads(1).T{1}(:,3)-cads(1).T{1}(:,2)).';
expected=([1 (q-xMu)./xs]*beta).*ys+yMu;
verifyEqual(t,s.cads(1).P{1}(:,[3 2]),reshape(expected,numel(cads(1).wn),2),'AbsTol',1e-10);
end
function testInnerLOCOAndKRR(t)
[cads,c,out]=fixture(t);
c.useInnerCVForNComponents=true; c.maxComponentsForCV=2;
c.responseNormalizationRegion="AmideIII";
modifiedPLS(cads,out,"PLS",c);
s=load(fullfile(out,'predictedCadavers.mat'));
verifyTrue(t,all(cellfun(@(p)p.processoptions.nComponents<=2,s.reconstructionInfo)));
verifyEqual(t,s.reconstructionInfo{1}.processoptions.responseNormalizationRegion,"AmideIII");
out2=fullfile(out,'krr');
c.useInnerCVForNComponents=false;
modifiedPLS(cads,out2,"KRR_RBF",c);
s=load(fullfile(out2,'predictedCadavers.mat'));
verifyTrue(t,all(isfinite(s.cads(1).P{1}),'all'));
end
function testMLPConfiguredOrClearlyUnavailable(t)
[cads,c,out]=fixture(t);
c.mlpHiddenLayerSizes=3; c.mlpMaxEpochs=2;
if exist('fitnet','file')~=2
    verifyError(t,@()modifiedPLS(cads,out,"MLP",c),'MainGUI:ReconstructionMLPUnavailable');
else
    modifiedPLS(cads,out,"MLP",c);
    s=load(fullfile(out,'predictedCadavers.mat'));
    verifyTrue(t,all(isfinite(s.cads(1).P{1}),'all'));
end
end
function testDispatcherOutputAndOverwriteProtection(t)
[cads,c,out]=fixture(t);
f=figure('Visible','off'); cleanup=onCleanup(@()delete(f)); %#ok<NASGU>
config=guiDefaultConfig(); config.reconstruction=c; config.analysisOutputDirectory=out;
f.UserData=struct('config',config,'analysisData',struct('cads',cads), ...
    'analysisDatasetType',"cadaverDataset",'analysisFile','synthetic_test.mat');
ud=f.UserData; ud.config.reconstruction.reconstructionModel="KRR_RBF"; f.UserData=ud;
runReconstructionAnalysis(f);
folder=f.UserData.lastReconstructionOutputDirectory;
verifyTrue(t,startsWith(folder,out));
verifyTrue(t,isfile(fullfile(folder,'predictedCadavers.mat')));
m=jsondecode(fileread(fullfile(folder,'reconstruction_settings.json')));
verifyEqual(t,string(m.status),"complete");
verifyEqual(t,string(m.sourceDataset),"synthetic_test.mat");
verifyEqual(t,string(m.model),"KRR_RBF");
verifyEqual(t,string(m.settings.reconstructionModel),"KRR_RBF");
s=load(fullfile(folder,'predictedCadavers.mat'));
verifyEqual(t,string(s.reconstructionInfo{1}.processoptions.reconstructionModel),"KRR_RBF");
ud=f.UserData; ud.config.reconstruction.createRunSubfolder=false;
ud.config.analysisOutputDirectory=folder; f.UserData=ud;
verifyError(t,@()runReconstructionAnalysis(f),'MainGUI:ReconstructionOutputExists');
end
function testReconstructionControlsVisible(t)
existing=findall(groot,'Type','figure'); GUI_Ver2;
created=setdiff(findall(groot,'Type','figure'),existing);
cleanup=onCleanup(@()delete(created)); %#ok<NASGU>
f=created(1); h=f.UserData.controls; registry=analysisModeRegistry();
for mode="reconstructSpectra"
    h.modePopup.Value=find(strcmp({registry.value},mode));
    cb=h.modePopup.Callback; cb(h.modePopup,[]);
    verifyEqual(t,string(h.reconstructionConfigButton.Visible),"on");
    verifyEqual(t,string(h.spectrumEdit.Enable),"off");
    verifyEqual(t,string(h.tscoreConfigButton.Visible),"off");
end
end
function [cads,c,out]=fixture(t)
tmp=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
out=tmp.Folder;
c=reconstructionDefaultConfig(); c.fixedNComponents=2;
wn=(800:5:1750).';
saved=rng; cleanup=onCleanup(@()rng(saved)); rng(42); %#ok<NASGU>
base=0.1+exp(-((wn-960)/20).^2)+0.7*exp(-((wn-1270)/25).^2)+0.8*exp(-((wn-1440)/25).^2)+0.4*exp(-((wn-1660)/25).^2);
for k=1:6
    cads(k).id=sprintf('TEST%02d',k); %#ok<AGROW>
    cads(k).wn=wn; cads(k).category='NORMAL'; cads(k).Tscore=-k/2;
    for j=1:2
        cads(k).E{j}=base.*[1 1.1 1.2]+0.03*rand(numel(wn),3)+k*.01;
        cads(k).T{j}=base.*[1.3 1.2 1.1]+0.08*rand(numel(wn),3)+j*.02;
        tag=c.tagsToUse{j};
        cads(k).list(j,:)={sprintf('%s_E_%s.mat',cads(k).id,tag),sprintf('%s_T_%s.mat',cads(k).id,tag)};
    end
end
end
function deleteIfValid(h)
if isgraphics(h), delete(h); end
end

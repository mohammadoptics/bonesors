function tests=testStructuredTscoreDialog
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.OldPath=path; root=fileparts(fileparts(mfilename('fullpath')));
addpath(root, fullfile(root,'app'), fullfile(root,'app','analysis'));
end
function teardownOnce(t), path(t.TestData.OldPath); end
function testIndependentSourceScalingAndModels(t)
[f,d]=dialogFixture(); clean=onCleanup(@()closeBoth(f,d));
source=findobj(d,'Tag','TscorePredictorSource');
verifyEqual(t,numel(source.String),3);
setValue(d,'TscorePredictorSource',3);
setValue(d,'TscoreRamanFeatureMode',2);
setValue(d,'TscoreModelRIDGE',1);
setValue(d,'TscoreBlockScale',1);
verifyEqual(t,get(findobj(d,'Tag','TscoreModelPLS'),'Value'),1);
verifyEqual(t,get(findobj(d,'Tag','TscoreModelSVR'),'Value'),1);
verifyEqual(t,get(findobj(d,'Tag','TscoreModelRIDGE'),'Value'),1);
verifyEqual(t,get(findobj(d,'Tag','TscoreRamanFeatureMode'),'Value'),2);
verifyEqual(t,get(findobj(d,'Tag','TscoreValidationProtocol'),'Value'),1);
press(d,'TscoreApply');
c=f.UserData.config.tscore;
verifyEqual(t,c.models,["PLS" "SVR" "RIDGE"]);
verifyTrue(t,c.blockScaleRamanDemographics);
verifyEqual(t,c.ramanFeatureMode,"ratios");
end
function testBlockStandardizationGuardAndNoSilentModelChanges(t)
[f,d]=dialogFixture(); clean=onCleanup(@()closeBoth(f,d));
setValue(d,'TscorePredictorSource',3); setValue(d,'TscoreBlockScale',1);
setValue(d,'TscoreStandardize',0);
verifyEqual(t,get(findobj(d,'Tag','TscoreApply'),'Enable'),'off');
verifyTrue(t,contains(string(get(findobj(d,'Tag','TscoreDialogStatus'),'String')),'standardization'));
verifyEqual(t,get(findobj(d,'Tag','TscoreModelSVR'),'Value'),1);
setValue(d,'TscoreStandardize',1);
verifyEqual(t,get(findobj(d,'Tag','TscoreApply'),'Enable'),'on');
setValue(d,'TscorePredictorSource',1);
verifyEqual(t,get(findobj(d,'Tag','TscoreBlockScale'),'Enable'),'off');
press(d,'TscoreApply');
verifyFalse(t,f.UserData.config.tscore.blockScaleRamanDemographics);
end
function testEditableGridAndMixedMatchedModels(t)
[f,d]=dialogFixture(); clean=onCleanup(@()closeBoth(f,d));
setValue(d,'TscoreValidationProtocol',2); setValue(d,'TscoreSvrTuningMode',2); setValue(d,'TscoreModelRIDGE',1);
set(findobj(d,'Tag','TscoreSvrCGrid'),'String','0.2, 2, 20');
set(findobj(d,'Tag','TscoreSvrEpsilonGrid'),'String','0.05 0.2');
set(findobj(d,'Tag','TscoreSvrScaleGrid'),'String','1; 4');
set(findobj(d,'Tag','TscoreRidgeAlphaGrid'),'String','0.1 10');
press(d,'TscoreApply');
c=f.UserData.config.tscore;
verifyEqual(t,c.models,["PLS" "SVR" "RIDGE"]); verifyEqual(t,c.svrBoxConstraintGrid,[.2 2 20]);
verifyEqual(t,c.svrEpsilonGrid,[.05 .2]); verifyEqual(t,c.svrKernelScaleGrid,[1 4]);
verifyEqual(t,c.ridgeAlphaGrid,[.1 10]); verifyEqual(t,c.validationProtocol,"matchedKFold");
end
function testNativeSvrBlockWeightsAndUnscaledParity(t)
[X,y,ids,s]=fixture(); s.svrOptimizationMode="fixed";
p=localPredictTscoreSVR(X,y,ids,s,[4 2]); q=localPredictTscoreSVR(X,y,ids,s);
test=ids==ids(1); A=X(~test,:); B=X(test,:);
mu=mean(A); sd=std(A); weights=[ones(1,4)/2 ones(1,2)/sqrt(2)];
a=((A-mu)./sd).*weights; b=((B-mu)./sd).*weights;
m=fitrsvm(a,y(~test),'KernelFunction','gaussian','KernelScale',s.svrKernelScale, ...
    'BoxConstraint',s.svrBoxConstraint,'Epsilon',s.svrEpsilon,'Standardize',false);
verifyEqual(t,p(test),predict(m,b),'AbsTol',1e-10);
m=fitrsvm(A,y(~test),'KernelFunction','gaussian','KernelScale',s.svrKernelScale, ...
    'BoxConstraint',s.svrBoxConstraint,'Epsilon',s.svrEpsilon,'Standardize',true);
verifyEqual(t,q(test),predict(m,B),'AbsTol',1e-10);
s.standardizePredictors=false;
verifyError(t,@()localPredictTscoreSVR(X,y,ids,s,[4 2]),'MainGUI:TscoreBlockScaling');
end
function testNativeNestedSvrHeldOutIsolation(t)
[X,y,ids,s]=fixture(); s.svrOptimizationMode="nested";
s.svrBoxConstraintGrid=[1 3]; s.svrEpsilonGrid=.1; s.svrKernelScaleGrid=2;
s.svrBoxConstraint=1; s.svrEpsilon=.1; s.svrKernelScale=2; s.svrMaxCandidates=2;
[p,a]=localPredictTscoreSVR(X,y,ids,s,[4 2]);
test=ids==ids(1); y(test)=y(test)+100;
[q,b]=localPredictTscoreSVR(X,y,ids,s,[4 2]);
verifyEqual(t,p(test),q(test),'AbsTol',1e-10);
verifyEqual(t,a(1),b(1));
X(test,:)=X(test,:)+100;
[~,c]=localPredictTscoreSVR(X,y,ids,s,[4 2]);
verifyEqual(t,a(1),c(1));
end
function testMlpBlockWeights(t)
[X,y,ids,s]=fixture(); s.mlpHiddenLayers=3; s.mlpMaxEpochs=10;
p=localPredictTscoreMLP(X,y,ids,s,[4 2]);
test=ids==ids(1); [a,b]=localStandardizeTrainTest(X(~test,:),X(test,:),[4 2]);
old=rng; clean=onCleanup(@()rng(old)); rng(s.randomSeed,'twister');
m=fitrnet(a,y(~test),'LayerSizes',3,'Activations','relu','Lambda',s.mlpRegularization, ...
    'Standardize',false,'StandardizeResponses',true,'IterationLimit',10,'Verbose',0);
verifyEqual(t,p(test),predict(m,b),'AbsTol',1e-10);
s.standardizePredictors=false;
verifyError(t,@()localPredictTscoreMLP(X,y,ids,s,[4 2]),'MainGUI:TscoreBlockScaling');
end
function [X,y,ids,s]=fixture()
old=rng; clean=onCleanup(@()rng(old)); rng(74);
X=randn(16,6); X(:,5:6)=10*X(:,5:6)+30;
y=X(:,1)+.1*X(:,5); ids=repelem("C"+string((1:8)'),2);
c=guiDefaultConfig(); a=applyTscoreConfigToSettings(analysisDefaultSettings(),c.tscore); s=a.feature;
s.svrInnerFolds=3;
end
function [f,d]=dialogFixture()
f=figure('Visible','off'); f.UserData=struct('config',guiDefaultConfig());
d=configureTscorePredictionDialog(f,false); set(d,'Visible','off');
end
function setValue(d,tag,value)
h=findobj(d,'Tag',tag); h.Value=value; cb=h.Callback; cb(h,[]);
end
function press(d,tag)
h=findobj(d,'Tag',tag); cb=h.Callback; cb(h,[]);
end
function closeBoth(f,d)
if isgraphics(d), delete(d); end
if isgraphics(f), delete(f); end
end

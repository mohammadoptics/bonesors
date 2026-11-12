function tests = testBlockScaledPLS
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
testCase.TestData.OriginalPath = path;
addpath(root,fullfile(root,'analysis'));
end

function teardownOnce(testCase)
path(testCase.TestData.OriginalPath);
end

function testDefaultAndLegacyConfigurationsRemainUnscaled(testCase)
c = guiDefaultConfig();
verifyFalse(testCase,c.tscore.blockScaleRamanDemographics);
old = rmfield(c.tscore,'blockScaleRamanDemographics');
completed = completeTscoreConfiguration(old);
verifyFalse(testCase,completed.blockScaleRamanDemographics);
end

function testTrainingOnlyScalingAndBlockVariance(testCase)
[X,~,~] = syntheticData();
train = X(1:8,:); heldout = X(9:end,:);
[a,b] = localStandardizeTrainTest(train,heldout,[4 2]);
w = [ones(1,4)/2 ones(1,2)/sqrt(2)];
verifyEqual(testCase,a,((train-mean(train))./std(train)).*w,'AbsTol',1e-12);
verifyEqual(testCase,b,((heldout-mean(train))./std(train)).*w,'AbsTol',1e-12);
verifyEqual(testCase,sum(var(a(:,1:4))),1,'AbsTol',1e-12);
verifyEqual(testCase,sum(var(a(:,5:6))),1,'AbsTol',1e-12);
[changed,~] = localStandardizeTrainTest(train,heldout+1000,[4 2]);
verifyEqual(testCase,changed,a);
[plainTrain,plainTest] = localStandardizeTrainTest(train,heldout);
[emptyTrain,emptyTest] = localStandardizeTrainTest(train,heldout,[]);
verifyEqual(testCase,plainTrain,emptyTrain);
verifyEqual(testCase,plainTest,emptyTest);
end

function testConstantColumnsAndInvalidBlocks(testCase)
[X,y,ids] = syntheticData();
X(:,6) = 1;
[a,b] = localStandardizeTrainTest(X(1:8,:),X(9:end,:),[5 1]);
verifyTrue(testCase,all(isfinite([a(:);b(:)])));
verifyEqual(testCase,a(:,6),zeros(8,1));
verifyError(testCase,@()localStandardizeTrainTest(X,X,[4 1]), ...
    'MainGUI:TscoreBlockSizes');
verifyError(testCase,@()localPredictTscorePLS(X,y,ids,3,[],false,[4 2]), ...
    'MainGUI:TscoreBlockScaling');
end

function testNestedPredictionsMatchIndependentFoldCalculation(testCase)
[X,y,ids] = syntheticData();
[pred,ranks,tuning] = localPredictTscorePLS(X,y,ids,3,[],true,[4 2]);
outerTest = ids == ids(1); outerTrain = ~outerTest;
trainX = X(outerTrain,:); trainY = y(outerTrain); trainIDs = ids(outerTrain);
uniqueIDs = unique(trainIDs,'stable');
innerPred = nan(numel(trainY),3);
for k = 1:numel(uniqueIDs)
    test = trainIDs == uniqueIDs(k);
    [a,b] = referenceScale(trainX(~test,:),trainX(test,:));
    for rank = 1:3
        [~,~,~,~,beta] = plsregress(a,trainY(~test),rank);
        innerPred(test,rank) = [ones(sum(test),1) b]*beta;
    end
end
truth = zeros(numel(uniqueIDs),1); prediction = zeros(numel(uniqueIDs),3);
for k = 1:numel(uniqueIDs)
    rows = trainIDs == uniqueIDs(k);
    truth(k) = mean(trainY(rows));
    prediction(k,:) = mean(innerPred(rows,:),1);
end
[expectedRMSE,expectedRank] = min(sqrt(mean((prediction-truth).^2,1)));
[a,b] = referenceScale(trainX,X(outerTest,:));
[~,~,~,~,beta] = plsregress(a,trainY,expectedRank);
verifyEqual(testCase,pred(outerTest),[ones(sum(outerTest),1) b]*beta,'AbsTol',1e-10);
verifyEqual(testCase,ranks(outerTest),repmat(expectedRank,sum(outerTest),1));
verifyEqual(testCase,tuning(1).InnerRMSE,expectedRMSE,'AbsTol',1e-10);

% Changing all outcomes for the outer donor cannot change that donor's fit.
changedY = y; changedY(outerTest) = 1000;
[pred2,ranks2,tuning2] = localPredictTscorePLS(X,changedY,ids,3,[],true,[4 2]);
verifyEqual(testCase,pred2(outerTest),pred(outerTest),'AbsTol',1e-10);
verifyEqual(testCase,ranks2(outerTest),ranks(outerTest));
verifyEqual(testCase,tuning2(1).InnerRMSE,tuning(1).InnerRMSE,'AbsTol',1e-10);

% Changing outer test predictors cannot affect inner selection either.
changedX = X; changedX(outerTest,:) = changedX(outerTest,:) + 500;
[~,ranks3,tuning3] = localPredictTscorePLS(changedX,y,ids,3,[],true,[4 2]);
verifyEqual(testCase,ranks3(outerTest),ranks(outerTest));
verifyEqual(testCase,tuning3(1).InnerRMSE,tuning(1).InnerRMSE,'AbsTol',1e-10);
end

function testFixedComponentsUseBlockWeights(testCase)
[X,y,ids] = syntheticData();
[pred,ranks,tuning] = localPredictTscorePLS(X,y,ids,3,2,true,[4 2]);
test = ids == ids(1);
[a,b] = referenceScale(X(~test,:),X(test,:));
[~,~,~,~,beta] = plsregress(a,y(~test),2);
verifyEqual(testCase,pred(test),[ones(sum(test),1) b]*beta,'AbsTol',1e-10);
verifyEqual(testCase,ranks,2*ones(size(y)));
verifyTrue(testCase,all([tuning.FixedRank]));
end

function testConfigurationMappingAndGuardrails(testCase)
c = guiDefaultConfig(); c = c.tscore;
c.predictorSource = "combined";
c.models = "PLS";
c.blockScaleRamanDemographics = true;
c = validateTscoreConfiguration(c);
s = applyTscoreConfigToSettings(analysisDefaultSettings(),c);
verifyTrue(testCase,s.feature.blockScaleRamanDemographics);
verifyTrue(testCase,contains(string(formatTscoreConfigSummary(c)),"Block-scaled"));
verifyTrue(testCase,contains(localTscoreModelAnnotation("PLS; block-scaled",NaN),"block-scaled"));
bad = c; bad.standardizePredictors = false;
verifyError(testCase,@()validateTscoreConfiguration(bad),'MainGUI:TscoreBlockScaling');
allowed = c; allowed.models = ["PLS" "SVR" "RIDGE" "MLP"];
validateTscoreConfiguration(allowed);
allowed.ramanFeatureMode = "ratios"; validateTscoreConfiguration(allowed);
bad = c; bad.useAge = false; bad.useSex = false; bad.useBMI = false; bad.useWeight = false;
verifyError(testCase,@()validateTscoreConfiguration(bad),'MainGUI:TscorePredictors');
end

function testRecordPipelineUsesActualSpectralAndDemographicCounts(testCase)
state = rng; cleanup = onCleanup(@()rng(state)); %#ok<NASGU>
rng(7);
c = guiDefaultConfig(); c = c.tscore;
c.predictorSource = "combined"; c.models = "PLS";
c.blockScaleRamanDemographics = true;
c.useAge = true; c.useSex = false; c.useBMI = false; c.useWeight = true;
c.normalizationRegion = "none"; c.fixedPLSRank = 2;
s = applyTscoreConfigToSettings(analysisDefaultSettings(),c);
f = s.feature; f.tscoreModel = "pls"; f.spectrumCombineMode = "concat";
wn = linspace(800,1750,499).';
records = repmat(struct('Spectrum',[],'Wavenumber',wn,'Age',0,'Sex',0, ...
    'BMI',0,'Weight',0,'Tscore',0,'Category',"NORMAL",'CadaverID',""),8,1);
X = zeros(8,1000);
for k = 1:8
    records(k).Spectrum = 10+randn(499,2);
    records(k).Age = 50+randn; records(k).Weight = 70+randn;
    records(k).Tscore = -2+randn;
    records(k).CadaverID = "CAD"+k;
    X(k,:) = [records(k).Spectrum(:).' records(k).Age records(k).Weight];
end
result = localComputeTscorePrediction(records,'E',[2 3],3,f);
expected = localPredictTscorePLS(X,[records.Tscore].', ...
    string({records.CadaverID}).',3,2,true,[998 2]);
verifyTrue(testCase,result.ok);
verifyEqual(testCase,result.blockSizes,[998 2]);
verifyEqual(testCase,result.nFeatures,1000);
verifyEqual(testCase,result.yPred,expected,'AbsTol',1e-10);
verifyTrue(testCase,contains(result.modelText,"block-scaled"));
verifyTrue(testCase,contains(result.featureLabel,"block-scaled"));
f.tscoreFeatureMode = "ratiosConcat";
r = localComputeTscorePrediction(records,'E',[2 3],3,f);
verifyTrue(testCase,r.ok); verifyEqual(testCase,r.blockSizes,[10 2]);
end

function testDialogAppliesAndRestoresBlockScaledOption(testCase)
parent = figure('Visible','off');
cleanup = onCleanup(@()delete(parent)); %#ok<NASGU>
parent.UserData = struct('config',guiDefaultConfig());
dialog = configureTscorePredictionDialog(parent,false);
cleanupDialog = onCleanup(@()closeIfPresent(dialog)); %#ok<NASGU>
source = findobj(dialog,'Tag','TscorePredictorSource');
set(source,'Value',3); callback = get(source,'Callback'); callback(source,[]);
block=findobj(dialog,'Tag','TscoreBlockScale'); set(block,'Value',1); callback=block.Callback; callback(block,[]);
verifyEqual(testCase,get(findobj(dialog,'Tag','TscoreModelSVR'),'Enable'),'on');
verifyEqual(testCase,get(findobj(dialog,'Tag','TscoreRamanFeatureMode'),'Enable'),'on');
verifyEqual(testCase,get(findobj(dialog,'Tag','TscoreStandardize'),'Value'),1);
apply = findobj(dialog,'Tag','TscoreApply'); callback = get(apply,'Callback'); callback(apply,[]);
saved = parent.UserData.config.tscore;
verifyTrue(testCase,saved.blockScaleRamanDemographics);
verifyEqual(testCase,saved.predictorSource,"combined");
verifyEqual(testCase,saved.models,["PLS" "SVR"]);
dialog2 = configureTscorePredictionDialog(parent,false);
cleanupDialog2 = onCleanup(@()closeIfPresent(dialog2)); %#ok<NASGU>
source = findobj(dialog2,'Tag','TscorePredictorSource');
verifyEqual(testCase,get(source,'Value'),3);
block=findobj(dialog2,'Tag','TscoreBlockScale'); verifyEqual(testCase,block.Value,1);
set(block,'Value',0); callback=block.Callback; callback(block,[]);
set(source,'Value',3); callback = get(source,'Callback'); callback(source,[]);
verifyEqual(testCase,get(findobj(dialog2,'Tag','TscoreRamanFeatureMode'),'Enable'),'on');
verifyEqual(testCase,get(findobj(dialog2,'Tag','TscoreModelSVR'),'Enable'),'on');
apply = findobj(dialog2,'Tag','TscoreApply'); callback = get(apply,'Callback'); callback(apply,[]);
verifyFalse(testCase,parent.UserData.config.tscore.blockScaleRamanDemographics);
end

function [a,b] = referenceScale(train,test)
mu = mean(train,1); sd = std(train,0,1);
sd(~isfinite(sd) | sd == 0) = 1;
w = [ones(1,4)/2 ones(1,2)/sqrt(2)];
a = ((train-mu)./sd).*w; b = ((test-mu)./sd).*w;
end

function [X,y,ids] = syntheticData()
state = rng; cleanup = onCleanup(@()rng(state)); %#ok<NASGU>
rng(31);
X = randn(16,6); X(:,5:6) = 20+10*X(:,5:6);
y = 2*X(:,1) + 0.3*X(:,5) + 0.1*randn(16,1);
ids = repelem("CAD"+string((1:8).'),2);
end

function closeIfPresent(h)
if isgraphics(h), delete(h); end
end

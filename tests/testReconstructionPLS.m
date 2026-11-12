function tests=testReconstructionPLS
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.OriginalPath=path;
addpath(fileparts(fileparts(mfilename('fullpath'))));
end
function teardownOnce(t)
path(t.TestData.OriginalPath);
end
function testIndependentSklearnGoldenPredictions(t)
d=load(fullfile(fileparts(mfilename('fullpath')),'fixtures','sklearn_nipals_reference.mat'));
for j=1:numel(d.ranks)
    [p,info]=fitReconstructionPLS(d.X,d.Y,d.Xtest,double(d.ranks(j)));
    verifyEqual(t,p,d.predictions(:,:,j),'AbsTol',1e-11);
    verifyEqual(t,info.algorithm,"NIPALS");
    verifyEqual(t,info.fittedComponents,double(d.ranks(j)));
end
end
function testConstantResponse(t)
X=reshape(sin(1:60),10,6); Y=repmat([2 -3 1],10,1);
[p,info]=fitReconstructionPLS(X,Y,X(1:2,:),2);
verifyEqual(t,p,Y(1:2,:),'AbsTol',1e-12);
verifyEqual(t,info.fittedComponents,0);
end
function testLegacySIMPLS(t)
d=load(fullfile(fileparts(mfilename('fullpath')),'fixtures','sklearn_nipals_reference.mat'));
p=fitReconstructionPLS(d.X,d.Y,d.Xtest,3,"SIMPLS");
[~,~,~,~,b]=plsregress(d.X,d.Y,3);
verifyEqual(t,p,[ones(4,1),d.Xtest]*b,'AbsTol',1e-12);
verifyGreaterThan(t,max(abs(p-d.predictions(:,:,2)),[],'all'),1e-4);
end
function testAlgorithmConfiguration(t)
c=reconstructionDefaultConfig(); c.plsAlgorithm="SIMPLS";
c=validateReconstructionConfiguration(c); verifyEqual(t,c.plsAlgorithm,"SIMPLS");
c.plsTolerance=0;
verifyError(t,@()validateReconstructionConfiguration(c),'MATLAB:expectedPositive');
end

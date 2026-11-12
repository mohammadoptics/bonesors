function tests=testCompactReconstruction
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.oldPath=path;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root, fullfile(root,'app'));
end
function teardownOnce(t)
path(t.TestData.oldPath);
end
function testDefaultsMigration(t)
c=validateReconstructionConfiguration(struct('reconstructionModel',"PCA_MLP"));
verifyEqual(t,c.compactInputPCGrid,[5 10]);
verifyEqual(t,c.compactSeeds,[7 17 27]);
verifyEqual(t,c.compactOutputPCs,5);
verifyTrue(t,contains(formatReconstructionConfigSummary(c),'Compact PCA + MLP'));
c.compactSeeds=[7 7];
verifyError(t,@()validateReconstructionConfiguration(c),'MainGUI:ReconstructionConfig');
end
function testDialogSelectionAndSave(t)
f=figure('Visible','off'); clean=onCleanup(@()delete(f)); %#ok<NASGU>
f.UserData=struct('config',guiDefaultConfig());
d=configureReconstructionDialog(f,false); clean2=onCleanup(@()safeDelete(d)); %#ok<NASGU>
h=d.UserData.controls;
verifyEqual(t,h.compactAlphaGrid.Enable,'off');
h.reconstructionModel.Value=find(strcmp(h.reconstructionModel.UserData,'PCA_MLP'));
cb=h.reconstructionModel.Callback; cb();
verifyEqual(t,h.compactAlphaGrid.Enable,'on');
verifyEqual(t,h.mlpMaxEpochs.Enable,'off');
verifyEqual(t,h.krrAlpha.Enable,'off');
h.compactSeeds.String='7,17,27'; h.compactInputPCGrid.String='5,10';
b=findall(d,'Tag','ReconstructionApply'); cb=b.Callback; cb(b,[]);
verifyFalse(t,isgraphics(d));
verifyEqual(t,f.UserData.config.reconstruction.reconstructionModel,"PCA_MLP");
verifyEqual(t,f.UserData.config.reconstruction.compactSeeds,[7 17 27]);
end
function testMissingPython(t)
c=reconstructionDefaultConfig(); c.compactPython="C:\not_an_installed_python\python.exe";
verifyError(t,@()predictCompactReconstruction(ones(4),ones(4),["a","b","c","d"],c,tempdir), ...
    'MainGUI:CompactPythonUnavailable');
end
function safeDelete(f)
if isgraphics(f), delete(f); end
end

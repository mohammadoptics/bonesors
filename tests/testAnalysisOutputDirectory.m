function tests=testAnalysisOutputDirectory
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.old=path; addpath(fileparts(fileparts(mfilename('fullpath'))));
end
function teardownOnce(t), path(t.TestData.old); end
function testExistingFolderNeverPrompts(t)
f=fixture(); clean=onCleanup(@()delete(f)); ud=f.UserData;
ud.config.analysisOutputDirectory=string(tempdir); f.UserData=ud;
verifyTrue(t,ensureAnalysisOutputDirectory(f,@mustNotPrompt));
verifyEqual(t,f.UserData.config.analysisOutputDirectory,string(tempdir));
end
function testSelectionSavedAndLabelUpdated(t)
f=fixture(); clean=onCleanup(@()delete(f));
verifyTrue(t,ensureAnalysisOutputDirectory(f,@(~,~)tempdir));
verifyEqual(t,f.UserData.config.analysisOutputDirectory,string(tempdir));
verifyEqual(t,string(f.UserData.controls.outputDirectoryText.TooltipString),string(tempdir));
verifyTrue(t,ensureAnalysisOutputDirectory(f,@mustNotPrompt));
end
function testCancellationDoesNotChangeConfiguration(t)
f=fixture(); clean=onCleanup(@()delete(f)); before=f.UserData.config;
verifyFalse(t,ensureAnalysisOutputDirectory(f,@(~,~)0));
verifyEqual(t,f.UserData.config,before);
end
function testMissingFolderPromptsAgain(t)
f=fixture(); clean=onCleanup(@()delete(f)); ud=f.UserData;
ud.config.analysisOutputDirectory=string(tempname); f.UserData=ud;
verifyTrue(t,ensureAnalysisOutputDirectory(f,@(~,~)tempdir));
verifyEqual(t,f.UserData.config.analysisOutputDirectory,string(tempdir));
end
function testInvalidSelectionStopsRun(t)
f=fixture(); clean=onCleanup(@()delete(f));
verifyError(t,@()ensureAnalysisOutputDirectory(f,@(~,~)tempname),'MainGUI:InvalidOutputDirectory');
verifyEqual(t,f.UserData.config.analysisOutputDirectory,"");
end
function f=fixture()
f=figure('Visible','off'); h=uicontrol(f,'Style','text','String','Not selected');
f.UserData=struct('config',guiDefaultConfig(),'controls',struct('outputDirectoryText',h));
end
function out=mustNotPrompt(varargin)
error('Test:UnexpectedPrompt','A valid output directory must not prompt again.');
out=0; %#ok<UNRCH>
end

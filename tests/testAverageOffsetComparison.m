function tests = testAverageOffsetComparison
tests = functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.oldPath=path;
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'analysis'));
t.TestData.visibility=get(groot,'DefaultFigureVisible');
set(groot,'DefaultFigureVisible','off');
end
function teardownOnce(t)
path(t.TestData.oldPath);
set(groot,'DefaultFigureVisible',t.TestData.visibility);
end
function testPlainListsArePanelsOnlyInAverageComparison(t)
for value={ '1,2,3', '1 2 3', [1 2 3] }
    [cols,mode,expr]=parseAnalysisSpectrumExpression(value{1},"compareAverageSpectra");
    verifyEqual(t,cols,[1 2 3]); verifyEqual(t,mode,"separate");
    verifyEqual(t,expr,"1,2,3");
end
[cols,mode]=parseAnalysisSpectrumExpression('3,1',"compareAverageSpectra");
verifyEqual(t,cols,[3 1]); verifyEqual(t,mode,"separate");
[~,mode]=parseAnalysisSpectrumExpression('1,2,3',"predictTscore");
verifyEqual(t,mode,"concat");
end
function testArithmeticAndSingleRemainUnchanged(t)
for pair={ {'3-2',"diff"}, {'3+2',"add"}, {'2',"single"}, {'3|2',"concat"} }
    p=pair{1}; [~,mode]=parseAnalysisSpectrumExpression(p{1},"compareAverageSpectra");
    verifyEqual(t,mode,p{2});
end
verifyError(t,@()parseAnalysisSpectrumExpression('1,2,3,4',"compareAverageSpectra"),'MainGUI:InvalidAverageOffsets');
verifyError(t,@()parseAnalysisSpectrumExpression('4',"compareAverageSpectra"),'MainGUI:InvalidAverageOffsets');
verifyError(t,@()parseAnalysisSpectrumExpression([1 1],"compareAverageSpectra"),'MainGUI:InvalidAverageOffsets');
end
function testGuiOptionsRoundTripAndValidation(t)
f=figure('Visible','off'); clean=onCleanup(@()delete(f));
c=guiDefaultConfig(); c.analysis.mode="compareAverageSpectra";
c.analysis.spectrumExpression="1,2,3"; f.UserData=struct('config',c);
o=getGuiAnalysisOptions(f); validateAnalysisRequest(o);
verifyEqual(t,o.spectrumCombineMode,"separate"); verifyEqual(t,o.spectrumNumbers,[1 2 3]);
validateSpectrumCombinationSettings(o,struct('normalizationRegion',"none"));
o.spectrumCombineMode="concat";
verifyError(t,@()validateAnalysisRequest(o),'MainGUI:AverageOffsetsNotConcatenation');
end
function testIndependentPanelsAndAgreementForOneTwoThreeOffsets(t)
for columns={2,[3 1],[1 2 3]}
    selected=columns{1}; [a,p,s]=fixture(selected);
    before=findall(groot,'Type','figure');
    clean=onCleanup(@()delete(setdiff(findall(groot,'Type','figure'),before)));
    localCompareAverageSpectra(a,p,selected,{'D3P1_MM00'},s.feature,false,s.compare);
    figures=setdiff(findall(groot,'Type','figure'),before);
    verifyEqual(t,numel(figures),2);
    spectra=figures(contains(string(get(figures,'Name')),'vertically offset categories'));
    ax=findall(spectra,'Type','axes'); verifyEqual(t,numel(ax),numel(selected));
    titles=string(arrayfun(@(x)x.Title.String,ax,'UniformOutput',false));
    for k=1:numel(selected)
        verifyTrue(t,any(contains(titles,localSpectrumDepthLabel(selected(k)))));
        [~,X]=localSpectraMatrixForRecordsColumn(a,s.feature,k,false);
        verifyEqual(t,X(1,:), (a(1).Spectrum(:,k)/max(a(1).Spectrum(:,k))).','AbsTol',1e-12);
    end
    rows=localIndividualAgreementTable(a,p,selected,s.feature,false,"category");
    verifyEqual(t,numel(rows),numel(a)*numel(selected));
    for k=1:numel(selected)
        verifyEqual(t,sum([rows.SpectrumNumber]==selected(k)),numel(a));
    end
    agreement=figures(contains(string(get(figures,'Name')),'Individual spectral agreement'));
    ax=findall(agreement,'Type','axes'); verifyEqual(t,numel(ax),3);
    for k=1:numel(ax), verifyEqual(t,numel(ax(k).XTick),numel(selected)); end
    clear clean
end
end
function [actual,predicted,s]=fixture(columns)
wn=(750:2:1740).'; s=analysisDefaultSettings();
s.feature.normalizationRegion="PO4"; s.feature.normalizationMethod="peak";
s.feature.spectrumCombineMode="separate";
cats={'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
actual=struct('CadaverID',{},'Category',{},'Tag',{},'Spectrum',{},'Wavenumber',{});
for i=1:6
    M=[];
    for j=1:3
        M(:,j)=0.1+exp(-((wn-960)/12).^2)+(.2+.03*i+.04*j)*exp(-((wn-1450)/22).^2);
    end
    actual(i)=struct('CadaverID',sprintf('DONOR%d',i),'Category',cats{ceil(i/2)}, ...
        'Tag','D3P1_MM00','Spectrum',M(:,columns),'Wavenumber',wn);
end
predicted=actual;
for i=1:6, predicted(i).Spectrum=actual(i).Spectrum.*(1+.01*sin(wn/40)); end
end

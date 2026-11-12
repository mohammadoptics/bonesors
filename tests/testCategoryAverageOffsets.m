function tests=testCategoryAverageOffsets
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.oldPath=path;
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root, fullfile(root,'app'), fullfile(root,'app','analysis'),fullfile(root,'tests'));
t.TestData.visibility=get(groot,'DefaultFigureVisible');
set(groot,'DefaultFigureVisible','off');
end
function teardownOnce(t)
path(t.TestData.oldPath); set(groot,'DefaultFigureVisible',t.TestData.visibility);
end
function testParsingAndValidation(t)
for mode=["compareAverageSpectra","categoryAverageSpectra"]
    [c,m,e]=parseAnalysisSpectrumExpression('1,2,3',mode);
    verifyEqual(t,c,[1 2 3]); verifyEqual(t,m,"separate"); verifyEqual(t,e,"1,2,3");
    [c,m]=parseAnalysisSpectrumExpression('3-2',mode);
    verifyEqual(t,c,[3 2]); verifyEqual(t,m,"diff");
    verifyError(t,@()parseAnalysisSpectrumExpression('1,2,3,4',mode),'MainGUI:InvalidAverageOffsets');
end
end
function testPanelPlanUsesCompactSelectionAndKeepsTissuesSeparate(t)
[records,groups,~]=categoryAverageOffsetFixture([3 1]);
p=localCategoryAveragePanelPlan(groups,[3 1],"separate","PO4");
verifyEqual(t,numel(p),4); verifyEqual(t,[p.Columns],[3 1 3 1]);
verifyEqual(t,string({p.Tissue}),["E" "E" "P" "P"]);
verifyEqual(t,p(1).Records(1).Spectrum,records(1).Spectrum(:,1));
verifyEqual(t,p(2).Records(1).Spectrum,records(1).Spectrum(:,2));
verifyEqual(t,p(3).Records(1).Spectrum,groups(2).Records(1).Spectrum(:,1));
end
function testExpressionIsOnePanelPerTissue(t)
[records,groups,~]=categoryAverageOffsetFixture([3 2]);
p=localCategoryAveragePanelPlan(groups,[3 2],"diff","CH2");
verifyEqual(t,numel(p),2); verifyEqual(t,p(1).Columns,[3 2]);
verifyEqual(t,p(1).Records,records); verifyEqual(t,p(1).CombineMode,"diff");
end
function testPlotOneTwoThreeOffsetsAndMeanValues(t)
for selection={2,[3 1],[1 2 3]}
    cols=selection{1}; [records,groups,s]=categoryAverageOffsetFixture(cols);
    before=findall(groot,'Type','figure');
    cleanup=onCleanup(@()delete(setdiff(findall(groot,'Type','figure'),before)));
    localPlotCategoryAverageFeatureGrid(records,"E",cols,{'D3P1_MM00'},s.feature,false,s.categoryAverage,groups);
    f=setdiff(findall(groot,'Type','figure'),before); verifyEqual(t,numel(f),1);
    ax=findall(f,'Type','axes'); verifyEqual(t,numel(ax),2*numel(cols));
    for k=1:numel(cols)
        titleText=sprintf('%s (Measured exposed bone, %s)',char('A'+k-1),localSpectrumDepthLabel(cols(k)));
        a=ax(arrayfun(@(x)strcmp(x.Title.String,titleText),ax)); verifyEqual(t,numel(a),1);
        line=findobj(a,'Type','line','DisplayName','NORMAL (n=3)');
        expected=zeros(size(records(1).Wavenumber));
        for r=1:3
            expected=expected+normalizeSpectra(records(r).Wavenumber,records(r).Spectrum(:,k),'PO4','peak')/3;
        end
        verifyEqual(t,line.YData(:),expected,'AbsTol',1e-12);
    end
    clear cleanup
end
end
function testGUIComparisonRowIsOptional(t)
before=findall(groot,'Type','figure'); clean=onCleanup(@()delete(setdiff(findall(groot,'Type','figure'),before)));
BoneSORS; f=setdiff(findall(groot,'Type','figure'),before); c=f.UserData.controls;
registry=analysisModeRegistry(); c.modePopup.Value=find(strcmp({registry.value},'categoryAverageSpectra'));
feval(c.modePopup.Callback,c.modePopup,[]);
verifyEqual(t,string(c.categoryComparisonCheck.Visible),"on"); verifyEqual(t,string(c.comparisonTissuePopup.Enable),"off");
verifyEqual(t,string(c.locationCombinePopup.Visible),"off");
c.categoryComparisonCheck.Value=1; feval(c.categoryComparisonCheck.Callback,c.categoryComparisonCheck,[]);
verifyEqual(t,string(c.comparisonTissuePopup.Enable),"on");
c.modePopup.Value=find(strcmp({registry.value},'predictTscore')); feval(c.modePopup.Callback,c.modePopup,[]);
verifyEqual(t,string(c.categoryComparisonCheck.Visible),"off"); verifyEqual(t,string(c.locationCombinePopup.Visible),"on");
end

function renderCategoryAverageOffsets(outputFolder)
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root, fullfile(root,'app'), fullfile(root,'app','analysis'),fullfile(root,'tests'));
if ~isfolder(outputFolder), mkdir(outputFolder); end
before=findall(groot,'Type','figure');
clean=onCleanup(@()delete(setdiff(findall(groot,'Type','figure'),before)));
for cols={ [1 2], [1 2 3] }
    [records,groups,s]=categoryAverageOffsetFixture(cols{1});
    localPlotCategoryAverageFeatureGrid(records,"E",cols{1},{'D3P1_MM00'},s.feature,false,s.categoryAverage,groups);
    f=gcf;
    exportgraphics(f,fullfile(outputFolder,sprintf('synthetic_category_%d_offsets.png',numel(cols{1}))),'Resolution',120);
    delete(f);
end
end

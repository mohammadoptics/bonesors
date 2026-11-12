function runCadaverDatasetAnalysis(fig)
%RUNCADAVERDATASETANALYSIS Dispatch a generated cadaver-dataset analysis.
% Scientific implementations live in the analysis folder, one module per
% selectable analysis. This function intentionally contains no calculations.

if nargin < 1 || isempty(fig) || ~ishandle(fig)
    error('MainGUI:InvalidFigure', ...
        'runCadaverDatasetAnalysis requires the GUI figure handle.');
end

analysisFolder = fullfile(fileparts(mfilename('fullpath')), 'analysis');
if ~contains(path, analysisFolder), addpath(analysisFolder); end

context = buildAnalysisContext(fig);
mode = context.options.mode;

switch mode
    case "displayRatios"
        runner = @analysisDisplayRatios;
    case "displayFWHM"
        runner = @analysisDisplayFWHM;
    case "detectOutliers"
        runner = @analysisDetectOutliers;
    case "predictTscore"
        runner = @analysisPredictTscore;
    case "groupTscore"
        runner = @analysisGroupTscore;
    case "ratioGroupTscore"
        runner = @analysisRatioGroupTscore;
    case "strictPredictTscore"
        runner = @analysisStrictPredictTscore;
    case "compareAverageSpectra"
        runner = @analysisCompareAverageSpectra;
    case "categoryAverageSpectra"
        runner = @analysisCategoryAverageSpectra;
    case "compareRatioPlots"
        runner = @analysisCompareRatios;
    case "plotPO4VisibilityQC"
        runner = @analysisPO4VisibilityQC;
    case "printDemographicsTable"
        runner = @analysisDemographics;
    case "visualizeAutoscaling"
        runner = @analysisVisualizeAutoscaling;
    case "compareTscorePlots"
        runner = @analysisCompareTscore;
    case "compareClassificationPlots"
        runner = @analysisCompareClassification;
    case "sweepTscoreSettings"
        runner = @analysisSweepTscore;
    case "spatialCategorySpectra"
        runner = @analysisSpatialCategorySpectra;
    case "spatialMetricProfiles"
        runner = @analysisSpatialMetricProfiles;
    otherwise
        error('MainGUI:UnregisteredAnalysis', ...
            'No analysis module is registered for %s.', mode);
end

runner(context);
ud = fig.UserData;
ud.lastAnalysisDatasetFile = context.datasetFile;
fig.UserData = ud;
end

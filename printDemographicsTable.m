function summaryTable = printDemographicsTable(fig, T)
%PRINTDEMOGRAPHICSTABLE Print paper-ready demographic summaries.
%
% This table is based on the loaded category workbook. It is intended for
% the Materials and Methods donor-demographics table, not for a specific ML
% model output.

    if nargin < 1 || isempty(fig) || ~ishandle(fig)
        error('printDemographicsTable requires the GUI figure handle.');
    end

    if nargin < 2 || isempty(T)
        if ~isfield(fig.UserData,'statusTable') || isempty(fig.UserData.statusTable)
            chooseCategoryFile(fig);
        end

        if ~isfield(fig.UserData,'statusTable') || isempty(fig.UserData.statusTable)
            warning('No category table loaded. Load the Excel category workbook first.');
            summaryTable = table();
            return
        end

        T = fig.UserData.statusTable;
    end

    colWHO  = 'WHO Classification (Distal Radius; 1/3)';
    colAge  = 'Age';
    colBMI  = 'BMI';
    colBMD  = 'Distal Radius BMD (g/cm2; 1/3)';
    colTsc  = 'Distal Radius T-Score (1/3)';
    colRace = 'Race';

    requiredCols = {colWHO,colAge,colBMI,colBMD,colTsc,colRace};
    missing = requiredCols(~ismember(requiredCols, T.Properties.VariableNames));
    if ~isempty(missing)
        error('Category workbook is missing required column(s): %s', strjoin(missing, ', '));
    end

    classOrder = ["Normal"; "Osteopenia"; "Osteoporosis"];
    WHOClass = strings(numel(classOrder),1);
    N = zeros(numel(classOrder),1);
    Ethnicity_BlackWhite = strings(numel(classOrder),1);
    Age_years = strings(numel(classOrder),1);
    BMI_kg_m2 = strings(numel(classOrder),1);
    RadiusBMD_g_cm2 = strings(numel(classOrder),1);
    RadiusTscore = strings(numel(classOrder),1);

    who = lower(strtrim(string(T.(colWHO))));
    race = lower(strtrim(string(T.(colRace))));

    for c = 1:numel(classOrder)
        className = classOrder(c);
        idx = strcmpi(who, className);

        WHOClass(c) = className;
        N(c) = sum(idx);

        nBlack = sum(contains(race(idx), "black"));
        nWhite = sum(contains(race(idx), "caucasian") | contains(race(idx), "white"));

        Ethnicity_BlackWhite(c) = sprintf('%d / %d', nBlack, nWhite);
        Age_years(c) = localMeanSDString(T.(colAge)(idx), 1);
        BMI_kg_m2(c) = localMeanSDString(T.(colBMI)(idx), 1);
        RadiusBMD_g_cm2(c) = localMeanSDString(T.(colBMD)(idx), 3);
        RadiusTscore(c) = localMeanSDString(T.(colTsc)(idx), 2);
    end

    summaryTable = table(WHOClass, N, Ethnicity_BlackWhite, Age_years, ...
        BMI_kg_m2, RadiusBMD_g_cm2, RadiusTscore);

    fprintf('\nTable. Demographics of distal-radius cadaver donors (mean +/- SD)\n');
    fprintf('------------------------------------------------------------------\n');
    localPrintCohortSummary(T, colAge, colRace, colWHO, 'Current workbook cohort');
    fprintf('------------------------------------------------------------------\n');
    disp(summaryTable);
    fprintf('------------------------------------------------------------------\n');
    fprintf('Copy the displayed values into the manuscript table as needed.\n\n');
end

function localPrintCohortSummary(T, colAge, colRace, colWHO, label)
    ages = double(T.(colAge));
    ages = ages(isfinite(ages));
    race = lower(strtrim(string(T.(colRace))));
    who = lower(strtrim(string(T.(colWHO))));

    nWhite = sum(contains(race, "caucasian") | contains(race, "white"));
    nBlack = sum(contains(race, "black"));
    nNormal = sum(strcmpi(who, "normal"));
    nOsteopenia = sum(strcmpi(who, "osteopenia"));
    nOsteoporosis = sum(strcmpi(who, "osteoporosis"));

    if isempty(ages)
        fprintf('%s: no valid age values found.\n', label);
        return
    end

    fprintf('%s:\n', label);
    fprintf('  The cohort had a mean +/- SD age of %.0f +/- %.0f years (range %.0f-%.0f years).\n', ...
        mean(ages, 'omitnan'), std(ages, 0, 'omitnan'), min(ages), max(ages));
    fprintf('  Race: %d White/Caucasian, %d Black. WHO: Normal n=%d, Osteopenia n=%d, Osteoporosis n=%d.\n', ...
        nWhite, nBlack, nNormal, nOsteopenia, nOsteoporosis);
end


function txt = localMeanSDString(values, nDecimals)
    values = double(values);
    values = values(isfinite(values));

    if isempty(values)
        txt = "NA";
        return
    end

    mu = mean(values, 'omitnan');
    sd = std(values, 0, 'omitnan');
    fmt = sprintf('%%.%df +/- %%.%df', nDecimals, nDecimals);
    txt = string(sprintf(fmt, mu, sd));
end

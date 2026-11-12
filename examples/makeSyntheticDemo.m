function [datasetFile, categoryFile] = makeSyntheticDemo(outputFolder)
%MAKESYNTHETICDEMO Write artificial paired spectra and a category workbook.
% The files demonstrate the GUI schema and contain no measurements.

if nargin == 0
    outputFolder = fullfile(tempdir, 'bonesors-demo');
end
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

datasetFile = fullfile(outputFolder, 'syntheticCadavers.mat');
categoryFile = fullfile(outputFolder, 'syntheticCategories.xlsx');
wn = (750:2:1740).';
ids = "DEMO" + string((1:9).');
tscores = [0.3; -0.2; -0.6; -1.3; -1.7; -2.2; -2.7; -3.1; -3.5];
categories = repelem(["NORMAL"; "OSTEOPENIA"; "OSTEOPOROSIS"], 3);
offsetWeights = [0.38, 0.58, 0.76];
blank = struct('id', '', 'wn', wn, 'E', {{}}, 'T', {{}}, 'list', {{}});
cads = repmat(blank, numel(ids), 1);

for i = 1:numel(ids)
    mineral = (1 + 0.10 * tscores(i)) * exp(-((wn - 960) / 13).^2);
    matrix = 0.27 * exp(-((wn - 1450) / 35).^2) + ...
        0.15 * exp(-((wn - 1660) / 28).^2);
    exposed = 0.035 + (mineral + matrix) .* [1, 0.95, 0.9] + ...
        0.004 * sin(wn / 31 + i);
    soft = 0.35 * exp(-((wn - 1450) / 52).^2) + ...
        0.20 * exp(-((wn - 1290) / 48).^2);
    intact = exposed .* offsetWeights + soft .* (1 - offsetWeights);
    cads(i) = struct('id', char(ids(i)), 'wn', wn, 'E', {{exposed}}, ...
        'T', {{intact}}, 'list', {{char(ids(i) + "_E_D3P1_MM00"), ...
        char(ids(i) + "_T_D3P1_MM00")}});
end

save(datasetFile, 'cads', '-v7');
labels = table(ids, tscores, categories, 'VariableNames', ...
    {'AGR-ID', 'Distal Radius T-Score (1/3)', 'WHO Classification (Distal Radius; 1/3)'});
writetable(labels, categoryFile);
fprintf('Synthetic dataset: %s\nCategory workbook: %s\n', datasetFile, categoryFile);
end

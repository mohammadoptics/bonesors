function config=resolveTscoreAnalysisConfig(config,analysis)
% The Analysis page is the sole source of location selection and fusion mode.
config=completeTscoreConfiguration(config);
config.locationTags=upper(strtrim(string(analysis.tags(:).')));
config.locationCombineMode="records";
if isfield(analysis,'locationCombineMode')
    config.locationCombineMode=string(analysis.locationCombineMode);
end
% Comparison panels always form one feature row per donor at each requested
% location/group. This does not modify the individual-plot mode on Analysis.
if config.figureMode=="locationComparison", config.locationCombineMode="concat"; end
end

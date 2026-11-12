function config = completeTscoreConfiguration(config)
%COMPLETETSCORECONFIGURATION Add defaults introduced after a GUI started.

defaults = guiDefaultConfig();
defaults = defaults.tscore;
names = fieldnames(defaults);
for k = 1:numel(names)
    if ~isfield(config,names{k})
        config.(names{k}) = defaults.(names{k});
    end
end
end

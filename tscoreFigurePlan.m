function plan=tscoreFigurePlan(config,tags)
% Explicit panel specification, independent from models and preprocessing.
config=completeTscoreConfiguration(config);
tags=unique(upper(strtrim(string(tags(:).'))),'stable');
tags(strlength(tags)==0)=[];
hasDemo=any([config.useAge config.useSex config.useBMI config.useWeight]);
raman=tags; combined=tags;
if config.figureSelectionConfigured
    raman=tags(ismember(tags,upper(string(config.figureRamanTags))));
    combined=tags(ismember(tags,upper(string(config.figureCombinedTags))));
end
plan=struct('tags',{},'useRaman',{},'withDemographics',{});
if config.figureIncludeDemographics && hasDemo
    plan(end+1)=struct('tags',strings(1,0),'useRaman',false,'withDemographics',true);
end
for tag=tags
    if ismember(tag,raman), add(tag,false); end
    if ismember(tag,combined) && hasDemo, add(tag,true); end
end
if numel(tags)>1
    if config.figureIncludeConcatenatedRaman, add(tags,false); end
    if config.figureIncludeConcatenatedCombined && hasDemo, add(tags,true); end
end
    function add(selected,demo)
        plan(end+1)=struct('tags',selected,'useRaman',true,'withDemographics',demo);
    end
end

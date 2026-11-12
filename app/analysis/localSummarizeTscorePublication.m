function [caption,classification,heading]=localSummarizeTscorePublication(panels,options,model)
% Summarize actual held-out predictions using the GUI's category boundaries.
assert(~isempty(panels),'At least one comparison panel is required.');
f=panels(1).feature;
demoIndex=find([panels.withDemographics],1);
if ~isempty(demoIndex), f=panels(demoIndex).feature; end
demo=strings(0,1); keys={'useAge','useSex','useBMI','useWeight'};
names=["age","sex","BMI","weight"];
for j=1:4, if f.(keys{j}), demo(end+1)=names(j); end, end %#ok<AGROW>
heading="Demographics: "+strjoin(demo,', ');
switch string(options.tissue)
    case "T", tissue="transcutaneous";
    case "E", tissue="exposed-bone";
    otherwise, tissue="reconstructed";
end
offsets=arrayfun(@(s)string(localSpectrumDepthLabel(s)),options.spectrumNumbers);
if numel(offsets)==1
    representation=offsets+" spectra";
elseif string(options.spectrumCombineMode)=="diff"
    representation=strjoin(offsets,' minus ')+" difference spectra";
else
    representation="spectra at "+strjoin(offsets,', ')+ ...
        " (offset combination: "+string(options.spectrumCombineMode)+")";
end
if strcmpi(f.normalizationRegion,'none')
    normalization="No spectral normalization was applied.";
else
    normalization="Each offset spectrum was normalized separately using "+ ...
        string(f.normalizationRegion)+" "+string(f.normalizationMethod)+ ...
        " normalization before combining offsets.";
end
scale="";
scaled=arrayfun(@(p)p.feature.blockScaleRamanDemographics,panels);
if any(scaled)
    scale=" Raman and demographic blocks were block-scaled in panels "+strjoin(string({panels(scaled).letter}),', ')+".";
end
classes=["NORMAL","OSTEOPENIA","OSTEOPOROSIS"];
counts=arrayfun(@(c)sum(strcmpi(panels(1).result.cats,c)),classes);
panelDescriptions=strings(1,numel(panels)); concatenation="";
for k=1:numel(panels)
    p=panels(k); shortTags=replace(regexprep(string(p.tags),'(?i)_?MM00$',''),'_',' / ');
    if ~p.feature.useRaman, description="demographics only ("+strjoin(demo,', ')+")";
    else
        description=strjoin(shortTags,', ')+"; Raman only";
        if p.withDemographics, description=strjoin(shortTags,', ')+"; Raman + demographics ("+strjoin(demo,', ')+")"; end
        if numel(p.tags)>1
            concatenation=" Brackets denote horizontal concatenation of location-specific feature vectors, not subtraction.";
        end
    end
    panelDescriptions(k)="Panel "+string(p.letter)+": "+description+".";
end
featureNote="";
if string(f.tscoreFeatureMode)~="spectrum"
    featureNote=" Raman representation: "+string(f.tscoreFeatureMode)+"; ratios: "+strjoin(string(f.tscoreRatioNames),', ')+".";
    if ~ismember(string(f.tscoreFeatureMode),["spectrum","ratios"])
        normalization="Ratios were calculated per offset before ratio-level feature combination; spectral normalization was not used.";
    end
end
if ~any(arrayfun(@(p)p.feature.useRaman,panels))
    normalization="No Raman predictors were used.";
end
caption=string(sprintf(['Prediction of wrist T-score using %s Raman %s and %s regression. ' ...
    '%s%s%s ' ...
    '%s%s All panels use the same n = %d donors (normal: n = %d; osteopenia: n = %d; osteoporosis: n = %d) with leave-one-cadaver-out validation. ' ...
    'The dashed line denotes perfect agreement with DXA. Blue squares, green diamonds, and red circles ' ...
    'represent normal, osteopenia, and osteoporosis categories, respectively. ' ...
    'Panels report Pearson r and cross-validated root-mean-square error (RMSECV).'], ...
    tissue,representation,upper(string(model)),strjoin(panelDescriptions,' '), ...
    concatenation,featureNote,normalization,scale,numel(panels(1).result.y),counts(1),counts(2),counts(3)));
if ~any(arrayfun(@(p)p.feature.useRaman,panels))
    caption=replace(caption,"using "+tissue+" Raman "+representation,"using demographics only");
end
classification=table();
for k=1:numel(panels)
    p=panels(k); r=p.result; actual=upper(strtrim(string(r.cats(:))));
    assert(numel(r.yPred)==numel(actual) && all(isfinite(r.yPred(:))), ...
        'Classification requires finite predictions for every donor.');
    assert(all(ismember(actual,classes)),'Unknown reference category in publication results.');
    predicted=localTscoreToCategory(r.yPred(:)); correct=predicted==actual;
    byClass=strings(1,3);
    for j=1:3
        selected=actual==classes(j);
        byClass(j)=sprintf('%d/%d',sum(correct & selected),sum(selected));
    end
    source="Raman only"; location=strjoin(p.tags,' + ');
    if ~p.feature.useRaman, source="Demographics only"; location="Not applicable";
    elseif p.withDemographics, source="Raman + demographics"; end
    classification=[classification;table(string(p.letter),location,source, ...
        sum(correct),numel(actual),100*mean(correct),byClass(1),byClass(2),byClass(3), ...
        'VariableNames',{'Panel','Locations','Predictors','Correct','Total','AccuracyPercent', ...
        'Normal','Osteopenia','Osteoporosis'})]; %#ok<AGROW>
end
end

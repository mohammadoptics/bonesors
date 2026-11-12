function [panels,cohort]=localComputeTscorePublication(context,model)
% Fit only requested panels, using one common complete donor cohort.
c=resolveTscoreAnalysisConfig(context.ud.config.tscore,context.options);
c=validateTscoreConfiguration(c);
if c.figureMode~="locationComparison", error('MainGUI:TscorePublication','Select multi-panel comparison output.'); end
plan=tscoreFigurePlan(c,c.locationTags);
tags=unique([plan.tags],'stable'); hasDemo=any([plan.withDemographics]);
base=c; base.figureMode="individual"; base.models=upper(string(model));
base.blockScaleRamanDemographics=false;
base.predictorSource="raman";
if hasDemo, base.predictorSource="combined"; end
base.locationTags=tags; base.locationCombineMode="concat";
if isempty(tags), base.locationCombineMode="records"; base.predictorSource="demographics"; end
s=applyTscoreConfigToSettings(context.settings,base);
s.feature.spectrumCombineMode=context.options.spectrumCombineMode;
if ~isempty(tags)
    [fused,cohort]=localFuseTscoreLocations(context.records,s.feature);
else
    % A demographic-only figure does not require unused spectra or locations.
    ids=string({context.records.CadaverID}); [~,ix]=unique(ids,'sorted');
    fused=context.records(ix); keep=true(size(fused));
    fields={'Age','Sex','BMI','Weight'}; flags={'useAge','useSex','useBMI','useWeight'};
    for i=1:numel(fused)
        values=fused(i).Tscore;
        for j=1:4, if s.feature.(flags{j}), values(end+1)=fused(i).(fields{j}); end, end %#ok<AGROW>
        keep(i)=all(isfinite(values));
    end
    cohort=struct('included',string({fused(keep).CadaverID}).', ...
        'excluded',string({fused(~keep).CadaverID}).','tags',tags, ...
        'reasons',repmat("Missing outcome or selected demographics",sum(~keep),1));
    fused=fused(keep);
end
if numel(cohort.included)<4
    error('MainGUI:TscorePublication','At least four complete donors are required for the selected panels.');
end
records=context.records(ismember(string({context.records.CadaverID}),cohort.included));
panels=struct('letter',{},'tags',{},'withDemographics',{},'feature',{},'result',{});
for k=1:numel(plan)
    p=plan(k); cc=base; cc.locationTags=p.tags;
    cc.predictorSource="raman";
    if p.withDemographics, cc.predictorSource="combined"; end
    cc.blockScaleRamanDemographics=p.useRaman && p.withDemographics && c.blockScaleRamanDemographics;
    input=records;
    if ~p.useRaman
        cc.predictorSource="demographics"; cc.locationCombineMode="records"; input=fused;
        nDemo=nnz([cc.useAge cc.useSex cc.useBMI cc.useWeight]);
        if strcmpi(model,'PLS') && ~isempty(cc.fixedPLSRank) && cc.fixedPLSRank>nDemo
            fprintf('Demographics-only PLS: limiting components to %d predictors.\n',nDemo);
            cc.fixedPLSRank=nDemo;
        end
    end
    st=applyTscoreConfigToSettings(context.settings,cc);
    st.feature.spectrumCombineMode=context.options.spectrumCombineMode;
    st.feature.tscoreModel=lower(string(model));
    letter=char('A'+k-1);
    fprintf('\nComparison panel %s: %s; Raman=%d; demographics=%d\n',letter,strjoin(p.tags,', '),p.useRaman,p.withDemographics);
    r=localComputeTscorePrediction(input,context.options.tissue,context.options.spectrumNumbers,st.maxRank,st.feature);
    if ~r.ok || ~isequal(r.cadIDs,cohort.included)
        error('MainGUI:TscorePublicationCohort','Panel donor IDs differ; comparison cancelled rather than mixing cohorts.');
    end
    if ~isempty(panels) && (~isequal(r.y,panels(1).result.y) || ~isequal(r.cats,panels(1).result.cats))
        error('MainGUI:TscorePublicationCohort','Panel outcomes/categories differ.');
    end
    panels(end+1)=struct('letter',letter,'tags',p.tags,'withDemographics',p.withDemographics,'feature',st.feature,'result',r); %#ok<AGROW>
end
end

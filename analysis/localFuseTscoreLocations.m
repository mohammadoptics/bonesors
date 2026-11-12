function [fused,audit]=localFuseTscoreLocations(records,settings)
% Per-location normalization/expression first; then one complete row per donor.
tags=upper(string(settings.locationTags(:).')); mode=string(settings.locationCombineMode);
ids=sort(unique(string({records.CadaverID})));
fused=records([]); [fused.RamanFeatures]=deal([]);
audit=struct('tags',tags,'mode',mode,'donorOrder','sorted ID', ...
    'included',strings(0,1),'excluded',strings(0,1),'reasons',strings(0,1));
for id=ids(:).'
    rows=find(string({records.CadaverID})==id); loc=upper(string({records(rows).Tag}));
    chosen=zeros(1,numel(tags)); reason="";
    for j=1:numel(tags)
        hit=rows(loc==tags(j));
        if numel(hit)>1
            error('MainGUI:TscoreDuplicateLocation','Donor %s has duplicate records for %s; resolve replicates explicitly.',id,tags(j));
        elseif isempty(hit), reason="Missing location: "+tags(j); break
        else, chosen(j)=hit; end
    end
    if strlength(reason)==0
        rr=records(chosen); F=[];
        for j=1:numel(rr)
            if ~isequal(rr(j).Wavenumber,rr(1).Wavenumber)
                error('MainGUI:TscoreLocationGrid','Wavenumber grids differ between locations for %s.',id);
            end
            if ~isequaln([rr(j).Tscore rr(j).Age rr(j).Sex rr(j).BMI rr(j).Weight], ...
                    [rr(1).Tscore rr(1).Age rr(1).Sex rr(1).BMI rr(1).Weight])
                error('MainGUI:TscoreLocationMetadata','Inconsistent donor metadata for %s.',id);
            end
            f=localBuildTscoreRamanFeatures(rr(j).Wavenumber,rr(j).Spectrum,settings);
            if isempty(f)||any(~isfinite(f)), reason="Nonfinite spectral features"; break; end
            F(j,:)=f; %#ok<AGROW>
        end
        d=[]; fields={'Age','Sex','BMI','Weight'}; flags={'useAge','useSex','useBMI','useWeight'};
        for j=1:4, if settings.(flags{j}), d(end+1)=rr(1).(fields{j}); end, end %#ok<AGROW>
        if ~isfinite(rr(1).Tscore)||any(~isfinite(d)), reason="Missing outcome or selected demographics"; end
        if strlength(reason)==0
            rec=rr(1); rec.Tag=char(strjoin(tags,' + '));
            if mode=="concat", rec.RamanFeatures=reshape(F.',1,[]);
            elseif mode=="mean", rec.RamanFeatures=mean(F,1);
            else, error('MainGUI:TscoreLocations','Unknown location combination.'); end
            fused(end+1)=rec; audit.included(end+1,1)=id; %#ok<AGROW>
        end
    end
    if strlength(reason)>0
        audit.excluded(end+1,1)=id; audit.reasons(end+1,1)=reason;
        fprintf('Location fusion excludes %s: %s\n',id,reason);
    end
end
fprintf('Location %s: %d complete donors; %d excluded. Tags: %s\n',mode,numel(fused),numel(audit.excluded),strjoin(tags,', '));
end

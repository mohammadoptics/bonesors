function [available,known]=tscoreDemographicAvailability(ud)
% Unknown metadata does not disable configuration; confirmed absent fields do.
available=true(1,4); known=false;
if ~isfield(ud,'statusFilename') || ~isfile(string(ud.statusFilename)), return, end
try
    T=readtable(ud.statusFilename,'VariableNamingRule','preserve','TextType','string');
    if isfield(ud,'analysisData') && isstruct(ud.analysisData)
        S=ud.analysisData; cads=[];
        for key={'cads','cadavers','pairedCadavers'}
            if isfield(S,key{1}), cads=S.(key{1}); break, end
        end
        if ~isempty(cads) && isfield(cads,'id') && ismember('AGR-ID',T.Properties.VariableNames)
            T=T(ismember(upper(strrep(string(T.('AGR-ID')),' ','')),upper(string({cads.id}))),:);
        end
    end
    if height(T)==0, return, end
    values=nan(height(T),4);
    for i=1:height(T)
        values(i,:)=[localGetNumericTableValue(T,i,'Age'), ...
            localEncodeSex(localGetTableValue(T,i,'Sex')), ...
            localGetNumericTableValue(T,i,'BMI'),localGetWeightKg(T,i)];
    end
    available=any(isfinite(values),1); known=true;
catch
    % Loading/validating the category file at run time remains authoritative.
end
end

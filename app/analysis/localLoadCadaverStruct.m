function [cads, pairFile] = localLoadCadaverStruct(ud)
    cads = [];
    pairFile = '';
    if ~isfield(ud, 'analysisData') || isempty(ud.analysisData) || ...
            ~isfield(ud, 'analysisDatasetType') || ...
            string(ud.analysisDatasetType) ~= "cadaverDataset"
        errordlg('Load a cadaver dataset in the Analysis tab first.', ...
            'Analysis dataset required', 'modal');
        return
    end
    S = ud.analysisData;
    pairFile = ud.analysisFile;
    if isfield(S,'cads')
        cads = S.cads;
    elseif isfield(S,'cadavers')
        cads = S.cadavers;
    elseif isfield(S,'pairedCadavers')
        cads = S.pairedCadavers;
    else
        errordlg('Chosen .mat does not contain variable "cads" or "cadavers".', ...
            'Invalid paired file','modal');
    end
end


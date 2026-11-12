function tag = localGetTagFromList(cad, specIdx, listCol)
    tag = "";

    if ~isfield(cad,'list') || isempty(cad.list) || ...
            size(cad.list,1) < specIdx || size(cad.list,2) < listCol || ...
            isempty(cad.list{specIdx,listCol})
        return
    end

    tag = extractAcquisitionTag(cad.list{specIdx,listCol});
end


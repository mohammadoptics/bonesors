function [dataCells, listCol] = localGetTissueCells(cad, tissueToUse)
    switch upper(char(tissueToUse))
        case 'E'
            listCol = 1;
            if isfield(cad,'E'), dataCells = cad.E; else, dataCells = {}; end
        case 'T'
            listCol = 2;
            if isfield(cad,'T'), dataCells = cad.T; else, dataCells = {}; end
        case 'P'
            listCol = 3;
            if isfield(cad,'P'), dataCells = cad.P; else, dataCells = {}; end
            if isfield(cad,'list') && iscell(cad.list)
                listRows = cad.list;
                if isvector(listRows), listRows = listRows(:); end
                if size(listRows,2) < 3 || all(cellfun(@localIsEmptyListEntry, listRows(:,3)))
                    listCol = 1;
                end
            end
    end
end


% -------------------------------------------------------------------------
% loadBadSpectraSheet – builds fig.UserData.badMap from Excel
% -------------------------------------------------------------------------
function ok = loadBadSpectraSheet(fig)
% fig  – handle of the main GUI figure created in GUI62
% --------------------------------------------------------------
    ok = false;
    if nargin >= 1 && ~isempty(fig) && ishandle(fig)
        figure(fig);
        drawnow;
    end

    [f,p] = uigetfile({'*.xls*;*.xlsx','Excel files'}, ...
                      'Select "bad spectra" sheet');
    if f==0, return, end
    xlsFile = fullfile(p,f);

    % ----- read & clean the sheet (unchanged) --------------------------
    C = readcell(xlsFile,'FileType','spreadsheet');          % raw
    emptyRow = cellfun(@(row)all(cellfun(@(x)isempty(x)|| ...
              (isstring(x)&&strlength(x)==0) || ...
              (isnumeric(x)&&isnan(x)),row)),num2cell(C,2));
    C(emptyRow,:) = [];
    C = strtrim(string(C));

    idExpr = "^[A-Za-z]{2}\d+(_[ET])?$";
    if ~contains(C(1,1),regexpPattern(idExpr))
        C(1,:) = [];
    end

    badMap = containers.Map('KeyType','char','ValueType','any');
    for r = 1:size(C,1)
        cadID = upper(C(r,1));
        if cadID == "", continue, end
        tags = C(r,2:end);
        tags = tags(tags ~= "" & tags ~= "<missing>");
        if isempty(tags)
            tags = "__ALL__";
        end
        badMap(char(cadID)) = tags;
    end

    ud                    = fig.UserData;
    ud.badMap             = badMap;          % canonical name
    ud.hasBadSpectraSheet = true;            % flag for collectPairs
    fig.UserData          = ud;

    uiwait(msgbox(sprintf('Loaded %d cadaver IDs from bad-spectra sheet.', ...
                   badMap.Count), ...
           'Bad spectra sheet loaded','modal'));
    ok = true;
end

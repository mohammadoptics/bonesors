function coordinate = localSpatialTagCoordinate(tag)
%LOCALSPATIALTAGCOORDINATE MP is positive, MM is zero, and MD is negative.
token = regexp(upper(char(string(tag))), '_(MP|MM|MD)(\d+)$', ...
    'tokens', 'once');
if isempty(token)
    coordinate = NaN;
    return
end

distance = str2double(token{2});
switch token{1}
    case 'MP'
        coordinate = distance;
    case 'MD'
        coordinate = -distance;
    otherwise
        coordinate = 0;
end
end

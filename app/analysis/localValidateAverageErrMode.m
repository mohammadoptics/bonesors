function errMode = localValidateAverageErrMode(errMode)
    if nargin < 1 || isempty(errMode)
        errMode = 'none';
    end
    errMode = validatestring(char(string(errMode)), ...
        {'none','sd-fill','sd-dash','sem-dash','ci-fill'});
end


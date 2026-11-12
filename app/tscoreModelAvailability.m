function availability = tscoreModelAvailability()
%TSCOREMODELAVAILABILITY Detect model support in the current installation.

availability = struct();
availability.RIDGE = true; % Explicit unpenalized-intercept ridge solve, no toolbox.
availability.PLS = exist('plsregress','file') == 2;
availability.SVR = exist('fitrsvm','file') == 2;
availability.MLP = exist('fitrnet','file') == 2 || exist('fitnet','file') == 2;
availability.CNN = exist('trainNetwork','file') == 2;
end

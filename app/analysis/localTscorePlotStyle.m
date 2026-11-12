function style = localTscorePlotStyle()
%LOCALTSCOREPLOTSTYLE Compact styling shared by T-score scatter plots.
% Fonts remain compact while cadaver markers are enlarged for visibility.

style.markerSize = 9;
style.scatterSize = style.markerSize.^2;
style.axisFontSize = 15;
style.annotationFontSize = 15;
style.titleFontSize = 17;
style.legendFontSize = 14;
style.axisLineWidth = 1.7;
style.referenceLineWidth = 1.7;
style.legendTokenSize = [20 9];
end

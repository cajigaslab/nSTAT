%% FitResSummary Examples
% |FitResSummary| collects multiple |FitResult| objects returned by
% |Analysis.RunAnalysisForAllNeurons|.  It provides aggregate plotting and
% model-comparison utilities.
%
% See <AnalysisExamples2.html Analysis Examples 2> for a complete workflow
% that builds and visualises a |FitResSummary|.
%
%% Key Properties
%
% * |numResults| -- number of contained FitResult objects
% * |lambda| -- combined conditional-intensity signal across fits
% * |b| -- cell array of coefficient vectors (one per fit)
%
%% Aggregate Methods
%
%   fitResults.plotResults;            % side-by-side fit comparison
%   fitResults.plotResults_KS;         % KS plots for all fits
%   fitResults.evalLambda(idx, newData); % evaluate model idx on new data
%   fitResults.plotCoeffBoxPlots;      % boxplots across configurations
%
%% Example
%
%   % After running an analysis:
%   fitResults = Analysis.RunAnalysisForAllNeurons(trial, configColl, 0);
%   fitResults.plotResults;            % visualise all configurations
%   disp(fitResults.numResults);       % number of fits

%% FitResult Examples
% |FitResult| objects are created automatically by |Analysis.RunAnalysisForAllNeurons|
% and |Analysis.RunAnalysisForNeuron|.  They encapsulate the fitted model
% coefficients, goodness-of-fit statistics, and the conditional intensity.
%
% See <AnalysisExamples2.html Analysis Examples 2> for a complete walkthrough
% that produces |FitResult| objects and the <FitResultReference.html FitResult Reference>
% for a full property/method listing.
%
%% Creating a FitResult via Analysis
% After defining a Trial and TrialConfig, run the analysis:
%
%   fitResults = Analysis.RunAnalysisForAllNeurons(trial, configColl, 0);
%
% |fitResults| is a |FitResSummary| containing one |FitResult| per
% (neuron, configuration) pair.
%
%% Inspecting a FitResult
% Key properties available on each FitResult:
%
% * |b| -- fitted coefficient vector
% * |dev| -- model deviance
% * |stats| -- GLM statistics structure (standard errors, p-values)
% * |lambda| -- estimated conditional intensity (|SignalObj|)
% * |AIC|, |BIC| -- information criteria for model comparison
% * |KSStats| -- Kolmogorov-Smirnov goodness-of-fit results
%
%% Plotting
%
%   fitResults.plotResults;          % summary panel of all fits
%   fitResults.plotResults_KS;       % KS goodness-of-fit plots

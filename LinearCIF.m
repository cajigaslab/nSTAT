classdef LinearCIF < handle
 %LINEARCIF Conditional intensity function with closed-form derivatives.
 %
 % A subset of CIF.m that supports only the canonical-link cases —
 % Poisson (log link) and binomial (logit link). For these,
 % derivatives of lambda*delta and log(lambda*delta) with respect to
 % the stimulus variables are available in closed form and require
 % NO Symbolic Math Toolbox.
 %
 % Drop-in compatible with CIF for the 5 eval methods used by
 % nstat.decoding.PPAF.PPDecode_update:
 % evalLambdaDelta, evalGradient, evalGradientLog,
 % evalJacobian, evalJacobianLog.
 %
 % Constructor signature mirrors CIF:
 % LinearCIF(beta, Xnames, stimNames, fitType, histCoeffs, historyObj, nst)
 %
 % Closed-form derivatives :
 % Poisson: ld = exp(X*beta + H*gamma)
 % grad = ld * beta_stim
 % gradlog = beta_stim
 % jacobian = ld * (beta_stim' * beta_stim)
 % jaclog = zeros(nStim,nStim)
 % Binomial: ld = sigma(X*beta + H*gamma)
 % grad = ld*(1-ld) * beta_stim
 % gradlog = (1-ld) * beta_stim
 % jacobian = ld*(1-ld)*(1-2*ld) * (beta_stim' * beta_stim)
 % jaclog = -ld*(1-ld) * (beta_stim' * beta_stim)
 %
 % Phase 3 Task 3.5 of the 2026-05-19 nSTAT review action plan.

 properties
 b % Regression coefficients (1 x nVar)
 varIn % All variable names as symbolic column vector
 stimVars % Subset of varIn that are stimulus/state variables (sym column)
 fitType % 'poisson' | 'binomial'
 histCoeffs % History coefficients (1 x nHist) or []
 history % History object or []
 spikeTrain % nspikeTrain used for history (or [])
 historyMat % Precomputed history matrix (when applicable)

 stimIdx % Indices into varIn for the stimulus columns (column vector)
 bStim % Stimulus coefficients beta_stim (1 x nStim row)
 end

 methods
 function obj = LinearCIF(beta, Xnames, stimNames, fitType, histCoeffs, historyObj, nst)
 % LINEARCIF Construct a closed-form canonical-link CIF.
 % See class header for argument semantics.

 if nargin < 7
 obj.spikeTrain = [];
 else
 obj.spikeTrain = nst.nstCopy;
 end
 if nargin < 6
 obj.history = [];
 else
 obj.setHistory(historyObj);
 end
 if nargin < 5
 obj.histCoeffs = [];
 else
 [r, c] = size(histCoeffs);
 if r == 1
 obj.histCoeffs = histCoeffs;
 elseif c == 1
 obj.histCoeffs = histCoeffs';
 elseif isempty(histCoeffs)
 obj.histCoeffs = [];
 else
 error('LinearCIF:InvalidHistCoeffs',...
 'History coefficient vector must have one dimension equal to 1');
 end
 end

 if nargin < 4 || isempty(fitType)
 fitType = 'poisson';
 end
 if ~ismember(fitType, {'poisson', 'binomial'})
 error('LinearCIF:InvalidFitType',...
 'fitType must be ''poisson'' or ''binomial'', got ''%s''', fitType);
 end
 obj.fitType = fitType;

 % Normalize Xnames into a sym column vector (matches CIF behavior).
 if isa(Xnames, 'sym')
 XnamesTemp = cell(length(Xnames), 1);
 for i = 1:length(Xnames)
 XnamesTemp{i} = char(Xnames(i));
 end
 Xnames = XnamesTemp;
 end
 [r, c] = size(Xnames);
 if r == 1
 Xnames = Xnames';
 elseif c ~= 1
 error('LinearCIF:InvalidXnames',...
 'Xnames must have one dimension equal to 1');
 end
 obj.varIn = sym(Xnames);

 % Normalize stimNames into a sym column vector.
 [r, c] = size(stimNames);
 if r == 1
 obj.stimVars = sym(stimNames');
 elseif c == 1
 obj.stimVars = sym(stimNames);
 else
 error('LinearCIF:InvalidStimNames',...
 'stimNames must have one dimension equal to 1');
 end

 % Normalize beta into a row vector. We support numeric input only
 % (closed-form derivatives require numeric coefficients).
 if ~isnumeric(beta)
 error('LinearCIF:NonNumericBeta',...
 'LinearCIF requires numeric beta; got %s', class(beta));
 end
 [r, c] = size(beta);
 if r == 1
 obj.b = beta;
 elseif c == 1
 obj.b = beta';
 else
 error('LinearCIF:InvalidBeta',...
 'Beta must have one dimension equal to 1');
 end
 if numel(obj.b) ~= numel(obj.varIn)
 error('LinearCIF:BetaXnamesMismatch',...
 'numel(beta)=%d does not match numel(Xnames)=%d',...
 numel(obj.b), numel(obj.varIn));
 end

 % Compute stimulus indices into varIn (and the stim-coefficient row).
 nStim = numel(obj.stimVars);
 obj.stimIdx = zeros(nStim, 1);
 for k = 1:nStim
 idx = find(obj.varIn == obj.stimVars(k), 1);
 if isempty(idx)
 error('LinearCIF:StimNotInXnames',...
 'Stim variable ''%s'' not found in Xnames', char(obj.stimVars(k)));
 end
 obj.stimIdx(k) = idx;
 end
 obj.bStim = obj.b(obj.stimIdx); % 1 x nStim row vector

 % Precompute history matrix when both history and spike train present.
 if ~isempty(obj.spikeTrain) && ~isempty(obj.history)
 obj.historyMat = obj.history.computeHistory(obj.spikeTrain).dataToMatrix;
 else
 obj.historyMat = [];
 end
 end

 function setSpikeTrain(obj, spikeTrain)
 obj.spikeTrain = spikeTrain.nstCopy;
 if ~isempty(obj.history)
 obj.historyMat = obj.history.computeHistory(obj.spikeTrain).dataToMatrix;
 else
 obj.historyMat = [];
 end
 end

 function setHistory(obj, histObj)
 if isa(histObj, 'History')
 obj.history = History(histObj.windowTimes);
 elseif isa(histObj, 'double')
 obj.history = History(histObj);
 else
 error('LinearCIF:InvalidHistory',...
 'History can only be set by passing in a History Object or a vector of windowTimes');
 end
 end

 function ld = evalLambdaDelta(obj, stimVal, time_index, nst)
 % EVALLAMBDADELTA Scalar lambda*delta at stimVal (and history).
 if nargin < 3, time_index = []; end
 if nargin < 4, nst = []; end
 eta = obj.computeEta(stimVal, time_index, nst);
 ld = obj.linkInverse(eta);
 end

 function g = evalGradient(obj, stimVal, time_index, nst)
 % EVALGRADIENT Gradient of (lambda*delta) w.r.t. stimulus vars.
 % Row vector (1 x nStim).
 if nargin < 3, time_index = []; end
 if nargin < 4, nst = []; end
 ld = obj.evalLambdaDelta(stimVal, time_index, nst);
 switch obj.fitType
 case 'poisson'
 g = ld * obj.bStim;
 case 'binomial'
 g = ld * (1 - ld) * obj.bStim;
 end
 end

 function g = evalGradientLog(obj, stimVal, time_index, nst)
 % EVALGRADIENTLOG Gradient of log(lambda*delta) w.r.t. stim vars.
 % Row vector (1 x nStim).
 if nargin < 3, time_index = []; end
 if nargin < 4, nst = []; end
 switch obj.fitType
 case 'poisson'
 g = obj.bStim;
 case 'binomial'
 ld = obj.evalLambdaDelta(stimVal, time_index, nst);
 g = (1 - ld) * obj.bStim;
 end
 end

 function J = evalJacobian(obj, stimVal, time_index, nst)
 % EVALJACOBIAN Hessian of (lambda*delta) w.r.t. stim vars (nStim x nStim).
 if nargin < 3, time_index = []; end
 if nargin < 4, nst = []; end
 ld = obj.evalLambdaDelta(stimVal, time_index, nst);
 outer = obj.bStim' * obj.bStim;
 switch obj.fitType
 case 'poisson'
 J = ld * outer;
 case 'binomial'
 J = ld * (1 - ld) * (1 - 2 * ld) * outer;
 end
 end

 function J = evalJacobianLog(obj, stimVal, time_index, nst)
 % EVALJACOBIANLOG Hessian of log(lambda*delta) w.r.t. stim vars.
 if nargin < 3, time_index = []; end
 if nargin < 4, nst = []; end
 nStim = numel(obj.stimVars);
 switch obj.fitType
 case 'poisson'
 J = zeros(nStim, nStim);
 case 'binomial'
 ld = obj.evalLambdaDelta(stimVal, time_index, nst);
 J = -ld * (1 - ld) * (obj.bStim' * obj.bStim);
 end
 end
 end

 methods (Access = private)
 function eta = computeEta(obj, stimVal, time_index, nst)
 % COMPUTEETA Compute the linear predictor eta = X*beta + H*gamma.
 % Mirrors CIF's expandStimToVarIn + history evaluation logic.
 histVal = obj.resolveHistVal(time_index, nst);
 xFull = obj.expandStimToVarIn(stimVal); % column nVar x 1
 eta = obj.b * xFull; % scalar
 if ~isempty(histVal) && ~isempty(obj.histCoeffs)
 eta = eta + obj.histCoeffs * histVal;
 end
 end

 function histVal = resolveHistVal(obj, time_index, nst)
 % RESOLVEHISTVAL Replicate CIF's eval-method history resolution.
 % time_index and nst are always passed by callers; empty values
 % mean "not supplied" (matches CIF's nargin-based semantics).
 histVal = [];
 if isempty(nst)
 if ~isempty(time_index) && ~isempty(obj.historyMat)
 histVal = obj.historyMat(time_index, :)';
 end
 elseif isa(nst, 'nspikeTrain')
 if ~isempty(obj.history)
 histData = obj.history.computeHistory(nst).dataToMatrix;
 histVal = histData(end, :)';
 end
 else
 error('LinearCIF:InvalidNST',...
 'Second Input must be of class nspikeTrain');
 end
 end

 function fullVal = expandStimToVarIn(obj, stimVal)
 % EXPANDSTIMTOVARIN Mirror of CIF.expandStimToVarIn.
 % If stimVal already has length nVar, pass through. Otherwise
 % treat it as nStim stimulus values and fill the remaining
 % positions (intercept/constant columns) with 1.0.
 nVar = numel(obj.varIn);
 nStim = numel(obj.stimVars);
 stimVal = stimVal(:);
 if numel(stimVal) == nVar
 fullVal = stimVal;
 elseif numel(stimVal) == nStim
 fullVal = ones(nVar, 1);
 for k = 1:nStim
 fullVal(obj.stimIdx(k)) = stimVal(k);
 end
 else
 error('LinearCIF:InvalidStimValSize',...
 'stimVal must have length %d (all vars) or %d (stim vars only), got %d.',...
 nVar, nStim, numel(stimVal));
 end
 end

 function ld = linkInverse(obj, eta)
 switch obj.fitType
 case 'poisson'
 ld = exp(eta);
 case 'binomial'
 % Use a numerically stable sigmoid.
 if eta >= 0
 ez = exp(-eta);
 ld = 1 / (1 + ez);
 else
 ez = exp(eta);
 ld = ez / (1 + ez);
 end
 end
 end
 end
end

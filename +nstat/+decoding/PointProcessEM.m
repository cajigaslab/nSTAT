classdef PointProcessEM
 %POINTPROCESSEM Point-process EM (no continuous LFP observation).
 %
 % The PPLFP family specialized to spike-only observations. Linear-
 % Gaussian state dynamics and Poisson spike observations, with EM
 % parameter learning for (A, Q, mu, beta, gamma, x_0, Px_0). Mirrors
 % the structure of nstat.decoding.PPLFP minus the continuous-
 % observation pipeline (C, R, alpha all dropped).
 %
 % Extracted from DecodingAlgorithms.m (Phase 3 Task 3.2 Step H -- the
 % FINAL cluster extraction of the 2026-05-19 nSTAT review action
 % plan). DecodingAlgorithms.PP_* are now thin deprecation shims that
 % forward here.
 %
 % Static methods:
 % PP_EMCreateConstraints -- EM constraint builder.
 % PP_ComputeParamStandardErrors -- Fisher-info SE calculator (~881 LOC).
 % PP_EM -- Main EM loop (~672 LOC).
 % PP_EStep -- F-B pass (calls nstat.decoding.PPAF
 % PPDecode_updateLinear / predict, and
 % nstat.decoding.KalmanFilter
 % kalman_smootherFromFiltered).
 % PP_MStep -- Joint M-step (~1125 LOC).
 %
 % Cross-cluster calls inside PP_EStep are rewired directly to
 % nstat.decoding.PPAF.* and nstat.decoding.KalmanFilter.* so EM
 % iterations do not emit the deprecation-shim warning on every pass.
 %
 % Shared helpers (prepareEMResults, ComputeStimulusCIs, estimateInfoMat,
 % computeSpikeRateCIs, computeSpikeRateDiffCIs) remain in
 % DecodingAlgorithms and are referenced as DecodingAlgorithms.* below.
 %
 % Refs: Dempster, Laird & Rubin 1977 (EM);
 %.B.7 PPLFP (this is the spike-
 % only special case).

 methods (Static)
 function C = PP_EMCreateConstraints(EstimateA, AhatDiag,QhatDiag,QhatIsotropic,Estimatex0,EstimatePx0, Px0Isotropic,mcIter, EnableIkeda)
 %PP_EMCREATECONSTRAINTS constraint/option struct for PP_EM.
 % C = PP_EMCreateConstraints(EstimateA, AhatDiag, QhatDiag,
 % QhatIsotropic, Estimatex0, EstimatePx0, Px0Isotropic, mcIter,
 % EnableIkeda); every argument is optional.
 %
 % Defaults (changed in fix/pp-em round 2):
 % EstimateA=1, AhatDiag=0 (full A), QhatDiag=1, QhatIsotropic=0,
 % Estimatex0=0, EstimatePx0=0, Px0Isotropic=0, mcIter=1000,
 % EnableIkeda=0.
 % x0 and Px0 are NOT estimated by default (previously 1 and 1): the
 % Px0 M-step, Px0hat = (x0hat-x0)(x0hat-x0)'.*I, is a single-sample
 % estimate that collapses to ~0 after one iteration, which drives
 % -1/2*log(det(Px0)) and hence the E-step log-likelihood to +Inf
 % and stops EM after ~2 iterations. Pass Estimatex0/EstimatePx0 = 1
 % explicitly to restore the old behaviour.
 if(nargin<9 || isempty(EnableIkeda))
 EnableIkeda=0;
 end
 if(nargin<8 || isempty(mcIter))
 mcIter=1000;
 end
 if(nargin<7 || isempty(Px0Isotropic))
 Px0Isotropic=0;
 end
 if(nargin<6 || isempty(EstimatePx0))
 EstimatePx0=0; % FIX: default was 1 (degenerate Px0 collapse; see help)
 end
 if(nargin<5 || isempty(Estimatex0))
 Estimatex0=0; % FIX: default was 1 (see help)
 end
 if(nargin<4 || isempty(QhatIsotropic))
 QhatIsotropic=0;
 end
 if(nargin<3 || isempty(QhatDiag))
 QhatDiag=1;
 end
 if(nargin<2)
 AhatDiag=0;
 end
 if(nargin<1)
 EstimateA=1;
 end
 C.EstimateA = EstimateA;
 C.AhatDiag = AhatDiag;
 C.QhatDiag = QhatDiag;
 if(QhatDiag && QhatIsotropic)
 C.QhatIsotropic=1;
 else
 C.QhatIsotropic=0;
 end
 C.Estimatex0 = Estimatex0;
 C.EstimatePx0 = EstimatePx0;
 if(EstimatePx0 && Px0Isotropic)
 C.Px0Isotropic=1;
 else
 C.Px0Isotropic=0; 
 end
 C.mcIter = mcIter;
 C.EnableIkeda=EnableIkeda;
 end 
 function [SE,Pvals,nTerms] = PP_ComputeParamStandardErrors(dN, xKFinal, WKFinal, Ahat, Qhat, x0hat, Px0hat, ExpectationSumsFinal, fitType, muhat, betahat, gammahat, windowTimes, HkAll, PPEM_Constraints)

 % Use inverse observed information matrix to estimate the standard errors of the estimated model parameters
 % Requires computation of the complete information matrix and an estimate of the missing information matrix

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
 % Complete Information Matrices 
 % Recall from McLachlan and Krishnan Eq. 4.7
 % Io(theta;y) = Ic(theta;y) - Im(theta;y)
 % Io(theta;y) = Ic(theta;y) - cov(Sc(X;theta)Sc(X;theta)')
 % where Sc(X;theta) is the score vector of the complete log likelihood
 % function evaluated at theta. We first compute Ic term by term and then
 % approximate the covariance term using Monte Carlo approximation
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 % FIX (G2): this function has 15 inputs, so the old test nargin<19 was
 % always true and the caller's constraints were ALWAYS replaced by the
 % PP_EMCreateConstraints() defaults: mcIter was always 1000, AhatDiag=1
 % still produced a full SE.A (SEs for off-diagonal entries that were
 % never estimated), EstimateA=0 still reported SE.A, and the missing
 % information (which couples every block) was built for the wrong
 % parameter vector. (Copied from PPLFP_ComputeParamStandardErrors,
 % which has 19 inputs.) Use the defaults only when the argument is
 % absent or empty.
 if(nargin<15 || isempty(PPEM_Constraints))
 PPEM_Constraints=nstat.decoding.PointProcessEM.PP_EMCreateConstraints;
 end
 % FIX (G2): with the constraints honoured, three non-default paths
 % became reachable that used variables this routine never defined
 % (only the always-default path had been exercised): EstimateA=0 left
 % N undefined (it was set inside the A block), and QhatIsotropic=1 /
 % Px0Isotropic=1 used an undefined dx. Define both up front, as
 % PPLFP_ComputeParamStandardErrors does.
 N=size(xKFinal,2);
 dx=size(xKFinal,1);
 % FIX (F12): a shared history-coefficient column (numWindows x 1,
 % including a scalar for one window) with several cells is expanded
 % to numWindows x numCells (gamma(w,c) = gamma_shared(w)), the rule
 % PP_EM applies before it calls this routine (B9). The gamma
 % information blocks and scores below are built per cell (numWindows
 % rows each) and index gammahat(:,c), so a scalar gamma with C > 1
 % counted one gamma parameter against C per-cell blocks (dimension
 % error) and a numWindows x 1 column failed on gammahat(:,c), c > 1.
 % After the expansion every cell has its own coefficients and SE.gamma
 % / Pvals.gamma are numWindows x numCells, exactly as for the
 % expanded input; the count matches PP_EM's IC count (one
 % parameter per coefficient). An all-zero gamma is left as passed.
 if(~isempty(windowTimes) && size(gammahat,2)==1 && size(dN,1)>1 ...
 && size(gammahat,1)==numel(windowTimes)-1 && any(gammahat(:)~=0))
 gammahat = repmat(gammahat,1,size(dN,1));
 end

 
 if(PPEM_Constraints.EstimateA==1)
 if(PPEM_Constraints.AhatDiag==1)
 IAComp=zeros(numel(diag(Ahat)),numel(diag(Ahat)));
 else
 IAComp=zeros(numel(Ahat),numel(Ahat));
 end
 [n1,n2] =size(Ahat);
 el=(eye(n1,n1));
 em=(eye(n2,n2));
 cnt=1;
 N=size(xKFinal,2);

 if(PPEM_Constraints.AhatDiag==1)
 for l=1:n1
 for m=l
 termMat=Qhat\el(:,l)*em(:,m)'*ExpectationSumsFinal.Sxkm1xkm1.*eye(n1,n2);
 termvec = diag(termMat);
 IAComp(:,cnt)=termvec;
 cnt=cnt+1;
 end
 end
 else
 for l=1:n1
 for m=1:n2
 termMat=(inv(Qhat))*el(:,l)*em(:,m)'*ExpectationSumsFinal.Sxkm1xkm1;
 termvec=reshape(termMat',1,numel(Ahat));
 IAComp(:,cnt)=termvec';
 cnt=cnt+1;
 end
 end
 end
 end

 
 [n1,n2] =size(Qhat);
 el=(eye(n1,n1));
 em=(eye(n2,n2));
 cnt=1;
 if(PPEM_Constraints.QhatDiag==1)
 if(PPEM_Constraints.QhatIsotropic==1)
 IQComp=zeros(1,1);
 IQComp = 0.5*N*dx*Qhat(1,1)^(-2); 
 else
 IQComp=zeros(numel(diag(Qhat)),numel(diag(Qhat)));
 for l=1:n1
 for m=l
 % FIX (H1): operator precedence. MATLAB evaluates *, / and \ left
 % to right, so N/2*(Qhat)\e*e'/(Qhat) was ((N/2)*Qhat)\e*e'/Qhat =
 % (2/N)*inv(Q)*e*e'*inv(Q), not the intended (N/2)*inv(Q)*e*e'*inv(Q)
 % (information of a covariance entry, K/(2*q^2) on the diagonal): the
 % Q / R information was N^2/4 too small (SEs ~K/2 too large) and the
 % single-sample Px0 information (1/2)*inv(P)*e*e'*inv(P) 4x too large.
 % Parenthesised at every such site of this routine.
 termMat= N/2*((Qhat)\em(:,m)*el(:,l)'/(Qhat));
 termvec=diag(termMat);
 IQComp(:,cnt)=termvec;
 cnt=cnt+1;
 end
 end
 end
 else
 IQComp=zeros(numel(Qhat),numel(Qhat));
 for l=1:n1
 for m=1:n2
 % FIX (H1): parenthesised (operator precedence; see the first H1 note).
 termMat= N/2*((Qhat)\em(:,m)*el(:,l)'/(Qhat));
 termvec=reshape(termMat',1,numel(Qhat));
 IQComp(:,cnt)=termvec;
 cnt=cnt+1;
 end
 end
 end

 if(PPEM_Constraints.EstimatePx0==1)
 if(PPEM_Constraints.Px0Isotropic==1)
 ISComp = 0.5*dx*Px0hat(1,1)^(-2);
 else
 ISComp=zeros(numel(diag(Px0hat)),numel(diag(Px0hat)));
 [n1,n2] =size(Px0hat);
 el=(eye(n1,n1));
 em=(eye(n2,n2));
 cnt=1;
 for l=1:n1
 for m=l
 % FIX (H1): parenthesised (operator precedence; see the first H1 note).
 termMat= 1/2*((Px0hat)\em(:,m)*el(:,l)'/(Px0hat));
 termvec=diag(termMat);
 ISComp(:,cnt)=termvec;
 cnt=cnt+1;
 end
 end
 end
 end

 if(PPEM_Constraints.Estimatex0==1)
 Ix0Comp=eye(size(Px0hat))/Px0hat+(Ahat'/Qhat)*Ahat;
 end

 
 K=size(xKFinal,2);
 numCells=size(betahat,2);
 McExp=PPEM_Constraints.mcIter; 
 xKDrawExp = zeros(size(xKFinal,1),K,McExp);
 

 % Generate the Monte Carlo
 for k=1:K
 % FIX (F9): draw via mcStateDraws (m + chol(W)'*z; was m + chol(W)*z,
 % whose covariance is chol(W)*chol(W)', not W, for non-diagonal W).
 xKDrawExp(:,k,:)=nstat.decoding.PointProcessEM.mcStateDraws(xKFinal(:,k),WKFinal(:,:,k),McExp);
 end
 
 IBetaComp =zeros(size(xKFinal,1)*numCells,size(xKFinal,1)*numCells);
 xkPerm = permute(xKDrawExp,[1 3 2]);
 % FIX (#99): matlabpool was removed in R2017a; same defect class as PPLFP.m.
 ppPool = gcp('nocreate'); if isempty(ppPool), pools = 0; else, pools = ppPool.NumWorkers; end
 if(strcmp(fitType,'poisson'))
 for c=1:numCells
 HessianTerm = zeros(size(xKFinal,1),size(xKFinal,1),K);
 for k=1:K
% Hk = squeeze(HkAll(:,:,c));
 Hk = (HkAll(k,:,c));
 Wk = WKFinal(:,:,k);
 
% xk = squeeze(xKDrawExp(:,k,:));
 xk=xkPerm(:,:,k);
 % FIX: no re-orientation. HkAll is (numTimeSteps x numWindows x
 % numCells) by construction, so this slice is already 1 x W (or
 % N x W). The old `size(Hk,1)==numCells` test fired for a single
 % cell (and for N == numCells) and broke the history terms.
 
 if(numel(gammahat)==1)
 gammaC=gammahat;
% gammaC=repmat(gammaC,[1 numCells]);
 else 
 gammaC=gammahat(:,c);
 end

 terms =muhat(c)+betahat(:,c)'*xk+gammaC'*Hk';
 ld=exp(terms);
 
 HessianTerm(:,:,k)=-1/McExp*(repmat(ld,[size(xk,1),1]).*xk)*xk';
 end
 startInd = size(betahat,1)*(c-1)+1; endInd = size(betahat,1)*c;
 IBetaComp(startInd:endInd,startInd:endInd)=-sum(HessianTerm,3);
 end
 else
 for c=1:numCells
 HessianTerm = zeros(size(xKFinal,1),size(xKFinal,1),K);
 for k=1:K
% Hk = squeeze(HkAll(:,:,c));
 Hk = (HkAll(k,:,c));
 Wk = WKFinal(:,:,k);
% xk = squeeze(xKDrawExp(:,k,:));
 xk = (xkPerm(:,:,k));
 % FIX: no re-orientation. HkAll is (numTimeSteps x numWindows x
 % numCells) by construction, so this slice is already 1 x W (or
 % N x W). The old `size(Hk,1)==numCells` test fired for a single
 % cell (and for N == numCells) and broke the history terms.
 
 if(numel(gammahat)==1)
 gammaC=gammahat;
% gammaC=repmat(gammaC,[1 numCells]);
 else 
 gammaC=gammahat(:,c);
 end
 terms =muhat(c)+betahat(:,c)'*xk+gammaC'*Hk';
 ld=exp(terms)./(1+exp(terms));
 ExplambdaDeltaXkXk=1/McExp*(repmat(ld,[size(xk,1),1]).*xk)*xk';
 ExplambdaDeltaSqXkXkT=1/McExp*(repmat(ld.^2,[size(xk,1),1]).*xk)*xk';
 ExplambdaDeltaCubeXkXkT=1/McExp*(repmat(ld.^3,[size(xk,1),1]).*xk)*xk';
 % FIX: missing `=`. The previous code computed a value and silently
 % discarded it, leaving HessianTerm(:,:,k) at its initial 0. The
 % binomial-branch parameter standard errors (IBetaComp) were
 % effectively all-zero. Parallel structure to the poisson branch a
 % few lines above which does `HessianTerm(:,:,k) = -1/McExp*(...)`.
 % Surfaced by checkcode VUNUS finding 2026-06-22.
 % FIX: the expression itself had the wrong sign/form (same
 % defect as PP_MStep's binomial beta step). For
 % log L = sum dN*log(p) - p, p = logistic(eta), the beta
 % Hessian is -p(1-p)(1+dN-2p)xx' =
 % (-(dN+1)p + (dN+3)p^2 - 2p^3)xx', the form the mu and gamma
 % information blocks below already use. The old
 % (E[p]+E[p^2]-2E[p^3])xx' made IBetaComp = -sum(Hessian)
 % negative definite, so binomial beta SEs were meaningless
 % (nearestSPD then masked the sign).
 HessianTerm(:,:,k) = -(dN(c,k)+1)*ExplambdaDeltaXkXk + (dN(c,k)+3)*ExplambdaDeltaSqXkXkT - 2*ExplambdaDeltaCubeXkXkT;
 
 end
 startInd = size(betahat,1)*(c-1)+1; endInd = size(betahat,1)*c;
 IBetaComp(startInd:endInd,startInd:endInd)=-sum(HessianTerm,3);
 end
 end

 
 %CIF means
 IMuComp=zeros(numel(muhat),numel(muhat));
 xkPerm = permute(xKDrawExp,[1 3 2]);
 if(pools==0)
 for c=1:numCells
 if(strcmp(fitType,'poisson'))
 HessianTerm = 0;
 for k=1:K
 % Hk = squeeze(HkAll(:,:,c));
 Hk = (HkAll(:,:,c));
 % FIX: no re-orientation. HkAll is (numTimeSteps x numWindows x
 % numCells) by construction, so this slice is already 1 x W (or
 % N x W). The old `size(Hk,1)==numCells` test fired for a single
 % cell (and for N == numCells) and broke the history terms.
 % xk = squeeze(xKDrawExp(:,k,:));
 xk = xkPerm(:,:,k);
 Wk = WKFinal(:,:,k);
 if(numel(gammahat)==1)
 gammaC=gammahat;
 else 
 gammaC=gammahat(:,c);
 end
 terms=muhat(c)+betahat(:,c)'*xk+gammaC'*Hk(k,:)';
 ld = exp(terms);
 HessianTerm=HessianTerm-1/McExp*sum(ld,2);
 end
 elseif(strcmp(fitType,'binomial'))
 HessianTerm = 0;
 for k=1:K
 % Hk = squeeze(HkAll(:,:,c));
 Hk = (HkAll(:,:,c));
 % FIX: no re-orientation. HkAll is (numTimeSteps x numWindows x
 % numCells) by construction, so this slice is already 1 x W (or
 % N x W). The old `size(Hk,1)==numCells` test fired for a single
 % cell (and for N == numCells) and broke the history terms.
 % xk = squeeze(xKDrawExp(:,k,:));
 xk = xkPerm(:,:,k);
 Wk = WKFinal(:,:,k);
 if(numel(gammahat)==1)
 gammaC=gammahat;
 else 
 gammaC=gammahat(:,c);
 end
 terms=muhat(c)+betahat(:,c)'*xk+gammaC'*Hk(k,:)';
 ld = exp(terms)./(1+exp(terms));
 ExplambdaDelta = 1/McExp*sum(ld,2);
 ExplambdaDeltaSquare = 1/McExp*sum(ld.^2,2);
 ExplambdaDeltaCubed = 1/McExp*sum(ld.^3,2);
 % FIX: the cubic coefficient was -3. For
 % log L = sum dN*log(p) - p, p = logistic(eta), the mu score is
 % (dN-p)(1-p) and d/dmu of it is -p(1-p)(1+dN-2p) =
 % -(dN+1)p + (dN+3)p^2 - 2p^3 (as in the M-step's mu update and
 % the beta/gamma blocks); -3*E[p^3] overstated the information.
 HessianTerm = HessianTerm -(dN(c,k)+1)*ExplambdaDelta...
 +(dN(c,k)+3)*ExplambdaDeltaSquare-2*ExplambdaDeltaCubed;
 end
 end
 IMuComp(c,c) = -HessianTerm;
 end
 else
 for c=1:numCells
 if(strcmp(fitType,'poisson'))
 HessianTerm = zeros(K,1);
 for k=1:K
 % Hk = squeeze(HkAll(:,:,c));
 Hk = (HkAll(k,:,c));
 % FIX: no re-orientation. HkAll is (numTimeSteps x numWindows x
 % numCells) by construction, so this slice is already 1 x W (or
 % N x W). The old `size(Hk,1)==numCells` test fired for a single
 % cell (and for N == numCells) and broke the history terms.
 % xk = squeeze(xKDrawExp(:,k,:));
 xk = xkPerm(:,:,k);
 Wk = WKFinal(:,:,k);
 if(numel(gammahat)==1)
 gammaC=gammahat;
 else 
 gammaC=gammahat(:,c);
 end
 terms=muhat(c)+betahat(:,c)'*xk+gammaC'*Hk';
 ld = exp(terms);
 HessianTerm(k)=-1/McExp*sum(ld,2);
 end
 elseif(strcmp(fitType,'binomial'))
 HessianTerm = zeros(K,1);
 for k=1:K
 % Hk = squeeze(HkAll(:,:,c));
 Hk = (HkAll(k,:,c));
 % FIX: no re-orientation. HkAll is (numTimeSteps x numWindows x
 % numCells) by construction, so this slice is already 1 x W (or
 % N x W). The old `size(Hk,1)==numCells` test fired for a single
 % cell (and for N == numCells) and broke the history terms.
 % xk = squeeze(xKDrawExp(:,k,:));
 xk = xkPerm(:,:,k);
 Wk = WKFinal(:,:,k);
 if(numel(gammahat)==1)
 gammaC=gammahat;
 else 
 gammaC=gammahat(:,c);
 end
 terms=muhat(c)+betahat(:,c)'*xk+gammaC'*Hk';
 ld = exp(terms)./(1+exp(terms));
 ExplambdaDelta = 1/McExp*sum(ld,2);
 ExplambdaDeltaSquare = 1/McExp*sum(ld.^2,2);
 ExplambdaDeltaCubed = 1/McExp*sum(ld.^3,2);
 % FIX: cubic coefficient -3 -> -2 (see the serial branch above).
 HessianTerm(k) = -(dN(c,k)+1)*ExplambdaDelta...
 +(dN(c,k)+3)*ExplambdaDeltaSquare-2*ExplambdaDeltaCubed;
 end
 end
 IMuComp(c,c) = -sum(HessianTerm);
 end
 end
 
 
 % Gamma Information Matrix
 IGammaComp = zeros(numel(gammahat),numel(gammahat));
 if(~isempty(windowTimes) && any(any(gammahat~=0)))
 xkPerm = permute(xKDrawExp,[1 3 2]);
 if(pools==0)
 for c=1:numCells
 if(strcmp(fitType,'poisson'))
 HessianTerm = zeros(size(HkAll,2),size(HkAll,2));
 for k=1:K
 % Hk = squeeze(HkAll(:,:,c));
 Hk = (HkAll(:,:,c));
 % FIX: no re-orientation. HkAll is (numTimeSteps x numWindows x
 % numCells) by construction, so this slice is already 1 x W (or
 % N x W). The old `size(Hk,1)==numCells` test fired for a single
 % cell (and for N == numCells) and broke the history terms.
 % xk = squeeze(xKDrawExp(:,k,:));
 xk = xkPerm(:,:,k);
 Wk = WKFinal(:,:,k);
 if(numel(gammahat)==1)
 gammaC=gammahat;
 else 
 gammaC=gammahat(:,c);
 end
 terms=muhat(c)+betahat(:,c)'*xk+gammaC'*Hk(k,:)';
 ld = exp(terms);
 ExplambdaDelta = 1/McExp*sum(ld,2);
 HessianTerm=HessianTerm-Hk(k,:)'*Hk(k,:)*ExplambdaDelta;
 end
 elseif(strcmp(fitType,'binomial'))
 HessianTerm = zeros(size(HkAll,2),size(HkAll,2));
 for k=1:K
 Hk = (HkAll(:,:,c));
 % FIX: no re-orientation. HkAll is (numTimeSteps x numWindows x
 % numCells) by construction, so this slice is already 1 x W (or
 % N x W). The old `size(Hk,1)==numCells` test fired for a single
 % cell (and for N == numCells) and broke the history terms.
 % xk = squeeze(xKDrawExp(:,k,:));
 xk = xkPerm(:,:,k);
 Wk = WKFinal(:,:,k);
 if(numel(gammahat)==1)
 gammaC=gammahat;
 else 
 gammaC=gammahat(:,c);
 end
 terms=muhat(c)+betahat(:,c)'*xk+gammaC'*Hk(k,:)';
 ld = exp(terms)./(1+exp(terms));
 ExplambdaDelta = 1/McExp*sum(ld,2);
 ExplambdaDeltaSquare = 1/McExp*sum(ld.^2,2);
 ExplambdaDeltaCubed = 1/McExp*sum(ld.^3,2); % FIX: was ld.^2 (copy-paste); should be ld.^3 for cubic moment
 % FIX: was `...*Hk(k,:)'*Hk(:,k)` -- Hk(:,k) is column k of the
 % (numTimeSteps x numWindows) history matrix, not the time-k row,
 % so this always errored ("Incorrect dimensions for matrix
 % multiplication") for binomial fits with history. Use the outer
 % product of the time-k row, as the poisson branch above does.
 HessianTerm=HessianTerm+(-ExplambdaDelta*(dN(c,k)+1)...
 +ExplambdaDeltaSquare*(dN(c,k)+3)...
 -2*ExplambdaDeltaCubed)*Hk(k,:)'*Hk(k,:);
 end
 end
 startInd=size(HkAll,2)*(c-1)+1; endInd = size(HkAll,2)*c;
 IGammaComp(startInd:endInd,startInd:endInd) = -HessianTerm;
 end

 else
 
 for c=1:numCells
 if(strcmp(fitType,'poisson'))
 HessianTerm = zeros(size(HkAll,2),size(HkAll,2),K);
 for k=1:K
 % Hk = squeeze(HkAll(:,:,c));
 Hk = (HkAll(k,:,c));
 % FIX: no re-orientation. HkAll is (numTimeSteps x numWindows x
 % numCells) by construction, so this slice is already 1 x W (or
 % N x W). The old `size(Hk,1)==numCells` test fired for a single
 % cell (and for N == numCells) and broke the history terms.
 % xk = squeeze(xKDrawExp(:,k,:));
 xk = xkPerm(:,:,k);
 Wk = WKFinal(:,:,k);
 if(numel(gammahat)==1)
 gammaC=gammahat;
 else 
 gammaC=gammahat(:,c);
 end
 terms=muhat(c)+betahat(:,c)'*xk+gammaC'*Hk';
 ld = exp(terms);
 ExplambdaDelta = 1/McExp*sum(ld,2);
 HessianTerm(:,:,k)=-Hk'*Hk*ExplambdaDelta;
 end
 elseif(strcmp(fitType,'binomial'))
 HessianTerm = zeros(size(HkAll,2),size(HkAll,2),K);

 for k=1:K
 Hk = (HkAll(k,:,c));
 % FIX: no re-orientation. HkAll is (numTimeSteps x numWindows x
 % numCells) by construction, so this slice is already 1 x W (or
 % N x W). The old `size(Hk,1)==numCells` test fired for a single
 % cell (and for N == numCells) and broke the history terms.
 % xk = squeeze(xKDrawExp(:,k,:));
 xk = xkPerm(:,:,k);
 Wk = WKFinal(:,:,k);
 if(numel(gammahat)==1)
 gammaC=gammahat;
 else 
 gammaC=gammahat(:,c);
 end
 terms=muhat(c)+betahat(:,c)'*xk+gammaC'*Hk';
 ld = exp(terms)./(1+exp(terms));
 ExplambdaDelta = 1/McExp*sum(ld,2);
 ExplambdaDeltaSquare = 1/McExp*sum(ld.^2,2);
 ExplambdaDeltaCubed = 1/McExp*sum(ld.^3,2); % FIX: was ld.^2 (copy-paste); should be ld.^3 for cubic moment
 HessianTerm(:,:,k)=+(-ExplambdaDelta*(dN(c,k)+1)...
 +ExplambdaDeltaSquare*(dN(c,k)+3)...
 -2*ExplambdaDeltaCubed)*Hk'*Hk;
 end
 end
 startInd=size(HkAll,2)*(c-1)+1; endInd = size(HkAll,2)*c;
 IGammaComp(startInd:endInd,startInd:endInd) = -sum(HessianTerm,3);
 end

 end
 end
 
 
 
 if(PPEM_Constraints.EstimateA==1)
 n1=size(IAComp,1); 
 else
 n1=0;
 end
 n2=size(IQComp,1); 
 
 if(PPEM_Constraints.EstimatePx0==1)
 n3=size(ISComp,1); 
 else
 n3=0;
 end
 if(PPEM_Constraints.Estimatex0==1) 
 n4=size(Ix0Comp,1);
 else
 n4=0;
 end
 n5=size(IMuComp,1);
 n6=size(IBetaComp,1);
 if(numel(gammahat)==1)
 if(gammahat==0)
 n7=0;
 else
 % FIX (F2): a single nonzero history coefficient (one cell, one
 % window) left n7 unassigned ("Unrecognized function or
 % variable"); it is one parameter, as in the EM's own IC count.
 n7=1;
 end
 else
 n7=size(IGammaComp,1);
 end
 nTerms=n1+n2+n3+n4+n5+n6+n7;
 IComp = zeros(nTerms,nTerms);
 if(PPEM_Constraints.EstimateA==1)
 IComp(1:n1,1:n1)=IAComp;
 end
 offset=n1+1;
 IComp(offset:(n1+n2),offset:(n1+n2))=IQComp;
 offset=n1+n2+1;
 if(PPEM_Constraints.EstimatePx0==1);
 IComp(offset:(n1+n2+n3),offset:(n1+n2+n3))=ISComp;
 end
 offset=n1+n2+n3+1;
 if(PPEM_Constraints.Estimatex0==1)
 IComp(offset:(n1+n2+n3+n4),offset:(n1+n2+n3+n4))=Ix0Comp;
 end
 offset=n1+n2+n3+n4+1;
 IComp(offset:(n1+n2+n3+n4+n5),offset:(n1+n2+n3+n4+n5))=IMuComp;
 offset=n1+n2+n3+n4+n5+1;
 IComp(offset:(n1+n2+n3+n4+n5+n6),offset:(n1+n2+n3+n4+n5+n6))=IBetaComp;
 offset=n1+n2+n3+n4+n5+n6+1;
 IComp(offset:(n1+n2+n3+n4+n5+n6+n7),offset:(n1+n2+n3+n4+n5+n6+n7))=IGammaComp; 
 
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %Missing Information Matrix
 %Approximate cov(Sc(X;theta)Sc(X;theta)')
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
 Mc=PPEM_Constraints.mcIter;
 xKDraw = zeros(size(xKFinal,1),N,Mc);

 % Generate the Monte Carlo samples for the unobserved data
 for n=1:N
 % FIX (F9): draw via mcStateDraws (m + chol(W)'*z; was m + chol(W)*z,
 % whose covariance is chol(W)*chol(W)', not W, for non-diagonal W).
 xKDraw(:,n,:)=nstat.decoding.PointProcessEM.mcStateDraws(xKFinal(:,n),WKFinal(:,:,n),Mc);
 end

 if(PPEM_Constraints.EstimatePx0|| PPEM_Constraints.Estimatex0)
 % FIX (F9): draw via mcStateDraws (m + chol(W)'*z; was m + chol(W)*z,
 % whose covariance is chol(W)*chol(W)', not W, for non-diagonal W).
 x0Draw=nstat.decoding.PointProcessEM.mcStateDraws(x0hat,Px0hat,Mc);
 else
 x0Draw=repmat(x0hat, [1 Mc]);

 end

 IMc = zeros(nTerms,nTerms,Mc);
 % Emperically estimate the covariance of the score
 % FIX (#99): matlabpool was removed in R2017a; same defect class as PPLFP.m.
 ppPool = gcp('nocreate'); if isempty(ppPool), pools = 0; else, pools = ppPool.NumWorkers; end
 if(pools==0) % parallel toolbox is not enabled;
 for c=1:Mc
 x_K=xKDraw(:,:,c);
 x_0=x0Draw(:,c);

 Dx=size(x_K,1);
 Sxkm1xk = zeros(Dx,Dx);
 Sxkm1xkm1 = zeros(Dx,Dx);
 Sxkxk = zeros(Dx,Dx);

 for k=1:K
 if(k==1)
 Sxkm1xk = Sxkm1xk+x_0*x_K(:,k)';
 Sxkm1xkm1 = Sxkm1xkm1+x_0*x_0'; 
 else
 Sxkm1xk = Sxkm1xk+x_K(:,k-1)*x_K(:,k)';
 Sxkm1xkm1= Sxkm1xkm1+x_K(:,k-1)*x_K(:,k-1)';
 end
 Sxkxk = Sxkxk+x_K(:,k)*x_K(:,k)';
 
 end
 Sxkxk = 0.5*(Sxkxk+Sxkxk');
 sumXkTerms = Sxkxk-Ahat*Sxkm1xk-Sxkm1xk'*Ahat'+Ahat*Sxkm1xkm1*Ahat';
 Sxkxkm1 = Sxkm1xk';
 sumXkTerms=0.5*(sumXkTerms+sumXkTerms');
 if(PPEM_Constraints.EstimateA==1)
 ScorA=Qhat\(Sxkxkm1-Ahat*Sxkm1xkm1);
 if(PPEM_Constraints.AhatDiag==1)
 ScoreAMc=diag(ScorA);
 else
 ScoreAMc=reshape(ScorA',numel(Ahat),1);
 end
 else
 ScoreAMc=[];
 end

 
 if(PPEM_Constraints.QhatDiag)
 if(PPEM_Constraints.QhatIsotropic)
 ScoreQ =-.5*(K*Dx*Qhat(1,1)^(-1) - Qhat(1,1)^(-2)*trace(sumXkTerms));
 else
 ScoreQ =(-.5*(Qhat\(K*eye(size(Qhat)) - sumXkTerms/Qhat)));
 end
 ScoreQMc = diag(ScoreQ);
 else
 ScoreQ =-.5*(Qhat\(K*eye(size(Qhat)) - sumXkTerms/Qhat));
 ScoreQMc =reshape(ScoreQ',numel(ScoreQ),1);
 end

 if(PPEM_Constraints.Px0Isotropic==1)
 ScoreSMc=-.5*(Dx*Px0hat(1,1)^(-1) - Px0hat(1,1)^(-2)*trace((x_0-x0hat)*(x_0-x0hat)'));
 else
 ScorS =-.5*(Px0hat\(eye(size(Px0hat)) - (x_0-x0hat)*(x_0-x0hat)'/Px0hat));
 ScoreSMc = diag(ScorS);
 end

 Scorx0=(-Px0hat\(x_0-x0hat))+Ahat'/Qhat*(x_K(:,1)-Ahat*x_0);
 Scorex0Mc=reshape(Scorx0',numel(Scorx0),1);
 ScoreMuMc=zeros(numCells,1);
 ScoreBetaMc=[];
 ScoreGammaMc=[];
 % Cell Scores
 for nc=1:numCells
 if(strcmp(fitType,'poisson'))
 Hk = (HkAll(:,:,nc));
 nHist = size(Hk,2);
 if(numel(gammahat)==1)
 gammaC=gammahat;
 else 
 gammaC=gammahat(:,nc);
 end
 terms=muhat(nc)+betahat(:,nc)'*x_K+gammaC'*Hk';
 ld = exp(terms);
 ScoreMuMc(nc) = sum(dN(nc,:)-ld,2);
 ScoreBetaMc = [ScoreBetaMc; sum(repmat((dN(nc,:)-ld),[Dx 1]).*x_K,2)];
 ScoreGammaMc= [ScoreGammaMc;sum(repmat(dN(nc,:)-ld,[nHist 1]).*Hk',2)];
 elseif(strcmp(fitType,'binomial'))
 Hk = (HkAll(:,:,nc));
 nHist = size(Hk,2);
 if(numel(gammahat)==1)
 gammaC=gammahat;
 else 
 gammaC=gammahat(:,nc);
 end
 terms=muhat(nc)+betahat(:,nc)'*x_K+gammaC'*Hk';
 ld = exp(terms)./(1+exp(terms));
 ScoreMuMc(nc) = sum(dN(nc,:)-(dN(nc,:)+1).*ld+ld.^2,2);
 ScoreBetaMc = [ScoreBetaMc;sum(repmat(dN(nc,:).*(1-ld) - ld.*(1-ld),[Dx,1]).*x_K,2)];
 ScoreGammaMc= [ScoreGammaMc;sum(repmat(dN(nc,:)-(dN(nc,:)+1).*ld+ld.^2,[nHist 1]).*Hk',2)];
 end
 
 end
 ScoreVec = [ScoreAMc; ScoreQMc];
 if(PPEM_Constraints.EstimatePx0==1)
 ScoreVec = [ScoreVec; ScoreSMc]; 
 end
 if(PPEM_Constraints.Estimatex0==1)
 ScoreVec = [ScoreVec; Scorex0Mc];
 end
 ScoreVec = [ScoreVec; ScoreMuMc; ScoreBetaMc];
 if((numel(gammahat)==1 && gammahat~=0) || numel(gammahat)>1)
 ScoreVec=[ScoreVec;ScoreGammaMc];
 end
 
 IMc(:,:,c)=ScoreVec*ScoreVec'; 
 end
 else %Use the parallel toolbox
 for c=1:Mc
 x_K=xKDraw(:,:,c);
 x_0=x0Draw(:,c);

 Dx=size(x_K,1);
 Sxkm1xk = zeros(Dx,Dx);
 Sxkm1xkm1 = zeros(Dx,Dx);
 Sxkxk = zeros(Dx,Dx);

 for k=1:K
 if(k==1)
 Sxkm1xk = Sxkm1xk+x_0*x_K(:,k)';
 Sxkm1xkm1 = Sxkm1xkm1+x_0*x_0'; 
 else
 Sxkm1xk = Sxkm1xk+x_K(:,k-1)*x_K(:,k)';
 Sxkm1xkm1= Sxkm1xkm1+x_K(:,k-1)*x_K(:,k-1)';
 end
 Sxkxk = Sxkxk+x_K(:,k)*x_K(:,k)';
 
 end
 Sxkxk = 0.5*(Sxkxk+Sxkxk');
 sumXkTerms = Sxkxk-Ahat*Sxkm1xk-Sxkm1xk'*Ahat'+Ahat*Sxkm1xkm1*Ahat';
 Sxkxkm1 = Sxkm1xk';
 sumXkTerms=0.5*(sumXkTerms+sumXkTerms');
 ScorA=Qhat\(Sxkxkm1-Ahat*Sxkm1xkm1);
 if(PPEM_Constraints.EstimateA==1)
 ScorA=Qhat\(Sxkxkm1-Ahat*Sxkm1xkm1);
 if(PPEM_Constraints.AhatDiag==1)
 ScoreAMc=diag(ScorA);
 else
 ScoreAMc=reshape(ScorA',numel(Ahat),1);
 end
 else
 ScoreAMc=[];
 end

 
 if(PPEM_Constraints.QhatDiag)
 if(PPEM_Constraints.QhatIsotropic)
 ScoreQ =-.5*(K*Dx*Qhat(1,1)^(-1) - Qhat(1,1)^(-2)*trace(sumXkTerms));
 else
 ScoreQ =(-.5*(Qhat\(K*eye(size(Qhat)) - sumXkTerms/Qhat)));
 end
 ScoreQMc = diag(ScoreQ);
 else
 ScoreQ =-.5*(Qhat\(K*eye(size(Qhat)) - sumXkTerms/Qhat));
 ScoreQMc =reshape(ScoreQ',numel(ScoreQ),1);
 end

 if(PPEM_Constraints.Px0Isotropic==1)
 ScoreSMc=-.5*(Dx*Px0hat(1,1)^(-1) - Px0hat(1,1)^(-2)*trace((x_0-x0hat)*(x_0-x0hat)'));
 else
 ScorS =-.5*(Px0hat\(eye(size(Px0hat)) - (x_0-x0hat)*(x_0-x0hat)'/Px0hat));
 ScoreSMc = diag(ScorS);
 end

 Scorx0=(-Px0hat\(x_0-x0hat))+Ahat'/Qhat*(x_K(:,1)-Ahat*x_0);
 Scorex0Mc=reshape(Scorx0',numel(Scorx0),1);
 ScoreMuMc=zeros(numCells,1);
 ScoreBetaMc=[];
 ScoreGammaMc=[];
 % Cell Scores
 for nc=1:numCells
 if(strcmp(fitType,'poisson'))
 Hk = (HkAll(:,:,nc));
 nHist = size(Hk,2);
 if(numel(gammahat)==1)
 gammaC=gammahat;
 else 
 gammaC=gammahat(:,nc);
 end
 terms=muhat(nc)+betahat(:,nc)'*x_K+gammaC'*Hk';
 ld = exp(terms);
 ScoreMuMc(nc) = sum(dN(nc,:)-ld,2);
 ScoreBetaMc = [ScoreBetaMc; sum(repmat((dN(nc,:)-ld),[Dx 1]).*x_K,2)];
 ScoreGammaMc= [ScoreGammaMc;sum(repmat(dN(nc,:)-ld,[nHist 1]).*Hk',2)];
 elseif(strcmp(fitType,'binomial'))
 Hk = (HkAll(:,:,nc));
 nHist = size(Hk,2);
 if(numel(gammahat)==1)
 gammaC=gammahat;
 else 
 gammaC=gammahat(:,nc);
 end
 terms=muhat(nc)+betahat(:,nc)'*x_K+gammaC'*Hk';
 ld = exp(terms)./(1+exp(terms));
 ScoreMuMc(nc) = sum(dN(nc,:)-(dN(nc,:)+1).*ld+ld.^2,2);
 ScoreBetaMc = [ScoreBetaMc;sum(repmat(dN(nc,:).*(1-ld) - ld.*(1-ld),[Dx,1]).*x_K,2)];
 ScoreGammaMc= [ScoreGammaMc;sum(repmat(dN(nc,:)-(dN(nc,:)+1).*ld+ld.^2,[nHist 1]).*Hk',2)];
 end
 
 end
 ScoreVec = [ScoreAMc; ScoreQMc];
 if(PPEM_Constraints.EstimatePx0==1)
 ScoreVec = [ScoreVec; ScoreSMc]; 
 end
 if(PPEM_Constraints.Estimatex0==1)
 ScoreVec = [ScoreVec; Scorex0Mc];
 end
 ScoreVec = [ScoreVec; ScoreMuMc; ScoreBetaMc];
 if((numel(gammahat)==1 && gammahat~=0) || numel(gammahat)>1)
 ScoreVec=[ScoreVec;ScoreGammaMc];
 end
 
 IMc(:,:,c)=ScoreVec*ScoreVec'; 
 end

 end
 IMissing = 1/Mc*sum(IMc,3);
 IObs = IComp-IMissing; 
 % FIX (#136): an exactly singular IObs made eye/IObs Inf/NaN and
 % nearestSPD loop forever; see seObservedInfoInverse. Unchanged when
 % IObs has no zero pivot.
 seLabels = nstat.decoding.PointProcessEM.seTermLabels({ ...
 'A', n1, size(Ahat), 'square'; 'Q', n2, size(Qhat), 'square'; ...
 'Px0', n3, size(Px0hat), 'square'; 'x0', n4, size(x0hat), 'vector'; ...
 'mu', n5, size(muhat), 'vector'; 'beta', n6, size(betahat), 'cellmajor'; ...
 'gamma', n7, size(gammahat), 'cellmajor'});
 % nearestSPD projection now inside seObservedInfoInverse (unchanged when nonsingular)
 [invIObs, nonIdentifiable] = nstat.decoding.PointProcessEM.seObservedInfoInverse(IObs, seLabels, 'PP_ComputeParamStandardErrors');
 VarVec = (diag(invIObs));
 SEVec = sqrt(VarVec);
 SEVec(nonIdentifiable) = NaN; % FIX (#136): not identifiable -> SE (and p-value) NaN
 SEAterms = SEVec(1:n1);
 SEQterms = SEVec(n1+1:(n1+n2));
 SEPx0terms=SEVec(n1+n2+1:(n1+n2+n3));
 SEx0terms=SEVec(n1+n2+n3+1:(n1+n2+n3+n4));
 SEMuTerms = SEVec(n1+n2+n3+n4+1:(n1+n2+n3+n4+n5));
 SEBetaTerms = SEVec(n1+n2+n3+n4+n5+1:(n1+n2+n3+n4+n5+n6)); 
 SEGammaTerms = SEVec(n1+n2+n3+n4+n5+n6+1:(n1+n2+n3+n4+n5+n6+n7)); 
 if(PPEM_Constraints.EstimatePx0==1)
 SES = diag(SEPx0terms);
 end
 if(PPEM_Constraints.Estimatex0==1)
 SEx0=SEx0terms;
 end

 if(PPEM_Constraints.EstimateA==1)
 if(PPEM_Constraints.AhatDiag==1)
 SEA=diag(SEAterms);
 else
 SEA=reshape(SEAterms,size(Ahat,2),size(Ahat,1))';
 end
 end
 
 if(PPEM_Constraints.QhatDiag==1)
 SEQ=diag(SEQterms);
 else
 SEQ=reshape(SEQterms,size(Qhat,2),size(Qhat,1))'; 
 end
 if(PPEM_Constraints.EstimateA==1)
 SE.A = SEA;
 end
 SE.Q = SEQ;
 
 if(PPEM_Constraints.EstimatePx0==1)
 SE.Px0=SES;
 end
 if(PPEM_Constraints.Estimatex0==1)
 SE.x0=SEx0;
 end
 
 SEMu = SEMuTerms;
 % FIX: SEBetaTerms is ordered cell by cell (IBetaComp/ScoreBetaMc
 % blocks are dx entries per cell), i.e. column-major for a dx x C
 % matrix. reshape(...,C,dx)' scrambled the entries whenever dx>1
 % and C>1 (for dx == C it returned the transpose). Same for gamma.
 SEBeta=reshape(SEBetaTerms,size(betahat,1),size(betahat,2));

 SE.mu = SEMu;
 SE.beta = SEBeta;
 if((numel(gammahat)==1 && gammahat~=0) || numel(gammahat)>1)
 % FIX: cell-by-cell ordering -> reshape to numWindows x C (was
 % reshape(...,C,numWindows)', which scrambled the entries).
 SEGamma=reshape(SEGammaTerms,size(gammahat,1),size(gammahat,2));
 SE.gamma = SEGamma;
 end
 % Compute parameter p-values
 
 if(PPEM_Constraints.EstimateA==1)
 clear h p;
 if(PPEM_Constraints.AhatDiag==1)
 VecParams = diag(Ahat);
 VecSE = diag(SEA);
 for i=1:length(VecParams)
 [h(i) p(i)] = ztest(VecParams(i),0,VecSE(i));
 end
 pA = diag(p);
 else
 VecParams = reshape(Ahat,[numel(Ahat) 1]);
 VecSE = reshape(SEA, [numel(Ahat) 1]);
 for i=1:length(VecParams)
 [h(i) p(i)] = ztest(VecParams(i),0,VecSE(i));
 end 
 pA = reshape(p, [size(Ahat,1) size(Ahat,2)]);
 end
 end

 %Q matrix
 clear h p;
 if(PPEM_Constraints.QhatDiag==1)
 if(PPEM_Constraints.QhatIsotropic==1)
 VecParams = Qhat(1,1);
 VecSE = SEQ(1,1);
 [h p] = ztest(VecParams,0,VecSE);
 pQ = diag(p);
 else
 VecParams = diag(Qhat);
 VecSE = diag(SEQ);
 for i=1:length(VecParams)
 [h(i) p(i)] = ztest(VecParams(i),0,VecSE(i));
 end
 pQ = diag(p);
 end
 else
 VecParams = reshape(Qhat,[numel(Qhat) 1]);
 VecSE = reshape(SEQ, [numel(Qhat) 1]);
 for i=1:length(VecParams)
 [h(i) p(i)] = ztest(VecParams(i),0,VecSE(i));
 end 
 pQ = reshape(p, [size(Qhat,1) size(Qhat,2)]);
 end
 %Px0
 if(PPEM_Constraints.EstimatePx0==1)
 clear h p;
 if(PPEM_Constraints.Px0Isotropic==1)
 VecParams = Px0hat(1,1);
 VecSE = SES(1,1);
 [h p] = ztest(VecParams,0,VecSE);
 pPX0 = diag(p);
 else
 VecParams = diag(Px0hat);
 VecSE = diag(SES);
 for i=1:length(VecParams)
 [h(i) p(i)] = ztest(VecParams(i),0,VecSE(i));
 end
 pPX0 = diag(p);
 end
 end

 if(PPEM_Constraints.Estimatex0==1)
 clear h p;
 VecParams = x0hat;
 VecSE = SEx0;
 for i=1:length(VecParams)
 [h(i) p(i)] = ztest(VecParams(i),0,VecSE(i));
 end
 pX0 = p';
 end
 
 %Mu
 clear h p;
 VecParams = muhat;
 VecSE = SEMu;
 for i=1:length(VecParams)
 [h(i) p(i)] = ztest(VecParams(i),0,VecSE(i));
 end
 pMu = p';
 
 %Beta
 clear h p;
 VecParams = reshape(betahat,[numel(betahat),1]);
 VecSE = reshape(SEBeta, [numel(SEBeta),1]);
 for i=1:length(VecParams)
 [h(i) p(i)] = ztest(VecParams(i),0,VecSE(i));
 end 
 pBeta = reshape(p, [size(betahat,1) size(betahat,2)]);
 
 %Gamma
 clear h p;
 if((numel(gammahat)==1 && gammahat~=0) || numel(gammahat)>1)
 VecParams = reshape(gammahat,[numel(gammahat),1]);
 VecSE = reshape(SEGamma, [numel(gammahat),1]);
 for i=1:length(VecParams)
 [h(i) p(i)] = ztest(VecParams(i),0,VecSE(i));
 end 
 pGamma = reshape(p, [size(gammahat,1) size(gammahat,2)]);
 end
 if(PPEM_Constraints.EstimateA==1)
 Pvals.A = pA;
 end
 Pvals.Q = pQ;
 
 if(PPEM_Constraints.EstimatePx0==1)
 Pvals.Px0 = pPX0;
 end
 if(PPEM_Constraints.Estimatex0==1)
 Pvals.x0 = pX0;
 end
 Pvals.mu = pMu;
 Pvals.beta = pBeta;
 
 if(numel(gammahat)==1)
 if(gammahat~=0)
 Pvals.gamma = pGamma;
 end
 else
 Pvals.gamma = pGamma;
 end

 end
 function [xKFinal,WKFinal,Ahat, Qhat, muhat, betahat, gammahat, x0hat, Px0hat, IC, SE, Pvals,nIter]=PP_EM(dN, Ahat0, Qhat0, mu, beta, fitType,delta, gamma, windowTimes, x0, Px0,PPEM_Constraints,MstepMethod)
 %PP_EM EM for a linear-Gaussian state observed through point processes.
 % [xKFinal,WKFinal,Ahat,Qhat,muhat,betahat,gammahat,x0hat,Px0hat,IC,SE,Pvals,nIter]
 % = PP_EM(dN, Ahat0, Qhat0, mu, beta, fitType, delta, gamma,
 % windowTimes, x0, Px0, PPEM_Constraints, MstepMethod)
 %
 % Defaults: fitType 'poisson', delta 0.001 s, no history (gamma=[] or
 % 0, windowTimes=[]), x0 = 0, Px0 = 1e-9*I,
 % PPEM_Constraints = PP_EMCreateConstraints() (x0/Px0 not estimated),
 % MstepMethod = 'NewtonRaphson'.
 %
 % MstepMethod default changed from 'GLM' to 'NewtonRaphson' (fix/pp-em
 % round 2). The NewtonRaphson M-step maximises the expected
 % complete-data log-likelihood by Monte Carlo over the smoothed state
 % posterior (a proper EM step). The 'GLM' M-step is a plug-in
 % approximation: it regresses dN on the smoothed MEANS x_K and
 % ignores W_K; because the means have shrunk variance it inflates
 % beta, the next E-step can diverge, and EM stops early. 'GLM' is
 % still available by passing it explicitly.
 %
 % SE, Pvals (and nIter, which follows them) are computed only when
 % more than 10 outputs are requested.
 %
 % Note (G4): EM runs on an internally whitened state x_s = Tq*x,
 % Tq = inv(chol(Qhat0,'lower')). The "logll:" value printed at each
 % iteration is the expected complete-data log-likelihood of that
 % SCALED system; IC.llcomp is the same quantity on the ORIGINAL scale
 % (the best printed value + (K+1)*log|det Tq|, K = number of time
 % bins), and IC.llobs / AIC / AICc / BIC are on the original scale too.
 numStates = size(Ahat0,1);
 if(nargin<13 || isempty(MstepMethod))
 MstepMethod='NewtonRaphson'; % FIX: default was 'GLM' (see help)
 end
 if(nargin<12 || isempty(PPEM_Constraints))
 PPEM_Constraints = nstat.decoding.PointProcessEM.PP_EMCreateConstraints;
 end
 if(nargin<11 || isempty(Px0))
 Px0=10e-10*eye(numStates,numStates);
 end
 if(nargin<10 || isempty(x0))
 x0=zeros(numStates,1);
 end
 
 if(nargin<9 || isempty(windowTimes))
 % FIX: mirror PPLFP_EM FIX (#98) -- a scalar gamma==0 means "no
 % history", same as isempty(gamma). The previous guard only checked
 % isempty(), so gamma=0 + windowTimes=[] inferred 2 history windows
 % from length(scalar)+1 and built a (N, 2, numCells) HkAll that the
 % scalar-gamma broadcast in PPDecode_updateLinear cannot multiply.
 if(nargin<8 || isempty(gamma) || (isscalar(gamma) && gamma == 0))
 windowTimes =[];
 else
 % FIX: one default history window per history coefficient. The
 % old rule 0:delta:(length(gamma)+1)*delta has length(gamma)+2
 % edges, i.e. length(gamma)+1 windows for length(gamma)
 % coefficients, so every default-window call failed with
 % MATLAB:innerdim (and length() of a numWindows x numCells
 % matrix is max(numWindows,numCells)). gamma is
 % numWindows x numCells (or a shared numWindows x 1 column; a
 % scalar is one shared window); a row vector whose length is not
 % the number of cells is the shared coefficient list, so it is
 % made a column. Edges: 0:delta:numWindows*delta (numWindows+1
 % edges; window w = (w-1, w] bins before the current bin).
 if(isrow(gamma) && numel(gamma)~=size(dN,1))
 gamma = gamma(:);
 end
 if(isempty(delta))
 deltaW = .001;
 else
 deltaW = delta;
 end
 windowTimes = 0:deltaW:size(gamma,1)*deltaW;
 end
 end
 if(nargin<8)
 gamma=[];
 end
 if(nargin<7 || isempty(delta))
 delta =.001;
 end
 if(nargin<6)
 fitType = 'poisson';
 end
 
 % FIX: a shared history-coefficient column (numWindows x 1,
 % incl. a scalar for one window) applies to every cell; expand it to
 % numWindows x numCells (gamma(w,c) = gamma_shared(w)) as
 % PPAF.PPDecodeFilterLinear does. The E-step, the M-step
 % (gammahat(:,c)) and the SEs all index gamma per cell, so a shared
 % column failed with MATLAB:innerdim / index errors.
 % An all-zero gamma is left as passed: gamma = 0 means "no history
 % coefficients" downstream (M-step `gammahat==0`, the IC parameter
 % count and the SE gamma block test numel(gammahat)), so expanding
 % it would change those paths.
 if(~isempty(windowTimes) && ~isempty(gamma) && size(gamma,2)==1 ...
 && size(dN,1)>1 && size(gamma,1)==numel(windowTimes)-1 ...
 && any(gamma(:)~=0))
 gamma = repmat(gamma,1,size(dN,1));
 end
 minTime=0;
 maxTime=(size(dN,2)-1)*delta;
 K=size(dN,1);
 if(~isempty(windowTimes))
 histObj = History(windowTimes,minTime,maxTime);
 for k=1:K
 % FIX: build the spike train on the delta time base (binwidth =
 % delta). The default binwidth is 1 ms, so for delta ~= 0.001
 % computeHistory returned a 1 kHz history matrix (2N-1 rows for
 % delta = 2 ms) that PP_EStep then indexed as if it were on the
 % delta grid. Identical object for delta = 0.001 (the default).
 nst{k} = nspikeTrain( (find(dN(k,:)==1)-1)*delta, '', delta);
 nst{k}.setMinTime(minTime);
 nst{k}.setMaxTime(maxTime);
% HkAll{k} = histObj.computeHistory(nst{k}).dataToMatrix;
 HkAll(:,:,k) = histObj.computeHistory(nst{k}).dataToMatrix;
 end
 else
 % FIX: same defect as PPLFP_EM FIX (#98). The original
 % `for k=1:K, HkAll(:,:,k) = 0; end` loop sized HkAll as
 % (1, 1, numCells). PP_EStep permutes it [2 3 1] to
 % (1, numCells, 1) -- a single time slice -- so
 % PPAF.PPDecode_updateLinear's HkAll(:,:,time_index) went out of
 % bounds at time_index=2 ("Index in position 3 exceeds array
 % bounds") and PP_EM could never run without history. Size HkAll
 % like the with-history branch, (numTimeSteps, 1, numCells), the
 % same layout PPAF.PPDecodeFilterLinear builds for its no-history
 % case. gamma=0 still zeroes the history contribution.
 HkAll = zeros(size(dN,2), 1, K);
 gamma=0;
 end

 % tol = 1e-3; %absolute change;
 tolAbs = nstat.Defaults.EM_TolAbs;
 tolRel = nstat.Defaults.EM_TolRel;
 llTol = nstat.Defaults.EM_LogLTol;
 cnt=1;

 maxIter = 100;

 
 A0 = Ahat0;
 Q0 = Qhat0;
 
 Ahat{1} = A0;
 Qhat{1} = Q0;
 x0hat{1} = x0;
 Px0hat{1} = Px0;
 muhat{1} = mu;
 betahat{1} = beta;
 gammahat{1} = gamma;
 numToKeep=10;
 scaledSystem=1;
 
 if(scaledSystem==1)
 % FIX (G1): whiten with the LOWER Cholesky factor. Tq = inv(L),
 % L = chol(Q0,'lower') (Q0 = L*L'), gives Tq*Q0*Tq' = I. The upper
 % factor R (Q0 = R'*R) gave Tq*Q0*Tq' = inv(R)*R'*R*inv(R)' ~= I for
 % a non-diagonal Q0, so the default QhatDiag=1 M-step was applied to a
 % scaled Q that the starting point did not satisfy: the first M-step
 % lowered the likelihood and EM returned the initial parameters (e.g.
 % Q0 = [.01 .006; .006 .02]: logll -1332.92 -> -1345.34, stop). For a
 % diagonal Q0, L = R' = R: unchanged. Any invertible Tq is a valid
 % change of variables, and |det L| = |det R|, so F8's (Tq\S)/Tq' and
 % F10's log|det Tq| Jacobian are unaffected.
 Tq = eye(size(Qhat{1}))/(chol(Qhat{1},'lower'));
 Ahat{1}= Tq*Ahat{1}/Tq;
 Qhat{1}= Tq*Qhat{1}*Tq';
 x0hat{1} = Tq*x0;
 Px0hat{1} = Tq*Px0*Tq';
 betahat{1}=(betahat{1}'/Tq)';
 end

 cnt=1;
 dLikelihood(1)=inf;
% x0hat = x0;
 negLL=0;
 IkedaAcc=PPEM_Constraints.EnableIkeda;
 %Forward EM
 stoppingCriteria =0;
% logllNew= -inf;

 disp(' Point-Process Observation EM Algorithm '); 
 while(stoppingCriteria~=1 && cnt<=maxIter)
 storeInd = mod(cnt-1,numToKeep)+1; %make zero-based then mod, then add 1
 storeIndP1= mod(cnt,numToKeep)+1;
 storeIndM1= mod(cnt-2,numToKeep)+1;
 disp('--------------------------------------------------------------------------------------------------------');
 disp(['Iteration #' num2str(cnt)]);
 disp('--------------------------------------------------------------------------------------------------------');
 

 [x_K{storeInd},W_K{storeInd},ll(cnt),ExpectationSums{storeInd}]=...
 nstat.decoding.PointProcessEM.PP_EStep(Ahat{storeInd},Qhat{storeInd},dN, muhat{storeInd}, betahat{storeInd},fitType,gammahat{storeInd},HkAll, x0hat{storeInd}, Px0hat{storeInd});

 % FIX: stop before the M-step when the E-step log-likelihood is
 % not a finite real number. A degenerate iterate (e.g. Px0hat
 % collapsing to 0 under EstimatePx0=1, or a diverged filter)
 % gives logll = +/-Inf, NaN, or a complex value (log of a
 % non-positive determinant) with NaN/non-PD smoothed states; the
 % old loop fed those into PP_MStep, which then crashed (chol in
 % the NewtonRaphson MC draws, an undefined `A` inside Analysis'
 % bnlrCG) or, because NaN comparisons are false, slipped past the
 % likelihood stopping rule. The best valid iterate is returned
 % below, exactly as for the existing "likelihood decreased" stop.
 if(~isfinite(ll(cnt)) || imag(ll(cnt))~=0)
 display([' EM stopped at iteration# ' num2str(cnt) ' b/c the E-step log-likelihood was not a finite real number (' num2str(ll(cnt)) ')']);
 negLL=1;
 break;
 end

 [Ahat{storeIndP1}, Qhat{storeIndP1}, muhat{storeIndP1}, betahat{storeIndP1}, gammahat{storeIndP1},x0hat{storeIndP1},Px0hat{storeIndP1}]...
 = nstat.decoding.PointProcessEM.PP_MStep(dN,x_K{storeInd},W_K{storeInd},x0hat{storeInd}, Px0hat{storeInd}, ExpectationSums{storeInd}, fitType,muhat{storeInd},betahat{storeInd}, gammahat{storeInd},windowTimes,HkAll,PPEM_Constraints,MstepMethod,delta);
 
 if(IkedaAcc==1)
 disp(['****Ikeda Acceleration Step****']);
 
 if(gammahat{storeIndP1}==0)% No history effect
 dataMat = [ones(size(dN,2),1) x_K{storeInd}']; % design matrix: X 
 coeffsMat = [muhat{storeIndP1} betahat{storeIndP1}']; % coefficient vector: beta
 minTime=0;
 maxTime=(size(dN,2)-1)*delta;
 time=minTime:delta:maxTime;
 clear nstNew;
 for cc=1:length(muhat{storeIndP1})
 tempData = exp(dataMat*coeffsMat(cc,:)');

 if(strcmp(fitType,'poisson'))
 lambdaData = tempData;
 else
 lambdaData = tempData./(1+tempData); % Conditional Intensity Function for ith cell
 end
 lambda{cc}=Covariate(time,lambdaData./delta,...
 '\Lambda(t)','time','s','spikes/sec',...
 {strcat('\lambda_{',num2str(cc),'}')},{{' ''b'' '}});
 lambda{cc}=lambda{cc}.resample(1/delta);

 % generate one realization for each cell
 tempSpikeColl{cc} = CIF.simulateCIFByThinningFromLambda(lambda{cc},1); 
 nstNew{cc} = tempSpikeColl{cc}.getNST(1); % grab the realization
 nstNew{cc}.setName(num2str(cc)); % give each cell a unique name
% subplot(4,3,[8 11]);
% h2=lambda{cc}.plot([],{{' ''k'', ''LineWidth'',.5'}}); 
% legend off; hold all; % Plot the CIF

 end
 
 spikeColl = nstColl(nstNew); % Create a neural spike train collection
 else
 % FIX: the with-history branch of Ikeda acceleration was never
 % implemented. The previous code had a bare `time;` here which
 % evaluated `time` and silently discarded the result, leaving
 % `spikeColl` either undefined (error on line below) or stale
 % from outside this block. Better to fail loud than silently
 % decode against the wrong data. Surfaced by checkcode VUNUS
 % finding 2026-06-22.
 error('nstat:decoding:PointProcessEM:IkedaHistNotImplemented', ...
     ['Ikeda acceleration with non-zero history coefficients is ' ...
      'not implemented (gammahat ~= 0 branch). Either disable ' ...
      'IkedaAcc or restructure to handle history.']);
 end
 
 dNNew=spikeColl.dataToMatrix';
 dNNew(dNNew>1)=1; % more than one spike per bin will be treated as one spike. In
 % general we should pick delta small enough so that there is
 % only one spike per bin
 
 
% [x_K,W_K,logll,ExpectationSums]=PP_EStep(A,Q,dN, mu, beta,fitType,gamma,HkAll, x0, Px0)
 [x_KNew,W_KNew,logllNew,ExpectationSumsNew]=...
 nstat.decoding.PointProcessEM.PP_EStep(Ahat{storeInd},Qhat{storeInd},dNNew, muhat{storeInd}, betahat{storeInd},fitType,gammahat{storeInd},HkAll, x0, Px0);

 [AhatNew, QhatNew, muhatNew, betahatNew, gammahatNew,x0new,Px0new]...
 = nstat.decoding.PointProcessEM.PP_MStep(dNNew,x_KNew,W_KNew, x0hat{storeInd}, Px0hat{storeInd}, ExpectationSumsNew, fitType,muhat{storeInd},betahat{storeInd}, gammahat{storeInd},windowTimes,HkAll,PPEM_Constraints,MstepMethod,delta);
 
 Ahat{storeIndP1} = 2*Ahat{storeIndP1}-AhatNew;
 Qhat{storeIndP1} = 2*Qhat{storeIndP1}-QhatNew;
 Qhat{storeIndP1} = (Qhat{storeIndP1}+Qhat{storeIndP1}')/2;
 muhat{storeIndP1}= 2*muhat{storeIndP1}-muhatNew;
 betahat{storeIndP1} = 2*betahat{storeIndP1}-betahatNew;
 gammahat{storeIndP1}= 2*gammahat{storeIndP1}-gammahatNew;
% x0hat{storeIndP1} = 2*x0hat{storeIndP1} - x0new;
% Px0hat{storeIndP1} = 2*Px0hat{storeIndP1}- Px0new;
% [V,D] = eig(Px0hat{storeIndP1});
% D(D<0)=1e-9;
% Px0hat{storeIndP1} = V*D*V';
% Px0hat{storeIndP1} = (Px0hat{storeIndP1}+Px0hat{storeIndP1}')/2;
 
 
 end
 if(PPEM_Constraints.EstimateA==0)
 Ahat{storeIndP1}=Ahat{storeInd};
 end
 if(cnt==1)
 dLikelihood(cnt+1)=inf;
 else
 dLikelihood(cnt+1)=(ll(cnt)-ll(cnt-1));%./abs(ll(cnt-1));
 end
 if(cnt==1)
 QhatInit = Qhat{1};
 xKInit = x_K{1};
 end
 %Plot the progress
% if(mod(cnt,2)==0)
 if(cnt==1)
 scrsz = get(0,'ScreenSize');
 h=figure('OuterPosition',[scrsz(3)*.01 scrsz(4)*.04 scrsz(3)*.98 scrsz(4)*.95]);
 end
 figure(h);
 time = linspace(minTime,maxTime,size(x_K{storeInd},2));
 subplot(2,4,[1 2 5 6]); plot(1:cnt,ll,'k','Linewidth', 2); hy=ylabel('Log Likelihood'); hx=xlabel('Iteration'); axis auto;
 set([hx, hy],'FontName', 'Arial','FontSize',12,'FontWeight','bold');
 subplot(2,4,3:4); hNew=plot(time, x_K{storeInd}','Linewidth', 2); hy=ylabel('States'); hx=xlabel('time [s]');
 set([hx, hy],'FontName', 'Arial','FontSize',12,'FontWeight','bold'); 
 hold on; hOrig=plot(time, xKInit','--','Linewidth', 2); 
 legend([hOrig(1) hNew(1)],'Initial','Current');
 
 
 subplot(2,4,7:8); hNew=plot(diag(Qhat{storeInd}),'o','Linewidth', 2); hy=ylabel('Q'); hx=xlabel('Diagonal Entry');
 set(gca, 'XTick', 1:1:length(diag(Qhat{storeInd})));
 set([hx, hy],'FontName', 'Arial','FontSize',12,'FontWeight','bold');
 hold on; hOrig=plot(diag(QhatInit),'r.','Linewidth', 2);
 legend([hOrig(1) hNew(1)],'Initial','Current');
 drawnow;
 hold off;

 if(cnt==1)
 dMax=inf;
 else
 dQvals = max(max(abs(sqrt(Qhat{storeInd})-sqrt(Qhat{storeIndM1}))));
 dAvals = max(max(abs((Ahat{storeInd})-(Ahat{storeIndM1}))));
 dMuvals = max(abs((muhat{storeInd})-(muhat{storeIndM1})));
 dBetavals = max(max(abs((betahat{storeInd})-(betahat{storeIndM1}))));
 dGammavals = max(max(abs((gammahat{storeInd})-(gammahat{storeIndM1}))));
 dMax = max([dQvals,dAvals,dMuvals,dBetavals,dGammavals]);
 end

 if(cnt==1)
 disp(['Max Parameter Change: N/A']);
 else
 disp(['Max Parameter Change: ' num2str(dMax)]);
 end
 
 cnt=(cnt+1);
 if(dMax<tolAbs)
 stoppingCriteria=1;
 display([' EM converged at iteration# ' num2str(cnt-1) ' b/c change in params was within criteria']);
 negLL=0;
 end
 
 if(abs(dLikelihood(cnt))<llTol || dLikelihood(cnt)<0)
 stoppingCriteria=1;
 display([' EM stopped at iteration# ' num2str(cnt-1) ' b/c change in likelihood was negative']);
 negLL=1;
 end
 

 end
 disp('--------------------------------------------------------------------------------------------------------');

 % FIX: choose the best FINITE, REAL log-likelihood. max() skips
 % NaN but not +Inf (a degenerate Px0hat -> 0 iterate), and on a
 % complex array it compares magnitudes, so a degenerate iterate
 % could be returned as the "best" one. Identical to the old
 % selection whenever every ll is a finite real number.
 llSel = ll; llSel(~isfinite(llSel) | imag(llSel)~=0) = NaN;
 llSel = real(llSel);
 maxLLIndex = find(llSel == max(llSel),1,'first');
 maxLLIndMod = mod(maxLLIndex-1,numToKeep)+1;
 if(maxLLIndex==1)
% maxLLIndex=cnt-1;
 maxLLIndex =1;
 maxLLIndMod = 1;
 elseif(isempty(maxLLIndex))
 maxLLIndex = 1; 
 maxLLIndMod = 1;
% else
% maxLLIndMod = mod(maxLLIndex,numToKeep); 
 
 end
 nIter = cnt-1; 
% maxLLIndMod
 
 xKFinal = x_K{maxLLIndMod};
 WKFinal = W_K{maxLLIndMod};
 Ahat = Ahat{maxLLIndMod};
 Qhat = Qhat{maxLLIndMod};
 muhat= muhat{maxLLIndMod};
 betahat = betahat{maxLLIndMod};
 gammahat = gammahat{maxLLIndMod};
 x0hat =x0hat{maxLLIndMod};
 Px0hat=Px0hat{maxLLIndMod};
 
 if(scaledSystem==1)
 % FIX (G1): same lower factor as at the start (see there).
 Tq = eye(size(Qhat))/(chol(Q0,'lower'));
 Ahat=Tq\Ahat*Tq;
 Qhat=(Tq\Qhat)/Tq';
 xKFinal = Tq\xKFinal;
 x0hat = Tq\x0hat;
 Px0hat= (Tq\Px0hat)/(Tq');
 tempWK =zeros(size(WKFinal));
 for kk=1:size(WKFinal,3)
 tempWK(:,:,kk)=(Tq\WKFinal(:,:,kk))/Tq';
 end
 WKFinal = tempWK;
 betahat=(betahat'*Tq)';
 end
 llFinal=ll(end);
 ll = ll(maxLLIndex);
 ExpectationSumsFinal = ExpectationSums{maxLLIndMod};
 if(nargout>10)
 % FIX (F8): the expectation sums come from the E-step of the
 % internally SCALED system (x_s = Tq*x, Tq = inv(chol(Q0,'lower'))), while
 % xKFinal, WKFinal, Ahat, Qhat, x0hat, Px0hat and betahat passed
 % here are back on the ORIGINAL scale. PP_ComputeParamStandardErrors
 % reads ES.Sxkm1xkm1 (A information Q^-1 (x) Sxkm1xkm1) with the
 % unscaled Qhat, so the SEs mixed scales whenever Q0 ~= I (SE.A
 % off by the Tq factor). Transform the sum it reads back to the
 % original scale: Sxkm1xkm1 = Tq \ Sxkm1xkm1_s / Tq'.
 ESforSE = ExpectationSumsFinal;
 if(scaledSystem==1)
 ESforSE.Sxkm1xkm1 = (Tq\ESforSE.Sxkm1xkm1)/Tq';
 end
 [SE, Pvals]=nstat.decoding.PointProcessEM.PP_ComputeParamStandardErrors(dN,...
 xKFinal, WKFinal, Ahat, Qhat, x0hat, Px0hat, ESforSE,...
 fitType, muhat, betahat, gammahat, windowTimes, HkAll,...
 PPEM_Constraints);
 end

 %Compute number of parameters
 if(PPEM_Constraints.EstimateA==1 && PPEM_Constraints.AhatDiag==1)
 n1=size(Ahat,1); 
 elseif(PPEM_Constraints.EstimateA==1 && PPEM_Constraints.AhatDiag==0)
 n1=numel(Ahat);
 else 
 n1=0;
 end
 if(PPEM_Constraints.QhatDiag==1 && PPEM_Constraints.QhatIsotropic==1)
 n2=1;
 elseif(PPEM_Constraints.QhatDiag==1 && PPEM_Constraints.QhatIsotropic==0)
 n2=size(Qhat,1);
 else
 n2=numel(Qhat);
 end

 if(PPEM_Constraints.EstimatePx0==1 && PPEM_Constraints.Px0Isotropic==1)
 n3=1;
 elseif(PPEM_Constraints.EstimatePx0==1 && PPEM_Constraints.Px0Isotropic==0)
 n3=size(Px0hat,1);
 else
 n3=0;
 end

 if(PPEM_Constraints.Estimatex0==1) 
 n4=size(x0hat,1);
 else
 n4=0;
 end

 n5=size(muhat,1);
 n6=numel(betahat);
 if(numel(gammahat)==1)
 if(gammahat==0)
 n7=0;
 else
 n7=1;
 end
 else
 n7=numel(gammahat);
 end
 nTerms=n1+n2+n3+n4+n5+n6+n7;
 
 K = size(xKFinal,2); 
 Dx = size(Ahat,2);
 sumXkTerms = ExpectationSums{maxLLIndMod}.sumXkTerms;
 % FIX (F10): ll (the best E-step's expected complete-data
 % log-likelihood) and sumXkTerms come from the internally SCALED
 % system x_s = Tq*x (Tq = inv(chol(Q0,'lower'))), while Qhat and Px0hat
 % have been mapped back to the original scale, so llobs (= ll minus
 % the expected state log-density) mixed scales and AIC/BIC depended
 % on the units of x (llobs 18680 -> 1342 when the state was rescaled
 % by 3). Map both to the original scale first:
 % S = Tq \ S_s / Tq', and each of the K+1 state log-densities
 % (x_0 .. x_K) gains log|det Tq|, so ll = ll_s + (K+1)*log|det Tq|.
 % llobs is then E[log p(dN | x)] (the E-step's sumPPll), invariant
 % to the state's units, and IC.llcomp is the expected complete-data
 % log-likelihood on the original scale (what PP_EStep returns when
 % run in the original coordinates at the returned estimates).
 llcomp = ll;
 if(scaledSystem==1)
 sumXkTerms = (Tq\sumXkTerms)/Tq';
 llcomp = ll + (K+1)*log(abs(det(Tq)));
 end
 llobs = llcomp + Dx*K/2*log(2*pi)+K/2*log(det(Qhat))...
 + 1/2*trace(Qhat\sumXkTerms)...
 + Dx/2*log(2*pi)+1/2*log(det(Px0hat))...
 + 1/2*Dx;
 AIC = 2*nTerms - 2*llobs;
 AICc= AIC+ 2*nTerms*(nTerms+1)/(K-nTerms-1);
 BIC = -2*llobs+nTerms*log(K);
 IC.AIC = AIC;
 IC.AICc= AICc;
 IC.BIC = BIC;
 IC.llobs = llobs;
 IC.llcomp=llcomp;
 
 
 end
 % function [xKFinal,WKFinal,Ahat, Qhat, muhat, betahat, gammahat, x0hat, Px0hat, logll,nIter,negLL]=PP_EM(dN, Ahat0, Qhat0, mu, beta, fitType,delta, gamma, windowTimes, x0, Px0,MstepMethod)
% numStates = size(Ahat0,1);
% if(nargin<12 || isempty(MstepMethod))
% MstepMethod='GLM'; %or NewtonRaphson 
% end
% if(nargin<11 || isempty(Px0))
% Px0=10e-10*eye(numStates,numStates);
% end
% if(nargin<10 || isempty(x0))
% x0=zeros(numStates,1);
% end
% 
% if(nargin<9 || isempty(windowTimes))
% if(isempty(gamma)||gamma==0)
% windowTimes =[];
% else
% % numWindows =length(gamma0)+1; 
% windowTimes = 0:delta:(length(gamma)+1)*delta;
% end
% end
% if(nargin<8)
% gamma=[];
% end
% if(nargin<11 || isempty(delta))
% delta =.001;
% end
% if(nargin<6)
% fitType = 'poisson';
% end
% 
% minTime=0;
% maxTime=(size(dN,2)-1)*delta;
% K=size(dN,1);
% N=size(dN,2);
% if(~isempty(windowTimes))
% histObj = History(windowTimes,minTime,maxTime);
% for k=1:K
% nst{k} = nspikeTrain( (find(dN(k,:)==1)-1)*delta);
% nst{k}.setMinTime(minTime);
% nst{k}.setMaxTime(maxTime);
% % HkAll{k} = histObj.computeHistory(nst{k}).dataToMatrix;
% HkAll(:,:,k) = histObj.computeHistory(nst{k}).dataToMatrix;
% end
% if(size(gamma,1)==K)
% gamma=gamma';
% end
% 
% else
% for k=1:K
% HkAll(:,:,k) = zeros(N,length(windowTimes)-1);
% end
% gamma=0;
% end
% 
% 
% 
% % tol = 1e-3; %absolute change;
% tolAbs = 1e-3;
% tolRel = 1e-3;
% llTol = 1e-3;
% cnt=1;
% 
% maxIter = 100;
% 
% 
% A0 = Ahat0;
% Q0 = Qhat0;
% 
% Ahat{1} = A0;
% Qhat{1} = Q0;
% x0hat{1} = x0;
% Px0hat{1} = Px0;
% muhat{1} = mu;
% betahat{1} = beta;
% gammahat{1} = gamma;
% numToKeep=10;
% scaledSystem=1;
% 
% if(scaledSystem==1)
% Tq = eye(size(Qhat{1}))/(chol(Qhat{1}));
% Ahat{1}= Tq*Ahat{1}/Tq;
% Qhat{1}= Tq*Qhat{1}*Tq';
% x0hat{1} = Tq*x0;
% Px0hat{1} = Tq*Px0*Tq';
% betahat{1}=(betahat{1}'/Tq)';
% end
% 
% cnt=1;
% dLikelihood(1)=inf;
% negLL=0;
% IkedaAcc=0;
% %Forward EM
% stoppingCriteria =0;
% 
% while(stoppingCriteria~=1 && cnt<=maxIter)
% storeInd = mod(cnt-1,numToKeep)+1; %make zero-based then mod, then add 1
% storeIndP1= mod(cnt,numToKeep)+1;
% storeIndM1= mod(cnt-2,numToKeep)+1;
% disp('---------------');
% disp(['Iteration #' num2str(cnt)]);
% disp('---------------');
% 
% 
% [x_K{storeInd},W_K{storeInd},logll(cnt),ExpectationSums{storeInd}]=...
% DecodingAlgorithms.PP_EStep(Ahat{storeInd},Qhat{storeInd},dN, muhat{storeInd}, betahat{storeInd},fitType,gammahat{storeInd},HkAll, x0hat{storeInd}, Px0hat{storeInd});
% 
% [Ahat{storeIndP1}, Qhat{storeIndP1}, muhat{storeIndP1}, betahat{storeIndP1}, gammahat{storeIndP1},x0hat{storeIndP1},Px0hat{storeIndP1}]...
% = DecodingAlgorithms.PP_MStep(dN,x_K{storeInd},W_K{storeInd},x0hat{storeInd},ExpectationSums{storeInd}, fitType,muhat{storeInd},betahat{storeInd}, gammahat{storeInd},windowTimes,HkAll,MstepMethod);
% 
% if(IkedaAcc==1)
% disp(['****Ikeda Acceleration Step****']);
% 
% if(gammahat{storeIndP1}==0)% No history effect
% dataMat = [ones(size(dN,2),1) x_K{storeInd}']; % design matrix: X 
% coeffsMat = [muhat{storeIndP1} betahat{storeIndP1}']; % coefficient vector: beta
% minTime=0;
% maxTime=(size(dN,2)-1)*delta;
% time=minTime:delta:maxTime;
% clear nstNew;
% for cc=1:length(muhat{storeIndP1})
% tempData = exp(dataMat*coeffsMat(cc,:)');
% 
% if(strcmp(fitType,'poisson'))
% lambdaData = tempData;
% else
% lambdaData = tempData./(1+tempData); % Conditional Intensity Function for ith cell
% end
% lambda{cc}=Covariate(time,lambdaData./delta,...
% '\Lambda(t)','time','s','spikes/sec',...
% {strcat('\lambda_{',num2str(cc),'}')},{{' ''b'' '}});
% lambda{cc}=lambda{cc}.resample(1/delta);
% 
% % generate one realization for each cell
% tempSpikeColl{cc} = CIF.simulateCIFByThinningFromLambda(lambda{cc},1); 
% nstNew{cc} = tempSpikeColl{cc}.getNST(1); % grab the realization
% nstNew{cc}.setName(num2str(cc)); % give each cell a unique name
% % subplot(4,3,[8 11]);
% % h2=lambda{cc}.plot([],{{' ''k'', ''LineWidth'',.5'}}); 
% % legend off; hold all; % Plot the CIF
% 
% end
% 
% spikeColl = nstColl(nstNew); % Create a neural spike train collection
% else
% time;
% end
% 
% dNNew=spikeColl.dataToMatrix';
% dNNew(dNNew>1)=1; % more than one spike per bin will be treated as one spike. In
% % general we should pick delta small enough so that there is
% % only one spike per bin
% 
% 
% % [x_K,W_K,logll,ExpectationSums]=PP_EStep(A,Q,dN, mu, beta,fitType,gamma,HkAll, x0, Px0)
% [x_KNew,W_KNew,logllNew,ExpectationSumsNew]=...
% DecodingAlgorithms.PP_EStep(Ahat{storeInd},Qhat{storeInd},dNNew, muhat{storeInd}, betahat{storeInd},fitType,gammahat{storeInd},HkAll, x0, Px0);
% 
% 
% [AhatNew, QhatNew, muhatNew, betahatNew, gammahatNew,x0new,Px0new]...
% = DecodingAlgorithms.PP_MStep(dNNew,x_KNew,W_KNew, x0hat{storeInd}, ExpectationSumsNew, fitType,muhat{storeInd},betahat{storeInd}, gammahat{storeInd},windowTimes,HkAll,MstepMethod);
% 
% Ahat{storeIndP1} = 2*Ahat{storeIndP1}-AhatNew;
% Qhat{storeIndP1} = 2*Qhat{storeIndP1}-QhatNew;
% Qhat{storeIndP1} = (Qhat{storeIndP1}+Qhat{storeIndP1}')/2;
% muhat{storeIndP1}= 2*muhat{storeIndP1}-muhatNew;
% betahat{storeIndP1} = 2*betahat{storeIndP1}-betahatNew;
% gammahat{storeIndP1}= 2*gammahat{storeIndP1}-gammahatNew;
% % x0hat{storeIndP1} = 2*x0hat{storeIndP1} - x0new;
% % Px0hat{storeIndP1} = 2*Px0hat{storeIndP1}- Px0new;
% % [V,D] = eig(Px0hat{storeIndP1});
% % D(D<0)=1e-9;
% % Px0hat{storeIndP1} = V*D*V';
% % Px0hat{storeIndP1} = (Px0hat{storeIndP1}+Px0hat{storeIndP1}')/2;
% 
% 
% end
% 
% if(cnt==1)
% dLikelihood(cnt+1)=inf;
% else
% dLikelihood(cnt+1)=(logll(cnt)-logll(cnt-1));%./abs(logll(cnt-1));
% end
% if(cnt==1)
% QhatInit = Qhat{1};
% xKInit = x_K{1};
% end
% %Plot the progress
% % if(mod(cnt,2)==0)
% if(cnt==1)
% scrsz = get(0,'ScreenSize');
% h=figure('OuterPosition',[scrsz(3)*.01 scrsz(4)*.04 scrsz(3)*.98 scrsz(4)*.95]);
% end
% figure(h);
% time = linspace(minTime,maxTime,size(x_K{storeInd},2));
% subplot(2,4,[1 2 5 6]); plot(1:cnt,logll,'k','Linewidth', 2); hy=ylabel('Log Likelihood'); hx=xlabel('Iteration'); axis auto;
% set([hx, hy],'FontName', 'Arial','FontSize',12,'FontWeight','bold');
% subplot(2,4,3:4); hNew=plot(time, x_K{storeInd}','Linewidth', 2); hy=ylabel('States'); hx=xlabel('time [s]');
% set([hx, hy],'FontName', 'Arial','FontSize',12,'FontWeight','bold'); 
% hold on; hOrig=plot(time, xKInit','--','Linewidth', 2); 
% legend([hOrig(1) hNew(1)],'Initial','Current');
% 
% 
% subplot(2,4,7:8); hNew=plot(diag(Qhat{storeInd}),'o','Linewidth', 2); hy=ylabel('Q'); hx=xlabel('Diagonal Entry');
% set(gca, 'XTick', 1:1:length(diag(Qhat{storeInd})));
% set([hx, hy],'FontName', 'Arial','FontSize',12,'FontWeight','bold');
% hold on; hOrig=plot(diag(QhatInit),'r.','Linewidth', 2);
% legend([hOrig(1) hNew(1)],'Initial','Current');
% drawnow;
% hold off;
% % end
% 
% if(cnt==1)
% dMax=inf;
% else
% dQvals = max(max(abs(sqrt(Qhat{storeInd})-sqrt(Qhat{storeIndM1}))));
% dAvals = max(max(abs((Ahat{storeInd})-(Ahat{storeIndM1}))));
% dMuvals = max(abs((muhat{storeInd})-(muhat{storeIndM1})));
% dBetavals = max(max(abs((betahat{storeInd})-(betahat{storeIndM1}))));
% dGammavals = max(max(abs((gammahat{storeInd})-(gammahat{storeIndM1}))));
% dMax = max([dQvals,dAvals,dMuvals,dBetavals,dGammavals]);
% end
% 
% % 
% % dQRel = max(abs(dQvals./sqrt(Qhat(:,storeIndM1))));
% % dGammaRel = max(abs(dGamma./gammahat(storeIndM1,:)));
% % dMaxRel = max([dQRel,dGammaRel]);
% 
% 
% cnt=(cnt+1);
% if(dMax<tolAbs)
% stoppingCriteria=1;
% display([' EM converged at iteration# ' num2str(cnt-1) ' b/c change in params was within criteria']);
% negLL=0;
% end
% 
% if(abs(dLikelihood(cnt))<llTol || dLikelihood(cnt)<0)
% stoppingCriteria=1;
% display([' EM stopped at iteration# ' num2str(cnt-1) ' b/c change in likelihood was negative']);
% negLL=1;
% end
% 
% 
% end
% 
% 
% 
% 
% maxLLIndex = find(logll == max(logll),1,'first');
% maxLLIndMod = mod(maxLLIndex-1,numToKeep)+1;
% if(maxLLIndex==1)
% % maxLLIndex=cnt-1;
% maxLLIndex =1;
% maxLLIndMod = 1;
% elseif(isempty(maxLLIndex))
% maxLLIndex = 1; 
% maxLLIndMod = 1;
% % else
% % maxLLIndMod = mod(maxLLIndex,numToKeep); 
% 
% end
% nIter = cnt-1; 
% % maxLLIndMod
% 
% xKFinal = x_K{maxLLIndMod};
% WKFinal = W_K{maxLLIndMod};
% Ahat = Ahat{maxLLIndMod};
% Qhat = Qhat{maxLLIndMod};
% muhat= muhat{maxLLIndMod};
% betahat = betahat{maxLLIndMod};
% gammahat = gammahat{maxLLIndMod};
% x0hat =x0hat{maxLLIndMod};
% Px0hat=Px0hat{maxLLIndMod};
% 
% if(scaledSystem==1)
% Tq = eye(size(Qhat))/(chol(Q0));
% Ahat=Tq\Ahat*Tq;
% Qhat=(Tq\Qhat)/Tq';
% xKFinal = Tq\xKFinal;
% x0hat = Tq\x0hat;
% Px0hat= (Tq\Px0hat)/(Tq');
% tempWK =zeros(size(WKFinal));
% for kk=1:size(WKFinal,3)
% tempWK(:,:,kk)=(Tq\WKFinal(:,:,kk))/Tq';
% end
% WKFinal = tempWK;
% betahat=(betahat'*Tq)';
% end
% 
% logll = logll(maxLLIndex);
% ExpectationSumsFinal = ExpectationSums{maxLLIndMod};
% K=size(dN,1);
% SumXkTermsFinal = diag(Qhat(:,:,end))*K;
% logllFinal=logll(end);
% McInfo=100;
% McCI = 3000;
% 
% % nIter = [];%[nIter1,nIter2,nIter3];
% 
% 
% K = size(dN,1); 
% Dx = size(Ahat,2);
% sumXkTerms = ExpectationSums{maxLLIndMod}.sumXkTerms;
% logllobs = logll + Dx*K/2*log(2*pi)+K/2*log(det(Qhat))+ 1/2*trace(pinv(Qhat)*sumXkTerms); 
% 
% % InfoMat = DecodingAlgorithms.estimateInfoMat_PPLFP(fitType,xKFinal, WKFinal,Ahat,Qhat,Chat, Rhat,alphahat, muhat, betahat,gammahat,dN,windowTimes, HkAll,delta,ExpectationSums{maxLLIndMod},McInfo);
% % 
% % 
% % fitResults = DecodingAlgorithms.prepareEMResults(fitType,neuronName,dN,HkAll,xKFinal,WKFinal,Qhat,gammahat,windowTimes,delta,InfoMat,logllobs);
% % [stimCIs, stimulus] = DecodingAlgorithms.ComputeStimulusCIs(fitType,xKFinal,WkuFinal,delta,McCI);
% % 
% 
% end
 function [x_K,W_K,logll,ExpectationSums]=PP_EStep(A,Q,dN, mu, beta,fitType,gamma,HkAll, x0, Px0)
 DEBUG = 0;
 [numCells,K] = size(dN); 
 Dx = size(A,2);
 
 x_p = zeros( size(A,2), K+1 );
 x_u = zeros( size(A,2), K );
 W_p = zeros( size(A,2),size(A,2), K+1 );
 W_u = zeros( size(A,2),size(A,2), K );
 x_p(:,1)= A(:,:)*x0;
 W_p(:,:,1)=A*Px0*A' + Q;
 HkPerm=permute(HkAll, [2 3 1]);
 for k=1:K
 [x_u(:,k), W_u(:,:,k)] = nstat.decoding.PPAF.PPDecode_updateLinear(x_p(:,k), W_p(:,:,k), dN,mu,beta,fitType,gamma,HkPerm,k,[]);
 [x_p(:,k+1), W_p(:,:,k+1)] = nstat.decoding.PPAF.PPDecode_predict(x_u(:,k), W_u(:,:,k), A(:,:,min(size(A,3),k)), Q(:,:,min(size(Q,3),k))); % FIX: added k index for time-varying Q support
 end
 
 [x_K, W_K,Lk] = nstat.decoding.KalmanFilter.kalman_smootherFromFiltered(A, x_p, W_p, x_u, W_u); 
 
 numStates = size(x_K,1);
 Wku=zeros(numStates,numStates,K,K);
 Tk = zeros(numStates,numStates,K-1);
 for k=1:K
 Wku(:,:,k,k)=W_K(:,:,k);
 end

 for u=K:-1:2
 for k=(u-1):-1:(u-1)
 Tk(:,:,k)=A;
% Dk(:,:,k)=W_u(:,:,k)*Tk(:,:,k)'*pinv(W_p(:,:,k)); %From deJong and MacKinnon 1988
 Dk(:,:,k)=W_u(:,:,k)*Tk(:,:,k)'/(W_p(:,:,k+1)); %From deJong and MacKinnon 1988
 Wku(:,:,k,u)=Dk(:,:,k)*Wku(:,:,k+1,u);
 Wku(:,:,u,k)=Wku(:,:,k,u)';
 end
 end
 
 %All terms
 Sxkm1xk = zeros(Dx,Dx);
 Sxkm1xkm1 = zeros(Dx,Dx);
 Sxkxk = zeros(Dx,Dx);
 for k=1:K
 if(k==1)
 Sxkm1xk = Sxkm1xk+Px0*A'/W_p(:,:,1)*Wku(:,:,1,1);
 Sxkm1xkm1 = Sxkm1xkm1+Px0+x0*x0'; 
 else
 Sxkm1xk = Sxkm1xk+Wku(:,:,k-1,k)+x_K(:,k-1)*x_K(:,k)';
 Sxkm1xkm1= Sxkm1xkm1+Wku(:,:,k-1,k-1)+x_K(:,k-1)*x_K(:,k-1)';
 end
 Sxkxk = Sxkxk+Wku(:,:,k,k)+x_K(:,k)*x_K(:,k)';

 end
 Sxkxk = 0.5*(Sxkxk+Sxkxk');
 sumXkTerms = Sxkxk-A*Sxkm1xk-Sxkm1xk'*A'+A*Sxkm1xkm1*A';
 Sxkxkm1 = Sxkm1xk';
 
 %Vectorize for loop over cells
 if(strcmp(fitType,'poisson'))
 sumPPll=0;
 Histtermperm = permute(HkAll,[2 3 1]);
 
 for k=1:K
% Hk=squeeze(HkAll(k,:,:)); 
 Hk= Histtermperm(:,:,k);
 % FIX: orient Hk as (numWindows x numCells) by checking its
 % COLUMNS. The slice of permute(HkAll,[2 3 1]) is already
 % numWindows x numCells; the old test `size(Hk,1)==numCells`
 % also fired when numWindows == numCells and transposed it, so
 % diag(gammaC'*Hk) paired gamma(w,c) with Hk(c,w) and logll was
 % wrong for square history (the filter, PPDecode_updateLinear,
 % already checks columns and was unaffected). Identical for
 % numWindows ~= numCells.
 if(size(Hk,2)~=numCells)
 Hk = Hk';
 end
 xk = x_K(:,k);
 if(numel(gamma)==1)
 gammaC=repmat(gamma,1,numCells);
 else 
 gammaC=gamma;
 end
 terms=mu+beta'*xk+diag(gammaC'*Hk);
 Wk = W_K(:,:,k);
 ld = exp(terms);
 bt = beta;
 ExplambdaDelta =ld+0.5*(ld.*diag((bt'*Wk*bt)));
 ExplogLD = terms;
 sumPPll=sumPPll+sum(dN(:,k).*ExplogLD - ExplambdaDelta);
 
 end
 
 %Vectorize over number of cells
 elseif(strcmp(fitType,'binomial'))
 sumPPll=0;
 Histtermperm = permute(HkAll,[2 3 1]);
 for k=1:K
% Hk=squeeze(HkAll(k,:,:)); 
 Hk= Histtermperm(:,:,k);
 % FIX: column-based orientation check; see the poisson branch.
 if(size(Hk,2)~=numCells)
 Hk = Hk';
 end
 xk = x_K(:,k);
 if(numel(gamma)==1)
 gammaC=repmat(gamma,1,numCells);
 else 
 gammaC=gamma;
 end
 terms=mu+beta'*xk+diag(gammaC'*Hk);
 Wk = W_K(:,:,k);
 ld = exp(terms)./(1+exp(terms));
 bt = beta; 
 ExplambdaDelta = ld+0.5*(ld.*(1-ld).*(1-2.*ld)).*diag((bt'*Wk*bt));
 ExplogLD = log(ld)+0.5*(-ld.*(1-ld)).*diag(bt'*Wk*bt);
 sumPPll=sumPPll+sum(dN(:,k).*ExplogLD - ExplambdaDelta); 
 
 end

 
 end

 logll = -Dx*K/2*log(2*pi)-K/2*log(det(Q))...
 - Dx/2*log(2*pi) -1/2*log(det(Px0))...
 +sumPPll - 1/2*trace((eye(size(Q))/Q)*sumXkTerms)...
 -Dx/2;
 string0 = ['logll: ' num2str(logll)];
 disp(string0);
 if(DEBUG==1)
 string1 = ['-K/2*log(det(Q)):' num2str(-K/2*log(det(Q)))];
 string12= ['Constants: ' num2str(-Dx*K/2*log(2*pi)- Dx/2*log(2*pi) -Dx/2 -1/2*log(det(Px0)))];
 string2 = ['SumPPll: ' num2str(sumPPll)];
 string3 = ['-.5*trace(Q\sumXkTerms): ' num2str(-.5*trace(Q\sumXkTerms))];
 
 disp(string1);
 disp(['Q=' num2str(diag(Q)')]);
 disp(string12);
 disp(string2);
 disp(string3);
 end

 ExpectationSums.Sxkm1xkm1=Sxkm1xkm1;
 ExpectationSums.Sxkm1xk=Sxkm1xk;
 ExpectationSums.Sxkxkm1=Sxkxkm1;
 ExpectationSums.Sxkxk=Sxkxk;
 ExpectationSums.sumXkTerms=sumXkTerms;
 ExpectationSums.sumPPll=sumPPll;

 end
 % function [x_K,W_K,logll,ExpectationSums]=PP_EStep(A,Q,dN, mu, beta,fitType,gamma,HkAll, x0, Px0)
% 
% DEBUG = 0;
% [numCells,K] = size(dN); 
% Dx = size(A,2);
% 
% x_p = zeros( size(A,2), K+1 );
% x_u = zeros( size(A,2), K );
% W_p = zeros( size(A,2),size(A,2), K+1 );
% W_u = zeros( size(A,2),size(A,2), K );
% x_p(:,1)= A(:,:)*x0;
% W_p(:,:,1)=A*Px0*A' + Q;
% % WuConv=[];
% for k=1:K
% [x_u(:,k), W_u(:,:,k)] = DecodingAlgorithms.PPDecode_updateLinear(x_p(:,k), W_p(:,:,k), dN,mu,beta,fitType,gamma,HkAll,k,[]);
% [x_p(:,k+1), W_p(:,:,k+1)] = DecodingAlgorithms.PPDecode_predict(x_u(:,k), W_u(:,:,k), A(:,:,min(size(A,3),k)), Q(:,:,min(size(Q,3))));
% % if(k>1 && isempty(WuConv))
% % diffWu = abs(W_u(:,:,k)-W_u(:,:,k-1));
% % maxWu = max(max(diffWu));
% % if(maxWu<5e-2)
% % WuConv = W_u(:,:,k);
% % WuConvIter = k;
% % end
% % end
% end
% 
% 
% [x_K, W_K,Lk] = DecodingAlgorithms.kalman_smootherFromFiltered(A, x_p, W_p, x_u, W_u);
% 
% %Best estimates of initial states given the data
% W1G0 = A*Px0*A' + Q;
% L0=Px0*A'/W1G0;
% 
% Ex0Gy = x0+L0*(x_K(:,1)-x_p(:,1)); 
% Px0Gy = Px0+L0*(eye(size(W_K(:,:,1)))/(W_K(:,:,1))-eye(size(W1G0))/W1G0)*L0';
% Px0Gy = (Px0Gy+Px0Gy')/2;
% numStates = size(x_K,1);
% Wku=zeros(numStates,numStates,K,K);
% Tk = zeros(numStates,numStates,K-1);
% for k=1:K
% Wku(:,:,k,k)=W_K(:,:,k);
% end
% 
% for u=K:-1:2
% for k=(u-1):-1:(u-1)
% Tk(:,:,k)=A;
% % Dk(:,:,k)=W_u(:,:,k)*Tk(:,:,k)'*pinv(W_p(:,:,k)); %From deJong and MacKinnon 1988
% Dk(:,:,k)=W_u(:,:,k)*Tk(:,:,k)'/(W_p(:,:,k+1)); %From deJong and MacKinnon 1988
% Wku(:,:,k,u)=Dk(:,:,k)*Wku(:,:,k+1,u);
% Wku(:,:,u,k)=Wku(:,:,k,u)';
% end
% end
% 
% %All terms
% Sxkm1xk = zeros(Dx,Dx);
% Sxkxkm1 = zeros(Dx,Dx);
% Sxkm1xkm1 = zeros(Dx,Dx);
% Sxkxk = zeros(Dx,Dx);
% 
% for k=1:K
% if(k==1)
% Sxkm1xk = Sxkm1xk+Px0*A'/W_p(:,:,1)*Wku(:,:,1,1);
% Sxkm1xkm1 = Sxkm1xkm1+Px0+x0*x0'; 
% else
% % 
% Sxkm1xk = Sxkm1xk+Wku(:,:,k-1,k)+x_K(:,k-1)*x_K(:,k)';
% 
% Sxkm1xkm1= Sxkm1xkm1+Wku(:,:,k-1,k-1)+x_K(:,k-1)*x_K(:,k-1)';
% end
% Sxkxk = Sxkxk+Wku(:,:,k,k)+x_K(:,k)*x_K(:,k)';
% 
% end
% Sx0x0 = Px0+x0*x0';
% Sxkxk = 0.5*(Sxkxk+Sxkxk');
% sumXkTerms = Sxkxk-A*Sxkm1xk-Sxkm1xk'*A'+A*Sxkm1xkm1*A';
% Sxkxkm1 = Sxkm1xk';
% 
% % if(strcmp(fitType,'poisson'))
% % sumPPll=0;
% % for c=1:numCells
% % % Hk=HkAll{c};
% % Hk=squeeze(HkAll(k,:,c));
% % for k=1:K
% % xk = x_K(:,k);
% % if(numel(gamma)==1)
% % gammaC=gamma;
% % else 
% % gammaC=gamma(:,c);
% % end
% % % terms=mu(c)+beta(:,c)'*xk+gammaC'*Hk(k,:)';
% % if(numel(Hk)~=1)
% % terms=mu(c)+beta(:,c)'*xk+gammaC'*Hk(k,:)';
% % else
% % terms=mu(c)+beta(:,c)'*xk+gammaC'*Hk';
% % end
% % Wk = W_K(:,:,k);
% % ld = exp(terms);
% % bt = beta(:,c);
% % ExplambdaDelta =ld+0.5*trace(bt*bt'*ld*Wk);
% % ExplogLD = terms;
% % sumPPll=sumPPll+dN(c,k).*ExplogLD - ExplambdaDelta;
% % end
% % 
% % 
% % end
% % elseif(strcmp(fitType,'binomial'))
% % sumPPll=0;
% % for c=1:C
% % for k=1:K
% % Hk=squeeze(HkAll(k,:,c));
% % xk = x_K(:,k);
% % if(numel(gamma)==1)
% % gammaC=gamma;
% % else 
% % gammaC=gamma(:,c);
% % end
% % if(numel(Hk)~=1)
% % terms=mu(c)+beta(:,c)'*xk+gammaC'*Hk(k,:)';
% % else
% % terms=mu(c)+beta(:,c)'*xk+gammaC'*Hk';
% % end
% % Wk = W_K(:,:,k);
% % ld = exp(terms)./(1+exp(terms));
% % bt = beta;
% % ExplambdaDelta =sum(ld+0.5*sum(bt'*bt*repmat(ld.*(1-ld).*(1-2.*ld),1,2)*Wk,2));
% % ExplogLD = (log(ld)+0.5*sum(bt*bt'*(repmat(ld.*(1-ld),1,size(bt,1))*Wk)')');
% % sumPPll=sumPPll+dN(:,k)'*ExplogLD - ExplambdaDelta;
% % end
% % end
% % 
% % % for c=1:numCells
% % % Hk=HkAll{c};
% % % for k=1:K
% % % xk = x_K(:,k);
% % % if(numel(gamma)==1)
% % % gammaC=gamma;
% % % else 
% % % gammaC=gamma(:,c);
% % % end
% % % if(numel(Hk)~=1)
% % % terms=mu(c)+beta(:,c)'*xk+gammaC'*Hk(k,:)';
% % % else
% % % terms=mu(c)+beta(:,c)'*xk+gammaC'*Hk';
% % % end
% % % Wk = W_K(:,:,k);
% % % ld = exp(terms)./(1+exp(terms));
% % % bt = beta(:,c);
% % % ExplambdaDelta =ld+0.5*trace(bt*bt'*ld*(1-ld)*(1-2*ld)*Wk);
% % % ExplogLD = log(ld)+0.5*trace(-(bt*bt'*ld*(1-ld))*Wk);
% % % sumPPll=sumPPll+dN(c,k).*ExplogLD - ExplambdaDelta;
% % % end
% % % 
% % % 
% % % end
% % end
% 
% %Vectorize for loop over cells
% if(strcmp(fitType,'poisson'))
% sumPPll=0;
% for k=1:K
% Hk=squeeze(HkAll(k,:,:)); 
% if(size(Hk,1)==numCells)
% Hk = Hk';
% end
% xk = x_K(:,k);
% if(numel(gamma)==1)
% gammaC=repmat(gamma,1,numCells);
% else 
% gammaC=gamma;
% end
% % if(size(gammaC,1)~=size(mu,1))
% % gammaC = gammaC';
% % end
% % if(size(Hk,1)~=size(mu,1))
% % Hk=Hk';
% % end
% terms=mu+beta'*xk+diag(gammaC'*Hk);
% Wk = W_K(:,:,k);
% ld = exp(terms);
% bt = beta;
% ExplambdaDelta =ld+0.5*(ld.*diag((bt'*Wk*bt)));
% ExplogLD = terms;
% sumPPll=sumPPll+sum(dN(:,k).*ExplogLD - ExplambdaDelta);
% 
% end
% 
% %Vectorize over number of cells
% elseif(strcmp(fitType,'binomial'))
% sumPPll=0;
% for k=1:K
% Hk=squeeze(HkAll(k,:,:));
% if(size(Hk,1)==numCells)
% Hk = Hk';
% end
% xk = x_K(:,k);
% if(numel(gamma)==1)
% gammaC=repmat(gamma,1,numCells);
% else 
% gammaC=gamma;
% end
% % if(size(gammaC,1)~=size(mu,1))
% % gammaC = gammaC';
% % end
% % if(size(Hk,1)~=size(mu,1))
% % Hk=Hk';
% % end
% terms=mu+beta'*xk+diag(gammaC'*Hk);
% Wk = W_K(:,:,k);
% ld = exp(terms)./(1+exp(terms));
% bt = beta; 
% ExplambdaDelta = ld+0.5*(ld.*(1-ld).*(1-2.*ld)).*diag((bt'*Wk*bt));
% ExplogLD = log(ld)+0.5*(-ld.*(1-ld)).*diag(bt'*Wk*bt);
% sumPPll=sumPPll+sum(dN(:,k).*ExplogLD - ExplambdaDelta); 
% 
% end
% 
% 
% end
% 
% logll = -Dx*K/2*log(2*pi)-K/2*log(det(Q))...
% - Dx/2*log(2*pi) -1/2*log(det(Px0))...
% +sumPPll - 1/2*trace((eye(size(Q))/Q)*sumXkTerms)...
% -Dx/2;
% string0 = ['logll: ' num2str(logll)];
% disp(string0);
% if(DEBUG==1)
% string1 = ['-K/2*log(det(Q)):' num2str(-K/2*log(det(Q)))];
% string12= ['Constants: ' num2str(-Dx*K/2*log(2*pi)-Dx/2*log(2*pi) -Dx/2 -1/2*log(det(Px0)))];
% string2 = ['SumPPll: ' num2str(sumPPll)];
% string3 = ['-.5*trace(Q\sumXkTerms): ' num2str(-.5*trace(Q\sumXkTerms))];
% 
% disp(string1);
% disp(['Q=' num2str(diag(Q)')]);
% disp(string12);
% disp(string2);
% disp(string3);
% 
% end
% 
% ExpectationSums.Sxkm1xkm1=Sxkm1xkm1;
% ExpectationSums.Sxkm1xk=Sxkm1xk;
% ExpectationSums.Sxkxkm1=Sxkxkm1;
% ExpectationSums.Sxkxk=Sxkxk;
% ExpectationSums.sumXkTerms=sumXkTerms;
% ExpectationSums.sumPPll=sumPPll;
% ExpectationSums.Sx0 = Ex0Gy;
% ExpectationSums.Sx0x0 = Px0Gy + Ex0Gy*Ex0Gy';
% ExpectationSums.A = A;
% ExpectationSums.Q = Q;
% ExpectationSums.mu = mu;
% ExpectationSums.beta = beta;
% ExpectationSums.gamma = gamma;
% 
% end
 function [Ahat, Qhat, muhat_new, betahat_new, gammahat_new, x0hat, Px0hat] = PP_MStep(dN, x_K,W_K,x0, Px0, ExpectationSums,fitType, muhat, betahat,gammahat, windowTimes, HkAll,PPEM_Constraints,MstepMethod,delta)
 %PP_MSTEP M-step of PP_EM.
 % MstepMethod: 'NewtonRaphson' (default since fix/pp-em round 2; was
 % 'GLM') or 'GLM' (plug-in fit on the smoothed means; see PP_EM help).
 % delta: seconds per bin (default 0.001); sets the GLM M-step's time
 % base.
 % FIX: optional 15th input `delta` (seconds per bin, default 0.001)
 % so the GLM M-step builds its Trial on the same time base as PP_EM
 % (see the GLM block below). PP_EM now passes its delta.
 if(nargin<15 || isempty(delta))
 delta = .001;
 end
 if(nargin<14 || isempty(MstepMethod))
 MstepMethod = 'NewtonRaphson'; % FIX: default was 'GLM' (see PP_EM help)
 end
 if(nargin<13 || isempty(PPEM_Constraints))
 PPEM_Constraints = nstat.decoding.PointProcessEM.PP_EMCreateConstraints;
 end
 
 Sxkm1xkm1=ExpectationSums.Sxkm1xkm1;
 Sxkxkm1=ExpectationSums.Sxkxkm1;
 sumXkTerms = ExpectationSums.sumXkTerms;
 [dx,K] = size(x_K); 
 numCells=size(dN,1);
 
 if(PPEM_Constraints.AhatDiag==1)
 I=eye(dx,dx);
 Ahat = (Sxkxkm1.*I)/(Sxkm1xkm1.*I);
 else
 Ahat = Sxkxkm1/Sxkm1xkm1;
 end
 
 
 if(PPEM_Constraints.QhatDiag==1)
 if(PPEM_Constraints.QhatIsotropic==1)
 Qhat=1/(dx*K)*trace(sumXkTerms)*eye(dx,dx);
 else
 I=eye(dx,dx);
 Qhat=1/K*(sumXkTerms.*I);
 Qhat = (Qhat + Qhat')/2;
 end
 else
 Qhat=1/K*sumXkTerms;
 Qhat = (Qhat + Qhat')/2;
 end
 
 if(PPEM_Constraints.Estimatex0)
 x0hat = (inv(Px0)+Ahat'/Qhat*Ahat)\(Ahat'/Qhat*x_K(:,1)+Px0\x0);
 else
 x0hat = x0;
 end
 
 if(PPEM_Constraints.EstimatePx0==1)
 if(PPEM_Constraints.Px0Isotropic==1)
 Px0hat=(trace(x0hat*x0hat' - x0*x0hat' - x0hat*x0' +(x0*x0'))/(dx*K))*eye(dx,dx); 
 else
 I=eye(dx,dx);
 Px0hat =(x0hat*x0hat' - x0*x0hat' - x0hat*x0' +(x0*x0')).*I;
 Px0hat = (Px0hat+Px0hat')/2;
 end
 
 else
 Px0hat =Px0;
 end
 
 betahat_new =betahat;
 gammahat_new = gammahat;
 muhat_new = muhat;
 
 %Compute the new CIF beta using the GLM
 if(strcmp(fitType,'poisson'))
 algorithm = 'GLM';
 else
 algorithm = 'BNLRCG';
 end
 
 % Estimate params via GLM
 if(strcmp(MstepMethod,'GLM'))
 % FIX: removed `close all`. PP_EM creates its progress figure `h`
 % after the first M-step; on iteration 2 this `close all` deleted
 % it and PP_EM's `figure(h)` then threw "Argument must be a Figure
 % object or a positive integer", so a GLM M-step EM could never
 % get past iteration 2. RunAnalysisForAllNeurons is called with
 % makePlot=0 below, so there is nothing for this step to close --
 % it only destroyed the caller's (and the user's) figures.
 clear c;
 % FIX: the time grid and the Trial sample rate were hardcoded
 % to 1 ms (`(0:length(x_K)-1)*.001`, `sampleRate = 1000`). For
 % delta ~= 0.001 the history windows (seconds) then covered the
 % wrong number of bins and no longer matched PP_EM's HkAll, which
 % the E-step uses. Use delta. Identical for delta = 0.001.
 time=(0:K-1)*delta;
 labels = cell(1,dx);
 labels2 = cell(1,dx+1);
 labels2{1} = 'vel';
 for i=1:dx
 labels{i} = strcat('v',num2str(i));
 labels2{i+1} = strcat('v',num2str(i));
 end
 vel = Covariate(time,x_K','vel','time','s','m/s',labels);
 baseline = Covariate(time,ones(length(time),1),'Baseline','time','s','',...
 {'constant'});
 for i=1:size(dN,1)
 spikeTimes = time(find(dN(i,:)==1));
 nst{i} = nspikeTrain(spikeTimes, '', delta);
 end
 nspikeColl = nstColl(nst);
 cc = CovColl({vel,baseline});
 trial = Trial(nspikeColl,cc);
 selfHist = windowTimes ; NeighborHist = []; sampleRate = 1/delta; 
 clear c;
 
 

 if(gammahat==0)
 c{1} = TrialConfig({{'Baseline','constant'},labels2},sampleRate,[],NeighborHist); 
 else
 c{1} = TrialConfig({{'Baseline','constant'},labels2},sampleRate,selfHist,NeighborHist); 
 end
 c{1}.setName('Baseline');
 cfgColl= ConfigColl(c);
 % FIX: `warning('OFF')` switched off every warning globally and never
 % restored it, so after one GLM M-step the CALLER's warnings (incl.
 % verifyWarning-based tests) stayed silenced. Keep the original
 % suppression during the fit but restore the caller's warning state
 % when this function returns.
 callerWarnState = warning;
 restoreCallerWarnings = onCleanup(@() warning(callerWarnState)); %#ok<NASGU>
 warning('OFF');

 results = Analysis.RunAnalysisForAllNeurons(trial,cfgColl,0,algorithm);
 temp = FitResSummary(results);
 % (coefficients are read by label below)
 % FIX: the GLM estimates were written to the INPUT variables
 % (betahat, muhat, gammahat) while this function returns
 % betahat_new / muhat_new / gammahat_new, which were set to the
 % inputs above and never updated -- so the GLM M-step silently
 % returned mu, beta and gamma unchanged and PP_EM never estimated
 % the CIF parameters. Write the fit into the returned variables.
 % A coefficient that FitResSummary reports as NaN (dropped by its
 % se<100 filter in computePlotParams, i.e. not identifiable from
 % these data) keeps its previous value instead of propagating NaN
 % into the next E-step; history coefficients follow the same
 % keep-previous rule below (by window label).
 % FIX (F3): map 'constant' and 'v1'..'vdx' BY LABEL. The old
 % positional read (mu = row 1, beta = rows 2:dx+1 of getCoeffs)
 % broke when FitResSummary dropped a label that is NaN (se>=100) for
 % every cell (index error / wrong rows), mis-mapped for dx >= 10
 % (labels sort as 'v1','v10','v2',...), and failed for a single cell
 % (getCoeffs then returns a 1 x nLabels row). A label that is absent,
 % or NaN for a cell, keeps the previous value (the R4a rule).
 [coeffMat, coeffLabels] = temp.getCoeffs;
 if(isempty(coeffLabels))
 coeffLabCol = {};
 else
 coeffLabCol = coeffLabels(:,1);
 end
 coeffMat = reshape(coeffMat, numel(coeffLabCol), []); % nLabels x numCells
 muFit = muhat_new(:);
 betaFit = betahat_new(1:dx,:);
 j = find(strcmp(coeffLabCol, 'constant'), 1);
 if(~isempty(j))
 v = coeffMat(j,:)';
 muFit(~isnan(v)) = v(~isnan(v));
 end
 for i=1:dx
 j = find(strcmp(coeffLabCol, labels{i}), 1);
 if(~isempty(j))
 v = coeffMat(j,:);
 betaFit(i,~isnan(v)) = v(~isnan(v));
 end
 end
 betahat_new(1:dx,:) = betaFit;
 muhat_new = muFit;
 if(gammahat==0)
 % no history terms in this fit; gammahat_new stays as input
 else
 % FIX (R4a): map the fitted history coefficients to the windows BY
 % LABEL. getHistCoeffs only returns labels that are non-NaN for at
 % least one cell (FitResSummary NaNs coefficients with se>=100), in
 % sorted label order, so `reshape(histTemp,[nWindows numCells])`
 % errored whenever a whole window was unestimable for every cell (and
 % relied on sorted labels matching window order). The window labels
 % come from the same History object the Trial uses. A window/cell
 % whose coefficient is missing or NaN keeps its previous gamma (the
 % rule used for mu/beta above; this replaces the old NaN -> 0).
 nWin = length(windowTimes)-1;
 [histMat, histLabels] = temp.getHistCoeffs;
 winCov = History(windowTimes, min(time), max(time)).computeHistory(nst{1}).getCov(1);
 winLabels = winCov.dataLabels;
 gPrev = gammahat;
 if(isscalar(gPrev))
 gPrev = gPrev*ones(nWin, numCells);
 elseif(size(gPrev,2)==1)
 gPrev = repmat(gPrev, 1, numCells);
 end
 histTemp = gPrev;
 % FIX (F1): getHistCoeffs returns labels = cell(0,0) when NO window is
 % estimable for any cell; histLabels(:,1) then threw
 % MATLAB:badsubscript. Treat that as "no fitted label" (every window
 % keeps its previous gamma).
 if(isempty(histLabels))
 histLabCol = {};
 else
 histLabCol = histLabels(:,1);
 end
 for w=1:nWin
 j = find(strcmp(histLabCol, winLabels{w}), 1);
 if(~isempty(j))
 for c=1:numCells
 v = histMat(j,1,c);
 if(~isnan(v))
 histTemp(w,c) = v;
 end
 end
 end
 end
 gammahat_new=histTemp;
 end
 else
 
 % Estimate via Newton-Raphson
 % Estimate via Newton-Raphson
 fprintf(['****M-step for beta**** \n']);
 McExp=50; 
 xKDrawExp = zeros(size(x_K,1),K,McExp);
 diffTol = 1e-5;

 % Generate the Monte Carlo samples
 for k=1:K
 % FIX (F9): draw via mcStateDraws (m + chol(W)'*z; was m + chol(W)*z,
 % whose covariance is chol(W)*chol(W)', not W, for non-diagonal W).
 xKDrawExp(:,k,:)=nstat.decoding.PointProcessEM.mcStateDraws(x_K(:,k),W_K(:,:,k),McExp);
 end
 
 % Stimulus Coefficients
 % FIX (#99): matlabpool was removed in R2017a; same defect class as PPLFP.m.
 ppPool = gcp('nocreate'); if isempty(ppPool), pool = 0; else, pool = ppPool.NumWorkers; end
 if(pool==0)
 for c=1:numCells
 converged=0;
 iter = 1;
 maxIter=100;
 fprintf(['neuron:' num2str(c) ' iter: ']);
 while(~converged && iter<maxIter)
 if(iter==1)
 fprintf('%d',iter);
 else
 fprintf(',%d',iter);
 end
 if(strcmp(fitType,'poisson'))
 HessianTerm = zeros(size(x_K,1),size(x_K,1));
 GradTerm = zeros(size(x_K,1),1);
 % FIX: was permute(xKDraw,[2 3 1]) -- `xKDraw` is undefined in
 % PP_MStep (the MC draws are xKDrawExp, dx x K x McExp), so the
 % serial (no parallel pool) NewtonRaphson M-step always errored,
 % and [2 3 1] would have sliced a K x McExp matrix instead of
 % the dx x McExp draws used below. Use the same permutation as
 % every other branch here and PPLFP_MStep: dx x McExp x K.
 xkPerm = permute(xKDrawExp,[1 3 2]);
 for k=1:K
 Hk = (HkAll(:,:,c));
 Wk = W_K(:,:,k);
% xk = squeeze(xKDrawExp(:,k,:));
 xk = xkPerm(:,:,k);
 % FIX (R4d): no re-orientation. Hk = HkAll(:,:,c) is already
 % (numTimeSteps x numWindows) by construction; the old
 % `size(Hk,1)==numCells` test fired when numTimeSteps == numCells
 % and then indexed Hk(k,:) on the transposed matrix.

 if(numel(gammahat)==1)
 gammaC=gammahat;
 % gammaC=repmat(gammaC,[1 numCells]);
 else 
 gammaC=gammahat(:,c);
 end

 terms =muhat(c)+betahat_new(:,c)'*xk+gammaC'*Hk(k,:)';
 ld=exp(terms);
 ExpLambdaXk = 1/McExp*sum(repmat(ld,[size(xk,1),1]).*xk,2);
 ExpLambdaXkXkT = 1/McExp*(repmat(ld,[size(xk,1),1]).*xk)*xk';
 GradTerm = GradTerm+dN(c,k)*x_K(:,k) - ExpLambdaXk;
 HessianTerm=HessianTerm-ExpLambdaXkXkT;

 end

 elseif(strcmp(fitType,'binomial'))
 HessianTerm = zeros(size(x_K,1),size(x_K,1));
 GradTerm = zeros(size(x_K,1),1);
 % FIX: was permute(xKDraw,...) -- undefined variable; see the
 % poisson branch above.
 xkPerm = permute(xKDrawExp,[1 3 2]);
 for k=1:K
 Hk = (HkAll(:,:,c));
 Wk = W_K(:,:,k);
% xk = squeeze(xKDrawExp(:,k,:));
 xk = xkPerm(:,:,k);
 % FIX (R4d): no re-orientation. Hk = HkAll(:,:,c) is already
 % (numTimeSteps x numWindows) by construction; the old
 % `size(Hk,1)==numCells` test fired when numTimeSteps == numCells
 % and then indexed Hk(k,:) on the transposed matrix.

 if(numel(gammahat)==1)
 gammaC=gammahat;
 % gammaC=repmat(gammaC,[1 numCells]);
 else 
 gammaC=gammahat(:,c);
 end

 terms =muhat(c)+betahat_new(:,c)'*xk+gammaC'*Hk(k,:)';
 ld=exp(terms)./(1+exp(terms));
 ExplambdaDeltaXkXk=1/McExp*(repmat(ld,[size(xk,1),1]).*xk)*xk';
 ExplambdaDeltaSqXkXkT=1/McExp*(repmat(ld.^2,[size(xk,1),1]).*xk)*xk';
 ExplambdaDeltaCubeXkXkT=1/McExp*(repmat(ld.^3,[size(xk,1),1]).*xk)*xk';
 ExpLambdaXk = 1/McExp*sum(repmat(ld,[size(xk,1),1]).*xk,2);
 ExpLambdaSquaredXk = 1/McExp*sum(repmat(ld.^2,[size(xk,1),1]).*xk,2);
 GradTerm = GradTerm+dN(c,k)*x_K(:,k) - (dN(c,k)+1)*ExpLambdaXk+ExpLambdaSquaredXk;
 % FIX: the beta Hessian was
 % +E[p]xx' + E[p^2]xx' - 2E[p^3]xx' (positive definite), so the
 % Newton step beta - H\g moved DOWNHILL and the binomial NR
 % M-step diverged (scaled beta 0.1 -> 200 in one M-step, then
 % non-PD smoothed covariances and NaN logll). For
 % log L = sum dN*log(p) - p, p = logistic(eta), whose gradient
 % (dN-p)(1-p)x is the GradTerm above, the Hessian is
 % -p(1-p)(1+dN-2p)xx' = (-(dN+1)p + (dN+3)p^2 - 2p^3)xx' --
 % the same expression the mu and gamma steps below already use.
 % Verified against a central finite difference of GradTerm
 % (max rel. error 3.5e-11; old form: wrong sign and magnitude).
 HessianTerm=HessianTerm-(dN(c,k)+1)*ExplambdaDeltaXkXk+(dN(c,k)+3)*ExplambdaDeltaSqXkXkT-2*ExplambdaDeltaCubeXkXkT;

 end

 end
 if(any(any(isnan(HessianTerm))) || any(any(isinf(HessianTerm))))
 betahat_newTemp = betahat_new(:,c);
 else
 betahat_newTemp = (betahat_new(:,c)-HessianTerm\GradTerm);
 if(any(isnan(betahat_newTemp)))
 betahat_newTemp = betahat_new(:,c);

 end
 end
 mabsDiff = max(abs(betahat_newTemp - betahat_new(:,c)));
 if(mabsDiff<diffTol)
 converged=1;
 end
 betahat_new(:,c)=betahat_newTemp;
 iter=iter+1;
 end
 fprintf('\n'); 
 end 
 else
 HessianTerm = zeros(size(betahat,1),size(betahat,1),numCells);
 GradTerm = zeros(size(betahat,1),numCells);
 betahat_newTemp=betahat_new;
 for c=1:numCells
 converged=0;
 iter = 1;
 maxIter=100;
 fprintf(['neuron:' num2str(c) ' iter: ']);
 while(~converged && iter<maxIter)
 if(iter==1)
 fprintf('%d',iter);
 else
 fprintf(',%d',iter);
 end
 if(strcmp(fitType,'poisson'))
 xkPerm = permute(xKDrawExp, [1 3 2]);
 for k=1:K
 Hk = (HkAll(:,:,c));
 Wk = W_K(:,:,k);
% xk = squeeze(xKDrawExp(:,k,:));
 xk = xkPerm(:,:,k);
 % FIX (R4d): no re-orientation. Hk = HkAll(:,:,c) is already
 % (numTimeSteps x numWindows) by construction; the old
 % `size(Hk,1)==numCells` test fired when numTimeSteps == numCells
 % and then indexed Hk(k,:) on the transposed matrix.

 if(numel(gammahat)==1)
 gammaC=gammahat;
 % gammaC=repmat(gammaC,[1 numCells]);
 else 
 gammaC=gammahat(:,c);
 end

 terms =muhat(c)+betahat_new(:,c)'*xk+gammaC'*Hk(k,:)';
 ld=exp(terms);
 ExpLambdaXk = 1/McExp*sum(repmat(ld,[size(xk,1),1]).*xk,2);
 ExpLambdaXkXkT = 1/McExp*(repmat(ld,[size(xk,1),1]).*xk)*xk';
 if(k==1)
 GradTerm(:,c) = dN(c,k)*x_K(:,k) - ExpLambdaXk;
 HessianTerm(:,:,c)=-ExpLambdaXkXkT;
 else
 GradTerm(:,c) = GradTerm(:,c)+dN(c,k)*x_K(:,k) - ExpLambdaXk;
 HessianTerm(:,:,c)=HessianTerm(:,:,c)-ExpLambdaXkXkT;
 end

 end

 elseif(strcmp(fitType,'binomial'))
 xkPerm = permute(xKDrawExp, [1 3 2]);
 for k=1:K
 Hk = (HkAll(:,:,c));
 Wk = W_K(:,:,k);
% xk = squeeze(xKDrawExp(:,k,:));
 % FIX: was xKDrawExp(:,:,k) -- the k-th MC draw of the whole
 % trajectory (dx x K), which errors for k > McExp. The draws
 % for time k are xkPerm(:,:,k) (dx x McExp), as in the poisson
 % branch above.
 xk=xkPerm(:,:,k);
 % FIX (R4d): no re-orientation. Hk = HkAll(:,:,c) is already
 % (numTimeSteps x numWindows) by construction; the old
 % `size(Hk,1)==numCells` test fired when numTimeSteps == numCells
 % and then indexed Hk(k,:) on the transposed matrix.

 if(numel(gammahat)==1)
 gammaC=gammahat;
 % gammaC=repmat(gammaC,[1 numCells]);
 else 
 gammaC=gammahat(:,c);
 end

 terms =muhat(c)+betahat_new(:,c)'*xk+gammaC'*Hk(k,:)';
 ld=exp(terms)./(1+exp(terms));
 ExplambdaDeltaXkXk=1/McExp*(repmat(ld,[size(xk,1),1]).*xk)*xk';
 ExplambdaDeltaSqXkXkT=1/McExp*(repmat(ld.^2,[size(xk,1),1]).*xk)*xk';
 ExplambdaDeltaCubeXkXkT=1/McExp*(repmat(ld.^3,[size(xk,1),1]).*xk)*xk';
 ExpLambdaXk = 1/McExp*sum(repmat(ld,[size(xk,1),1]).*xk,2);
 ExpLambdaSquaredXk = 1/McExp*sum(repmat(ld.^2,[size(xk,1),1]).*xk,2);
 % FIX: same wrong-sign binomial beta Hessian as the serial
 % branch above; use (-(dN+1)p + (dN+3)p^2 - 2p^3)xx'.
 if(k==1)
 GradTerm(:,c) = dN(c,k)*x_K(:,k) - (dN(c,k)+1)*ExpLambdaXk+ExpLambdaSquaredXk;
 HessianTerm(:,:,c)=-(dN(c,k)+1)*ExplambdaDeltaXkXk+(dN(c,k)+3)*ExplambdaDeltaSqXkXkT-2*ExplambdaDeltaCubeXkXkT;
 else
 GradTerm(:,c) = GradTerm(:,c)+dN(c,k)*x_K(:,k) - (dN(c,k)+1)*ExpLambdaXk+ExpLambdaSquaredXk;
 HessianTerm(:,:,c)=HessianTerm(:,:,c)-(dN(c,k)+1)*ExplambdaDeltaXkXk+(dN(c,k)+3)*ExplambdaDeltaSqXkXkT-2*ExplambdaDeltaCubeXkXkT;
 end
 end

 end
 if(any(any(isnan(HessianTerm(:,:,c)))) || any(any(isinf(HessianTerm(:,:,c)))))
 betahat_newTemp = betahat_new(:,c);
 else
 betahat_newTemp = (betahat_new(:,c)-HessianTerm(:,:,c)\GradTerm(:,c));
 if(any(isnan(betahat_newTemp)))
 betahat_newTemp = betahat_new(:,c);

 end
 end
 mabsDiff = max(abs(betahat_newTemp - betahat_new(:,c)));
 if(mabsDiff<diffTol)
 converged=1;
 end
 betahat_new(:,c)=betahat_newTemp;
 iter=iter+1;
 end
 fprintf('\n'); 
 end 
 end
 clear GradTerm HessianTerm;
 %Compute the CIF means 
 if(pool==0)
 for c=1:numCells
 converged=0;
 iter = 1;
 maxIter=100;
 % fprintf(['neuron:' num2str(c) ' iter: ']);
 while(~converged && iter<maxIter)
 % if(iter==1)
 % fprintf('%d',iter);
 % else
 % fprintf(',%d',iter);
 % end
 if(strcmp(fitType,'poisson'))
 HessianTerm = zeros(size(1,1),size(1,1));
 GradTerm = zeros(size(1,1),1);
 xkPerm = permute(xKDrawExp, [1 3 2]);
 for k=1:K
 Hk = (HkAll(:,:,c));
 Wk = W_K(:,:,k);
% xk = squeeze(xKDrawExp(:,k,:));
 xk = xkPerm(:,:,k);
 % FIX (R4d): no re-orientation. Hk = HkAll(:,:,c) is already
 % (numTimeSteps x numWindows) by construction; the old
 % `size(Hk,1)==numCells` test fired when numTimeSteps == numCells
 % and then indexed Hk(k,:) on the transposed matrix.

 if(numel(gammahat)==1)
 gammaC=gammahat;
 % gammaC=repmat(gammaC,[1 numCells]);
 else 
 gammaC=gammahat(:,c);
 end

 terms =muhat_new(c)+betahat(:,c)'*xk+gammaC'*Hk(k,:)';
 ld=exp(terms);
 ExpLambdaDelta = 1/McExp*sum(ld,2);
 GradTerm = GradTerm+(dN(c,k) - ExpLambdaDelta);
 HessianTerm=HessianTerm-ExpLambdaDelta;

 end

 elseif(strcmp(fitType,'binomial'))
 HessianTerm = zeros(size(1,1),size(1,1));
 GradTerm = zeros(size(1,1),1);
 xkPerm = permute(xKDrawExp, [1 3 2]);
 for k=1:K
 Hk = (HkAll(:,:,c));
 Wk = W_K(:,:,k);
% xk = squeeze(xKDrawExp(:,k,:));
 xk = xkPerm(:,:,k);
 % FIX (R4d): no re-orientation. Hk = HkAll(:,:,c) is already
 % (numTimeSteps x numWindows) by construction; the old
 % `size(Hk,1)==numCells` test fired when numTimeSteps == numCells
 % and then indexed Hk(k,:) on the transposed matrix.

 if(numel(gammahat)==1)
 gammaC=gammahat;
 % gammaC=repmat(gammaC,[1 numCells]);
 else 
 gammaC=gammahat(:,c);
 end

 terms =muhat_new(c)+betahat(:,c)'*xk+gammaC'*Hk(k,:)';
 ld=exp(terms)./(1+exp(terms));
 ExpLambdaDelta =1/McExp*(sum(ld,2));
 ExpLambdaDeltaSq = 1/McExp*(sum(ld.^2,2));
 ExpLambdaDeltaCubed = 1/McExp*(sum(ld.^3,2));
 GradTerm = GradTerm+(dN(c,k)-(dN(c,k)+1)*ExpLambdaDelta+ExpLambdaDeltaSq);
 HessianTerm=HessianTerm+(-ExpLambdaDelta*(dN(c,k)+1)+ExpLambdaDeltaSq*(dN(c,k)+3)-2*ExpLambdaDeltaCubed);

 end

 end
 if(any(any(isnan(HessianTerm))) || any(any(isinf(HessianTerm))))
 muhat_newTemp = muhat_new(c);
 else
 muhat_newTemp = (muhat_new(c)-HessianTerm\GradTerm);
 if(any(isnan(muhat_newTemp)))
 muhat_newTemp = muhat_new(c);

 end
 end
 mabsDiff = max(abs(muhat_newTemp - muhat_new(c)));
 if(mabsDiff<diffTol)
 converged=1;
 end
 muhat_new(c)=muhat_newTemp;
 iter=iter+1;
 end
 % fprintf('\n'); 
 end 
 else
 HessianTerm = zeros(1,numCells);
 GradTerm = zeros(1,numCells);
 for c=1:numCells
 converged=0;
 iter = 1;
 maxIter=100;
 % fprintf(['neuron:' num2str(c) ' iter: ']);
 while(~converged && iter<maxIter)
 % if(iter==1)
 % fprintf('%d',iter);
 % else
 % fprintf(',%d',iter);
 % end
 if(strcmp(fitType,'poisson'))
 xkPerm = permute(xKDrawExp, [1 3 2]);
 for k=1:K
 Hk = (HkAll(:,:,c));
 Wk = W_K(:,:,k);
% xk = squeeze(xKDrawExp(:,k,:));
 xk = xkPerm(:,:,k);
 % FIX (R4d): no re-orientation. Hk = HkAll(:,:,c) is already
 % (numTimeSteps x numWindows) by construction; the old
 % `size(Hk,1)==numCells` test fired when numTimeSteps == numCells
 % and then indexed Hk(k,:) on the transposed matrix.

 if(numel(gammahat)==1)
 gammaC=gammahat;
 % gammaC=repmat(gammaC,[1 numCells]);
 else 
 gammaC=gammahat(:,c);
 end

 terms =muhat_new(c)+betahat(:,c)'*xk+gammaC'*Hk(k,:)';
 ld=exp(terms);
 ExpLambdaDelta = 1/McExp*sum(ld,2);
 if(k==1)
 GradTerm(c) = (dN(c,k) - ExpLambdaDelta);
 HessianTerm(c)=-ExpLambdaDelta;
 else
 GradTerm(c) = GradTerm(c)+(dN(c,k) - ExpLambdaDelta);
 HessianTerm(c)=HessianTerm(c)-ExpLambdaDelta;
 end

 end

 elseif(strcmp(fitType,'binomial'))
 xkPerm = permute(xKDrawExp, [1 3 2]);
 for k=1:K
 Hk = (HkAll(:,:,c));
 Wk = W_K(:,:,k);
% xk = squeeze(xKDrawExp(:,k,:));
 xk = xkPerm(:,:,k);
 % FIX (R4d): no re-orientation. Hk = HkAll(:,:,c) is already
 % (numTimeSteps x numWindows) by construction; the old
 % `size(Hk,1)==numCells` test fired when numTimeSteps == numCells
 % and then indexed Hk(k,:) on the transposed matrix.

 if(numel(gammahat)==1)
 gammaC=gammahat;
 % gammaC=repmat(gammaC,[1 numCells]);
 else 
 gammaC=gammahat(:,c);
 end

 terms =muhat_new(c)+betahat(:,c)'*xk+gammaC'*Hk(k,:)';
 ld=exp(terms)./(1+exp(terms));
 ExpLambdaDelta =1/McExp*(sum(ld,2));
 ExpLambdaDeltaSq = 1/McExp*(sum(ld.^2,2));
 ExpLambdaDeltaCubed = 1/McExp*(sum(ld.^3,2));
 if(k==1)
 GradTerm(c) = (dN(c,k)-(dN(c,k)+1)*ExpLambdaDelta+ExpLambdaDeltaSq);
 HessianTerm(c)=(-ExpLambdaDelta*(dN(c,k)+1)+ExpLambdaDeltaSq*(dN(c,k)+3)-2*ExpLambdaDeltaCubed);
 else
 GradTerm(c) = GradTerm(c)+(dN(c,k)-(dN(c,k)+1)*ExpLambdaDelta+ExpLambdaDeltaSq);
 HessianTerm(c)=HessianTerm(c)+(-ExpLambdaDelta*(dN(c,k)+1)+ExpLambdaDeltaSq*(dN(c,k)+3)-2*ExpLambdaDeltaCubed);
 end

 end

 end
 if(any(any(isnan(HessianTerm(c)))) || any(any(isinf(HessianTerm(c)))))
 muhat_newTemp = muhat_new(c);
 else
 muhat_newTemp = (muhat_new(c)-HessianTerm(c)\GradTerm(c));
 if(any(isnan(muhat_newTemp)))
 muhat_newTemp = muhat_new(c);

 end
 end
 mabsDiff = max(abs(muhat_newTemp - muhat_new(c)));
 if(mabsDiff<diffTol)
 converged=1;
 end
 muhat_new(c)=muhat_newTemp;
 iter=iter+1;
 end
 % fprintf('\n'); 
 end 
 end
 clear HessianTerm GradTerm;
 
 
 %Compute the history coeffs
 if(~isempty(windowTimes) && any(any(gammahat_new~=0)))
 if(pool==0)
 for c=1:numCells
 converged=0;
 iter = 1;
 maxIter=100;
 % fprintf(['neuron:' num2str(c) ' iter: ']);
 while(~converged && iter<maxIter)
 % if(iter==1)
 % fprintf('%d',iter);
 % else
 % fprintf(',%d',iter);
 % end
 if(strcmp(fitType,'poisson'))
 HessianTerm = zeros(size(gammahat,1),size(gammahat,1));
 GradTerm = zeros(size(gammahat,1),1);
 xkPerm = permute(xKDrawExp, [1 3 2]);
 for k=1:K
 Hk = (HkAll(:,:,c));
 Wk = W_K(:,:,k);
% xk = squeeze(xKDrawExp(:,k,:));
 xk = xkPerm(:,:,k);
 % FIX (R4d): no re-orientation. Hk = HkAll(:,:,c) is already
 % (numTimeSteps x numWindows) by construction; the old
 % `size(Hk,1)==numCells` test fired when numTimeSteps == numCells
 % and then indexed Hk(k,:) on the transposed matrix.

 if(numel(gammahat_new)==1)
 gammaC=gammahat_new;
 % gammaC=repmat(gammaC,[1 numCells]);
 else 
 gammaC=gammahat_new(:,c);
 end

 terms =muhat(c)+betahat(:,c)'*xk+gammaC'*Hk(k,:)';
 ld=exp(terms);
 ExpLambdaDelta = 1/McExp*sum(ld,2);
 GradTerm = GradTerm+(dN(c,k) - ExpLambdaDelta)*Hk(k,:)';
 HessianTerm=HessianTerm-ExpLambdaDelta*Hk(k,:)'*Hk(k,:);

 end

 elseif(strcmp(fitType,'binomial'))
 HessianTerm = zeros(size(gammahat,1),size(gammahat,1));
 GradTerm = zeros(size(gammahat,1),1);
 xkPerm = permute(xKDrawExp, [1 3 2]);
 for k=1:K
 Hk = (HkAll(:,:,c));
 Wk = W_K(:,:,k);
% xk = squeeze(xKDrawExp(:,k,:));
 xk=xkPerm(:,:,k);
 % FIX (R4d): no re-orientation. Hk = HkAll(:,:,c) is already
 % (numTimeSteps x numWindows) by construction; the old
 % `size(Hk,1)==numCells` test fired when numTimeSteps == numCells
 % and then indexed Hk(k,:) on the transposed matrix.

 if(numel(gammahat_new)==1)
 gammaC=gammahat_new;
 % gammaC=repmat(gammaC,[1 numCells]);
 else 
 gammaC=gammahat_new(:,c);
 end

 terms =muhat(c)+betahat(:,c)'*xk+gammaC'*Hk(k,:)';
 ld=exp(terms)./(1+exp(terms));
 ExpLambdaDelta =1/McExp*(sum(ld,2));
 ExpLambdaDeltaSq = 1/McExp*(sum(ld.^2,2));
 ExpLambdaDeltaCubed = 1/McExp*(sum(ld.^3,2));
 GradTerm = GradTerm+(dN(c,k)-(dN(c,k)+1)*ExpLambdaDelta+ExpLambdaDeltaSq)*Hk(k,:)';
 HessianTerm=HessianTerm+(-ExpLambdaDelta*(dN(c,k)+1)+ExpLambdaDeltaSq*(dN(c,k)+3)-2*ExpLambdaDeltaCubed)*Hk(k,:)'*Hk(k,:);

 end

 end
 if(any(any(isnan(HessianTerm))) || any(any(isinf(HessianTerm))))
 gammahat_newTemp = gammahat_new(:,c);
 else
 gammahat_newTemp = (gammahat_new(:,c)-HessianTerm\GradTerm);
 if(any(isnan(gammahat_newTemp)))
 gammahat_newTemp = gammahat_new(:,c);

 end
 end
 mabsDiff = max(abs(gammahat_newTemp - gammahat_new(:,c)));
 if(mabsDiff<diffTol)
 converged=1;
 end
 gammahat_new(:,c)=gammahat_newTemp;
 iter=iter+1;
 end
 % fprintf('\n'); 
 end 
 else
 HessianTerm = zeros(size(gammahat,1),size(gammahat,1),numCells);
 GradTerm = zeros(size(gammahat,1),numCells);
 for c=1:numCells
 converged=0;
 iter = 1;
 maxIter=100;
 % fprintf(['neuron:' num2str(c) ' iter: ']);
 if(numel(gammahat_new)==1)
 gammaC=gammahat_new;
 % gammaC=repmat(gammaC,[1 numCells]);
 else 
 gammaC=gammahat_new(:,c);
 end
 while(~converged && iter<maxIter)
 % if(iter==1)
 % fprintf('%d',iter);
 % else
 % fprintf(',%d',iter);
 % end
 xkPerm = permute(xKDrawExp, [1 3 2]);
 if(strcmp(fitType,'poisson'))
 for k=1:K
 Hk = (HkAll(:,:,c));
 Wk = W_K(:,:,k);
% xk = squeeze(xKDrawExp(:,k,:));
 xk = xkPerm(:,:,k);
 % FIX (R4d): no re-orientation. Hk = HkAll(:,:,c) is already
 % (numTimeSteps x numWindows) by construction; the old
 % `size(Hk,1)==numCells` test fired when numTimeSteps == numCells
 % and then indexed Hk(k,:) on the transposed matrix.

 terms =muhat(c)+betahat(:,c)'*xk+gammaC'*Hk(k,:)';
 ld=exp(terms);
 ExpLambdaDelta = 1/McExp*sum(ld,2);
 if(k==1)
 GradTerm(:,c) = (dN(c,k) - ExpLambdaDelta)*Hk(k,:)';
 HessianTerm(:,:,c)=-ExpLambdaDelta*Hk(k,:)'*Hk(k,:);
 else
 GradTerm(:,c) = GradTerm(:,c)+(dN(c,k) - ExpLambdaDelta)*Hk(k,:)';
 HessianTerm(:,:,c)=HessianTerm(:,:,c)-ExpLambdaDelta*Hk(k,:)'*Hk(k,:);
 end
 end

 elseif(strcmp(fitType,'binomial'))
 for k=1:K
 Hk = (HkAll(:,:,c));
 Wk = W_K(:,:,k);
% xk = squeeze(xKDrawExp(:,k,:));
 xk = xkPerm(:,:,k);
 % FIX (R4d): no re-orientation. Hk = HkAll(:,:,c) is already
 % (numTimeSteps x numWindows) by construction; the old
 % `size(Hk,1)==numCells` test fired when numTimeSteps == numCells
 % and then indexed Hk(k,:) on the transposed matrix.

 terms =muhat(c)+betahat(:,c)'*xk+gammaC'*Hk(k,:)';
 ld=exp(terms)./(1+exp(terms));
 ExpLambdaDelta =1/McExp*(sum(ld,2));
 ExpLambdaDeltaSq = 1/McExp*(sum(ld.^2,2));
 ExpLambdaDeltaCubed = 1/McExp*(sum(ld.^3,2));
 if(k==1)
 GradTerm(:,c) = (dN(c,k)-(dN(c,k)+1)*ExpLambdaDelta+ExpLambdaDeltaSq)*Hk(k,:)';
 HessianTerm(:,:,c)=(-ExpLambdaDelta*(dN(c,k)+1)+ExpLambdaDeltaSq*(dN(c,k)+3)-2*ExpLambdaDeltaCubed)*Hk(k,:)'*Hk(k,:);
 else
 GradTerm(:,c) = GradTerm(:,c)+(dN(c,k)-(dN(c,k)+1)*ExpLambdaDelta+ExpLambdaDeltaSq)*Hk(k,:)';
 HessianTerm(:,:,c)=HessianTerm(:,:,c)+(-ExpLambdaDelta*(dN(c,k)+1)+ExpLambdaDeltaSq*(dN(c,k)+3)-2*ExpLambdaDeltaCubed)*Hk(k,:)'*Hk(k,:);
 end

 end

 end
 if(any(any(isnan(HessianTerm(:,:,c)))) || any(any(isinf(HessianTerm(:,:,c)))))
 gammahat_newTemp = gammaC;
 else
 gammahat_newTemp = (gammaC-HessianTerm(:,:,c)\GradTerm(:,c));
 if(any(isnan(gammahat_newTemp)))
 gammahat_newTemp = gammaC;

 end
 end
 mabsDiff = max(abs(gammahat_newTemp - gammaC));
 if(mabsDiff<diffTol)
 converged=1;
 end
 gammaC=gammahat_newTemp;
 iter=iter+1;
 end
 % FIX: was `gamma_new(:,c) = gammaC;` -- a variable that is
 % never returned, so the parallel-pool branch discarded the
 % history-coefficient update (the serial branch above writes
 % gammahat_new(:,c)).
 gammahat_new(:,c) =gammaC;
 % fprintf('\n'); 
 end 
 end
 end
 clear HessianTerm GradTerm; 
 end
 end

% function [Ahat, Qhat, muhat_new, betahat_new, gammahat_new, x0hat, Px0hat] = PP_MStep(dN,x_K,W_K,x0, ExpectationSums,fitType, muhat, betahat,gammahat, windowTimes, HkAll,MstepMethod)
% if(nargin<12 || isempty(MstepMethod))
% MstepMethod = 'GLM'; %GLM or NewtonRaphson
% end
% Sxkm1xkm1=ExpectationSums.Sxkm1xkm1;
% Sxkxkm1=ExpectationSums.Sxkxkm1;
% Sxkxk=ExpectationSums.Sxkxk;
% sumXkTerms = ExpectationSums.sumXkTerms;
% Sx0 = ExpectationSums.Sx0;
% Sx0x0 = ExpectationSums.Sx0x0;
% K = size(x_K,2); 
% numCells=size(dN,1);
% numStates = size(x_K,1);
% Ahat = Sxkxkm1/Sxkm1xkm1;
% 
% Px0hat =(Sx0x0 - x0*Sx0' - Sx0*x0' +(x0*x0'));
% 
% % [V,D] = eig(Px0hat);
% % D(D<0)=1e-9;
% % Px0hat = V*D*V';
% Px0hat = (Px0hat+Px0hat')/2;
% % Px0hat = diag(diag(Px0hat));
% x0hat = Sx0;
% 
% Qhat=1/K*sumXkTerms;
% % [V,D] = eig(Qhat);
% % D(D<=0)=1e-9;
% % Qhat = V*D*V';
% Qhat = (Qhat + Qhat')/2;
% if(det(Qhat)<=0)
% Qhat = ExpectationSums.Q; % Keep prior value
% end
% 
% 
% 
% betahat_new =betahat;
% gammahat_new = gammahat;
% muhat_new = muhat;
% 
% %Compute the new CIF beta using the GLM
% if(strcmp(fitType,'poisson'))
% algorithm = 'GLM';
% else
% algorithm = 'BNLRCG';
% end
% 
% % Estimate params via GLM
% if(strcmp(MstepMethod,'GLM'))
% clear c; close all;
% time=(0:length(x_K)-1)*.001;
% labels = cell(1,numStates);
% labels2 = cell(1,numStates+1);
% labels2{1} = 'vel';
% for i=1:numStates
% labels{i} = strcat('v',num2str(i));
% labels2{i+1} = strcat('v',num2str(i));
% end
% vel = Covariate(time,x_K','vel','time','s','m/s',labels);
% baseline = Covariate(time,ones(length(time),1),'Baseline','time','s','',...
% {'constant'});
% for i=1:size(dN,1)
% spikeTimes = time(dN(i,:)==1);
% nst{i} = nspikeTrain(spikeTimes);
% end
% nspikeColl = nstColl(nst);
% cc = CovColl({vel,baseline});
% trial = Trial(nspikeColl,cc);
% selfHist = windowTimes ; NeighborHist = []; sampleRate = 1000; 
% clear c;
% 
% 
% 
% if(gammahat==0)
% c{1} = TrialConfig({{'Baseline','constant'},labels2},sampleRate,[],NeighborHist); 
% else
% c{1} = TrialConfig({{'Baseline','constant'},labels2},sampleRate,selfHist,NeighborHist); 
% end
% c{1}.setName('Baseline');
% cfgColl= ConfigColl(c);
% warning('OFF');
% 
% results = Analysis.RunAnalysisForAllNeurons(trial,cfgColl,0,algorithm);
% temp = FitResSummary(results);
% tempCoeffs = squeeze(temp.getCoeffs);
% if(gammahat==0)
% betahat(1:numStates,:) = tempCoeffs(2:(numStates+1),:);
% muhat = tempCoeffs(1,:)';
% else
% betahat(1:numStates,:) = tempCoeffs(2:(numStates+1),:);
% muhat = tempCoeffs(1,:)';
% histTemp = squeeze(temp.getHistCoeffs);
% histTemp = reshape(histTemp, [length(windowTimes)-1 numCells]);
% histTemp(isnan(histTemp))=0;
% gammahat=histTemp;
% if(size(gammahat,2)~=size(muhat,1))
% gammahat = gammahat';
% end
% end
% else
% 
% % Estimate via Newton-Raphson
% fprintf(['****M-step for beta**** \n']);
% for c=1:numCells
% % c
% 
% 
% converged=0;
% iter = 1;
% maxIter=100;
% % disp(['M-step for beta, neuron:' num2str(c) ' iter: ' num2str(c) ' of ' num2str(maxIter)]); 
% fprintf(['neuron:' num2str(c) ' iter: ']);
% while(~converged && iter<maxIter)
% 
% if(iter==1)
% fprintf('%d',iter);
% else
% fprintf(',%d',iter);
% end
% if(strcmp(fitType,'poisson'))
% gradQ=zeros(size(betahat_new(:,c),1),1);
% jacQ =zeros(size(betahat_new(:,c),1),size(betahat_new(:,c),1));
% for k=1:K
% % Hk=HkAll{c};
% Hk = squeeze(HkAll(:,:,c));
% Wk = W_K(:,:,k);
% xk = x_K(:,k);
% if(numel(gammahat)==1)
% gammaC=gammahat;
% else 
% gammaC=gammahat(:,c);
% end
% terms =muhat(c)+betahat_new(:,c)'*xk+gammaC'*Hk(k,:)';
% ld=exp(terms);
% 
% numStates =length(xk);
% ExplambdaDeltaXk = zeros(numStates,1);
% ExplambdaDeltaXkXkT = zeros(numStates,numStates);
% for m=1:numStates
% sm = zeros(numStates,1);
% sm(m) =1;
% bt=betahat_new(:,c);
% ExplambdaDeltaXk(m) = ld*sm'*xk+...
%.5*trace(ld*(bt*xk'*sm*bt'+sm*bt'+bt*sm')*Wk);
% for n=1:m
% sn = zeros(numStates,1);
% sn(n) =1; 
% ExplambdaDeltaXkXkT(n,m) = ld*xk'*sm*sn'*xk+...
% +trace(ld*(2*bt*xk'*sn*sm'*xk*bt'+bt*xk'*sn*sm'+sn*sm'*xk*bt'+sn*sm')*Wk);
% if(n~=m)
% ExplambdaDeltaXkXkT(n,m)=ExplambdaDeltaXkXkT(m,n);
% end
% end
% end
% 
% gradQ = gradQ + (dN(c,k)*xk - ExplambdaDeltaXk);
% jacQ = jacQ - ExplambdaDeltaXkXkT;
% end
% 
% 
% elseif(strcmp(fitType,'binomial'))
% gradQ=zeros(size(betahat_new(:,c),1),1);
% jacQ =zeros(size(betahat_new(:,c),1),size(betahat_new(:,c),1));
% for k=1:K
% % Hk=HkAll{c};
% Hk = squeeze(HkAll(:,:,c));
% Wk = W_K(:,:,k);
% xk = x_K(:,k); 
% if(numel(gammahat)==1)
% gammaC=gammahat;
% else 
% gammaC=gammahat(:,c);
% end
% terms =muhat(c)+betahat_new(:,c)'*xk+gammaC'*Hk(k,:)';
% ld=exp(terms)./(1+exp(terms));
% 
% numStates =length(xk);
% ExplambdaDeltaXk = zeros(numStates,1);
% ExplambdaDeltaSqXk = zeros(numStates,1);
% ExplambdaDeltaXkXkT = zeros(numStates,numStates);
% ExplambdaDeltaSqXkXkT = zeros(numStates,numStates);
% ExplambdaDeltaCubedXkXkT = zeros(numStates,numStates);
% for m=1:numStates
% sm = zeros(numStates,1);
% sm(m) =1;
% bt=betahat_new(:,c);
% ExplambdaDeltaXk(m) = ld*sm'*xk+...
% +.5*trace(ld*(bt*xk'*sm*bt'+sm*bt'+bt*sm')*Wk)...
% -.5*trace((ld^2)*(3*bt*xk'*sm*bt'+sm*bt'+bt*sm')*Wk)...
% +.5*trace((ld^3)*(2*bt*xk'*sm*bt')*Wk);
% ExplambdaDeltaSqXk(m) = (ld)^2*sm'*xk+...
% +trace((ld^2)*(2*bt*xk'*sm*bt'+sm*bt'+bt*sm')*Wk)...
% -trace((ld^3)*(2*bt*xk'*sm*bt'+3*bt*xk'*sm*bt'+sm*bt'+bt*sm')*Wk)...
% +trace(3*(ld^4)*(bt*xk'*sm*bt')*Wk);
% 
% for n=1:m
% sn = zeros(numStates,1);
% sn(n) =1; 
% ExplambdaDeltaXkXkT(n,m) = ld*xk'*sm*sn'*xk+...
% +0.5*trace((ld)*(bt*xk'*sn*sm'*xk*bt'+2*sn*sm'*xk*bt'+2*bt*xk'*sn*sm'+2*sn*sm')*Wk)...
% -0.5*trace((ld)^2*(3*bt*xk'*sn*sm'*xk*bt'+2*sn*sm'*xk*bt'+2*bt*xk'*sn*sm')*Wk)...
% +0.5*trace((ld)^3*(2*bt*xk'*sn*sm'*xk*bt')*Wk);
% ExplambdaDeltaSqXkXkT(n,m) = (ld)^2*xk'*sm*sn'*xk+...
% +trace((ld)^2*(2*bt*xk'*sn*sm'*xk*bt'+2*sn*sm'*xk*bt'+2*bt*xk'*sn*sm'+sn*sm')*Wk)...
% -trace((ld)^3*(5*bt*xk'*sn*sm'*xk*bt'+2*sn*sm'*xk*bt'+2*bt*xk'*sn*sm')*Wk)...
% +trace((ld)^4*(3*bt*xk'*sn*sm'*xk*bt')*Wk);
% 
% ExplambdaDeltaCubedXkXkT(n,m) = (ld)^3*xk'*sm*sn'*xk+...
% +0.5*trace((ld)^3*(9*bt*xk'*sn*sm'*xk*bt'+6*sn*sm'*xk*bt'+6*bt*xk'*sn*sm'+2*sn*sm')*Wk)...
% -0.5*trace((ld)^4*(21*bt*xk'*sn*sm'*xk*bt'+6*sn*sm'*xk*bt'+6*bt*xk'*sn*sm')*Wk)...
% +0.5*trace((ld)^5*(12*bt*xk'*sn*sm'*xk*bt')*Wk);
% 
% if(n~=m)
% ExplambdaDeltaXkXkT(n,m)=ExplambdaDeltaXkXkT(m,n);
% ExplambdaDeltaSqXkXkT(n,m)=ExplambdaDeltaSqXkXkT(m,n);
% ExplambdaDeltaCubedXkXkT(n,m)=ExplambdaDeltaCubedXkXkT(m,n);
% end
% end
% end
% 
% gradQ = gradQ + dN(c,k)*x_K(:,k) - (dN(c,k)+1)*ExplambdaDeltaXk+ExplambdaDeltaSqXk;
% jacQ = jacQ + ExplambdaDeltaXkXkT+ExplambdaDeltaSqXkXkT-2*ExplambdaDeltaCubedXkXkT;
% end
% end
% 
% 
% % gradQ=0.01*gradQ;
% 
% 
% if(any(any(isnan(jacQ))) || any(any(isinf(jacQ))))
% betahat_newTemp = betahat_new(:,c);
% else
% betahat_newTemp = (betahat_new(:,c)-jacQ\gradQ);
% if(any(isnan(betahat_newTemp)))
% betahat_newTemp = betahat_new(:,c);
% 
% end
% end
% mabsDiff = max(abs(betahat_newTemp - betahat_new(:,c)));
% if(mabsDiff<10^-2)
% converged=1;
% end
% betahat_new(:,c)=betahat_newTemp;
% iter=iter+1;
% end
% fprintf('\n'); 
% end 
% 
% 
% %Compute the new CIF means
% muhat_new =muhat;
% for c=1:numCells
% converged=0;
% iter = 1;
% maxIter=100;
% while(~converged && iter<maxIter)
% if(strcmp(fitType,'poisson'))
% gradQ=zeros(size(muhat_new(c),2),1);
% jacQ =zeros(size(muhat_new(c),2),size(muhat_new(c),2));
% for k=1:K
% % Hk=HkAll{c};
% Hk = squeeze(HkAll(:,:,c));
% Wk = W_K(:,:,k);
% if(numel(gammahat)==1)
% gammaC=gammahat;
% else 
% gammaC=gammahat(:,c);
% end
% terms=muhat_new(c)+betahat(:,c)'*x_K(:,k)+gammaC'*Hk(k,:)';
% ld = exp(terms);
% bt = betahat(:,c);
% ExplambdaDelta =ld +0.5*trace(ld*bt*bt'*Wk);
% 
% 
% gradQ = gradQ + dN(c,k)' - ExplambdaDelta;
% jacQ = jacQ - ExplambdaDelta;
% end
% 
% 
% elseif(strcmp(fitType,'binomial'))
% gradQ=zeros(size(muhat_new(c),2),1);
% jacQ =zeros(size(muhat_new(c),2),size(muhat_new(c),2));
% for k=1:K
% % Hk=HkAll{c};
% Hk = squeeze(HkAll(:,:,c));
% Wk = W_K(:,:,k);
% if(numel(gammahat)==1)
% gammaC=gammahat;
% else 
% gammaC=gammahat(:,c);
% end
% terms=muhat_new(c)+betahat(:,c)'*x_K(:,k)+gammaC'*Hk(k,:)';
% ld = exp(terms)./(1+exp(terms));
% bt = betahat(:,c);
% ExplambdaDelta = ld+0.5*trace(bt*bt'*(ld)*(1-ld)*(1-2*ld)*Wk);
% ExplambdaDeltaSq = (ld)^2+...
% 0.5*trace((ld)^2*(1-ld)*(2-3*ld)*bt*bt'*Wk);
% ExplambdaDeltaCubed = (ld)^3+...
% 0.5*trace(3*(ld)^3*(3-7*ld+4*(ld)^2)*bt*bt'*Wk);
% 
% gradQ = gradQ + dN(c,k)' -(dN(c,k)+1)*ExplambdaDelta...
% +ExplambdaDeltaSq;
% jacQ = jacQ - (dN(c,k)+1)*ExplambdaDelta...
% +(dN(c,k)+3)*ExplambdaDeltaSq...
% -3*ExplambdaDeltaCubed;
% end
% 
% end
% % gradQ=0.01*gradQ;
% muhat_newTemp = (muhat_new(c)'-(1/jacQ)*gradQ)';
% if(any(isnan(muhat_newTemp)))
% muhat_newTemp = muhat_new(c);
% 
% end
% mabsDiff = max(abs(muhat_newTemp - muhat_new(c)));
% if(mabsDiff<10^-2)
% converged=1;
% end
% muhat_new(c)=muhat_newTemp;
% iter=iter+1;
% end
% 
% end
% 
% % Compute the history parameters
% gammahat_new = gammahat;
% if(~isempty(windowTimes) && any(any(gammahat_new~=0)))
% for c=1:numCells
% converged=0;
% iter = 1;
% maxIter=100;
% while(~converged && iter<maxIter)
% if(strcmp(fitType,'poisson'))
% gradQ=zeros(size(gammahat_new(c),2),1);
% jacQ =zeros(size(gammahat_new(c),2),size(gammahat_new(c),2));
% for k=1:K
% % Hk=HkAll{c};
% Hk = squeeze(HkAll(:,:,c));
% Wk = W_K(:,:,k);
% if(numel(gammahat)==1)
% gammaC=gammahat;
% else 
% gammaC=gammahat(:,c);
% end
% terms=muhat_new(c)+betahat(:,c)'*x_K(:,k)+gammaC'*Hk(k,:)';
% ld = exp(terms);
% bt = betahat(:,c);
% ExplambdaDelta =ld +0.5*trace(bt*bt'*ld*Wk);
% 
% 
% gradQ = gradQ + (dN(c,k)' - ExplambdaDelta)*Hk;
% jacQ = jacQ - ExplambdaDelta*Hk*Hk';
% end
% 
% 
% elseif(strcmp(fitType,'binomial'))
% gradQ=zeros(size(gammahat_new(c),2),1);
% jacQ =zeros(size(gammahat_new(c),2),size(gammahat_new(c),2));
% for k=1:K
% % Hk=HkAll{c};
% Hk = squeeze(HkAll(:,:,c));
% Wk = W_K(:,:,k);
% if(numel(gammahat)==1)
% gammaC=gammahat;
% else 
% gammaC=gammahat(:,c);
% end
% terms=muhat_new(c)+betahat(:,c)'*x_K(:,k)+gammaC'*Hk(k,:)';
% ld = exp(terms)./(1+exp(terms));
% bt = betahat(:,c);
% ExplambdaDelta =ld...
% +0.5*trace(bt*bt'*ld*(1-ld)*(1-2*ld)*Wk);
% ExplambdaDeltaSq=ld^2...
% +trace((ld^2*(1-ld)*(2-3*ld)*bt*bt')*Wk);
% ExplambdaDeltaCubed=ld^3...
% +0.5*trace((9*(ld^3)*(1-ld)^2*bt*bt'-3*(ld^4)*(1-ld)*bt*bt')*Wk);
% gradQ = gradQ + (dN(c,k) - (dN(c,k)+1)*ExplambdaDelta+ExplambdaDeltaSq)*Hk;
% jacQ = jacQ + -ExplambdaDelta*(dN(c,k)+1)*Hk*Hk'...
% +ExplambdaDeltaSq*(dN(c,k)+3)*Hk*Hk'...
% -ExplambdaDeltaCubed*2*Hk*Hk';
% end
% 
% end
% 
% 
% % gradQ=0.01*gradQ;
% 
% gammahat_newTemp = (gammahat_new(:,c)-(eye(size(Hk,2),size(Hk,2))/jacQ)*gradQ');
% if(any(isnan(gammahat_newTemp)))
% gammahat_newTemp = gammahat_new(:,c);
% 
% end
% mabsDiff = max(abs(gammahat_newTemp - gammahat_new(:,c)));
% if(mabsDiff<10^-2)
% converged=1;
% end
% gammahat_new(:,c)=gammahat_newTemp;
% iter=iter+1;
% end
% 
% end
% % gammahat(:,c) = gammahat_new;
% end
% % betahat =betahat_new;
% % gammahat = gammahat_new;
% % muhat = muhat_new;
% end
% end
 end

 methods (Static, Access = {?nstat.decoding.PointProcessEM, ?nstat.decoding.KF_EM, ?matlab.unittest.TestCase})
 % FIX (KF track M, item C1): KF_EM has the identical upper-factor
 % Monte Carlo draw defect (F9). Access is extended to KF_EM rather
 % than duplicating the helper.
 function X = mcStateDraws(m, W, M)
 %MCSTATEDRAWS M Monte Carlo draws from N(m, W), returned as dx x M.
 % X = mcStateDraws(m, W, M) with m (dx x 1), W (dx x dx).
 % FIX (F9): every Monte Carlo draw in this class was made as
 % [chol_m,p] = chol(W); z = normrnd(0,1,dx,M); x = m + chol_m*z.
 % MATLAB's chol returns the UPPER factor R with R'*R = W, so R*z
 % has covariance R*R', which equals W only for a diagonal W (or
 % dx == 1): the draws had the wrong covariance whenever the
 % smoothed state covariance was not diagonal. The draw is
 % x = m + R'*z (cov R'*R = W). Kept as before: z is drawn with
 % normrnd(0,1,dx,M) (same random stream; diagonal-W draws are
 % bit-identical), the factor comes from the two-output chol of the
 % same (upper) triangle, and a W that is not positive definite
 % still errors (partial factor -> dimension mismatch) rather than
 % being silently repaired. Access is limited to this class and
 % unit tests; it is not part of the public API.
 [R,~] = chol(W);
 z = normrnd(0,1,numel(m),M);
 X = repmat(m(:),[1 M]) + R'*z;
 end
 end

 methods (Static, Access = {?nstat.decoding.PointProcessEM, ?nstat.decoding.PPLFP, ?matlab.unittest.TestCase})
 function [invIObs, nonIdentifiable] = seObservedInfoInverse(IObs, labels, routine)
 %SEOBSERVEDINFOINVERSE Covariance (projected inverse observed information)
 % for the EM SE routines: nearestSPD of the inverse, as before.
 % [invIObs, nonIdentifiable] = seObservedInfoInverse(IObs, labels, routine)
 % FIX (#136): the SE routines computed invIObs = eye(size(IObs))/IObs
 % and then nearestSPD(invIObs). When IObs is exactly singular (an
 % LU zero pivot) eye/IObs is Inf/NaN, and nearestSPD's
 % "while p ~= 0" loop never ends on a NaN matrix (chol keeps
 % failing, eig returns NaN), so PP_EM / PPLFP_EM never returned when
 % SEs were requested. The usual cause is a separated history window
 % (no spike in it is followed by a spike): the Newton steps walk its
 % coefficient to the exp() underflow, where its information and score
 % are exactly 0.
 % Now:
 % * no zero pivot -> exactly the old eye(size(IObs))/IObs (all
 % previously returned values are unchanged);
 % * a zero pivot -> the pseudo-inverse (singular values at or below
 % 1e-15 x the largest dropped). A parameter whose unit vector has a
 % component larger than sqrt(eps) in the dropped null space is not
 % identifiable (the log-likelihood is flat along it): it is flagged
 % in nonIdentifiable and the caller reports its SE and p-value as
 % NaN. A warning (nSTAT:EM:singularInformation) names them;
 % * a non-finite IObs or inverse -> an error
 % (nSTAT:EM:nonFiniteInformation) instead of looping.
 % The result is then projected with nearestSPD, as before. In the
 % singular case only the identifiable block is projected: the
 % pseudo-inverse is singular there, and nearestSPD does not return on
 % a singular matrix either (when chol fails while min(eig) is a tiny
 % positive rounding value, its shift -mineig*k^2 + eps(mineig) is
 % negative and the loop never ends). The flagged rows and columns
 % are left as they are; their SEs are reported as NaN.
 % This matches the Python port (nstat-python
 % _em_singular_information_inverse). Access is limited to the EM
 % classes and unit tests; it is not part of the public API.
 n = size(IObs,1);
 nonIdentifiable = false(n,1);
 if ~all(isfinite(IObs(:)))
 error('nSTAT:EM:nonFiniteInformation', ...
 '%s: the observed information matrix is not finite; standard errors cannot be computed.', routine);
 end
 [~,U] = lu(IObs);
 if all(diag(U) ~= 0)
 invIObs = eye(size(IObs))/IObs;
 else
 [Us,S,V] = svd(IObs);
 s = diag(S);
 keep = s > 1e-15*max(s);
 invIObs = V(:,keep)*diag(1./s(keep))*Us(:,keep)';
 weight = sqrt(sum(V(:,~keep).^2,2));
 nonIdentifiable = weight > sqrt(eps);
 msg = sprintf(['%s: the observed information matrix is singular; the standard errors ' ...
 'come from its pseudo-inverse.'], routine);
 idx = find(nonIdentifiable);
 if ~isempty(idx)
 names = cell(1,numel(idx));
 for k = 1:numel(idx)
 if idx(k) <= numel(labels)
 names{k} = labels{idx(k)};
 else
 names{k} = sprintf('term %d', idx(k));
 end
 end
 msg = [msg sprintf([' Not identifiable from the data, SE and p-value set to NaN: %s. ' ...
 'The log-likelihood is flat along them; a history coefficient is not identifiable ' ...
 'when no spike in its window is followed by a spike (a separated window).'], ...
 strjoin(names, ', '))];
 end
 warning('nSTAT:EM:singularInformation', '%s', msg);
 end
 if ~all(isfinite(invIObs(:)))
 error('nSTAT:EM:nonFiniteInformation', ...
 '%s: the inverse observed information is not finite; standard errors cannot be computed.', routine);
 end
 if any(nonIdentifiable)
 keep = ~nonIdentifiable;
 if any(keep)
 invIObs(keep,keep) = nearestSPD(invIObs(keep,keep));
 end
 else
 invIObs = nearestSPD(invIObs); % Find the nearest positive semidefinite approximation for the variance matrix
 end
 end

 function labels = seTermLabels(groups)
 %SETERMLABELS Names of the entries of an EM routine's stacked SE vector.
 % groups is an n x 4 cell {name, nTerms, shape, layout} in stacking
 % order; layout is 'square' (rows*cols row by row, rows = its
 % diagonal, 1 = isotropic), 'rowmajor', 'cellmajor' (states- or
 % windows-by-cells, one cell's column after another) or 'vector'.
 labels = {};
 for g = 1:size(groups,1)
 name = groups{g,1}; n = groups{g,2}; shp = [groups{g,3}(:)' 1 1]; layout = groups{g,4};
 if n <= 0
 continue;
 end
 r = shp(1); c = shp(2);
 if strcmp(layout,'vector') && n == r
 for i = 1:r, labels{end+1} = sprintf('%s(%d)',name,i); end %#ok<AGROW>
 elseif strcmp(layout,'cellmajor') && n == r*c
 for j = 1:c, for i = 1:r, labels{end+1} = sprintf('%s(%d,%d)',name,i,j); end, end %#ok<AGROW>
 elseif any(strcmp(layout,{'square','rowmajor'})) && n == r*c
 for i = 1:r, for j = 1:c, labels{end+1} = sprintf('%s(%d,%d)',name,i,j); end, end %#ok<AGROW>
 elseif strcmp(layout,'square') && n == r
 for i = 1:r, labels{end+1} = sprintf('%s(%d,%d)',name,i,i); end %#ok<AGROW>
 elseif strcmp(layout,'square') && n == 1
 labels{end+1} = sprintf('%s (isotropic)',name); %#ok<AGROW>
 else
 for k = 1:n, labels{end+1} = sprintf('%s term %d',name,k); end %#ok<AGROW>
 end
 end
 end
 end
end

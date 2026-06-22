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
 %By default, all parameters are estimated. To empose diagonal
 %structure on the EM parameter results must pass in the
 %constraints element
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
 EstimatePx0=1;
 end
 if(nargin<5 || isempty(Estimatex0))
 Estimatex0=1;
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

 if(nargin<19 || isempty(PPEM_Constraints))
 PPEM_Constraints=nstat.decoding.PointProcessEM.PP_EMCreateConstraints;
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
 termMat= N/2*(Qhat)\em(:,m)*el(:,l)'/(Qhat);
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
 termMat= N/2*(Qhat)\em(:,m)*el(:,l)'/(Qhat);
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
 termMat= 1/2*(Px0hat)\em(:,m)*el(:,l)'/(Px0hat);
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
 WuTemp=squeeze(WKFinal(:,:,k));
 [chol_m,p]=chol(WuTemp);
 z=normrnd(0,1,size(xKFinal,1),McExp);
 xKDrawExp(:,k,:)=repmat(xKFinal(:,k),[1 McExp])+(chol_m*z);
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
 if(size(Hk,1)==numCells)
 Hk = Hk';
 end
 
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
 if(size(Hk,1)==numCells)
 Hk = Hk';
 end
 
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
 HessianTerm(:,:,k) = ExplambdaDeltaXkXk + ExplambdaDeltaSqXkXkT - 2*ExplambdaDeltaCubeXkXkT;
 
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
 if(size(Hk,1)==numCells)
 Hk = Hk';
 end
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
 if(size(Hk,1)==numCells)
 Hk = Hk';
 end
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
 HessianTerm = HessianTerm -(dN(c,k)+1)*ExplambdaDelta...
 +(dN(c,k)+3)*ExplambdaDeltaSquare-3*ExplambdaDeltaCubed;
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
 if(size(Hk,1)==numCells)
 Hk = Hk';
 end
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
 if(size(Hk,1)==numCells)
 Hk = Hk';
 end
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
 HessianTerm(k) = -(dN(c,k)+1)*ExplambdaDelta...
 +(dN(c,k)+3)*ExplambdaDeltaSquare-3*ExplambdaDeltaCubed;
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
 if(size(Hk,1)==numCells)
 Hk = Hk';
 end
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
 if(size(Hk,1)==numCells)
 Hk = Hk';
 end
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
 HessianTerm=HessianTerm+(-ExplambdaDelta*(dN(c,k)+1)...
 +ExplambdaDeltaSquare*(dN(c,k)+3)...
 -2*ExplambdaDeltaCubed)*Hk(k,:)'*Hk(:,k);
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
 if(size(Hk,1)==numCells)
 Hk = Hk';
 end
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
 if(size(Hk,1)==numCells)
 Hk = Hk';
 end
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
 WuTemp=(WKFinal(:,:,n));
 [chol_m,p]=chol(WuTemp);
 z=normrnd(0,1,size(xKFinal,1),Mc);
 xKDraw(:,n,:)=repmat(xKFinal(:,n),[1 Mc])+(chol_m*z);
 end

 if(PPEM_Constraints.EstimatePx0|| PPEM_Constraints.Estimatex0)
 [chol_m,p]=chol(Px0hat);
 z=normrnd(0,1,size(xKFinal,1),Mc);
 x0Draw=repmat(x0hat,[1 Mc])+(chol_m*z); 
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
 invIObs = eye(size(IObs))/IObs;
% figure(1); subplot(1,2,1); imagesc(invIObs); subplot(1,2,2); imagesc(nearestSPD(invIObs));
 invIObs = nearestSPD(invIObs); % Find the nearest positive semidefinite approximation for the variance matrix
 VarVec = (diag(invIObs));
 SEVec = sqrt(VarVec);
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
 SEBeta=reshape(SEBetaTerms,size(betahat,2),size(betahat,1))';

 SE.mu = SEMu;
 SE.beta = SEBeta;
 if((numel(gammahat)==1 && gammahat~=0) || numel(gammahat)>1)
 SEGamma=reshape(SEGammaTerms,size(gammahat,2),size(gammahat,1))';
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
 numStates = size(Ahat0,1);
 if(nargin<13 || isempty(MstepMethod))
 MstepMethod='GLM'; %or NewtonRaphson 
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
 if(isempty(gamma))
 windowTimes =[];
 else
 % numWindows =length(gamma0)+1; 
 windowTimes = 0:delta:(length(gamma)+1)*delta;
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
 
 minTime=0;
 maxTime=(size(dN,2)-1)*delta;
 K=size(dN,1);
 if(~isempty(windowTimes))
 histObj = History(windowTimes,minTime,maxTime);
 for k=1:K
 nst{k} = nspikeTrain( (find(dN(k,:)==1)-1)*delta);
 nst{k}.setMinTime(minTime);
 nst{k}.setMaxTime(maxTime);
% HkAll{k} = histObj.computeHistory(nst{k}).dataToMatrix;
 HkAll(:,:,k) = histObj.computeHistory(nst{k}).dataToMatrix;
 end
 else
 for k=1:K
% HkAll{k} = 0;
 HkAll(:,:,k) = 0;
 end
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
 Tq = eye(size(Qhat{1}))/(chol(Qhat{1}));
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
 
 [Ahat{storeIndP1}, Qhat{storeIndP1}, muhat{storeIndP1}, betahat{storeIndP1}, gammahat{storeIndP1},x0hat{storeIndP1},Px0hat{storeIndP1}]...
 = nstat.decoding.PointProcessEM.PP_MStep(dN,x_K{storeInd},W_K{storeInd},x0hat{storeInd}, Px0hat{storeInd}, ExpectationSums{storeInd}, fitType,muhat{storeInd},betahat{storeInd}, gammahat{storeInd},windowTimes,HkAll,PPEM_Constraints,MstepMethod);
 
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
 = nstat.decoding.PointProcessEM.PP_MStep(dNNew,x_KNew,W_KNew, x0hat{storeInd}, Px0hat{storeInd}, ExpectationSumsNew, fitType,muhat{storeInd},betahat{storeInd}, gammahat{storeInd},windowTimes,HkAll,PPEM_Constraints,MstepMethod);
 
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

 maxLLIndex = find(ll == max(ll),1,'first');
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
 Tq = eye(size(Qhat))/(chol(Q0));
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
 [SE, Pvals]=nstat.decoding.PointProcessEM.PP_ComputeParamStandardErrors(dN,...
 xKFinal, WKFinal, Ahat, Qhat, x0hat, Px0hat, ExpectationSumsFinal,...
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
 llobs = ll + Dx*K/2*log(2*pi)+K/2*log(det(Qhat))...
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
 IC.llcomp=ll;
 
 
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
 if(size(Hk,1)==numCells)
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
 if(size(Hk,1)==numCells)
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
 function [Ahat, Qhat, muhat_new, betahat_new, gammahat_new, x0hat, Px0hat] = PP_MStep(dN, x_K,W_K,x0, Px0, ExpectationSums,fitType, muhat, betahat,gammahat, windowTimes, HkAll,PPEM_Constraints,MstepMethod)
 if(nargin<14 || isempty(MstepMethod))
 MstepMethod = 'GLM'; %GLM or NewtonRaphson
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
 clear c; close all;
 time=(0:length(x_K)-1)*.001;
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
 nst{i} = nspikeTrain(spikeTimes);
 end
 nspikeColl = nstColl(nst);
 cc = CovColl({vel,baseline});
 trial = Trial(nspikeColl,cc);
 selfHist = windowTimes ; NeighborHist = []; sampleRate = 1000; 
 clear c;
 
 

 if(gammahat==0)
 c{1} = TrialConfig({{'Baseline','constant'},labels2},sampleRate,[],NeighborHist); 
 else
 c{1} = TrialConfig({{'Baseline','constant'},labels2},sampleRate,selfHist,NeighborHist); 
 end
 c{1}.setName('Baseline');
 cfgColl= ConfigColl(c);
 warning('OFF');

 results = Analysis.RunAnalysisForAllNeurons(trial,cfgColl,0,algorithm);
 temp = FitResSummary(results);
 tempCoeffs = squeeze(temp.getCoeffs);
 if(gammahat==0)
 betahat(1:dx,:) = tempCoeffs(2:(dx+1),:);
 muhat = tempCoeffs(1,:)';
 else
 betahat(1:dx,:) = tempCoeffs(2:(dx+1),:);
 muhat = tempCoeffs(1,:)';
 histTemp = squeeze(temp.getHistCoeffs);
 histTemp = reshape(histTemp, [length(windowTimes)-1 numCells]);
 histTemp(isnan(histTemp))=0;
 gammahat=histTemp;
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
 WuTemp=(W_K(:,:,k));
 [chol_m,p]=chol(WuTemp);
 z=normrnd(0,1,size(x_K,1),McExp);
 xKDrawExp(:,k,:)=repmat(x_K(:,k),[1 McExp])+(chol_m*z);
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
 xkPerm = permute(xKDraw,[2 3 1]);
 for k=1:K
 Hk = (HkAll(:,:,c));
 Wk = W_K(:,:,k);
% xk = squeeze(xKDrawExp(:,k,:));
 xk = xkPerm(:,:,k);
 if(size(Hk,1)==numCells)
 Hk = Hk';
 end

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
 xkPerm = permute(xKDraw,[1 3 2]);
 for k=1:K
 Hk = (HkAll(:,:,c));
 Wk = W_K(:,:,k);
% xk = squeeze(xKDrawExp(:,k,:));
 xk = xkPerm(:,:,k);
 if(size(Hk,1)==numCells)
 Hk = Hk';
 end

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
 HessianTerm=HessianTerm+ExplambdaDeltaXkXk+ExplambdaDeltaSqXkXkT-2*ExplambdaDeltaCubeXkXkT;

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
 if(size(Hk,1)==numCells)
 Hk = Hk';
 end

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
 xk=xKDrawExp(:,:,k);
 if(size(Hk,1)==numCells)
 Hk = Hk';
 end

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
 if(k==1)
 GradTerm(:,c) = dN(c,k)*x_K(:,k) - (dN(c,k)+1)*ExpLambdaXk+ExpLambdaSquaredXk;
 HessianTerm(:,:,c)=ExplambdaDeltaXkXk+ExplambdaDeltaSqXkXkT-2*ExplambdaDeltaCubeXkXkT;
 else
 GradTerm(:,c) = GradTerm(:,c)+dN(c,k)*x_K(:,k) - (dN(c,k)+1)*ExpLambdaXk+ExpLambdaSquaredXk;
 HessianTerm(:,:,c)=HessianTerm(:,:,c)+ExplambdaDeltaXkXk+ExplambdaDeltaSqXkXkT-2*ExplambdaDeltaCubeXkXkT;
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
 if(size(Hk,1)==numCells)
 Hk = Hk';
 end

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
 if(size(Hk,1)==numCells)
 Hk = Hk';
 end

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
 if(size(Hk,1)==numCells)
 Hk = Hk';
 end

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
 if(size(Hk,1)==numCells)
 Hk = Hk';
 end

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
 if(size(Hk,1)==numCells)
 Hk = Hk';
 end

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
 if(size(Hk,1)==numCells)
 Hk = Hk';
 end

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
 if(size(Hk,1)==numCells)
 Hk = Hk';
 end

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
 if(size(Hk,1)==numCells)
 Hk = Hk';
 end

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
 gamma_new(:,c) =gammaC;
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
end

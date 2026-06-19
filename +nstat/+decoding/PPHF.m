classdef PPHF
 %PPHF Point-process hybrid filter (Srinivasan, Eden, Mitter & Brown 2007).
 %
 % Joint discrete + continuous state estimator: a discrete Markov state
 % s_k indexes a bank of linear-Gaussian dynamics for a continuous state
 % x_k, all observed through Poisson spike counts. The posterior is a
 % Gaussian mixture (one component per discrete state) collapsed by
 % Bayes rule at each step.
 %
 % Extracted from DecodingAlgorithms.m (Phase 3 Task 3.2 Step D of the
 % 2026-05-19 nSTAT review action plan). DecodingAlgorithms.PPHybridFilter
 % and PPHybridFilterLinear are now thin deprecation shims that forward
 % here.
 %
 % Static methods:
 % PPHybridFilterLinear - Hybrid filter for canonical-link linear CIF.
 % PPHybridFilter - Hybrid filter for general (symbolic) CIF.
 %
 % Refs: Srinivasan, Eden, Mitter & Brown 2007, Neural Comput 19:1490-1518;
 %.B.8 PPHF derivation;
 %.C.3 Srinivasan derivation.

 methods (Static)
 %% Point Process Hybrid Filter
 function [S_est, X, W, MU_u, X_s, W_s,pNGivenS]= PPHybridFilterLinear(A, Q, p_ij,Mu0, dN,mu,beta,fitType,binwidth,gamma,windowTimes,x0,Pi0, yT,PiT,estimateTarget,MinClassificationError)

 % General-purpose filter design for neural prosthetic devices.
 % Srinivasan L, Eden UT, Mitter SK, Brown EN.
 % J Neurophysiol. 2007 Oct;98(4):2456-75. Epub 2007 May 23.

 [C,N] = size(dN); % N time samples, C cells
 nmodels = length(A);
 for s=1:nmodels
 ns(s)=size(A{s},1); % number of states
 end
 nsMax = max(ns);
 if(nargin<17 || isempty(MinClassificationError))
 MinClassificationError=0; %0: chooses the most probable discrete state estimate and take the
 % probability weighted average
 % of the continous states. This
 % is the approximate MMSE
 % filter.
 %1: takes the most likely discrete state estimate and also the 
 % continuous states
 % corresponding to the most
 % likely discrete state model.
 % This is approximately the
 % Maximum Likelihood Filter
 end
 if(nargin<16 || isempty(estimateTarget))
 estimateTarget=0;
 end

 if(nargin<15 || isempty(PiT))
 for s=1:nmodels
 if(estimateTarget==1)
 PiT{s} = zeros(size(Q{s}));
 else
 PiT{s} = 0*diag(ones(ns(s),1))*1e-6;
 end
 end
 end
 if(nargin<13 || isempty(Pi0))
 for s=1:nmodels
 Pi0{s}(:,:) = zeros(ns(s),ns(s));
 end
 end
 if(nargin<14 || isempty(yT))
 for s=1:nmodels
 yT{s}=[];
 Amat{s} = A{s};
 Qmat{s} = Q{s};
 ft{s} = zeros(size(Amat{s},2),N);
 PiT{s} = zeros(size(Q{s}));
 betaNew{s} = beta;
 end
 beta = betaNew;
 else
 Pi0new=cell(1,nmodels);
 for s=1:nmodels

 PitT{s}= zeros(ns(s),ns(s),N); % Pi(t,T) in Srinivasan et al. 
 QT{s} = zeros(ns(s),ns(s),N); % The noise covaraince given target observation (Q_t)
 if(estimateTarget==1)
 PitT{s}(:,:,N)=Q{s}; % Pi(T,T)=Pi_T + Q_T, setting PiT=0
 else
 PitT{s}(:,:,N)=PiT{s}+Q{s};
 end
 PhitT{s} = zeros(ns(s),ns(s),N);% phi(t,T) - transition matrix from time T to t
 % PhiTt = zeros(ns,ns,N);% phi(T,t) - transition matrix from time t to T
 PhitT{s}(:,:,N) = eye(ns(s),ns(s)); % phi(T,T) = I
 B{s} = zeros(ns(s),ns(s),N); % See Equation 2.21 in Srinivasan et. al

 for n=N:-1:2
 if(rcond(A{s})<1000*eps)
 invA=pinv(A{s});
 else
 invA=eye(size(A{s}))/A{s};
 end
 % state transition matrix
 PhitT{s}(:,:,n-1)= invA*PhitT{s}(:,:,n);
 % PhiTt(:,:,n)= A^(N-n);

 % Equation 2.16 in Srinivasan et al. Note there is a typo in the paper. 
 % This is the correct expression. The term Q_t-1 does not
 % need to be mulitplied by phi(t-1,t)

 PitT{s}(:,:,n-1) = invA*PitT{s}(:,:,n)*invA'+Q{s};

 if(n<=N)
 B{s}(:,:,n) = A{s}-(Q{s}*pinv(PitT{s}(:,:,n)))*A{s}; %Equation 2.21 in Srinivasan et. al
 QT{s}(:,:,n) = Q{s}-(Q{s}*pinv(PitT{s}(:,:,n)))*Q{s}';
 end
 end
 % PhiTt(:,:,1)= A^(N-1);
 B{s}(:,:,1) = A{s}-(Q{s}*pinv(PitT{s}(:,:,1)))*A{s};
 QT{s}(:,:,1) = Q{s}-(Q{s}*pinv(PitT{s}(:,:,1)))*Q{s}';
 betaNew{s} = beta;
 % See Equations 2.23 through 2.26 in Srinivasan et. al
 if(estimateTarget==1)

 betaNew{s} = [beta ;zeros(ns(s),C)];
 for n=1:N
 psi = B{s}(:,:,n);
 if(n==N)
 gammaMat = eye(ns(s),ns(s));
 else
 gammaMat = (Q{s}*pinv(PitT{s}(:,:,n)))*PhitT{s}(:,:,n);
 end
 Amat{s}(:,:,n) = [psi,gammaMat;
 zeros(ns(s),ns(s)), eye(ns(s),ns(s))];
 % if(n>1)
 % tUnc(:,:,n) = tUnc(:,:,n-1)+PhiTt(:,:,n)*Q*PhiTt(:,:,n)';
 % else
 % tUnc(:,:,n) = PhiTt(:,:,n)*Q*PhiTt(:,:,n)'; 
 % end
 Qmat{s}(:,:,n) = [QT{s}(:,:,n), zeros(ns(s),ns(s));
 zeros(ns(s),ns(s)) zeros(ns(s),ns(s))]; 

 end

 Pi0new{s} = [Pi0{s}, zeros(ns(s),ns(s));
 zeros(ns(s),ns(s)) zeros(ns(s),ns(s))]; 

 else

 Amat{s} = B{s};
 Qmat{s} = QT{s};
 for n=1:N
 ft{s}(:,n) = (Q{s}*pinv(PitT{s}(:,:,n)))*PhitT{s}(:,:,n)*yT{s};
 end

 end

 end
 if(estimateTarget==1)
 Pi0 = Pi0new;

 end
 beta = betaNew;
 end

 if(nargin<12 || isempty(x0))
 for s=1:nmodels
 x0{s}=zeros(size(Amat{s},2),1);
 end
 end

 if(nargin<9)
 binwidth=0.001; %1 msec
 end

 if(isa(A,'cell'))
 dimMat = zeros(1,length(Amat));
 X_u = cell(1,length(Amat));
 W_u = cell(1,length(Amat));
 X_p = cell(1,length(Amat));
 W_p = cell(1,length(Amat));
 ind = cell(1,length(Amat));
 ut = cell(1,length(Amat));

 for i=1:length(Amat)
 lambdaDeltaMat{i} = zeros(size(dN));
 X_u{i} = zeros(size(Amat{i},1), size(dN,2));
 X_p{i} = zeros(size(Amat{i},1), size(dN,2)+1);
 W_u{i} = zeros(size(Amat{i},1), size(Amat{i},1), size(dN,2));
 W_p{i} = zeros(size(Amat{i},1), size(Amat{i},1), size(dN,2)+1);
 dimMat(i) = size(Amat{i},2);
 W_u{i}(:,:,1) =Pi0{i};
 ind{i} = 1:dimMat(i);
 ut{i} = zeros(size(Amat{i},1), size(dN,2));
 end
 end

 maxDim = max(dimMat);
 % nmodels = length(Amat);
 % lambdaCIFColl = CIFColl(lambda);

 minTime=0;
 maxTime=(size(dN,2)-1)*binwidth;

 C=size(dN,1);

 if(nargin<11 || isempty(windowTimes))
 for c=1:C
 HkAll(:,:,c) = zeros(N,1);
 gammaNew(c)=0;
 end
 gamma=gammaNew;
 else
 histObj = History(windowTimes,minTime,maxTime);
 for c=1:C
 nst{c} = nspikeTrain( (find(dN(c,:)==1)-1)*binwidth);
 nst{c}.setMinTime(minTime);
 nst{c}.setMaxTime(maxTime);
 nst{c}=nst{c}.resample(1/delta);
 HkAll(:,:,c) = histObj.computeHistory(nst{c}).dataToMatrix;
 end
 if(size(gamma,2)==1 && C>1) % if more than 1 cell but only 1 gamma
 gammaNew(:,c) = gamma;
 end
 gamma = gammaNew;

 end
 % Overall estimates of Hybrid filter
 X = zeros(maxDim, size(dN,2)); % Estimated Trajectories
 W = zeros(maxDim, maxDim, size(dN,2)); % Covariance of estimate
 % Individual Model Estimates
 for i=1:nmodels
 X_s{i} = X; % Individual Model Estimates
 W_s{i} = W; % Individual Model Covariances
 end
 % Model probabilities 
 MU_u = zeros(nmodels,size(dN,2)); % P(s_k | H_k+1) % updated state probabilities
 MU_p = zeros(nmodels,size(dN,2)); % P(s_k | H_k) % prediction state probabilities
 pNGivenS = zeros(nmodels,size(dN,2));

 %mu_0|1 = mu_0|0;
 if(isempty(Mu0))
 Mu0 = ones(nmodels,1)*1/nmodels;
 elseif(size(Mu0,1)==nmodels && size(Mu0,2)==1)
 Mu0 = Mu0;
 elseif(size(Mu0,1)==1 && size(Mu0,2)==nmodels)
 Mu0 = Mu0';
 else
 error('Mu0 must be a column or row vector with the same number of dimensions as the number of states');
 end

 % Fuse initial state prior with terminal constraint for each
 % model, matching PPDecodeFilterLinear (Srinivasan et al. Eq. 2.23).
 % This was missing from PPHybridFilterLinear since the original
 % 2013 implementation and caused the goal-directed filter to
 % underperform because x0/Pi0 never incorporated target info.
 for s=1:nmodels
 if(~isempty(yT) && ~isempty(yT{s}) && estimateTarget==0)
 Pi0s = Pi0{s}(ind{s},ind{s});
 x0s = x0{s}(ind{s});
 if(det(Pi0s)~=0)
 invPi0s = pinv(Pi0s);
 invPitTs = pinv(PitT{s}(:,:,1));
 Pi0New = pinv(invPi0s + invPitTs);
 Pi0New(isnan(Pi0New)) = 0;
 x0New = Pi0New*(invPi0s*x0s + invPitTs*PhitT{s}(:,:,1)*yT{s});
 x0{s}(ind{s}) = x0New;
 Pi0{s}(ind{s},ind{s}) = Pi0New;
 W_u{s}(ind{s},ind{s},1) = Pi0New;
 end
 end
 end

 for s=1:nmodels
 [X_p{s}(ind{s},1),W_p{s}(ind{s},ind{s},1)] = nstat.decoding.PPAF.PPDecode_predict(x0{s}(ind{s}), Pi0{s}(ind{s},ind{s}), Amat{s}(ind{s},ind{s},min(size(Amat{s},3),1)), Qmat{s}(:,:,min(size(Qmat{s},3),1)));

 if((estimateTarget==0 && ~isempty(yT{s})))
 invA= pinv(Amat{s}(:,:,min(size(Amat{s},3),1)));
 ut{s}(:,1) = (Q{s}*pinv(PitT{s}(:,:,1)))*PhitT{s}(:,:,1)*(yT{s}-pinv(invA*PhitT{s}(:,:,1))*x0{s});
 X_p{s}(ind{s},1) = X_p{s}(ind{s},1)+ut{s}(:,1);
 W_p{s}(ind{s},ind{s},1) =W_p{s}(ind{s},ind{s},1) + (Q{s}*pinv(PitT{s}(:,:,1)))*A{s}*Pi0{s}*A{s}'*(Q{s}*pinv(PitT{s}(:,:,1)))';
 end
 end

 % [~, S_est(1)] = max(MU_p(:,1)); %Most likely current state

 %State transition Probabilities must integrate to 1
 sumVal = sum(p_ij,2);
 if(any(sumVal~=1))
 error('State Transition probability matrix must sum to 1 along each row');
 end
 %% 9 Steps
 % Filtering steps.
 HkPerm=permute(HkAll,[2 3 1]);
 for k = 1:(size(dN,2))

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Step 1 - p(s_k | H_k) = Sum(p(s_k|s_k-1)*p(s_k-1|H_k))
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %MU(:,k)_p= [ p(s_k=1 | H_k)] is a vector of the probabilities
 % [ p(s_k=2 | H_k)]
 %.
 %.
 %.
 % [ p(s_k=N | H_k)]
 % thus it is an prediction of the discrete state at time k given all
 % of the neural firing up to k-1 as summarized in H_k
 %
 % Whereas 
 % MU_u(:,k)=[ p(s_k=1 | H_k+1)] is a vector of the probabilities
 % [ p(s_k=2 | H_k+1)]
 %.
 %.
 %.
 % [ p(s_k=N | H_k+1)]
 % The s suffix indicates that this is a "smoothed" estimate of
 % the state given the firing up to time k summarized in H_k+1
 if k==1
 MU_p(:,k) = p_ij'*Mu0; %state probability prediction equation
 else
 MU_p(:,k) = p_ij'*MU_u(:,k-1); 
 end

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Step 2 - p(s_k-1 | s_k, H_k)
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % This is a matrix with i,j entry indicating the probability that 
 % s_k-1 = j given than s_k = i
 %
 % MU_p is the normalization factor. The first column of the
 % matrix of probabilities is:
 %
 % P(s_k-1=1 | s_k=1,H_k) ~ P(s_k=1|s_k-1=1,H_k)*P(s_k-1=1|H_k)
 % P(s_k-1=1 | s_k=2,H_k) ~ P(s_k=2|s_k-1=1,H_k)*P(s_k-1=1|H_k)
 % 
 % And the second columns... etc
 %
 % 
 % P(s_k-1=2 | s_k=1,H_k) ~ P(s_k=1|s_k-1=2,H_k)*P(s_k-1=1|H_k)
 % P(s_k-1=2 | s_k=2,H_k) ~ P(s_k=2|s_k-1=2,H_k)*P(s_k-1=1|H_k)

 if(k==1)
 p_ij_s= p_ij.*(Mu0*ones(1,nmodels));%.*(ones(nmodels,1)*(1./MU_p(:,k))');
 else
 p_ij_s= p_ij.*(MU_u(:,k-1)*ones(1,nmodels));%.*(ones(nmodels,1)*(1./MU_p(:,k))');
 end
 % 
 % To avoid any numerical issues with roundoff, we normalize to
 % 1 again
 normFact = repmat(sum(p_ij_s,1),[nmodels 1]); %Every column must sum to 1

 p_ij_s = p_ij_s./normFact;
 % for i=1:length(normFact)
 % if(normFact(i)~=0)
 % p_ij_s(:,i) = p_ij_s(:,i)./normFact(i);
 % else %reset all the states to be equally likely (each row must sum to 1)
 % p_ij_s(:,i) = 1/nmodels*ones(nmodels,1);
 % end
 % end 
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Step 3 - Approximate p(x_k-1 | s_k, H_k) with Gaussian 
 % approximation to Mixtures of Gaussians
 % Calculate the mixed state mean for each filter
 % This will be the initial states for the update step of the
 % Point Process Adaptive Filter
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 for j = 1:nmodels
 for i = 1:nmodels
 if(k>1)
 X_s{j}(ind{i},k) = X_s{j}(ind{i},k) + X_u{i}(ind{i},k-1)*p_ij_s(i,j);
 else
 X_s{j}(ind{i},k) = X_s{j}(ind{i},k) + x0{i}(ind{i})*p_ij_s(i,j); 
 end
 end
 end

 % Calculate the mixed state covariance for each filter

 for j = 1:nmodels
 for i = 1:nmodels
 if(k>1)
 W_s{j}(ind{i},ind{i},k) = W_s{j}(ind{i},ind{i},k) + (W_u{i}(ind{i},ind{i},k-1) + (X_u{i}(ind{i},k-1)-X_s{j}(ind{i},k))*(X_u{i}(ind{i},k-1)-X_s{j}(ind{i},k))')*p_ij_s(i,j);
 else
 W_s{j}(ind{i},ind{i},k) = W_s{j}(ind{i},ind{i},k) + (Pi0{i}(ind{i},ind{i})+ (x0{i}(ind{i})-X_s{j}(ind{i},k))*(x0{i}(ind{i})-X_s{j}(ind{i},k))')*p_ij_s(i,j);
 end
 end
 end

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Step 4 - Approximate p(x_k+1 |s_k+1,n_k+1,H_k+1)
 % Uses a bank of nmodel point process filters
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % k
 
 for s=1:nmodels

 % Prediction Step — use original Srinivasan indexing:
 % size(A{s},3) for Amat (selects B(:,:,1) for time-invariant A)
 % min(size(Qmat{s},3)) for Qmat (selects QT(:,:,N))
 [X_p{s}(ind{s},k),W_p{s}(ind{s},ind{s},k)] = nstat.decoding.PPAF.PPDecode_predict(X_s{s}(ind{s},k), W_s{s}(ind{s},ind{s},k), Amat{s}(:,:,min(size(A{s},3),k)), Qmat{s}(:,:,min(size(Qmat{s},3))));

 if(estimateTarget==0 && ~isempty(yT{s}))
 if(k>1)
 ut{s}(:,k) = (Q{s}*pinv(PitT{s}(:,:,k)))*PhitT{s}(:,:,k)*(yT{s}-pinv(PhitT{s}(:,:,k-1))*X_s{s}(ind{s},k));
 else
 invA = pinv(A{s}(:,:,min(size(A{s},3),1)));
 ut{s}(:,k) = (Q{s}*pinv(PitT{s}(:,:,1)))*PhitT{s}(:,:,1)*(yT{s}-pinv(invA*PhitT{s}(:,:,1))*X_s{s}(ind{s},k));
 end
 X_p{s}(ind{s},k) = X_p{s}(ind{s},k)+ut{s}(:,k);
 W_p{s}(ind{s},ind{s},k) =W_p{s}(ind{s},ind{s},k) + (Q{s}*pinv(PitT{s}(:,:,k)))*A{s}*W_s{s}(ind{s},ind{s},k)*A{s}'*(Q{s}*pinv(PitT{s}(:,:,k)))';

 end

 % Update Step
 % Fold in the neural firing in the current time step
 [X_u{s}(ind{s},k),W_u{s}(ind{s},ind{s},k),lambdaDeltaMat{s}(:,k)] = nstat.decoding.PPAF.PPDecode_updateLinear(X_p{s}(ind{s},k),squeeze(W_p{s}(ind{s},ind{s},k)),dN,mu,beta{s}(ind{s},:),fitType,gamma,HkPerm,k);

 end
 % pause;
 % close all; plot(lambdaDeltaMat{1}(:,k),'k.'); hold on; plot(lambdaDeltaMat{2}(:,k),'b*');
 % 
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Step 5 - p(n_k | s_k, H_k) using Laplace approximation
 % See General-purpose filter design for neural prosthetic devices.
 % Srinivasan L, Eden UT, Mitter SK, Brown EN.
 % J Neurophysiol. 2007 Oct;98(4):2456-75. Epub 2007 May 23.
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 for s=1:nmodels

 tempPdf = sqrt(det(W_u{s}(:,:,k)))./sqrt(det(W_p{s}(:,:,k)))*prod(exp(dN(:,k).*log(lambdaDeltaMat{s}(:,k))-lambdaDeltaMat{s}(:,k)));
 pNGivenS(s,k) = tempPdf;
 end
 tempData = pNGivenS(:,k);
 tempData(isinf(tempData))=0;
 pNGivenS(:,k) = tempData;

 normFact = sum(pNGivenS(:,k));
 if(normFact~=0 && ~isnan(normFact))
 pNGivenS(:,k)=pNGivenS(:,k)./sum(pNGivenS(:,k));
 else

 if(k>1)
 pNGivenS(:,k) = pNGivenS(:,k-1);
 else
 pNGivenS(:,k) =.5*ones(nmodels,1);
 end
 end
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Step 6 - Calculate p(s_k | n_k, H_k) = p(s_k | H_k+1)
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 pSGivenN(:,k) = MU_p(:,k).*pNGivenS(:,k);

 %Normalization Factor
 normFact = sum(pSGivenN(:,k));
 if(normFact~=0 && ~isnan(normFact))
 pSGivenN(:,k) = pSGivenN(:,k)./sum(pSGivenN(:,k));
 else
 if(k>1)
 pSGivenN(:,k) = pSGivenN(:,k-1);
 else
 pSGivenN(:,k) = Mu0;
 end

 end

 MU_u(:,k) = pSGivenN(:,k); %estimate of s_k given data up to k

 [~, S_est(k)] = max(MU_u(:,k)); %Most likely current state

 if(MinClassificationError==1)

 s= S_est(k);
 X(ind{s},k) = X_u{s}(ind{s},k);
 W(ind{s},ind{s},k) = W_u{s}(ind{s},ind{s},k);

 else %Minimize the mean squared error

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Step 7 - Calculate p(x_k | n_k, H_k) - using gaussian
 % approximation to mixture of gaussians 
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 for s=1:nmodels
 X(ind{s},k) = X(ind{s},k)+MU_u(s,k)*X_u{s}(ind{s},k); 
 end
 for s=1:nmodels
 W(ind{s},ind{s},k) = W(ind{s},ind{s},k) +MU_u(s,k)*(W_u{s}(ind{s},ind{s},k) + (X_u{s}(ind{s},k)-X(ind{s},k))*(X_u{s}(ind{s},k)-X(ind{s},k))');
 end
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 end
 end

 %Solution to the known target problem. Run the Hybrid Filter
 %Forward to determine the most likely states.... this is the
 %sequence of the A dynamics matrices to use in the computation of
 %the Target Reach Model of Srinivasan et al. Compute PiT

 end 
 function [S_est, X, W, MU_u, X_s, W_s,pNGivenS] = PPHybridFilter(A, Q, p_ij,Mu0,dN,lambdaCIFColl,binwidth,x0,Pi0, yT,PiT,estimateTarget,MinClassificationError)
 % FIX (#91): renamed 4th output MU_s -> MU_u to match the body, which
 % only ever assigns MU_u. Sister function PPHybridFilterLinear (line 25)
 % uses the same MU_u name for its 4th output.

 % General-purpose filter design for neural prosthetic devices.
 % Srinivasan L, Eden UT, Mitter SK, Brown EN.
 % J Neurophysiol. 2007 Oct;98(4):2456-75. Epub 2007 May 23.

 [C,N] = size(dN); % N time samples, C cells
 nmodels = length(A);
 for s=1:nmodels
 ns(s)=size(A{s},1); % number of states
 end
 nsMax = max(ns);
 if(nargin<13 || isempty(MinClassificationError))
 MinClassificationError=0; %Minimum mean square error state estimate. By default do maximum likelihood
 end
 if(nargin<12 || isempty(estimateTarget))
 estimateTarget=0;
 end

 if(nargin<11 || isempty(PiT))
 for s=1:nmodels
 if(estimateTarget==1)
 PiT{s} = zeros(size(Q{s}));
 else
 PiT{s} = 0*diag(ones(ns(s),1))*1e-6;
 end
 end
 end
 if(nargin<9 || isempty(Pi0))
 for s=1:nmodels
 Pi0{s}(:,:) = zeros(ns(s),ns(s));
 end
 end
 if(nargin<10 || isempty(yT))
 for s=1:nmodels
 yT{s}=[];
 Amat{s} = A{s};
 Qmat{s} = Q{s};
 ft{s} = zeros(size(Amat{s},2),N);
 PiT{s} = zeros(size(Q{s}));
 end
 
 else
 Pi0new=cell(1,nmodels);
 for s=1:nmodels

 PitT{s}= zeros(ns(s),ns(s),N); % Pi(t,T) in Srinivasan et al. 
 QT{s} = zeros(ns(s),ns(s),N); % The noise covaraince given target observation (Q_t)
 if(estimateTarget==1)
 PitT{s}(:,:,N)=Q{s}; % Pi(T,T)=Pi_T + Q_T, setting PiT=0
 else
 PitT{s}(:,:,N)=PiT{s}+Q{s};
 end
 PhitT{s} = zeros(ns(s),ns(s),N);% phi(t,T) - transition matrix from time T to t
 % PhiTt = zeros(ns,ns,N);% phi(T,t) - transition matrix from time t to T
 PhitT{s}(:,:,N) = eye(ns(s),ns(s)); % phi(T,T) = I
 B{s} = zeros(ns(s),ns(s),N); % See Equation 2.21 in Srinivasan et. al

 for n=N:-1:2
 if(rcond(A{s})<1000*eps)
 invA=pinv(A{s});
 else
 invA=eye(size(A{s}))/A{s};
 end
 % state transition matrix
 PhitT{s}(:,:,n-1)= invA*PhitT{s}(:,:,n);
 % PhiTt(:,:,n)= A^(N-n);

 % Equation 2.16 in Srinivasan et al. Note there is a typo in the paper. 
 % This is the correct expression. The term Q_t-1 does not
 % need to be mulitplied by phi(t-1,t)

 PitT{s}(:,:,n-1) = invA*PitT{s}(:,:,n)*invA'+Q{s};

 if(n<=N)
 B{s}(:,:,n) = A{s}-(Q{s}*pinv(PitT{s}(:,:,n)))*A{s}; %Equation 2.21 in Srinivasan et. al
 QT{s}(:,:,n) = Q{s}-(Q{s}*pinv(PitT{s}(:,:,n)))*Q{s}';
 end
 end
 % PhiTt(:,:,1)= A^(N-1);
 B{s}(:,:,1) = A{s}-(Q{s}*pinv(PitT{s}(:,:,1)))*A{s};
 QT{s}(:,:,1) = Q{s}-(Q{s}*pinv(PitT{s}(:,:,1)))*Q{s}';
 % See Equations 2.23 through 2.26 in Srinivasan et. al
 if(estimateTarget==1)

 
 for n=1:N
 psi = B{s}(:,:,n);
 if(n==N)
 gammaMat = eye(ns(s),ns(s));
 else
 gammaMat = (Q{s}*pinv(PitT{s}(:,:,n)))*PhitT{s}(:,:,n);
 end
 Amat{s}(:,:,n) = [psi,gammaMat;
 zeros(ns(s),ns(s)), eye(ns(s),ns(s))];
 
 Qmat{s}(:,:,n) = [QT{s}(:,:,n), zeros(ns(s),ns(s));
 zeros(ns(s),ns(s)) zeros(ns(s),ns(s))]; 

 end

 Pi0new{s} = [Pi0{s}, zeros(ns(s),ns(s));
 zeros(ns(s),ns(s)) zeros(ns(s),ns(s))]; 

 else

 Amat{s} = B{s};
 Qmat{s} = QT{s};
 for n=1:N
 ft{s}(:,n) = (Q{s}*pinv(PitT{s}(:,:,n)))*PhitT{s}(:,:,n)*yT{s};
 end

 end

 end
 if(estimateTarget==1)
 Pi0 = Pi0new;

 end
 end

 if(nargin<8 || isempty(x0))
 for s=1:nmodels
 x0{s}=zeros(size(Amat{s},2),1);
 end
 end

 if(nargin<7)
 binwidth=0.001; %1 msec
 end

 if(isa(A,'cell'))
 dimMat = zeros(1,length(Amat));
 X_u = cell(1,length(Amat));
 W_u = cell(1,length(Amat));
 X_p = cell(1,length(Amat));
 W_p = cell(1,length(Amat));
 ind = cell(1,length(Amat));
 ut = cell(1,length(Amat));

 for i=1:length(Amat)
 lambdaDeltaMat{i} = zeros(size(dN));
 X_u{i} = zeros(size(Amat{i},1), size(dN,2));
 X_p{i} = zeros(size(Amat{i},1), size(dN,2)+1);
 W_u{i} = zeros(size(Amat{i},1), size(Amat{i},1), size(dN,2));
 W_p{i} = zeros(size(Amat{i},1), size(Amat{i},1), size(dN,2)+1);
 dimMat(i) = size(Amat{i},2);
 W_u{i}(:,:,1) =Pi0{i};
 ind{i} = 1:dimMat(i);
 ut{i} = zeros(size(Amat{i},1), size(dN,2));
 end
 end

 maxDim = max(dimMat);
 % nmodels = length(Amat);
 % lambdaCIFColl = CIFColl(lambda);

 minTime=0;
 maxTime=(size(dN,2)-1)*binwidth;

 C=size(dN,1);

 % Overall estimates of Hybrid filter
 X = zeros(maxDim, size(dN,2)); % Estimated Trajectories
 W = zeros(maxDim, maxDim, size(dN,2)); % Covariance of estimate
 % Individual Model Estimates
 for i=1:nmodels
 X_s{i} = X; % Individual Model Estimates
 W_s{i} = W; % Individual Model Covariances
 end
 % Model probabilities 
 MU_u = zeros(nmodels,size(dN,2)); % P(s_k | H_k+1) % updated state probabilities
 MU_p = zeros(nmodels,size(dN,2)); % P(s_k | H_k) % prediction state probabilities
 pNGivenS = zeros(nmodels,size(dN,2));

 %mu_0|1 = mu_0|0;
 if(isempty(Mu0))
 Mu0 = ones(nmodels,1)*1/nmodels;
 elseif(size(Mu0,1)==nmodels && size(Mu0,2)==1)
 Mu0 = Mu0;
 elseif(size(Mu0,1)==1 && size(Mu0,2)==nmodels)
 Mu0 = Mu0';
 else
 error('Mu0 must be a column or row vector with the same number of dimensions as the number of states');
 end

 % Fuse initial state prior with terminal constraint for each
 % model, matching PPDecodeFilterLinear (Srinivasan et al. Eq. 2.23).
 for s=1:nmodels
 if(~isempty(yT) && ~isempty(yT{s}) && estimateTarget==0)
 Pi0s = Pi0{s}(ind{s},ind{s});
 x0s = x0{s}(ind{s});
 if(det(Pi0s)~=0)
 invPi0s = pinv(Pi0s);
 invPitTs = pinv(PitT{s}(:,:,1));
 Pi0New = pinv(invPi0s + invPitTs);
 Pi0New(isnan(Pi0New)) = 0;
 x0New = Pi0New*(invPi0s*x0s + invPitTs*PhitT{s}(:,:,1)*yT{s});
 x0{s}(ind{s}) = x0New;
 Pi0{s}(ind{s},ind{s}) = Pi0New;
 W_u{s}(ind{s},ind{s},1) = Pi0New;
 end
 end
 end

 for s=1:nmodels
 [X_p{s}(ind{s},1),W_p{s}(ind{s},ind{s},1)] = nstat.decoding.PPAF.PPDecode_predict(x0{s}(ind{s}), Pi0{s}(ind{s},ind{s}), Amat{s}(ind{s},ind{s},min(size(Amat{s},3),1)), Qmat{s}(:,:,min(size(Qmat{s},3),1)));

 if((estimateTarget==0 && ~isempty(yT{s})))
 invA= pinv(Amat{s}(:,:,min(size(Amat{s},3),1)));
 ut{s}(:,1) = (Q{s}*pinv(PitT{s}(:,:,1)))*PhitT{s}(:,:,1)*(yT{s}-pinv(invA*PhitT{s}(:,:,1))*x0{s});
 X_p{s}(ind{s},1) = X_p{s}(ind{s},1)+ut{s}(:,1);
 W_p{s}(ind{s},ind{s},1) =W_p{s}(ind{s},ind{s},1) + (Q{s}*pinv(PitT{s}(:,:,1)))*A{s}*Pi0{s}*A{s}'*(Q{s}*pinv(PitT{s}(:,:,1)))';
 end
 end

 % [~, S_est(1)] = max(MU_p(:,1)); %Most likely current state

 %State transition Probabilities must integrate to 1
 sumVal = sum(p_ij,2);
 if(any(sumVal~=1))
 error('State Transition probability matrix must sum to 1 along each row');
 end
 %% 9 Steps
 % Filtering steps.
 for k = 1:(size(dN,2))

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Step 1 - p(s_k | H_k) = Sum(p(s_k|s_k-1)*p(s_k-1|H_k))
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %MU(:,k)_p= [ p(s_k=1 | H_k)] is a vector of the probabilities
 % [ p(s_k=2 | H_k)]
 %.
 %.
 %.
 % [ p(s_k=N | H_k)]
 % thus it is an prediction of the discrete state at time k given all
 % of the neural firing up to k-1 as summarized in H_k
 %
 % Whereas 
 % MU_u(:,k)=[ p(s_k=1 | H_k+1)] is a vector of the probabilities
 % [ p(s_k=2 | H_k+1)]
 %.
 %.
 %.
 % [ p(s_k=N | H_k+1)]
 % The s suffix indicates that this is a "smoothed" estimate of
 % the state given the firing up to time k summarized in H_k+1
 if k==1
 MU_p(:,k) = p_ij'*Mu0; %state probability prediction equation
 else
 MU_p(:,k) = p_ij'*MU_u(:,k-1); 
 end

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Step 2 - p(s_k-1 | s_k, H_k)
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % This is a matrix with i,j entry indicating the probability that 
 % s_k-1 = j given than s_k = i
 %
 % MU_p is the normalization factor. The first column of the
 % matrix of probabilities is:
 %
 % P(s_k-1=1 | s_k=1,H_k) ~ P(s_k=1|s_k-1=1,H_k)*P(s_k-1=1|H_k)
 % P(s_k-1=1 | s_k=2,H_k) ~ P(s_k=2|s_k-1=1,H_k)*P(s_k-1=1|H_k)
 % 
 % And the second columns... etc
 %
 % 
 % P(s_k-1=2 | s_k=1,H_k) ~ P(s_k=1|s_k-1=2,H_k)*P(s_k-1=1|H_k)
 % P(s_k-1=2 | s_k=2,H_k) ~ P(s_k=2|s_k-1=2,H_k)*P(s_k-1=1|H_k)

 if(k==1)
 p_ij_s= p_ij.*(Mu0*ones(1,nmodels));%.*(ones(nmodels,1)*(1./MU_p(:,k))');
 else
 p_ij_s= p_ij.*(MU_u(:,k-1)*ones(1,nmodels));%.*(ones(nmodels,1)*(1./MU_p(:,k))');
 end
 % 
 % To avoid any numerical issues with roundoff, we normalize to
 % 1 again
 normFact = repmat(sum(p_ij_s,1),[nmodels 1]); %Every column must sum to 1

 p_ij_s = p_ij_s./normFact;
 % for i=1:length(normFact)
 % if(normFact(i)~=0)
 % p_ij_s(:,i) = p_ij_s(:,i)./normFact(i);
 % else %reset all the states to be equally likely (each row must sum to 1)
 % p_ij_s(:,i) = 1/nmodels*ones(nmodels,1);
 % end
 % end 
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Step 3 - Approximate p(x_k-1 | s_k, H_k) with Gaussian 
 % approximation to Mixtures of Gaussians
 % Calculate the mixed state mean for each filter
 % This will be the initial states for the update step of the
 % Point Process Adaptive Filter
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 for j = 1:nmodels
 for i = 1:nmodels
 if(k>1)
 X_s{j}(ind{i},k) = X_s{j}(ind{i},k) + X_u{i}(ind{i},k-1)*p_ij_s(i,j);
 else
 X_s{j}(ind{i},k) = X_s{j}(ind{i},k) + x0{i}(ind{i})*p_ij_s(i,j); 
 end
 end
 end

 % Calculate the mixed state covariance for each filter

 for j = 1:nmodels
 for i = 1:nmodels
 if(k>1)
 W_s{j}(ind{i},ind{i},k) = W_s{j}(ind{i},ind{i},k) + (W_u{i}(ind{i},ind{i},k-1) + (X_u{i}(ind{i},k-1)-X_s{j}(ind{i},k))*(X_u{i}(ind{i},k-1)-X_s{j}(ind{i},k))')*p_ij_s(i,j);
 else
 W_s{j}(ind{i},ind{i},k) = W_s{j}(ind{i},ind{i},k) + (Pi0{i}(ind{i},ind{i})+ (x0{i}(ind{i})-X_s{j}(ind{i},k))*(x0{i}(ind{i})-X_s{j}(ind{i},k))')*p_ij_s(i,j);
 end
 end
 end

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Step 4 - Approximate p(x_k+1 |s_k+1,n_k+1,H_k+1)
 % Uses a bank of nmodel point process filters
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % k
 for s=1:nmodels

 % Prediction Step — use original Srinivasan indexing:
 % size(A{s},3) for Amat (selects B(:,:,1) for time-invariant A)
 % min(size(Qmat{s},3)) for Qmat (selects QT(:,:,N))
 [X_p{s}(ind{s},k),W_p{s}(ind{s},ind{s},k)] = nstat.decoding.PPAF.PPDecode_predict(X_s{s}(ind{s},k), W_s{s}(ind{s},ind{s},k), Amat{s}(:,:,min(size(A{s},3),k)), Qmat{s}(:,:,min(size(Qmat{s},3))));

 if(estimateTarget==0 && ~isempty(yT{s}))
 if(k>1)
 ut{s}(:,k) = (Q{s}*pinv(PitT{s}(:,:,k)))*PhitT{s}(:,:,k)*(yT{s}-pinv(PhitT{s}(:,:,k-1))*X_s{s}(ind{s},k));
 else
 invA = pinv(A{s}(:,:,min(size(A{s},3),1)));
 ut{s}(:,k) = (Q{s}*pinv(PitT{s}(:,:,1)))*PhitT{s}(:,:,1)*(yT{s}-pinv(invA*PhitT{s}(:,:,1))*X_s{s}(ind{s},k));
 end
 X_p{s}(ind{s},k) = X_p{s}(ind{s},k)+ut{s}(:,k);
 W_p{s}(ind{s},ind{s},k) =W_p{s}(ind{s},ind{s},k) + (Q{s}*pinv(PitT{s}(:,:,k)))*A{s}*W_s{s}(ind{s},ind{s},k)*A{s}'*(Q{s}*pinv(PitT{s}(:,:,k)))';

 end

 % Update Step
 % Fold in the neural firing in the current time step
 [X_u{s}(ind{s},k),W_u{s}(ind{s},ind{s},k),lambdaDeltaMat{s}(:,k)] = nstat.decoding.PPAF.PPDecode_update(X_p{s}(ind{s},k),squeeze(W_p{s}(ind{s},ind{s},k)),dN(:,1:k),lambdaCIFColl,binwidth,k);

 end

 % 
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Step 5 - p(n_k | s_k, H_k) using Laplace approximation
 % See General-purpose filter design for neural prosthetic devices.
 % Srinivasan L, Eden UT, Mitter SK, Brown EN.
 % J Neurophysiol. 2007 Oct;98(4):2456-75. Epub 2007 May 23.
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 for s=1:nmodels

 tempPdf = sqrt(det(W_u{s}(:,:,k)))./sqrt(det(W_p{s}(:,:,k)))*prod(exp(dN(:,k).*log(lambdaDeltaMat{s}(:,k))-lambdaDeltaMat{s}(:,k)));
 pNGivenS(s,k) = tempPdf;
 end
 tempData = pNGivenS(:,k);
 tempData(isinf(tempData))=0;
 pNGivenS(:,k) = tempData;

 normFact = sum(pNGivenS(:,k));
 if(normFact~=0 && ~isnan(normFact))
 pNGivenS(:,k)=pNGivenS(:,k)./sum(pNGivenS(:,k));
 else

 if(k>1)
 pNGivenS(:,k) = pNGivenS(:,k-1);
 else
 pNGivenS(:,k) =.5*ones(nmodels,1);
 end
 end
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Step 6 - Calculate p(s_k | n_k, H_k) = p(s_k | H_k+1)
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 pSGivenN(:,k) = MU_p(:,k).*pNGivenS(:,k);

 %Normalization Factor
 normFact = sum(pSGivenN(:,k));
 if(normFact~=0 && ~isnan(normFact))
 pSGivenN(:,k) = pSGivenN(:,k)./sum(pSGivenN(:,k));
 else
 if(k>1)
 pSGivenN(:,k) = pSGivenN(:,k-1);
 else
 pSGivenN(:,k) = Mu0;
 end

 end

 MU_u(:,k) = pSGivenN(:,k); %estimate of s_k given data up to k

 [~, S_est(k)] = max(MU_u(:,k)); %Most likely current state

 if(MinClassificationError==1)

 s= S_est(k);
 X(ind{s},k) = X_u{s}(ind{s},k);
 W(ind{s},ind{s},k) = W_u{s}(ind{s},ind{s},k);

 else %Minimize the mean squared error

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Step 7 - Calculate p(x_k | n_k, H_k) - using gaussian
 % approximation to mixture of gaussians 
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 for s=1:nmodels
 X(ind{s},k) = X(ind{s},k)+MU_u(s,k)*X_u{s}(ind{s},k); 
 end
 for s=1:nmodels
 W(ind{s},ind{s},k) = W(ind{s},ind{s},k) +MU_u(s,k)*(W_u{s}(ind{s},ind{s},k) + (X_u{s}(ind{s},k)-X(ind{s},k))*(X_u{s}(ind{s},k)-X(ind{s},k))');
 end
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 end
 end

 end 
 
 end
end

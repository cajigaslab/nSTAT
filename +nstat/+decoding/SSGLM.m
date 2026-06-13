classdef SSGLM
 %SSGLM State-space GLM with random-walk drifting coefficients.
 %
 % Trial-drifting GLM coefficients estimated via expectation-maximization
 % (Czanner et al. 2008). The PP-GLM coefficients evolve as a Gaussian
 % random walk across trials; the E-step is a forward-backward pass
 % over the spike-train likelihood and the M-step updates the
 % process-noise covariance and the history coefficient vector.
 %
 % Extracted from DecodingAlgorithms.m (Phase 3 Task 3.2 Step F of the
 % 2026-05-19 nSTAT review action plan). DecodingAlgorithms.PPSS_* are
 % now thin deprecation shims that forward here.
 %
 % Static methods:
 % PPSS_EMFB -- Forward-backward EM variant.
 % PPSS_EM -- Main EM loop with ring-buffer parameter history.
 % PPSS_EStep -- Forward-backward E-step.
 % PPSS_MStep -- Closed-form M-step (Q, gamma).
 %
 % Cross-cluster calls in the E-step are rewired directly to
 % nstat.decoding.KalmanFilter.* (kalman_smootherFromFiltered) so EM
 % iterations do not emit the deprecation-shim warning on every pass.
 % Shared helpers prepareEMResults, ComputeStimulusCIs, and
 % estimateInfoMat remain as DecodingAlgorithms.* calls -- they are
 % unowned by any cluster and stay in DecodingAlgorithms.m until a
 % follow-up cleanup decides where they belong.
 %
 % Refs: Czanner et al. 2008, J Neurophysiol 99:2672-2693;
 %.B.6 SSGLM.

 methods (Static)
 function [xKFinal,WKFinal, WkuFinal,Qhat,gammahat,fitResults,stimulus,stimCIs,logll,QhatAll,gammahatAll,nIter]=PPSS_EMFB(A,Q0,x0,dN,fitType,delta,gamma0,windowTimes, numBasis,neuronName)
 % if(nargin<10 || isempty(neuronName))
 % neuronName = 1;
 % end
 dLikelihood(1)=inf;
 if(numel(Q0)==length(Q0)^2)
 Q0=diag(Q0); %turn Q into a vector
 end

 Qhat=Q0;
 gammahat=gamma0;
 xK0=x0;
 cnt=1; tol=1e-2; maxIter=2e3;
 tolAbs = nstat.Defaults.EM_TolAbs;
 tolRel = nstat.Defaults.EM_TolRel;
 llTol = nstat.Defaults.EM_LogLTol;
 stoppingCriteria=0;

 minTime=0;
 maxTime=(size(dN,2)-1)*delta;

 K=size(dN,1);
 if(~isempty(windowTimes))
 histObj = History(windowTimes,minTime,maxTime);
 for k=1:K
 nst{k} = nspikeTrain( (find(dN(k,:)==1)-1)*delta);
 nst{k}.setMinTime(minTime);
 nst{k}.setMaxTime(maxTime);
 HkAll{k} = histObj.computeHistory(nst{k}).dataToMatrix;
 end
 else
 for k=1:K
 HkAll{k} = 0;
 end
 gamma0=0;
 end

 HkAllR=HkAll(end:-1:1);
 % if(~isempty(windowTimes))
 % histObj = History(windowTimes,minTime,maxTime);
 % for k=K:-11:1
 % nstr{k} = nspikeTrain( (find(dN(k,:)==1)-1)*delta);
 % nstr{k}.setMinTime(minTime);
 % nstr{k}.setMaxTime(maxTime);
 % HkAllR{k} = histObj.computeHistory(nstr{k}).dataToMatrix;
 % end
 % else
 % for k=1:K
 % HkAllR{k} = 0;
 % end
 % gammahat=0;
 % end

 while(stoppingCriteria~=1 && cnt<maxIter)
 display('EMFB: Forward EM');
 [xK,WK, Wku,Qhat(:,cnt+1),gammahat(cnt+1,:),logll(cnt),~,~,nIter1,negLL]=nstat.decoding.SSGLM.PPSS_EM(A,Qhat(:,cnt),xK0,dN,fitType,delta,gammahat(cnt,:),windowTimes, numBasis,HkAll); 
 if(~negLL)
 display('EMFB: Backward EM');
 [xKR,~, ~,QhatR(:,cnt+1),gammahatR(cnt+1,:),logllR(cnt),~,~,nIter2,negLL]=nstat.decoding.SSGLM.PPSS_EM(A,Qhat(:,cnt+1),xK(:,end),flipud(dN),fitType,delta,gammahat(cnt+1,:),windowTimes, numBasis,HkAllR);
 if(~negLL)
 display('EMFB: Forward EM');

 [xK2,WK2, Wku2,Qhat2,gammahat2,logll2,~,~,nIter3,negLL2]=nstat.decoding.SSGLM.PPSS_EM(A,QhatR(:,cnt+1),xKR(:,end),dN,fitType,delta,gammahatR(cnt+1,:),windowTimes, numBasis,HkAll);
 if(~negLL2)
 xK=xK2;
 WK=WK2;
 Wku=Wku2;
 Qhat(:,cnt+1) = Qhat2;
 gammahat(cnt+1,:) = gammahat2;
 logll(cnt) = logll2;

 end
 end
 end

 xK0=xK(:,1);
 if(cnt==1)
 dLikelihood(cnt+1)=inf;
 else
 dLikelihood(cnt+1)=(logll(cnt)-logll(cnt-1));%./abs(logll(cnt-1));
 end
 cnt=cnt+1;

 % figure(1)
 % 
 % subplot(1,2,1); surf(xK);
 % subplot(1,2,2); plot(logll); ylabel('Log Likelihood');

 dQvals = abs(sqrt(Qhat(:,cnt))-sqrt(Qhat(:,cnt-1)));
 dGamma = abs(gammahat(cnt,:)-gammahat(cnt-1,:));
 dMax = max([dQvals',dGamma]);

 dQRel = max(abs(dQvals./sqrt(Qhat(:,cnt-1))));
 dGammaRel = max(abs(dGamma./gammahat(cnt-1,:)));
 dMaxRel = max([dQRel,dGammaRel]);
 % dMax
 % dMaxRel
 if(dMax<tolAbs && dMaxRel<tolRel)
 stoppingCriteria=1;
 display(['EMFB converged at iteration:' num2str(cnt) ' b/c change in params was within criteria']);
 end
 if(abs(dLikelihood(cnt))<llTol || dLikelihood(cnt)<0)
 stoppingCriteria=1;
 display(['EMFB stopped at iteration:' num2str(cnt) ' b/c change in likelihood was negative']);
 end

 end

 maxLLIndex = find(logll == max(logll),1,'first');
 if(maxLLIndex==1)
 maxLLIndex=cnt-1;
 elseif(isempty(maxLLIndex))
 maxLLIndex = 1; 
 end

 xKFinal = xK;
 x0Final=xK(:,1);
 WKFinal = WK;
 WkuFinal = Wku;
 QhatAll =Qhat(:,1:maxLLIndex+1);
 Qhat = Qhat(:,maxLLIndex+1);
 gammahatAll =gammahat(1:maxLLIndex+1);
 gammahat = gammahat(maxLLIndex+1,:);
 logll = logll(maxLLIndex);

 K=size(dN,1);
 SumXkTermsFinal = diag(Qhat(:,:,end))*K;
 logllFinal=logll(end);
 McInfo=100;
 McCI = 3000;

 nIter = [];%[nIter1,nIter2,nIter3];
 
 
 K = size(dN,1); 
 R=size(xK,1);
 logllobs = logll+R*K*log(2*pi)+K/2*log(det(diag(Qhat)))+ 1/2*trace(diag(Qhat)\SumXkTermsFinal);

 InfoMat = DecodingAlgorithms.estimateInfoMat(fitType,dN,HkAll,A,x0Final,xKFinal,WKFinal,WkuFinal,Qhat,gammahat,windowTimes,SumXkTermsFinal,delta,McInfo);
 fitResults = DecodingAlgorithms.prepareEMResults(fitType,neuronName,dN,HkAll,xKFinal,WKFinal,Qhat,gammahat,windowTimes,delta,InfoMat,logllobs);
 [stimCIs, stimulus] = DecodingAlgorithms.ComputeStimulusCIs(fitType,xKFinal,WkuFinal,delta,McCI);
 % 

 end
 function [xKFinal,WKFinal, WkuFinal,Qhat,gammahat,logll,QhatAll,gammahatAll,nIter,negLL]=PPSS_EM(A,Q0,x0,dN,fitType,delta,gamma0,windowTimes, numBasis,Hk)
 if(nargin<9 || isempty(numBasis))
 numBasis = 20;
 end
 if(nargin<8 || isempty(windowTimes))
 if(isempty(gamma0))
 windowTimes =[];
 else
 % numWindows =length(gamma0)+1; 
 windowTimes = 0:delta:(length(gamma0)+1)*delta;
 end
 end
 if(nargin<7)
 gamma0=[];
 end
 if(nargin<6 || isempty(delta))
 delta =.001;
 end
 if(nargin<5)
 fitType = 'poisson';
 end

 minTime=0;
 maxTime=(size(dN,2)-1)*delta;
 K=size(dN,1);

 % tol = 1e-3; %absolute change;
 tolAbs = nstat.Defaults.EM_TolAbs;
 tolRel = nstat.Defaults.EM_TolRel;
 llTol = nstat.Defaults.EM_LogLTol;
 cnt=1;

 maxIter = 100;

 if(numel(Q0)==length(Q0)^2)
 Q0=diag(Q0); %turn Q into a vector
 end
 numToKeep=10;
 Qhat = zeros(length(Q0),numToKeep);
 Qhat(:,1)=Q0;
 gammahat=zeros(numToKeep,length(gamma0));
 gammahat(1,:)=gamma0;
% QhatNew=Q0;
% gammahatNew(1,:)=gamma0;
 cnt=1;
 dLikelihood(1)=inf;
 % logll(1)=-inf;
 x0hat = x0;
 negLL=0;
 
 %Forward EM
 stoppingCriteria =0;
% logllNew= -inf;
 while(stoppingCriteria~=1 && cnt<=maxIter)
 storeInd = mod(cnt-1,numToKeep)+1; %make zero-based then mod, then add 1
 storeIndP1= mod(cnt,numToKeep)+1;
 storeIndM1= mod(cnt-2,numToKeep)+1;
 [xK{storeInd},WK{storeInd},Wku{storeInd},logll(cnt),SumXkTerms,sumPPll]=...
 nstat.decoding.SSGLM.PPSS_EStep(A,Qhat(:,storeInd),x0hat,dN,Hk,fitType,delta,gammahat(storeInd,:),numBasis);
 
 [Qhat(:,storeIndP1),gammahat(storeIndP1,:)] = nstat.decoding.SSGLM.PPSS_MStep(dN,Hk,fitType,xK{storeInd},WK{storeInd},gammahat(storeInd,:),delta,SumXkTerms,windowTimes);
 if(cnt==1)
 dLikelihood(cnt+1)=inf;
 else
 dLikelihood(cnt+1)=(logll(cnt)-logll(cnt-1));%./abs(logll(cnt-1));
 end

 if(mod(cnt,25)==0)
 figure(1);
 subplot(1,2,1); surf(xK{storeInd});
 subplot(1,2,2); plot(logll); ylabel('Log Likelihood');
 end
 
 dQvals = abs(sqrt(Qhat(:,storeInd))-sqrt(Qhat(:,storeIndM1)));
 dGamma = abs(gammahat(storeInd,:)-gammahat(storeIndM1,:));
 dMax = max([dQvals',dGamma]);

 dQRel = max(abs(dQvals./sqrt(Qhat(:,storeIndM1))));
 dGammaRel = max(abs(dGamma./gammahat(storeIndM1,:)));
 dMaxRel = max([dQRel,dGammaRel]);

 
 cnt=(cnt+1);
 if(dMax<tolAbs && dMaxRel<tolRel)
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

 maxLLIndex = find(logll == max(logll),1,'first');
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
 xKFinal = xK{maxLLIndMod};
 WKFinal = WK{maxLLIndMod};
 WkuFinal = Wku{maxLLIndMod};
 QhatAll =Qhat(:,1:maxLLIndMod);
 Qhat = Qhat(:,maxLLIndMod);
 gammahatAll =gammahat(1:maxLLIndMod);
 gammahat = gammahat(maxLLIndMod,:);
 logll = logll(maxLLIndex);
 
 end
 
 % Subroutines for the PPSS_EM algorithm
 function [x_K,W_K,Wku,logll,sumXkTerms,sumPPll]=PPSS_EStep(A,Q,x0,dN,HkAll,fitType,delta,gamma,numBasis)

 minTime=0;
 maxTime=(size(dN,2)-1)*delta;

 if(~isempty(numBasis))
 basisWidth = (maxTime-minTime)/numBasis;
 sampleRate=1/delta;
 unitPulseBasis=nstColl.generateUnitImpulseBasis(basisWidth,minTime,maxTime,sampleRate);
 basisMat = unitPulseBasis.data;
 end
 if(numel(Q)==length(Q))
 Q=diag(Q); %turn Q into a diagonal matrix
 end
 [K,N] = size(dN); 
 R=size(basisMat,2);

 x_p = zeros( size(A,2), K );
 x_u = zeros( size(A,2), K );
 W_p = zeros( size(A,2),size(A,2), K);
 W_u = zeros( size(A,2),size(A,2), K );

 for k=1:K

 if(k==1)
 x_p(:,k) = A * x0;
 W_p(:,:,k) = Q;
 else
 x_p(:,k) = A * x_u(:,k-1);
 W_p(:,:,k) = A * W_u(:,:,k-1) * A' + Q;
 end

 sumValVec=zeros(size(W_p,1),1);
 sumValMat=zeros(size(W_p,2),size(W_p,2));

 if(strcmp(fitType,'poisson'))
 Hk=HkAll{k};
 Wk = basisMat*diag(W_p(:,:,k));
 stimK=basisMat*x_p(:,k);

 histEffect=exp(gamma*Hk')';
 stimEffect=exp(stimK);
 lambdaDelta =stimEffect.*histEffect;
 GradLogLD =basisMat;
 JacobianLogLD = zeros(R,R);
 GradLD = basisMat.*repmat(lambdaDelta,[1 R]);

 sumValVec = GradLogLD'*dN(k,:)' - diag(GradLD'*basisMat);
 sumValMat = GradLD'*basisMat;

 elseif(strcmp(fitType,'binomial'))
 Hk=HkAll{k};
 Wk = basisMat*diag(W_p(:,:,k));
 stimK=basisMat*x_p(:,k);

 lambdaDelta=exp(stimK+(gamma*Hk')')./(1+exp(stimK+(gamma*Hk')')); 
 GradLogLD =basisMat.*(repmat(1-lambdaDelta,[1 R]));
 JacobianLogLD = basisMat.*repmat(lambdaDelta.*(-1+lambdaDelta),[1 R]);
 GradLD = basisMat.*(repmat(lambdaDelta.*(1-lambdaDelta),[1 R]));
 JacobianLD = basisMat.*(repmat(lambdaDelta.*(1-lambdaDelta).*(1-2*lambdaDelta),[1 R])); % FIX (#59): was (1-2*lambdaDelta.^2); the canonical sigmoid 2nd derivative is sigma*(1-sigma)*(1-2*sigma) -- linear in sigma. All sibling call sites (DecodingAlgorithms.m:533, 603; SSGLM.m:458, 545) use the linear form; this was the lone outlier.

 sumValVec = GradLogLD'*dN(k,:)' - diag(GradLD'*basisMat);
 sumValMat = -diag(JacobianLogLD'*dN(k,:)')+ JacobianLD'*basisMat;

 end 

% invW_u = pinv(W_p(:,:,k))+ sumValMat;
% W_u(:,:,k) = pinv(invW_u);% +100*diag(eps*rand(size(W_p,1),1));
% 
 

 invW_u = eye(size(W_p(:,:,k)))/W_p(:,:,k)+ sumValMat;
 W_u(:,:,k) = eye(size(invW_u))/invW_u;% +100*diag(eps*rand(size(W_p,1),1));

 % Maintain Positive Definiteness
 % Make sure eigenvalues are positive
 [vec,val]=eig(W_u(:,:,k) ); val(val<=0)=eps;
 W_u(:,:,k) =vec*val*vec';
 x_u(:,k) = x_p(:,k) + W_u(:,:,k)*(sumValVec);

 end

 [x_K, W_K,Lk] = nstat.decoding.KalmanFilter.kalman_smootherFromFiltered(A, x_p, W_p, x_u, W_u);

 Wku=zeros(R,R,K,K);
 Tk = zeros(R,R,K-1);
 for k=1:K
 Wku(:,:,k,k)=W_K(:,:,k);
 end

 for u=K:-1:2
 for k=(u-1):-1:1
 Tk(:,:,k)=A;
% Dk(:,:,k)=W_u(:,:,k)*Tk(:,:,k)'*pinv(W_p(:,:,k)); %From deJong and MacKinnon 1988
 Dk(:,:,k)=W_u(:,:,k)*Tk(:,:,k)'/(W_p(:,:,k+1)); %From deJong and MacKinnon 1988
 Wku(:,:,k,u)=Dk(:,:,k)*Wku(:,:,k+1,u);
 Wku(:,:,u,k)=Wku(:,:,k,u);
 end
 end
 

 %All terms
 Sxkxkp1 = zeros(R,R);
 Sxkp1xkp1 = zeros(R,R);
 Sxkxk = zeros(R,R);
 for k=1:K-1
% Sxkxkp1 = Sxkxkp1+x_u(:,k)*x_K(:,k+1)'+...
% Lk(:,:,k)*(W_K(:,:,k+1)+(x_K(:,k+1)-x_p(:,k+1))*x_K(:,k+1)');
 Sxkxkp1 = Sxkxkp1+Wku(:,:,k,k+1)+x_K(:,k)*x_K(:,k+1)';
 Sxkp1xkp1 = Sxkp1xkp1+W_K(:,:,k+1)+x_K(:,k+1)*x_K(:,k+1)';
 Sxkxk = Sxkxk+W_K(:,:,k)+x_K(:,k)*x_K(:,k)';

 end

 sumXkTerms = Sxkp1xkp1-A*Sxkxkp1-Sxkxkp1'*A'+A*Sxkxk*A'+...
 W_K(:,:,1)+x_K(:,1)*x_K(:,1)' +... %expected value of xK(1)^2
 -A*x0*x_K(:,1)' -x_K(:,1)*x0'*A' +A*(x0*x0')*A';

 if(strcmp(fitType,'poisson'))
 sumPPll=0;
 for k=1:K
 Hk=HkAll{k};
 Wk = basisMat*diag(W_K(:,:,k));
 stimK=basisMat*x_K(:,k);
 histEffect=exp(gamma*Hk')';
 stimEffect=exp(stimK)+exp(stimK)/2.*Wk;
 % stimEffect=exp(stimK + Wk*0.5);
 ExplambdaDelta =stimEffect.*histEffect;
 ExplogLD = (stimK + (gamma*Hk')');
 sumPPll=sum(dN(k,:)'.*ExplogLD - ExplambdaDelta);

 end
 elseif(strcmp(fitType,'binomial'))

 sumPPll=0;
 for k=1:K
 Hk=HkAll{k};
 Wk = basisMat*diag(W_K(:,:,k));
 stimK=basisMat*x_K(:,k);
 lambdaDelta = exp(stimK+(gamma*Hk')')./(1+exp(stimK+(gamma*Hk')'));
 ExplambdaDelta=lambdaDelta+Wk.*(lambdaDelta.*(1-lambdaDelta).*(1-2*lambdaDelta))/2; 
 % logLD = stimK+(gamma*Hk')' - log(1+lambdaDelta)
 ExplogLD = stimK+(gamma*Hk')' - log(1+exp(stimK+(gamma*Hk')')) -Wk.*(lambdaDelta).*(1-lambdaDelta)*.5;
 %E(f(x)]=f(x_hat) + 1/2sigma_x^2 * d^2/dx*f(x_hat)
 %This is applied to log(1+exp(x_K))
 % 
 sumPPll=sum(dN(k,:)'.*ExplogLD - ExplambdaDelta);
 end

 end
 R=numBasis;

 logll = -R*K*log(2*pi)-K/2*log(det(Q)) + sumPPll - 1/2*trace(pinv(Q)*sumXkTerms);

 end
 function [Qhat,gamma_new] = PPSS_MStep(dN,HkAll,fitType,x_K,W_K,gamma, delta,sumXkTerms,windowTimes)
 K=size(dN,1);
 N=size(dN,2);

 sumQ = diag(diag(sumXkTerms));
 Qhat = sumQ*(1/K);

 [vec,val]=eig(Qhat); val(val<=0)=0.00000001;
 Qhat =vec*val*vec';
 Qhat = (diag(Qhat));

 minTime=0;
 maxTime=(size(dN,2)-1)*delta;

 numBasis = size(x_K,1);
 if(~isempty(numBasis))
 basisWidth = (maxTime-minTime)/numBasis;
 sampleRate=1/delta;
 unitPulseBasis=nstColl.generateUnitImpulseBasis(basisWidth,minTime,maxTime,sampleRate);
 basisMat = unitPulseBasis.data;
 end

 gamma_new = gamma;

 if(~isempty(windowTimes) && all(gamma_new~=0))
 converged=0;
 iter = 1;
 maxIter=300;
 while(~converged && iter<maxIter)
 % disp([' - Newton-Raphson alg. iter #',num2str(iter)])
 if(strcmp(fitType,'poisson'))

 gradQ=zeros(size(gamma_new,2),1);
 jacQ =zeros(size(gamma_new,2),size(gamma_new,2));
 for k=1:K
 Hk=HkAll{k};

 Wk = basisMat*diag(W_K(:,:,k));
 stimK=basisMat*(x_K(:,k));
 histEffect=exp(gamma_new*Hk')';
 stimEffect=exp(stimK)+exp(stimK)/2.*Wk;
 % stimEffect=exp(stimK+Wk*0.5);
 lambdaDelta = stimEffect.*histEffect;

 gradQ = gradQ + Hk'*dN(k,:)' - Hk'*lambdaDelta;
 % jacQ = jacQ - diag(diag((Hk.*repmat(lambdaDelta,[1 size(Hk,2)]))'*Hk));
 jacQ = jacQ - (Hk.*repmat(lambdaDelta,[1 size(Hk,2)]))'*Hk;
 end

 elseif(strcmp(fitType,'binomial'))
 gradQ=zeros(size(gamma_new,2),1);
 jacQ =zeros(size(gamma_new,2),size(gamma_new,2));
 for k=1:K
 Hk=HkAll{k};

 Wk = basisMat*diag(W_K(:,:,k));
 stimK=basisMat*(x_K(:,k));

 histEffect=exp(gamma_new*Hk')';
 stimEffect=exp(stimK);
 % stimEffect=exp(stimK+Wk*0.5);
 C = stimEffect.*histEffect;
 M = 1./C;
 lambdaDelta = exp(stimK+(gamma*Hk')')./(1+exp(stimK+(gamma*Hk')'));
 ExpLambdaDelta = lambdaDelta+Wk.*(lambdaDelta.*(1-lambdaDelta).*(1-2*lambdaDelta))/2;
 ExpLDSquaredTimesInvExp = (lambdaDelta).^2.*1./C;
 ExpLDCubedTimesInvExpSquared = (lambdaDelta).^3.*M.^2 +Wk/2.*(3.*M.^4.*lambdaDelta.^3+12.*lambdaDelta.^3.*M.^3-12.*M.^4.*lambdaDelta.^4);

 % ExpLambdaDeltaTimesExp = C.*lambdaDelta + (2.*C.*lambdaDelta-3*C.*lambdaDelta.*lambdaDelta).*Wk/2;
 % ExpLambdaDeltaTimesExpSquared = C.^2.*lambdaDelta + (7.*C.^2.*lambdaDelta-5*C.^2.*lambdaDelta.*lambdaDelta).*Wk/2;

 % lambdaDelta = C./(1+C);

 % gradQ = gradQ + (Hk.*repmat(1-lambdaDelta,[1,size(Hk,2)]))'*dN(k,:)'...
 % - (Hk.*repmat(C,[1,size(Hk,2)]))'*lambdaDelta;
 % jacQ = jacQ - (Hk.*repmat(C.*lambdaDelta.*dN(k,:)',[1,size(Hk,2)]))'*Hk...
 % - (Hk.*repmat(lambdaDelta,[1,size(Hk,2)]))'*Hk...
 % - (Hk.*repmat(C.^2.*lambdaDelta,[1,size(Hk,2)]))'*Hk;
 gradQ = gradQ + (Hk.*repmat(1-ExpLambdaDelta,[1,size(Hk,2)]))'*dN(k,:)'...
 - (Hk.*repmat(ExpLDSquaredTimesInvExp./lambdaDelta,[1,size(Hk,2)]))'*lambdaDelta;
 jacQ = jacQ - (Hk.*repmat(ExpLDSquaredTimesInvExp.*dN(k,:)',[1,size(Hk,2)]))'*Hk...
 - (Hk.*repmat(ExpLDSquaredTimesInvExp,[1,size(Hk,2)]))'*Hk...
 - (Hk.*repmat(2*ExpLDCubedTimesInvExpSquared,[1,size(Hk,2)]))'*Hk;

 end

 end

 gamma_newTemp = (gamma_new'-pinv(jacQ)*gradQ)';
 if(any(isnan(gamma_newTemp)))
 gamma_newTemp = gamma_new;
 % gradQ=max(gradQ,-10);
 % gradQ=min(gradQ,10);
 % gamma_newTemp = (gamma_new' - jacQ\gradQ)';
 % if(any(isnan(gamma_newTemp)))
 % if(isinf(gamma_new))
 % gamma_newTemp(isinf(gamma_new))=-5;
 % else
 % gamma_newTemp=gamma_new; 
 % end
 % 
 % end
 % elseif(abs(gamma_newTemp)>1e1)
 % gamma_newTemp = sign(gamma_newTemp)*1e1;
 end
 mabsDiff = max(abs(gamma_newTemp - gamma_new));
 if(mabsDiff<10^-2)
 converged=1;
 end
 gamma_new=gamma_newTemp;
 iter=iter+1;
 end
 %Keep gamma from getting too large since this effect is
 %exponentiated
 gamma_new(gamma_new>1e2)=1e1;
 gamma_new(gamma_new<-1e2)=-1e1;
 end

 % pause;
 end
 end
end

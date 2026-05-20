classdef KF_EM
    %KF_EM Linear-Gaussian state-space EM (Shumway-Stoffer 1982).
    %
    % Maximum-likelihood estimation of the linear dynamical system
    %   x_{k+1} = A x_k + omega_k, omega ~ N(0,Q)
    %   y_k     = C x_k + alpha + nu_k,  nu ~ N(0,R)
    % via expectation-maximization. The E-step is a forward Kalman pass
    % followed by an RTS backward smoother (both from
    % nstat.decoding.KalmanFilter); the M-step is closed-form for
    % (A, Q, C, R, alpha, x_0, Px_0).
    %
    % Extracted from DecodingAlgorithms.m (Phase 3 Task 3.2 Step G of the
    % 2026-05-19 nSTAT review action plan). DecodingAlgorithms.KF_* are
    % now thin deprecation shims that forward here.
    %
    % Static methods:
    %   KF_EMCreateConstraints        -- EM constraint builder.
    %   KF_EM                         -- Main EM loop.
    %   KF_ComputeParamStandardErrors -- Fisher-info SE calculator (~740 LOC,
    %                                    longest single method in nSTAT).
    %   KF_EStep                      -- Forward-backward E-step (Kalman
    %                                    filter + RTS smoother).
    %   KF_MStep                      -- Closed-form M-step.
    %
    % Cross-cluster calls in the E-step are rewired directly to
    % nstat.decoding.KalmanFilter.* (kalman_filter, kalman_smootherFromFiltered)
    % so EM iterations do not emit the deprecation-shim warning on every pass.
    %
    % Refs: Shumway & Stoffer 1982, Time Series Analysis;
    %       Ghahramani & Hinton 1996, Parameter estimation for linear
    %       dynamical systems.

    methods (Static)
        function C = KF_EMCreateConstraints(EstimateA, AhatDiag,QhatDiag,QhatIsotropic,RhatDiag,RhatIsotropic,Estimatex0,EstimatePx0, Px0Isotropic,mcIter,EnableIkeda)
            %By default, all parameters are estimated. To empose diagonal
            %structure on the EM parameter results must pass in the
            %constraints element
            if(nargin<11 || isempty(EnableIkeda))
                EnableIkeda=0;
            end
            if(nargin<10 || isempty(mcIter))
                mcIter=1000;
            end
            if(nargin<9 || isempty(Px0Isotropic))
                Px0Isotropic=0;
            end
            if(nargin<8 || isempty(EstimatePx0))
                EstimatePx0=1;
            end
            if(nargin<7 || isempty(Estimatex0))
                Estimatex0=1;
            end
            if(nargin<6 || isempty(RhatIsotropic))
                RhatIsotropic=0;
            end
            if(nargin<5 || isempty(RhatDiag))
                RhatDiag=1;
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
            C.RhatDiag = RhatDiag;
            if(RhatDiag && RhatIsotropic)
                C.RhatIsotropic=1;
            else
                C.RhatIsotropic=0;
            end
            C.Estimatex0 = Estimatex0;
            C.EstimatePx0 = EstimatePx0;
            if(EstimatePx0 && Px0Isotropic)
                C.Px0Isotropic=1;
            else
                C.Px0Isotropic=0; 
            end
            C.mcIter = mcIter;
            C.EnableIkeda = EnableIkeda;
        end
        function [xKFinal,WKFinal,Ahat, Qhat, Chat, Rhat,alphahat, x0hat, Px0hat, IC, SE, Pvals, nIter]=KF_EM(y, Ahat0, Qhat0, Chat0, Rhat0, alphahat0, x0, Px0,KFEM_Constraints)
            numStates = size(Ahat0,1);
            
            if(nargin<9 || isempty(KFEM_Constraints))
                KFEM_Constraints=nstat.decoding.KF_EM.KF_EMCreateConstraints;
            end
            if(nargin<8 || isempty(Px0))
                Px0=10e-10*eye(numStates,numStates);
            end
            if(nargin<7 || isempty(x0))
                x0=zeros(numStates,1);
            end
            
    %         tol = 1e-3; %absolute change;
            tolAbs = nstat.Defaults.EM_TolAbs;
            tolRel = nstat.Defaults.EM_TolRel;
            llTol  = nstat.Defaults.EM_LogLTol;
            cnt=1;

            maxIter = 100;

            
            A0 = Ahat0;
            Q0 = Qhat0;
            C0 = Chat0;
            R0 = Rhat0;
            alpha0 = alphahat0;
           
           
            Ahat{1} = A0;
            Qhat{1} = Q0;
            Chat{1} = C0;
            Rhat{1} = R0;
            x0hat{1} = x0;
            Px0hat{1} = Px0;
            alphahat{1} = alpha0;
            yOrig=y;
            numToKeep=10;
            scaledSystem=1;
            
            if(scaledSystem==1)
                Tq = eye(size(Qhat{1}))/(chol(Qhat{1}));
                Tr = eye(size(Rhat{1}))/(chol(Rhat{1}));
                Ahat{1}= Tq*Ahat{1}/Tq;
                Chat{1}= Tr*Chat{1}/Tq;
                Qhat{1}= Tq*Qhat{1}*Tq';
                Rhat{1}= Tr*Rhat{1}*Tr';
                y= Tr*y;
                x0hat{1} = Tq*x0;
                Px0hat{1} = Tq*Px0*Tq';
                alphahat{1}= Tr*alphahat{1};  
            end

            cnt=1;
            dLikelihood(1)=inf;
            negLL=0;
            IkedaAcc=KFEM_Constraints.EnableIkeda;
            %Forward EM
            stoppingCriteria =0;

            disp('                       Kalman Filter/Gaussian Observation EM Algorithm                        ');     
            while(stoppingCriteria~=1 && cnt<=maxIter)
                 storeInd = mod(cnt-1,numToKeep)+1; %make zero-based then mod, then add 1
                 storeIndP1= mod(cnt,numToKeep)+1;
                 storeIndM1= mod(cnt-2,numToKeep)+1;
                disp('--------------------------------------------------------------------------------------------------------');
                disp(['Iteration #' num2str(cnt)]);
                disp('--------------------------------------------------------------------------------------------------------');
                
                
                [x_K{storeInd},W_K{storeInd},ll(cnt),ExpectationSums{storeInd}]=...
                    nstat.decoding.KF_EM.KF_EStep(Ahat{storeInd},Qhat{storeInd},Chat{storeInd},Rhat{storeInd}, y, alphahat{storeInd}, x0hat{storeInd}, Px0hat{storeInd});
                
                [Ahat{storeIndP1}, Qhat{storeIndP1}, Chat{storeIndP1}, Rhat{storeIndP1}, alphahat{storeIndP1},x0hat{storeIndP1},Px0hat{storeIndP1}] ...
                    = nstat.decoding.KF_EM.KF_MStep(y,x_K{storeInd},x0hat{storeInd}, Px0hat{storeInd},ExpectationSums{storeInd},KFEM_Constraints);
              
                if(IkedaAcc==1)
                    disp(['****Ikeda Acceleration Step****']);
                    %y=Cx+alpha+wk wk~Normal with covariance Rk
                     ykNew = mvnrnd((Chat{storeIndP1}*x_K{storeInd}+alphahat{storeIndP1}*ones(1,size(x_K{storeInd},2)))',Rhat{storeIndP1})';
                     
                                    
                     [x_KNew,W_KNew,llNew,ExpectationSumsNew]=...
                        nstat.decoding.KF_EM.KF_EStep(Ahat{storeInd},Qhat{storeInd},Chat{storeInd},Rhat{storeInd}, ykNew, alphahat{storeInd},x0, Px0);
         
                     [AhatNew, QhatNew, ChatNew, RhatNew, alphahatNew,x0new,Px0new] ...
                        = nstat.decoding.KF_EM.KF_MStep(ykNew,x_KNew, x0hat{storeInd}, Px0hat{storeInd}, ExpectationSumsNew,KFEM_Constraints);
               
                    Ahat{storeIndP1} = 2*Ahat{storeIndP1}-AhatNew;
                    Qhat{storeIndP1} = 2*Qhat{storeIndP1}-QhatNew;
                    Qhat{storeIndP1} = (Qhat{storeIndP1}+Qhat{storeIndP1}')/2;
                    Chat{storeIndP1} = 2*Chat{storeIndP1}-ChatNew;
                    Rhat{storeIndP1} = 2*Rhat{storeIndP1}-RhatNew;
                    Rhat{storeIndP1} = (Rhat{storeIndP1}+Rhat{storeIndP1}')/2;
                    alphahat{storeIndP1}=2*alphahat{storeIndP1}-alphahatNew;
                    
%                     x0hat{storeIndP1}   = 2*x0hat{storeIndP1} - x0new;
%                     Px0hat{storeIndP1}  = 2*Px0hat{storeIndP1}- Px0new;
%                     [V,D] = eig(Px0hat{storeIndP1});
%                     D(D<0)=1e-9;
%                     Px0hat{storeIndP1} = V*D*V';
%                     Px0hat{storeIndP1}  = (Px0hat{storeIndP1}+Px0hat{storeIndP1}')/2;
                    
               
                end
                if(KFEM_Constraints.EstimateA==0)
                    Ahat{storeIndP1}=Ahat{storeInd};
                end
                if(cnt==1)
                    dLikelihood(cnt+1)=inf;
                else
                    dLikelihood(cnt+1)=(ll(cnt)-ll(cnt-1));%./abs(logll(cnt-1));
                end
                if(cnt==1)
                    QhatInit = Qhat{1};
                    RhatInit = Rhat{1};
                    xKInit = x_K{1};
                end
                %Plot the progress
%                 if(mod(cnt,2)==0)
                if(cnt==1)
                    scrsz = get(0,'ScreenSize');
                    h=figure('OuterPosition',[scrsz(3)*.01 scrsz(4)*.04 scrsz(3)*.98 scrsz(4)*.95]);
                end
                    figure(h);
                    time = 0:(size(y,2)-1);
                    
                    subplot(2,5,[1 2 6 7]); plot(1:cnt,ll,'k','Linewidth', 2); hy=ylabel('Log Likelihood'); hx=xlabel('Iteration'); axis auto;
                    set([hx, hy],'FontName', 'Arial','FontSize',12,'FontWeight','bold');
                    subplot(2,5,3:5); hNew=plot(time, x_K{storeInd}','Linewidth', 2); hy=ylabel('States'); hx=xlabel('time [s]');
                    set([hx, hy],'FontName', 'Arial','FontSize',12,'FontWeight','bold');
                    hold on; hOrig=plot(time, xKInit','--','Linewidth', 2); 
                    legend([hOrig(1) hNew(1)],'Initial','Current');
                    
                    subplot(2,5,8); hNew=plot(diag(Qhat{storeInd}),'o','Linewidth', 2); hy=ylabel('Q'); hx=xlabel('Diagonal Entry');
                    set(gca, 'XTick'       , 1:1:length(diag(Qhat{storeInd})));
                    set([hx, hy],'FontName', 'Arial','FontSize',12,'FontWeight','bold');
                    hold on; hOrig=plot(diag(QhatInit),'r.','Linewidth', 2); 
                    legend([hOrig(1) hNew(1)],'Initial','Current');
                    
                    subplot(2,5,9); hNew=plot(diag(Rhat{storeInd}),'o','Linewidth', 2); hy=ylabel('R'); hx=xlabel('Diagonal Entry');
                    set(gca, 'XTick'       , 1:1:length(diag(Rhat{storeInd})));
                    set([hx, hy],'FontName', 'Arial','FontSize',12,'FontWeight','bold');
                    hold on; hOrig=plot(diag(RhatInit),'r.','Linewidth', 2); 
                    legend([hOrig(1) hNew(1)],'Initial','Current');
                    
                    
                    subplot(2,5,10); imagesc(Rhat{storeInd}); ht=title('R Matrix Image'); 
                    set(gca, 'XTick'       , 1:1:length(diag(Rhat{storeInd})), 'YTick', 1:1:length(diag(Rhat{storeInd})));
                    set(ht,'FontName', 'Arial','FontSize',12,'FontWeight','bold');
                    drawnow;
                    hold off;
%                 end
                
                if(cnt==1)
                    dMax=inf;
                else
                 dQvals = max(max(abs(sqrt(Qhat{storeInd})-sqrt(Qhat{storeIndM1}))));
                 dRvals = max(max(abs(sqrt(Rhat{storeInd})-sqrt(Rhat{storeIndM1}))));
                 dAvals = max(max(abs((Ahat{storeInd})-(Ahat{storeIndM1}))));
                 dCvals = max(max(abs((Chat{storeInd})-(Chat{storeIndM1}))));
                 dAlphavals = max(abs((alphahat{storeInd})-(alphahat{storeIndM1})));
                 dMax = max([dQvals,dRvals,dAvals,dCvals,dAlphavals]);
                end

% 
%                 dQRel = max(abs(dQvals./sqrt(Qhat(:,storeIndM1))));
%                 dGammaRel = max(abs(dGamma./gammahat(storeIndM1,:)));
%                 dMaxRel = max([dQRel,dGammaRel]);

                if(cnt==1)
                    disp(['Max Parameter Change: N/A']);
                else
                    disp(['Max Parameter Change: ' num2str(dMax)]);
                end 
                cnt=(cnt+1);
                
                if(dMax<tolAbs)
                    stoppingCriteria=1;
                    display(['         EM converged at iteration# ' num2str(cnt-1) ' b/c change in params was within criteria']);
                    negLL=0;
                end
            
                if(abs(dLikelihood(cnt))<llTol  || dLikelihood(cnt)<0)
                    stoppingCriteria=1;
                    display(['         EM stopped at iteration# ' num2str(cnt-1) ' b/c change in likelihood was negative']);
                    negLL=1;
                end
            
                
            end
            disp('--------------------------------------------------------------------------------------------------------');
            
            maxLLIndex  = find(ll == max(ll),1,'first');
            maxLLIndMod =  mod(maxLLIndex-1,numToKeep)+1;
            if(maxLLIndex==1)
%                 maxLLIndex=cnt-1;
                maxLLIndex =1;
                maxLLIndMod = 1;
            elseif(isempty(maxLLIndex))
               maxLLIndex = 1; 
               maxLLIndMod = 1;
%             else
%                maxLLIndMod = mod(maxLLIndex,numToKeep); 
               
            end
            nIter   = cnt-1;  
%             maxLLIndMod
           
            xKFinal = x_K{maxLLIndMod};
            WKFinal = W_K{maxLLIndMod};
            Ahat = Ahat{maxLLIndMod};
            Qhat = Qhat{maxLLIndMod};
            Chat = Chat{maxLLIndMod};
            Rhat = Rhat{maxLLIndMod};
            alphahat = alphahat{maxLLIndMod};
            x0hat =x0hat{maxLLIndMod};
            Px0hat=Px0hat{maxLLIndMod};
            
             if(scaledSystem==1)
               Tq = eye(size(Qhat))/(chol(Q0));
               Tr = eye(size(Rhat))/(chol(R0));
               Ahat=Tq\Ahat*Tq;
               Qhat=(Tq\Qhat)/Tq';
               Chat=Tr\Chat*Tq;
               Rhat=(Tr\Rhat)/Tr';
               alphahat=Tr\alphahat;
               xKFinal = Tq\xKFinal;
               x0hat = Tq\x0hat;
               Px0hat= (Tq\Px0hat)/(Tq');
               tempWK =zeros(size(WKFinal));
               for kk=1:size(WKFinal,3)
                tempWK(:,:,kk)=(Tq\WKFinal(:,:,kk))/Tq';
               end
               WKFinal = tempWK;
             end
            
            ll = ll(maxLLIndex);
            ExpectationSumsFinal = ExpectationSums{maxLLIndMod};

            if(nargout>10)
                [SE, Pvals]=nstat.decoding.KF_EM.KF_ComputeParamStandardErrors(y, xKFinal, WKFinal, Ahat, Qhat, Chat, Rhat, alphahat, x0hat, Px0hat, ExpectationSumsFinal, KFEM_Constraints);
            end
             %Compute number of parameters
            if(KFEM_Constraints.EstimateA==1 && KFEM_Constraints.AhatDiag==1)
                n1=size(Ahat,1); 
            elseif(KFEM_Constraints.EstimateA==1 && KFEM_Constraints.AhatDiag==0)
                n1=numel(Ahat);
            else 
                n1=0;
            end
            if(KFEM_Constraints.QhatDiag==1 && KFEM_Constraints.QhatIsotropic==1)
                n2=1;
            elseif(KFEM_Constraints.QhatDiag==1 && KFEM_Constraints.QhatIsotropic==0)
                n2=size(Qhat,1);
            else
                n2=numel(Qhat);
            end

            n3=numel(Chat); 
            if(KFEM_Constraints.RhatDiag==1 && KFEM_Constraints.RhatIsotropic==1)
                n4=1;
            elseif(KFEM_Constraints.QhatDiag==1 && KFEM_Constraints.QhatIsotropic==0)
                n4=size(Rhat,1);
            else
                n4=numel(Rhat);
            end

            if(KFEM_Constraints.EstimatePx0==1 && KFEM_Constraints.Px0Isotropic==1)
                n5=1;
            elseif(KFEM_Constraints.EstimatePx0==1 && KFEM_Constraints.Px0Isotropic==0)
                n5=size(Px0hat,1);
            else
                n5=0;
            end

            if(KFEM_Constraints.Estimatex0==1)   
                n6=size(x0hat,1);
            else
                n6=0;
            end

            n7=size(alphahat,1);
           
            nTerms=n1+n2+n3+n4+n5+n6+n7;
            K  = size(y,2); 
            Dx = size(Ahat,2);
            sumXkTerms = ExpectationSums{maxLLIndMod}.sumXkTerms;
            llobs = ll + Dx*K/2*log(2*pi)+K/2*log(det(Qhat))...
                + 1/2*trace(Qhat\sumXkTerms)...
                + Dx/2*log(2*pi)+1/2*log(det(Px0hat)) ...
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
        function [SE,Pvals,nTerms] = KF_ComputeParamStandardErrors(y, xKFinal, WKFinal, Ahat, Qhat, Chat, Rhat, alphahat, x0hat, Px0hat, ExpectationSumsFinal, KFEM_Constraints)
         % Use inverse observed information matrix to estimate the standard errors of the estimated model parameters
         % Requires computation of the complete information matrix and an estimate of the missing information matrix

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
        % Complete Information Matrices     
        % Recall from McLachlan and Krishnan Eq. 4.7
        %    Io(theta;y) = Ic(theta;y) - Im(theta;y)
        %    Io(theta;y) = Ic(theta;y) - cov(Sc(X;theta)Sc(X;theta)')
        % where Sc(X;theta) is the score vector of the complete log likelihood
        % function evaluated at theta. We first compute Ic term by term and then
        % approximate the covariance term using Monte Carlo approximation
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            if(nargin<12 || isempty(KFEM_Constraints))
                KFEM_Constraints=nstat.decoding.KF_EM.KF_EMCreateConstraints;
            end

            if(KFEM_Constraints.AhatDiag==1)
                IAComp=zeros(numel(diag(Ahat)),numel(diag(Ahat)));
            else
                IAComp=zeros(numel(Ahat),numel(Ahat));
            end
            [n1,n2] =size(Ahat);
            el=(eye(n1,n1));
            em=(eye(n2,n2));
            cnt=1;
            N=size(y,2);

            if(KFEM_Constraints.AhatDiag==1)
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


            ICComp=zeros(numel(Chat),numel(Chat));
            [n1,n2] =size(Chat);
            el=(eye(n1,n1));
            em=(eye(n2,n2));
            cnt=1;
            for l=1:n1
                for m=1:n2
                    termMat=Rhat\el(:,l)*em(:,m)'*ExpectationSumsFinal.Sxkxk;
                    termvec=reshape(termMat',1,numel(Chat));
                    ICComp(:,cnt)=termvec';
                    cnt=cnt+1;
                end
            end

            [n1,n2] =size(Rhat);
            ei=(eye(n1,n1));
            ej=(eye(n2,n2));
            cnt=1;
            [dy,N]=size(y);
            dx=size(xKFinal,1);

        %     if(KFEM_Constraints.RhatDiag==1)
        %         if(KFEM_Constraints.RhatIsotropic)
        %             IRinvComp=zeros(1,1);
        %             IRinvComp =  0.5*N*dy*Rhat(1,1)^2; 
        %         else
        %             IRinvComp=zeros(numel(diag(Rhat)),numel(diag(Rhat)));
        %             for i=1:n1
        %                 for j=i
        %                     termMat= N/2*(Rhat)\ei(:,i)*ej(:,j)'/(Rhat);
        %                     termvec=diag(termMat);
        %         %             termvec=reshape(termMat',1,numel(Rhat));
        %                     IRinvComp(cnt,:)=termvec';
        %                     cnt=cnt+1;
        %                 end
        %             end
        %         end
        %     else
        %         IRinvComp=zeros(numel(Rhat),numel(Rhat));
        %         for i=1:n1
        %             for j=1:n2
        %                 termMat= N/2*(Rhat)\ei(:,i)*ej(:,j)'/(Rhat);
        %                 termvec=reshape(termMat',1,numel(Rhat));
        %                 IRinvComp(cnt,:)=termvec;
        %                 cnt=cnt+1;
        %             end
        %         end
        %     end

            [n1,n2] =size(Rhat);
            el=(eye(n1,n1));
            em=(eye(n2,n2));
            cnt=1;
            N=size(y,2);
            if(KFEM_Constraints.RhatDiag==1)
                if(KFEM_Constraints.RhatIsotropic==1)
                    IRComp = 0.5*N*dy*Rhat(1,1)^(-2);
                else
                    IRComp=zeros(numel(diag(Rhat)),numel(diag(Rhat)));
                    for l=1:n1
                        for m=l
                            termMat= N/2*(Rhat)\em(:,m)*el(:,l)'/(Rhat);
                            termvec=diag(termMat);
                            IRComp(:,cnt)=termvec;
                            cnt=cnt+1;
                        end
                    end
                end
            else
                IRComp=zeros(numel((Rhat)),numel((Rhat)));
                for l=1:n1
                    for m=1:n2
                        termMat= N/2*(Rhat)\em(:,m)*el(:,l)'/(Rhat);
                        termvec=reshape(termMat',1,numel(Rhat));
                        IRComp(:,cnt)=termvec;
                        cnt=cnt+1;
                    end
                end
            end

        %     [n1,n2] =size(Qhat);
        %     ei=(eye(n1,n1));
        %     ej=(eye(n2,n2));
        %     cnt=1;
        %     N=size(y,2);
        %     dx=size(xKFinal,1);
        %     if(KFEM_Constraints.QhatDiag==1)
        %         if(KFEM_Constraints.QhatIsotropic==1)
        %             IQinvComp=zeros(1,1);
        %             IQinvComp =  0.5*N*dx*Qhat(1,1)^2; 
        %             
        %         else
        %             IQinvComp=zeros(numel(diag(Qhat)),numel(diag(Qhat)));
        %             for i=1:n1
        %                 for j=i
        %                     termMat= N/2*(Qhat)\ei(:,i)*ej(:,j)'/(Qhat);
        %                     termvec=diag(termMat);
        %         %             termvec=reshape(termMat',1,numel(Qhat));
        %                     IQinvComp(cnt,:)=termvec';
        %                     cnt=cnt+1;
        %                 end
        %             end
        %         end
        %     else
        %         IQinvComp=zeros(numel(Qhat),numel(Qhat));
        %         for i=1:n1
        %             for j=1:n2
        %                 termMat= N/2*(Qhat)\ei(:,i)*ej(:,j)'/(Qhat);
        %                 termvec=reshape(termMat',1,numel(Qhat));
        %                 IQinvComp(cnt,:)=termvec';
        %                 cnt=cnt+1;
        %             end
        %         end
        %     end

            [n1,n2] =size(Qhat);
            el=(eye(n1,n1));
            em=(eye(n2,n2));
            cnt=1;
            N=size(y,2);
            if(KFEM_Constraints.QhatDiag==1)
                if(KFEM_Constraints.QhatIsotropic==1)
                    IQComp=zeros(1,1);
                    IQComp =  0.5*N*dx*Qhat(1,1)^(-2); 
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

            if(KFEM_Constraints.EstimatePx0==1)
                if(KFEM_Constraints.Px0Isotropic==1)
        %             ISinvComp =  0.5*dx*Px0hat(1,1)^2;
                    ISComp =  0.5*dx*Px0hat(1,1)^(-2);
                else
        %             ISinvComp=zeros(numel(diag(Px0hat)),numel(diag(Px0hat)));
        %             [n1,n2] =size(Px0hat);
        %             ei=(eye(n1,n1));
        %             ej=(eye(n2,n2));
        %             cnt=1;
        %             for i=1:n1
        %                 for j=i
        %                     termMat= 1/2*(Px0hat)\ei(:,i)*ej(:,j)'/(Px0hat);
        %         %             termvec=reshape(termMat',1,numel(Px0hat));
        %                     termvec=diag(termMat);
        %                     ISinvComp(cnt,:)=termvec';
        %                     cnt=cnt+1;
        %                 end
        %             end

                    ISComp=zeros(numel(diag(Px0hat)),numel(diag(Px0hat)));
                    [n1,n2] =size(Px0hat);
                    el=(eye(n1,n1));
                    em=(eye(n2,n2));
                    cnt=1;
                    for l=1:n1
                        for m=l
                            termMat= 1/2*(Px0hat)\em(:,m)*el(:,l)'/(Px0hat);
                            termvec=diag(termMat);
                %             termvec=reshape(termMat',1,numel(Rhat));
                            ISComp(:,cnt)=termvec;
                            cnt=cnt+1;
                        end
                    end
                end
            end

            if(KFEM_Constraints.Estimatex0==1)
                Ix0Comp=eye(size(Px0hat))/Px0hat+(Ahat'/Qhat)*Ahat;
            end

            IAlphaComp = N*eye(size(Rhat))/Rhat;
            if(KFEM_Constraints.EstimateA==1)
                n1=size(IAComp,1); 
            else
                n1=0;
            end
            n2=size(IQComp,1); n3=size(ICComp,1);
            n4=size(IRComp,1); 
            if(KFEM_Constraints.EstimatePx0==1)
                n5=size(ISComp,1); 
            else
                n5=0;
            end
            if(KFEM_Constraints.Estimatex0==1)   
                n6=size(Ix0Comp,1);
            else
                n6=0;
            end
            n7=size(IAlphaComp,1);
            nTerms=n1+n2+n3+n4+n5+n6+n7;
            IComp = zeros(nTerms,nTerms);
            if(KFEM_Constraints.EstimateA==1)
                IComp(1:n1,1:n1)=IAComp;
            end
            offset=n1+1;
            IComp(offset:(n1+n2),offset:(n1+n2))=IQComp;
            offset=n1+n2+1;
            IComp(offset:(n1+n2+n3),offset:(n1+n2+n3))=ICComp;
            offset=n1+n2+n3+1;
            IComp(offset:(n1+n2+n3+n4),offset:(n1+n2+n3+n4))=IRComp;
            offset=n1+n2+n3+n4+1;
            if(KFEM_Constraints.EstimatePx0==1);
                IComp(offset:(n1+n2+n3+n4+n5),offset:(n1+n2+n3+n4+n5))=ISComp;
            end
            offset=n1+n2+n3+n4+n5+1;
            if(KFEM_Constraints.Estimatex0==1)
                IComp(offset:(n1+n2+n3+n4+n5+n6),offset:(n1+n2+n3+n4+n5+n6))=Ix0Comp;
            end
            offset=n1+n2+n3+n4+n5+n6+1;
            IComp(offset:(n1+n2+n3+n4+n5+n6+n7),offset:(n1+n2+n3+n4+n5+n6+n7))=IAlphaComp;


            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Missing Information Matrix
            %Approximate cov(Sc(X;theta)Sc(X;theta)')
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            K=size(y,2);
            Mc=KFEM_Constraints.mcIter;
            xKDraw = zeros(size(xKFinal,1),N,Mc);
        %     IMissing = zeros(nTerms,nTerms);
        % 
        %     if(KFEM_Constraints.AhatDiag==1)
        %         ScoreAMc = zeros(numel(diag(Ahat)),Mc);
        %         IAMissing=zeros(numel(diag(Ahat)),numel(diag(Ahat)));
        %     else
        %         ScoreAMc = zeros(numel(Ahat),Mc);
        %         IAMissing=zeros(numel(Ahat),numel(Ahat));
        %     end
        % 
        %     ScoreCMc = zeros(numel(Chat),Mc);
        %     if(KFEM_Constraints.RhatDiag==1)
        %         if(KFEM_Constraints.RhatIsotropic==1)
        %             ScoreRinvMc = zeros(1,Mc);  
        %             ScoreRMc = zeros(1,Mc);
        %             IRinvMissing=zeros(1,1);
        %             IRMissing=zeros(1,1);
        %         else
        %             ScoreRinvMc = zeros(numel(diag(Rhat)),Mc);  
        %             ScoreRMc = zeros(numel(diag(Rhat)),Mc);
        %             IRinvMissing=zeros(numel(diag(Rhat)),numel(diag(Rhat)));
        %             IRMissing=zeros(numel(diag(Rhat)),numel(diag(Rhat)));
        %         end
        %     else
        %         ScoreRMc = zeros(numel(Rhat),Mc);
        %         ScoreRinvMc = zeros(numel(Rhat),Mc);
        %         IRMissing=zeros(numel(Rhat),numel(Rhat));
        %         IRinvMissing=zeros(numel(Rhat),numel(Rhat));
        %     end
        % 
        %     if(KFEM_Constraints.QhatDiag==1)
        %         if(KFEM_Constraints.QhatIsotropic==1)
        %             ScoreQinvMc = zeros(1,Mc);
        %             ScoreQMc    = zeros(1,Mc); 
        %         else
        %             ScoreQinvMc = zeros(numel(diag(Qhat)),Mc);
        %             ScoreQMc    = zeros(numel(diag(Qhat)),Mc);
        %         end
        %     else
        %         ScoreQMc = zeros(numel(Qhat),Mc);
        %     end
        %     ScoreAlphaMc = zeros(numel(alphahat),Mc);

            % Generate the Monte Carlo samples for the unobserved data
            for n=1:N
                WuTemp=(WKFinal(:,:,n));
                [chol_m,p]=chol(WuTemp);
                z=normrnd(0,1,size(xKFinal,1),Mc);
                xKDraw(:,n,:)=repmat(xKFinal(:,n),[1 Mc])+(chol_m*z);
            end


            if(KFEM_Constraints.EstimatePx0|| KFEM_Constraints.Estimatex0)
                [chol_m,p]=chol(Px0hat);
                z=normrnd(0,1,size(xKFinal,1),Mc);
                x0Draw=repmat(x0hat,[1 Mc])+(chol_m*z); 
            else
               x0Draw=repmat(x0hat, [1 Mc]);

            end

            IMc = zeros(nTerms,nTerms,Mc);
            % Emperically estimate the covariance of the score
        %     if matlabpool('size') == 0 % checking to see if my pool is already open
        %         matlabpool;
        %     end
%             pools = matlabpool('size'); %number of parallel workers 
pools=0;
            if(pools==0) % parallel toolbox is not enabled;
                for c=1:Mc
                    x_K=xKDraw(:,:,c);
                    x_0=x0Draw(:,c);

                    Dx=size(x_K,1);
                    Dy=size(y,1);
                    Sxkm1xk = zeros(Dx,Dx);
                    Sxkm1xkm1 = zeros(Dx,Dx);
                    Sxkxk = zeros(Dx,Dx);
                    Sykyk = zeros(Dy,Dy);
                    Sxkyk = zeros(Dx,Dy);        

                    for k=1:K
                        if(k==1)
                            Sxkm1xk   = Sxkm1xk+x_0*x_K(:,k)';
                            Sxkm1xkm1 = Sxkm1xkm1+x_0*x_0';     
                        else
                            Sxkm1xk =  Sxkm1xk+x_K(:,k-1)*x_K(:,k)';
                            Sxkm1xkm1= Sxkm1xkm1+x_K(:,k-1)*x_K(:,k-1)';
                        end
                        Sxkxk = Sxkxk+x_K(:,k)*x_K(:,k)';
                        Sykyk = Sykyk+(y(:,k)-alphahat)*(y(:,k)-alphahat)';
                        Sxkyk = Sxkyk+x_K(:,k)*(y(:,k)-alphahat)';

                    end
                    Sx0x0 = x_0*x_0';
                    Sxkxk = 0.5*(Sxkxk+Sxkxk');
                    Sykyk = 0.5*(Sykyk+Sykyk');
                    sumXkTerms = Sxkxk-Ahat*Sxkm1xk-Sxkm1xk'*Ahat'+Ahat*Sxkm1xkm1*Ahat';
                    sumYkTerms = Sykyk - Chat*Sxkyk - Sxkyk'*Chat' + Chat*Sxkxk*Chat';      
                    Sxkxkm1 = Sxkm1xk';
                    Sykxk = Sxkyk';


                    sumXkTerms=0.5*(sumXkTerms+sumXkTerms');
                    sumYkTerms=0.5*(sumYkTerms+sumYkTerms');
                    if(KFEM_Constraints.EstimateA==1)
                        ScorA=Qhat\(Sxkxkm1-Ahat*Sxkm1xkm1);
                        if(KFEM_Constraints.AhatDiag==1)
                            ScoreAMc=diag(ScorA);
                        else
                            ScoreAMc=reshape(ScorA',numel(Ahat),1);
                        end
                    end

                    ScorC=Rhat\(Sykxk-Chat*Sxkxk);
                    ScoreCMc=reshape(ScorC',numel(ScorC),1);

                    if(KFEM_Constraints.QhatDiag)
                        if(KFEM_Constraints.QhatIsotropic)
                            ScoreQ  =-.5*(K*Dx*Qhat(1,1)^(-1) - Qhat(1,1)^(-2)*trace(sumXkTerms));
                        else
                            ScoreQ  =(-.5*(Qhat\(K*eye(size(Qhat)) - sumXkTerms/Qhat)));
                        end
                        ScoreQMc = diag(ScoreQ);
                    else
                        ScoreQ   =-.5*(Qhat\(K*eye(size(Qhat)) - sumXkTerms/Qhat));
                        ScoreQMc =reshape(ScoreQ',numel(ScoreQ),1);
                    end


                    ScoreAlphaMc = sum(Rhat\(y-Chat*x_K-alphahat*ones(1,N)),2);
                    if(KFEM_Constraints.RhatDiag)
                        if(KFEM_Constraints.RhatIsotropic)
                            ScoreR  =-.5*(K*Dy*Rhat(1,1)^(-1) - Rhat(1,1)^(-2)*trace(sumYkTerms));
                        else
                            ScoreR  =(-.5*(Rhat\(K*eye(size(Rhat)) - sumYkTerms/Rhat)));
                        end
                        ScoreRMc = diag(ScoreR);
                    else
                        ScoreR   =-.5*(Rhat\(K*eye(size(Rhat)) - sumYkTerms/Rhat));
                        ScoreRMc =reshape(ScoreR',numel(ScoreR),1);
                    end


                    if(KFEM_Constraints.Px0Isotropic==1)
                        ScoreSMc=-.5*(Dx*Px0hat(1,1)^(-1) - Px0hat(1,1)^(-2)*trace((x_0-x0hat)*(x_0-x0hat)'));
                    else
                        ScorS  =-.5*(Px0hat\(eye(size(Px0hat)) - (x_0-x0hat)*(x_0-x0hat)'/Px0hat));
                        ScoreSMc = diag(ScorS);
                    end

                    Scorx0=(-Px0hat\(x_0-x0hat))+Ahat'/Qhat*(x_K(:,1)-Ahat*x_0);
                    Scorex0Mc=reshape(Scorx0',numel(Scorx0),1);

                    if(KFEM_Constraints.EstimateA==1)
                        ScoreVec = ScoreAMc;
                    else
                        ScoreVec = [];
                    end
                    ScoreVec = [ScoreVec; ScoreQMc; ScoreCMc; ScoreRMc];
                    if(KFEM_Constraints.EstimatePx0==1)
                        ScoreVec = [ScoreVec; ScoreSMc]; 
                    end
                    if(KFEM_Constraints.Estimatex0==1)
                        ScoreVec = [ScoreVec; Scorex0Mc];
                    end
                    ScoreVec = [ScoreVec; ScoreAlphaMc];
                    IMc(:,:,c)=ScoreVec*ScoreVec';    
                end
            else %Use the parallel toolbox
                for c=1:Mc
                    x_K=xKDraw(:,:,c);
                    x_0=x0Draw(:,c);

                    Dx=size(x_K,1);
                    Dy=size(y,1);
                    Sxkm1xk = zeros(Dx,Dx);
                    Sxkm1xkm1 = zeros(Dx,Dx);
                    Sxkxk = zeros(Dx,Dx);
                    Sykyk = zeros(Dy,Dy);
                    Sxkyk = zeros(Dx,Dy);        

                    for k=1:K
                        if(k==1)
                            Sxkm1xk   = Sxkm1xk+x_0*x_K(:,k)';
                            Sxkm1xkm1 = Sxkm1xkm1+x_0*x_0';     
                        else
                            Sxkm1xk =  Sxkm1xk+x_K(:,k-1)*x_K(:,k)';
                            Sxkm1xkm1= Sxkm1xkm1+x_K(:,k-1)*x_K(:,k-1)';
                        end
                        Sxkxk = Sxkxk+x_K(:,k)*x_K(:,k)';
                        Sykyk = Sykyk+(y(:,k)-alphahat)*(y(:,k)-alphahat)';
                        Sxkyk = Sxkyk+x_K(:,k)*(y(:,k)-alphahat)';

                    end
                    Sx0x0 = x_0*x_0';
                    Sxkxk = 0.5*(Sxkxk+Sxkxk');
                    Sykyk = 0.5*(Sykyk+Sykyk');
                    sumXkTerms = Sxkxk-Ahat*Sxkm1xk-Sxkm1xk'*Ahat'+Ahat*Sxkm1xkm1*Ahat';
                    sumYkTerms = Sykyk - Chat*Sxkyk - Sxkyk'*Chat' + Chat*Sxkxk*Chat';      
                    Sxkxkm1 = Sxkm1xk';
                    Sykxk = Sxkyk';


                    sumXkTerms=0.5*(sumXkTerms+sumXkTerms');
                    sumYkTerms=0.5*(sumYkTerms+sumYkTerms');
                    if(KFEM_Constraints.EstimateA==1)
                        ScorA=Qhat\(Sxkxkm1-Ahat*Sxkm1xkm1);
                        if(KFEM_Constraints.AhatDiag==1)
                            ScoreAMc=diag(ScorA);
                        else
                            ScoreAMc=reshape(ScorA',numel(Ahat),1);
                        end
                    else 
                        ScoreAMc=[];
                    end

                    ScorC=Rhat\(Sykxk-Chat*Sxkxk);
                    ScoreCMc=reshape(ScorC',numel(ScorC),1);

                    if(KFEM_Constraints.QhatDiag)
                        if(KFEM_Constraints.QhatIsotropic)
                            ScoreQ  =-.5*(K*Dx*Qhat(1,1)^(-1) - Qhat(1,1)^(-2)*trace(sumXkTerms));
                        else
                            ScoreQ  =(-.5*(Qhat\(K*eye(size(Qhat)) - sumXkTerms/Qhat)));
                        end
                        ScoreQMc = diag(ScoreQ);
                    else
                        ScoreQ   =-.5*(Qhat\(K*eye(size(Qhat)) - sumXkTerms/Qhat));
                        ScoreQMc =reshape(ScoreQ',numel(ScoreQ),1);
                    end


                    ScoreAlphaMc = sum(Rhat\(y-Chat*x_K-alphahat*ones(1,N)),2);
                    if(KFEM_Constraints.RhatDiag)
                        if(KFEM_Constraints.RhatIsotropic)
                            ScoreR  =-.5*(K*Dy*Rhat(1,1)^(-1) - Rhat(1,1)^(-2)*trace(sumYkTerms));
                        else
                            ScoreR  =(-.5*(Rhat\(K*eye(size(Rhat)) - sumYkTerms/Rhat)));
                        end
                        ScoreRMc = diag(ScoreR);
                    else
                        ScoreR   =-.5*(Rhat\(K*eye(size(Rhat)) - sumYkTerms/Rhat));
                        ScoreRMc =reshape(ScoreR',numel(ScoreR),1);
                    end


                    if(KFEM_Constraints.Px0Isotropic==1)
                        ScoreSMc=-.5*(Dx*Px0hat(1,1)^(-1) - Px0hat(1,1)^(-2)*trace((x_0-x0hat)*(x_0-x0hat)'));
                    else
                        ScorS  =-.5*(Px0hat\(eye(size(Px0hat)) - (x_0-x0hat)*(x_0-x0hat)'/Px0hat));
                        ScoreSMc = diag(ScorS);
                    end

                    Scorx0=(-Px0hat\(x_0-x0hat))+Ahat'/Qhat*(x_K(:,1)-Ahat*x_0);
                    Scorex0Mc=reshape(Scorx0',numel(Scorx0),1);
                    ScoreVec = [ScoreAMc; ScoreQMc; ScoreCMc; ScoreRMc];
                    if(KFEM_Constraints.EstimatePx0==1)
                        ScoreVec = [ScoreVec; ScoreSMc]; 
                    end
                    if(KFEM_Constraints.Estimatex0==1)
                        ScoreVec = [ScoreVec; Scorex0Mc];
                    end
                    ScoreVec = [ScoreVec; ScoreAlphaMc];
                    IMc(:,:,c)=ScoreVec*ScoreVec';    
                end

            end
            IMissing = 1/Mc*sum(IMc,3);
            IObs  = IComp-IMissing;  
            invIObs = eye(size(IObs))/IObs;
        %     figure(1); subplot(1,2,1); imagesc(invIObs); subplot(1,2,2); imagesc(nearestSPD(invIObs));
            invIObs = nearestSPD(invIObs); % Find the nearest positive semidefinite approximation for the variance matrix
            VarVec = (diag(invIObs));
            SEVec = sqrt(VarVec);
            SEAterms = SEVec(1:n1);
            SEQterms = SEVec(n1+1:(n1+n2));
            SECterms = SEVec(n1+n2+1:(n1+n2+n3));
            SERterms = SEVec(n1+n2+n3+1:(n1+n2+n3+n4));
            SEPx0terms=SEVec(n1+n2+n3+n4+1:(n1+n2+n3+n4+n5));
            SEx0terms=SEVec(n1+n2+n3+n4+n5+1:(n1+n2+n3+n4+n5+n6));
            SEAlphaterms=SEVec(n1+n2+n3+n4+n5+n6+1:(n1+n2+n3+n4+n5+n6+n7));

        %     matlabpool close;

        %     figure(1); 
        %     subplot(1,3,1); image(IObs); subplot(1,3,2); image(IComp); subplot(1,3,3); image(IMissing);
            if(KFEM_Constraints.EstimatePx0==1)
                SES = diag(SEPx0terms);
            end
            if(KFEM_Constraints.Estimatex0==1)
                SEx0=SEx0terms;
            end
            if(KFEM_Constraints.EstimateA==1)
                if(KFEM_Constraints.AhatDiag==1)
                    SEA=diag(SEAterms);
                else
                    SEA=reshape(SEAterms,size(Ahat,1),size(Ahat,2))';
                end
            end
            SEC=reshape(SECterms,size(Chat,2),size(Chat,1))';
            SEAlpha=reshape(SEAlphaterms,size(alphahat,1),size(alphahat,2));

            if(KFEM_Constraints.RhatDiag==1)
                SER=diag(SERterms);
            else
                SER=reshape(SERterms,size(Rhat,1),size(Rhat,2))';
            end
            if(KFEM_Constraints.QhatDiag==1)
                SEQ=diag(SEQterms);
            else
                SEQ=reshape(SEQterms,size(Qhat,1),size(Qhat,2))'; 
            end
            if(KFEM_Constraints.EstimateA==1)
                SE.A = SEA;
            end
            SE.Q = SEQ;
            SE.C = SEC;
            SE.R = SER;
            SE.alpha = SEAlpha;

            if(KFEM_Constraints.EstimatePx0==1)
                SE.Px0=SES;
            end
            if(KFEM_Constraints.Estimatex0==1)
                SE.x0=SEx0;
            end
            % Compute parameter p-values
            if(KFEM_Constraints.EstimateA==1)
                clear h p;
                if(KFEM_Constraints.AhatDiag==1)
                    VecParams = diag(Ahat);
                    VecSE     = diag(SEA);
                    for i=1:length(VecParams)
                       [h(i) p(i)] = ztest(VecParams(i),0,VecSE(i));
                    end
                    pA = diag(p);
                else
                    VecParams = reshape(Ahat,[numel(Ahat) 1]);
                    VecSE     = reshape(SEA, [numel(Ahat) 1]);
                    for i=1:length(VecParams)
                       [h(i) p(i)] = ztest(VecParams(i),0,VecSE(i));
                    end  
                    pA = reshape(p, [size(Ahat,1) size(Ahat,2)]);
                end
            end
            %C matrix
            clear h p;
            VecParams = reshape(Chat,[numel(Chat) 1]);
            VecSE     = reshape(SEC, [numel(Chat) 1]);
            for i=1:length(VecParams)
               [h(i) p(i)] = ztest(VecParams(i),0,VecSE(i));
            end 
            pC = reshape(p, [size(Chat,1) size(Chat,2)]);

            %R matrix
            clear h p;
            if(KFEM_Constraints.RhatDiag==1)
                if(KFEM_Constraints.RhatIsotropic==1)
                    VecParams = Rhat(1,1);
                    VecSE     = SER(1,1);
                    [h p] = ztest(VecParams,0,VecSE);
                    pR = diag(p);
                else
                    VecParams = diag(Rhat);
                    VecSE     = diag(SER);
                    for i=1:length(VecParams)
                       [h(i) p(i)] = ztest(VecParams(i),0,VecSE(i));
                    end
                    pR = diag(p);
                end
            else
                VecParams = reshape(Rhat,[numel(Rhat) 1]);
                VecSE     = reshape(SER, [numel(Rhat) 1]);
                for i=1:length(VecParams)
                   [h(i) p(i)] = ztest(VecParams(i),0,VecSE(i));
                end  
                pR = reshape(p, [size(Rhat,1) size(Rhat,2)]);
            end

            %Q matrix
            clear h p;
            if(KFEM_Constraints.QhatDiag==1)
                if(KFEM_Constraints.QhatIsotropic==1)
                    VecParams = Qhat(1,1);
                    VecSE     = SEQ(1,1);
                    [h p] = ztest(VecParams,0,VecSE);
                    pQ = diag(p);
                else
                    VecParams = diag(Qhat);
                    VecSE     = diag(SEQ);
                    for i=1:length(VecParams)
                       [h(i) p(i)] = ztest(VecParams(i),0,VecSE(i));
                    end
                    pQ = diag(p);
                end
            else
                VecParams = reshape(Qhat,[numel(Qhat) 1]);
                VecSE     = reshape(SEQ, [numel(Qhat) 1]);
                for i=1:length(VecParams)
                   [h(i) p(i)] = ztest(VecParams(i),0,VecSE(i));
                end  
                pQ = reshape(p, [size(Qhat,1) size(Qhat,2)]);
            end
            %Px0
            if(KFEM_Constraints.EstimatePx0==1)
                clear h p;
                if(KFEM_Constraints.Px0Isotropic==1)
                    VecParams = Px0hat(1,1);
                    VecSE     = SES(1,1);
                    [h p] = ztest(VecParams,0,VecSE);
                    pPX0 = diag(p);
                else
                    VecParams = diag(Px0hat);
                    VecSE     = diag(SES);
                    for i=1:length(VecParams)
                        [h(i) p(i)] = ztest(VecParams(i),0,VecSE(i));
                    end
                    pPX0 = diag(p);
                end
            end

            clear h p;
            VecParams = alphahat;
            VecSE     = SEAlpha;
            for i=1:length(VecParams)
                [h(i) p(i)] = ztest(VecParams(i),0,VecSE(i));
            end
            pAlpha = p';

            if(KFEM_Constraints.Estimatex0==1)
                clear h p;
                VecParams = x0hat;
                VecSE     = SEx0;
                for i=1:length(VecParams)
                    [h(i) p(i)] = ztest(VecParams(i),0,VecSE(i));
                end
                pX0 = p';
            end
            if(KFEM_Constraints.EstimateA==1)
                Pvals.A = pA;
            end
            Pvals.Q = pQ;
            Pvals.C = pC;
            Pvals.R = pR;
            Pvals.alpha = pAlpha;
            if(KFEM_Constraints.EstimatePx0==1)
                Pvals.Px0 = pPX0;
            end
            if(KFEM_Constraints.Estimatex0==1)
                Pvals.x0 = pX0;
            end

        end
        function [x_K,W_K,logll,ExpectationSums]=KF_EStep(A,Q,C,R, y, alpha, x0, Px0)
             DEBUG = 0;

            Dx = size(A,2);
            Dy = size(C,1);
            K=size(y,2);
            [x_p, W_p, x_u, W_u] = nstat.decoding.KalmanFilter.kalman_filter(A, C, Q, R,Px0, x0, y-alpha*ones(1,size(y,2)));
            
            [x_K, W_K,Lk] = nstat.decoding.KalmanFilter.kalman_smootherFromFiltered(A, x_p, W_p, x_u, W_u);

            %Best estimates of initial states given the data
            W1G0 = A*Px0*A' + Q;
            L0=Px0*A'/W1G0;
            
            Ex0Gy = x0+L0*(x_K(:,1)-x_p(:,1));        
            Px0Gy = Px0+L0*(eye(size(W_K(:,:,1)))/(W_K(:,:,1))-eye(size(W1G0))/W1G0)*L0';
            Px0Gy = (Px0Gy+Px0Gy')/2;
            numStates = size(x_K,1);
            Wku=zeros(numStates,numStates,K,K);
            Tk = zeros(numStates,numStates,K-1);
            for k=1:K
                Wku(:,:,k,k)=W_K(:,:,k);
            end

            for u=K:-1:2
                for k=(u-1):-1:(u-1)
                    Tk(:,:,k)=A;
%                     Dk(:,:,k)=W_u(:,:,k)*Tk(:,:,k)'*pinv(W_p(:,:,k)); %From deJong and MacKinnon 1988
                     Dk(:,:,k)=W_u(:,:,k)*Tk(:,:,k)'/(W_p(:,:,k+1)); %From deJong and MacKinnon 1988
                    Wku(:,:,k,u)=Dk(:,:,k)*Wku(:,:,k+1,u);
                    Wku(:,:,u,k)=Wku(:,:,k,u)';
                end
            end
            
            %All terms
            Sxkm1xk = zeros(Dx,Dx);
            Sxkxkm1 = zeros(Dx,Dx);
            Sxkm1xkm1 = zeros(Dx,Dx);
            Sxkxk = zeros(Dx,Dx);
            Sykyk = zeros(Dy,Dy);
            Sxkyk = zeros(Dx,Dy);
            for k=1:K
                if(k==1)
                    Sxkm1xk   = Sxkm1xk+Px0*A'/W_p(:,:,1)*Wku(:,:,1,1);
                    Sxkm1xkm1 = Sxkm1xkm1+Px0+x0*x0';     
                else
                    Sxkm1xk =  Sxkm1xk+Wku(:,:,k-1,k)+x_K(:,k-1)*x_K(:,k)';
                    Sxkm1xkm1= Sxkm1xkm1+Wku(:,:,k-1,k-1)+x_K(:,k-1)*x_K(:,k-1)';
                end
                Sxkxk = Sxkxk+Wku(:,:,k,k)+x_K(:,k)*x_K(:,k)';
                Sykyk = Sykyk+(y(:,k)-alpha)*(y(:,k)-alpha)';
                Sxkyk = Sxkyk+x_K(:,k)*(y(:,k)-alpha)';

            end
            Sx0x0 = Px0+x0*x0';
            Sxkxk = 0.5*(Sxkxk+Sxkxk');
            Sykyk = 0.5*(Sykyk+Sykyk');
            sumXkTerms = Sxkxk-A*Sxkm1xk-Sxkm1xk'*A'+A*Sxkm1xkm1*A';
            sumYkTerms = Sykyk - C*Sxkyk - Sxkyk'*C' + C*Sxkxk*C';      
            Sxkxkm1 = Sxkm1xk';
            
           

            logll = -Dx*K/2*log(2*pi)-K/2*log(det(Q))-Dy*K/2*log(2*pi)...
                    -K/2*log(det(R))- Dx/2*log(2*pi) -1/2*log(det(Px0))  ...
                    -1/2*trace((eye(size(Q))/Q)*sumXkTerms) ...
                    -1/2*trace((eye(size(R))/R)*sumYkTerms) ...
                    -Dx/2;
                string0 = ['logll: ' num2str(logll)];
                disp(string0);
                if(DEBUG==1)
                    string1 = ['-K/2*log(det(Q)):' num2str(-K/2*log(det(Q)))];
                    string11 = ['-K/2*log(det(R)):' num2str(-K/2*log(det(R)))];
                    string12= ['Constants: ' num2str(-Dx*K/2*log(2*pi)-Dy*K/2*log(2*pi)- Dx/2*log(2*pi) -Dx/2 -1/2*log(det(Px0)))];
                    string3 = ['-.5*trace(Q\sumXkTerms): ' num2str(-.5*trace(Q\sumXkTerms))];
                    string4 = ['-.5*trace(R\sumYkTerms): ' num2str(-.5*trace(R\sumYkTerms))];

                    disp(string1);
                    disp(['Q=' num2str(diag(Q)')]);
                    disp(string11);
                    disp(['R=' num2str(diag(R)')]);
                    disp(string12);
                    disp(string3);
                    disp(string4);
                end

                ExpectationSums.Sxkm1xkm1=Sxkm1xkm1;
                ExpectationSums.Sxkm1xk=Sxkm1xk;
                ExpectationSums.Sxkxkm1=Sxkxkm1;
                ExpectationSums.Sxkxk=Sxkxk;
                ExpectationSums.Sxkyk=Sxkyk;
                ExpectationSums.Sykyk=Sykyk;
                ExpectationSums.sumXkTerms=sumXkTerms;
                ExpectationSums.sumYkTerms=sumYkTerms;
                ExpectationSums.Sx0 = Ex0Gy;
                ExpectationSums.Sx0x0 = Px0Gy + Ex0Gy*Ex0Gy';

        end
        function [Ahat, Qhat, Chat, Rhat, alphahat, x0hat, Px0hat] = KF_MStep(y,x_K,x0, Px0, ExpectationSums,KFEM_Constraints)
            if(nargin<6 || isempty(KFEM_Constraints))
                KFEM_Constraints = nstat.decoding.KF_EM.KF_EMCreateConstraints;
            end
            Sxkm1xkm1=ExpectationSums.Sxkm1xkm1;
            Sxkxkm1=ExpectationSums.Sxkxkm1;
            Sxkxk=ExpectationSums.Sxkxk;
            Sxkyk=ExpectationSums.Sxkyk;
            sumXkTerms = ExpectationSums.sumXkTerms;
            sumYkTerms = ExpectationSums.sumYkTerms;
            Sx0 = ExpectationSums.Sx0;
            Sx0x0 = ExpectationSums.Sx0x0;

            [N,K] = size(x_K); 
            
            
            if(KFEM_Constraints.AhatDiag==1)
                I=eye(N,N);
                Ahat = (Sxkxkm1.*I)/(Sxkm1xkm1.*I);
            else
                Ahat = Sxkxkm1/Sxkm1xkm1;
            end
            
            
%              [V,D] = eig(Px0hat);
%              D(D<0)=1e-9;
%              Px0hat = V*D*V';
            
            
             Chat = Sxkyk'/Sxkxk;             
             alphahat = sum(y - Chat*x_K,2)/K;
             
             if(KFEM_Constraints.QhatDiag==1)
                 if(KFEM_Constraints.QhatIsotropic==1)
                     Qhat=1/(N*K)*trace(sumXkTerms)*eye(N,N);
                 else
                     I=eye(N,N);
                     Qhat=1/K*(sumXkTerms.*I);
                     Qhat = (Qhat + Qhat')/2;
                 end
             else
                 Qhat=1/K*sumXkTerms;
                 Qhat = (Qhat + Qhat')/2;
             end
             dy=size(sumYkTerms,1);
             if(KFEM_Constraints.RhatDiag==1)
                 if(KFEM_Constraints.RhatIsotropic==1)
                     I=eye(dy,dy);
                     Rhat = 1/(dy*K)*trace(sumYkTerms)*I;
                 else
                     
                     I=eye(dy,dy);
                     Rhat = 1/K*(sumYkTerms.*I);
                     Rhat = (Rhat + Rhat')/2;
                 end
             else
                 Rhat = 1/K*(sumYkTerms);
                 Rhat = (Rhat + Rhat')/2;  
             end
             if(KFEM_Constraints.Estimatex0)
                x0hat = (inv(Px0)+Ahat'/Qhat*Ahat)\(Ahat'/Qhat*x_K(:,1)+Px0\x0);
            else
                x0hat = x0;
            end
             
            if(KFEM_Constraints.EstimatePx0==1)
                if(KFEM_Constraints.Px0Isotropic==1)
                   Px0hat=(trace(x0hat*x0hat' - x0*x0hat' - x0hat*x0' +(x0*x0'))/(N*K))*eye(N,N); 
                else
                    I=eye(N,N);
                    Px0hat =(x0hat*x0hat' - x0*x0hat' - x0hat*x0' +(x0*x0')).*I;
                    Px0hat = (Px0hat+Px0hat')/2;
                    [V,Lambda]=eig(Px0hat);
                    Lambda = diag(Lambda);
                    if(min(Lambda)<eps)
                        Lambda(Lambda==min(Lambda))=eps;
                        Px0hat = V*diag(Lambda)*V';
                    end
                    
                end
                
            else
                Px0hat =Px0;
            end
            
        end
        
    end
end

classdef PPAF
    %PPAF Point-process adaptive filter (Eden, Frank, Barbieri, Solo & Brown 2004).
    %
    % The spike-train analog of the Kalman filter: linear-Gaussian dynamics
    % plus Poisson observations, closed by a Laplace approximation at the
    % prediction mean.
    %
    % Extracted from DecodingAlgorithms.m (Phase 3 Task 3.2 Step C of the
    % 2026-05-19 nSTAT review action plan). DecodingAlgorithms.PPDecode*
    % and PP_fixedIntervalSmoother are now thin deprecation shims that
    % forward here.
    %
    % Static methods:
    %   PPDecodeFilter            - Forward PPAF for general (symbolic) CIF.
    %   PPDecodeFilterLinear      - Forward PPAF for canonical-link linear
    %                                 CIF (faster; closed-form gradient).
    %   PP_fixedIntervalSmoother  - Fixed-interval smoother wrapper.
    %   PPDecode_predict          - Time-update step.
    %   PPDecode_update           - Measurement-update step (general CIF).
    %   PPDecode_updateLinear     - Measurement-update step (linear CIF).
    %   PPDecode_updateIterated   - Iterated-Laplace update (general CIF;
    %                                 Newton-to-convergence at posterior mode).
    %   PPDecode_updateLinearIterated
    %                              - Iterated-Laplace update (linear CIF).
    %
    % Refs: Eden, Frank, Barbieri, Solo & Brown 2004, Neural Comp 16:971-998;
    %       bci-curriculum chapter-04 §4.B.5 PPAF derivation;
    %       bci-curriculum chapter-04 §4.C.2 PPAF as Newton step on
    %       variational free energy (and iterated-Laplace tightening).

    methods (Static)
        %PPDecodeFilter takes an object of class CIF describing the
        %conditional intensity function. This routine is more generic since
        %all of the computations for the PPAF are done symbolically based
        %on the CIF object. However, it also means that this version is
        %must slower than the linear version below.
        function [x_p, W_p, x_u, W_u, x_uT,W_uT,x_pT, W_pT, WConvIter] = PPDecodeFilter(A, Q, Px0, dN,lambdaCIFColl,binwidth,x0,Pi0, yT,PiT,estimateTarget,Wconv)  
            % A can be static or can be a different matrix for each time N
            if(nargin<13||isempty(Wconv))
                Wconv =[];
            end
            [C,N]   = size(dN); % N time samples, C cells

            ns=size(A,1); % number of states


            if(nargin<12 || isempty(estimateTarget))
                estimateTarget=0;
            end

            if(nargin<11 || isempty(PiT))
                if(estimateTarget==1)
                    PiT = zeros(size(Q));
                else
                    PiT = 0*diag(ones(ns,1))*1e-6;
                end
            end
            if(nargin<9 || isempty(Pi0))
                Pi0 = zeros(ns,ns);
            end
            if(nargin<10 || isempty(yT))
                yT=[];
                Amat = A;
                Qmat = Q;
                ft   = zeros(size(Amat,2),N);
                PiT = zeros(size(Q));

            else


                PitT= zeros(ns,ns,N);  % Pi(t,T) in Srinivasan et al. 
                QT  = zeros(ns,ns,N);  % The noise covaraince given target observation (Q_t)
                if(estimateTarget==1)
                    PitT(:,:,N)=Q;   % Pi(T,T)=Pi_T + Q_T, setting PiT=0
                else
                    PitT(:,:,N)=PiT+Q;
                end
                PhitT = zeros(ns,ns,N);% phi(t,T) - transition matrix from time T to t
    %             PhiTt = zeros(ns,ns,N);% phi(T,t) - transition matrix from time t to T
                PhitT(:,:,N) = eye(ns,ns); % phi(T,T) = I
                B = zeros(ns,ns,N);    % See Equation 2.21 in Srinivasan et. al

                for n=N:-1:2
                    invA=eye(size(A))/A;
                    % state transition matrix
                    PhitT(:,:,n-1)= invA*PhitT(:,:,n);
    %                 PhiTt(:,:,n)= A^(N-n);

                    % Equation 2.16 in Srinivasan et al. Note there is a typo in the paper. 
                    % This is the correct expression. The term Q_t-1 does not
                    % need to be mulitplied by phi(t-1,t)

                    PitT(:,:,n-1) = invA*PitT(:,:,n)*invA'+Q;



                    if(n<=N)
                        B(:,:,n) = A-(Q/PitT(:,:,n))*A; %Equation 2.21 in Srinivasan et. al
                        QT(:,:,n) = Q-(Q/PitT(:,:,n))*Q';
                    end
                end
    %             PhiTt(:,:,1)= A^(N-1);
                B(:,:,1) = A-(Q/PitT(:,:,1))*A;
                QT(:,:,1) = Q-(Q/PitT(:,:,1))*Q';
                % See Equations 2.23 through 2.26 in Srinivasan et. al
                if(estimateTarget==1)
    %                 beta = [beta ;zeros(ns,C)];
                    for n=1:N
                       psi = B(:,:,n);
                       if(n==N)
                           gammaMat = eye(ns,ns);
                       else
                           gammaMat = (Q/PitT(:,:,n))*PhitT(:,:,n);
                       end
                       Amat(:,:,n) = [psi,gammaMat;
                                      zeros(ns,ns), eye(ns,ns)];
        %                if(n>1)
        %                 tUnc(:,:,n) = tUnc(:,:,n-1)+PhiTt(:,:,n)*Q*PhiTt(:,:,n)';
        %                else
        %                 tUnc(:,:,n) = PhiTt(:,:,n)*Q*PhiTt(:,:,n)';   
        %                end
                       Qmat(:,:,n) = [QT(:,:,n),   zeros(ns,ns);
                                      zeros(ns,ns) zeros(ns,ns)]; 
                    end
                else

                    Amat = B;
                    Qmat = QT;
                    for n=1:N
                        ft(:,n)   = (Q/PitT(:,:,n))*PhitT(:,:,n)*yT;
                    end

                end

            end

            if(nargin<8 || isempty(x0))
                x0=zeros(size(A,2),1);
            end

            if(nargin<7)
                binwidth = .001; % in seconds
            end

            %% 
            % Return values are
            % x_p: state estimates given the past x_k|k-1
            % W_p: error covariance estimates given the past
            % x_u: state updates given the data - x_k|k
            % W_u: error covariance updates given the data

            [C,N]   = size(dN); % N time samples, C cells

              %% Initialize the PPAF
            x_p     = zeros( size(Amat,2), N+1 );
            x_u     = zeros( size(Amat,2), N );
            W_p    = zeros( size(Amat,2),size(Amat,2), N+1 );
            W_u    = zeros( size(Amat,2),size(Amat,2), N );




            if(~isempty(yT))
                if(det(Pi0)==0) % Assume x0 is known exactly

                else %else
                    invPi0 = pinv(Pi0);
                    invPitT= pinv(PitT(:,:,1));
                    Pi0New = pinv(invPi0+invPitT);
                    Pi0New(isnan(Pi0New))=0;
                    x0New  = Pi0New*(invPi0*x0+invPitT*PhitT(:,:,1)*yT);
                    x0=x0New; Pi0 = Pi0New;
                end
            end
            if(~isempty(yT) && estimateTarget==1)
                    x0= [x0;yT]; %simultaneous estimation of target requires state augmentation

            end


            if((estimateTarget==1 && ~isempty(yT)) || isempty(yT))
                x_p(:,1)= Amat(:,:,1)*x0;

            else
                invPitT  = pinv(PitT(:,:,1));
    %             invPhitT = pinv(PhitT(:,:,1));
                invA     = pinv(A);
                invPhi0T = pinv(invA*PhitT(:,:,1));
                ut(:,1) = (Q*invPitT)*PhitT(:,:,1)*(yT-invPhi0T*x0);
                [x_p(:,1), W_p(:,:,1)] = nstat.decoding.PPAF.PPDecode_predict(x0, Pi0, Amat(:,:,min(size(Amat,3),1)), Qmat(:,:,min(size(Qmat,3),1)));
                x_p(:,1) = x_p(:,1)+ut(:,1);
                W_p(:,:,1) = W_p(:,:,1) + (Q*invPitT)*A*Pi0*A'*(Q*invPitT)';

    %             x_p(:,1)= Amat(:,:,1)*x0 + ft(:,1);


            end
            if(estimateTarget==1 && ~isempty(yT))
               Pi0New = [Pi0, zeros(ns,ns);
                         zeros(ns,ns)  , zeros(ns,ns)];
               W_p(:,:,1) = Amat(:,:,1)*Pi0New*Amat(:,:,1)'+Qmat(:,:,1);      
            elseif(estimateTarget==0 && isempty(yT))

               W_p(:,:,1) = Amat(:,:,1)*Pi0*Amat(:,:,1)'+Qmat(:,:,1);
            end %Otherwise we computed it above.


            for n=1:N
                [x_u(:,n),   W_u(:,:,n)]   = nstat.decoding.PPAF.PPDecode_update( x_p(:,n), W_p(:,:,n), dN(:,1:n),lambdaCIFColl, binwidth,n);
    %             [x_p(:,n+1), W_p(:,:,n+1)] = nstat.decoding.PPAF.PPDecode_predict(x_u(:,n), W_u(:,:,n), Amat(:,:,min(size(A,3),n)), Qmat(:,:,min(size(Qmat,3))));

                if((estimateTarget==1 && ~isempty(yT)) || isempty(yT))
                    [x_p(:,n+1), W_p(:,:,n+1)] = nstat.decoding.PPAF.PPDecode_predict(x_u(:,n), W_u(:,:,n), Amat(:,:,min(size(Amat,3),n)), Qmat(:,:,min(size(Qmat,3),n)));
                else
                    %ut= Q_{t}\Pi(t,T)^{-1}\phi(t,T)(y_{T}-phi(T,t-1)x_{t-1}
                    if(n<N)
                        ut(:,n+1) = (Q*pinv(PitT(:,:,n+1)))*PhitT(:,:,n+1)*(yT-pinv(PhitT(:,:,n))*x_u(:,n));
        %                 ut(:,n+1) = ut(:,n+1)*delta;
                        [x_p(:,n+1), W_p(:,:,n+1)] = nstat.decoding.PPAF.PPDecode_predict(x_u(:,n), W_u(:,:,n), Amat(:,:,min(size(Amat,3),n)), Qmat(:,:,min(size(Qmat,3),n)));
                        x_p(:,n+1) = x_p(:,n+1)+ut(:,n+1);
                        W_p(:,:,n+1) = W_p(:,:,n+1) + (Q*pinv(PitT(:,:,n+1)))*A*W_u(:,:,n)*A'*(Q*pinv(PitT(:,:,n+1)))';
                    end
                end
                if(n>1 && isempty(Wconv))
                    diffWun = abs(trace(W_u(:,:,n))-W_u(:,:,n-1));
                    mAbsdiffWun = max(max(diffWun));
                    if(mAbsdiffWun<1e-6)
                        Wconv=W_u(:,:,n);
                        WConvIter = n;
                    else
                        WConvIter=[];
                    end
                    
                end
            

            end
            if(~isempty(yT) && estimateTarget==1)
               %decompose the augmented state space into estimates of the state
               %vector and the target position
               x_uT = x_u(ns+1:2*ns,:);
               W_uT = W_u(ns+1:2*ns,ns+1:2*ns,:);
               x_pT = x_p(ns+1:2*ns,:);
               W_pT = W_p(ns+1:2*ns,ns+1:2*ns,:);

               x_u = x_u(1:ns,:);
               W_u = W_u(1:ns,1:ns,:);
               x_p = x_p(1:ns,:);
               W_p = W_p(1:ns,1:ns,:);

            else
               x_uT = [];
               W_uT = [];
               x_pT = [];
               W_pT = [];

            end


        end
        %PPDecodeFilterLinear takes in a linear representation of the
        %conditional intensity terms. These are the terms that are inside
        %the exponential in a Poisson or Binomial description of the CIF.
        %If such a representation is available, use of this routine is
        %recommended because it is much faster.
        function [x_p, W_p, x_u, W_u, x_uT,W_uT,x_pT, W_pT] = PPDecodeFilterLinear(A, Q, dN,mu,beta,fitType,delta,gamma,windowTimes,x0, Pi0, yT,PiT,estimateTarget,Wconv)
        % [x_p, W_p, x_u, W_u] = PPDecodeFilterLinear(CIFType,A, Q, dN,beta,gamma,x0, xT)
        % Point process adaptive filter with the assumption of linear
        % expresion for the conditional intensity functions (see below). If
        % the terms in the conditional intensity function include
        % polynomial powers of a variable for example, these expressions do
        % not hold. Use the PPDecodeFilter instead since it will compute
        % these expressions symbolically. However, because of the matlab
        % symbolic toolbox, it runs much slower than this version.
        %
        % If a final value for xT is given then the approach of Srinivasan
        % et. al (2006) is used for concurrent estimate of the state and
        % the target. This involves state augmentation of the original
        % state space model. If a final value is not specified then the
        % standard Point Process Adaptive Filter of Eden et al (2004) is
        % used instead.
        % 
        % Assumes in both cases that 
        %   x_t = A*x_{t-1} + w_{t}     w_{t} ~ Normal with zero me and
        %                                       covariance Q
        %
        %
        % Paramerters:
        %  
        % A:        The state transition matrix from the x_{t-1} to x_{t}
        %
        % Q:        The covariance of the process noise w_t
        %
        % dN:       A C x N matrix of ones and zeros corresponding to the
        %           observed spike trains. N is the number of time steps in
        %           my code. C is the number of cells
        %
        % mu:       Cx1 vector of baseline firing rates for each cell. In
        %           the CIF expression in 'fitType' description 
        %           mu_c=mu(c);
        %
        % beta:     nsxC matrix of coefficients for the conditional
        %           intensity function. ns is the number of states in x_t 
        %           In the conditional intesity function description below
        %           beta_c = beta(:,c)';
        %
        % fitType: 'poisson' or 'binomial'. Determines how the beta and
        %           gamma coefficients are used to compute the conditional
        %           intensity function.
        %           For the cth cell:
        %           If poisson: lambda*delta = exp(mu_c+beta_c*x + gamma_c*hist_c)
        %           If binomial: logit(lambda*delta) = mu_c+beta_c*x + gamma_c*hist_c
        %
        % delta:    The number of seconds per time step. This is used to compute
        %           th history effect for each spike train using the input
        %           windowTimes and gamma
        %
        % gamma:    length(windowTimes)-1 x C matrix of the history
        %           coefficients for each window in windowTimes. In the 'fitType'
        %           expression above:
        %           gamma_c = gamma(:,c)';
        %           If gamma is a length(windowTimes)-1x1 vector, then the
        %           same history coefficients are used for each cell.
        %
        % windowTimes: Defines the distinct windows of time (in seconds)
        %           that will be computed for each spike train.
        %
        % xT:       Target Position
        %
        % PiT:      Target Uncertainty
        %
        % estimateTarget: By default (==0), it is assumed that that the 
        %                 initial target information is fixed. Set to 1 in order to 
        %                 simultaneously estimate the target location via 
        %                 state augmentation
        %
        %
        %
        % Code for reaching to final target adapted from:
        % L. Srinivasan, U. T. Eden, A. S. Willsky, and E. N. Brown, 
        % "A state-space analysis for reconstruction of goal-directed
        % movements using neural signals.,"
        % Neural computation, vol. 18, no. 10, pp. 2465?2494, Oct. 2006.
        %
        % Point Process Adaptive Filter from 
        % U. T. Eden, L. M. Frank, R. Barbieri, V. Solo, and E. N. Brown, 
        % "Dynamic analysis of neural encoding by point process adaptive
        % filtering.,"
        % Neural computation, vol. 16, no. 5, pp. 971?998, May. 2004.
        
            if(nargin<15||isempty(Wconv))
                Wconv =[];
            end
            [C,N]   = size(dN); % N time samples, C cells
            ns=size(A,1); % number of states

            if(isvector(mu) && numel(mu)==C)
                mu = mu(:);
            end
            if(isvector(beta) && ns==1 && numel(beta)==C)
                beta = reshape(beta,1,C);
            elseif(size(beta,1)==C && size(beta,2)==ns)
                beta = beta';
            end

            if(nargin<14 || isempty(estimateTarget))
                estimateTarget=0;
            end
            if(nargin<10 || isempty(x0))
               x0=zeros(ns,1);

            end
            if(nargin<9 || isempty(windowTimes))
               windowTimes=[]; 
            end
            if(nargin<8 || isempty(gamma))
                gamma=0;
            end
            if(nargin<7 || isempty(delta))
                delta = .001;
            end

            if(nargin<13 || isempty(PiT))
                if(estimateTarget==1)
                    PiT = zeros(size(Q));
                else
                    PiT = 0*diag(ones(ns,1))*1e-6;
                end
            end
            if(nargin<11 || isempty(Pi0))
                Pi0 = zeros(ns,ns);
            end
            if(nargin<12 || isempty(yT))
                yT=[];
                Amat = A;
                Qmat = Q;
                ft   = zeros(size(Amat,2),N);
                PiT = zeros(size(Q));

            else


                PitT= zeros(ns,ns,N);  % Pi(t,T) in Srinivasan et al. 
                QT  = zeros(ns,ns,N);  % The noise covaraince given target observation (Q_t)
                QN =Q(:,:,min(size(Q,3),N));
                if(estimateTarget==1)

                    PitT(:,:,N)=QN;   % Pi(T,T)=Pi_T + Q_T, setting PiT=0
                else
                    PitT(:,:,N)=PiT+QN;
                end
                PhitT = zeros(ns,ns,N);% phi(t,T) - transition matrix from time T to t
    %             PhiTt = zeros(ns,ns,N);% phi(T,t) - transition matrix from time t to T
                PhitT(:,:,N) = eye(ns,ns); % phi(T,T) = I
                B = zeros(ns,ns,N);    % See Equation 2.21 in Srinivasan et. al

                for n=N:-1:2
                    An =A(:,:,min(size(A,3),n));
                    Qn =Q(:,:,min(size(Q,3),n));

                    invA=pinv(An);
                    % state transition matrix
                    PhitT(:,:,n-1)= invA*PhitT(:,:,n);
    %                 PhiTt(:,:,n)= A^(N-n);

                    % Equation 2.16 in Srinivasan et al. Note there is a typo in the paper. 
                    % This is the correct expression. The term Q_t-1 does not
                    % need to be mulitplied by phi(t-1,t)

                    PitT(:,:,n-1) = invA*PitT(:,:,n)*invA'+Qn;



                    if(n<=N)

                        B(:,:,n) = An-(Qn*pinv(PitT(:,:,n)))*An; %Equation 2.21 in Srinivasan et. al
                        QT(:,:,n) = Qn-(Qn*pinv(PitT(:,:,n)))*Qn';
                    end
                end
                A1=A(:,:,min(size(A,3),1));
                Q1=Q(:,:,min(size(Q,3),1));
                B(:,:,1) = A1-(Q1*pinv(PitT(:,:,1)))*A1;
                QT(:,:,1) = Q1-(Q1*pinv(PitT(:,:,1)))*Q1';

                % See Equations 2.23 through 2.26 in Srinivasan et. al
                if(estimateTarget==1)
                    beta = [beta ;zeros(ns,C)];
                    for n=1:N
                        An =A(:,:,min(size(A,3),n));
                        Qn =Q(:,:,min(size(Q,3),n));
                        psi = B(:,:,n);
                        if(n==N)
                           gammaMat = eye(ns,ns);
                        else
                           gammaMat = (Qn*pinv(PitT(:,:,n)))*PhitT(:,:,n);
                        end
                        Amat(:,:,n) = [psi,gammaMat;
                                      zeros(ns,ns), eye(ns,ns)];
                        Qmat(:,:,n) = [QT(:,:,n),   zeros(ns,ns);
                                      zeros(ns,ns) zeros(ns,ns)]; 
                    end
                else

                    Amat = B;
                    Qmat = QT;
                    for n=1:N
                        An =A(:,:,min(size(A,3),n));
                        Qn =Q(:,:,min(size(Q,3),n));
                        ft(:,n)   = (Qn*pinv(PitT(:,:,n)))*PhitT(:,:,n)*yT;
                    end

                end

            end


            minTime=0;
            maxTime=(size(dN,2)-1)*delta;

            C=size(dN,1);
            if(~isempty(windowTimes))
                histObj = History(windowTimes,minTime,maxTime);
                HkAll = zeros(size(dN,2),length(windowTimes)-1,C);
                for c=1:C
                    nst{c} = nspikeTrain( (find(dN(c,:)==1)-1)*delta);
                    nst{c}.setMinTime(minTime);
                    nst{c}.setMaxTime(maxTime);
                    nst{c}=nst{c}.resample(1/delta);
                    HkAll(:,:,c) = histObj.computeHistory(nst{c}).dataToMatrix;
    %                 HkAll{c} = histObj.computeHistory(nst{c}).dataToMatrix;
                end
                if(size(gamma,2)==1 && C>1) % if more than 1 cell but only 1 gamma
                    gammaNew = repmat(gamma,1,C); % FIX (#20): was gammaNew(:,c)=gamma reusing post-loop c==C so only the last column was set
                else
                    gammaNew=gamma;
                end
                gamma = gammaNew;

            else
                for c=1:C
    %                 HkAll{c} = zeros(N,1);
                    HkAll(:,:,c) = zeros(N,1);
                    gammaNew(c)=0;
                end
                gamma=gammaNew;

            end
            if(size(gamma,2)~=C)
                gamma=gamma';
            end
        

        
            % Initialize the PPAF
            x_p     = zeros( size(Amat,2), N+1 );
            x_u     = zeros( size(Amat,2), N );
            W_p    = zeros( size(Amat,2),size(Amat,2), N+1 );
            W_u    = zeros( size(Amat,2),size(Amat,2), N );

        


            if(~isempty(yT))
                if(det(Pi0)==0) % Assume x0 is known exactly

                else %else
                    invPi0 = pinv(Pi0);
                    invPitT= pinv(PitT(:,:,1));
                    Pi0New = pinv(invPi0+invPitT);
                    Pi0New(isnan(Pi0New))=0;
                    x0New  = Pi0New*(invPi0*x0+invPitT*PhitT(:,:,1)*yT);
                    x0=x0New; Pi0 = Pi0New;
                end
            end
            if(~isempty(yT) && estimateTarget==1)
                    x0= [x0;yT]; %simultaneous estimation of target requires state augmentation

            end
        
        
            if((estimateTarget==1 && ~isempty(yT)) || isempty(yT))
                x_p(:,1)= Amat(:,:,1)*x0;

            else
                invPitT  = pinv(PitT(:,:,1));
    %             invPhitT = pinv(PhitT(:,:,1));
                A1 = A(:,:,min(size(A,3),1));
                Q1 = Q(:,:,min(size(Q,3),1));
                invA     = pinv(A1);
                invPhi0T = pinv(invA*PhitT(:,:,1));
                ut(:,1) = (Q1*invPitT)*PhitT(:,:,1)*(yT-invPhi0T*x0);
                [x_p(:,1), W_p(:,:,1)] = nstat.decoding.PPAF.PPDecode_predict(x0, Pi0, Amat(:,:,min(size(Amat,3),1)), Qmat(:,:,min(size(Qmat,3),1)));
                x_p(:,1) = x_p(:,1)+ut(:,1);
                W_p(:,:,1) = W_p(:,:,1) + (Q1*invPitT)*A1*Pi0*A1'*(Q1*invPitT)';

    %             x_p(:,1)= Amat(:,:,1)*x0 + ft(:,1);


            end
            if(estimateTarget==1 && ~isempty(yT))
               Pi0New = [Pi0, zeros(ns,ns);
                         zeros(ns,ns)  , zeros(ns,ns)];
               W_p(:,:,1) = Amat(:,:,1)*Pi0New*Amat(:,:,1)'+Qmat(:,:,1);      
            elseif(estimateTarget==0 && isempty(yT))

               W_p(:,:,1) = Amat(:,:,1)*Pi0*Amat(:,:,1)'+Qmat(:,:,1);
            end %Otherwise we computed it above.

            HkPerm = permute(HkAll,[2 3 1]);
            clear t;
            for n=1:N


                [x_u(:,n), W_u(:,:,n)] = nstat.decoding.PPAF.PPDecode_updateLinear(x_p(:,n), W_p(:,:,n), dN,mu,beta,fitType,gamma,HkPerm,n,Wconv);
                % The prediction step is identical to the symbolic implementation since
                % it is independent of the CIF

                if((estimateTarget==1 && ~isempty(yT)) || isempty(yT))
                    [x_p(:,n+1), W_p(:,:,n+1)] = nstat.decoding.PPAF.PPDecode_predict(x_u(:,n), W_u(:,:,n), Amat(:,:,min(size(Amat,3),n)), Qmat(:,:,min(size(Qmat,3),n)),Wconv);
                else
                    %ut= Q_{t}\Pi(t,T)^{-1}\phi(t,T)(y_{T}-phi(T,t-1)x_{t-1}
                    if(n<N)
                        An = A(:,:,min(size(A,3),n));
                        Qn = Q(:,:,min(size(Q,3),n));
                        invPitT  = pinv(PitT(:,:,n+1));
                        invPhitm1T = pinv(PhitT(:,:,n));
                        ut(:,n+1) = (Qn*invPitT)*PhitT(:,:,n+1)*(yT-invPhitm1T*x_u(:,n));
        %                 ut(:,n+1) = ut(:,n+1)*delta;
                        % Predict using modified dynamics B and noise QT.
                        % For time-invariant A, size(A,3)=1 so this always
                        % selects B(:,:,1). The Qmat index selects the last
                        % slice QT(:,:,N). This matches the original
                        % Srinivasan et al. implementation where the
                        % prediction uses the initial modified dynamics
                        % with the terminal modified noise covariance.
                        [x_p(:,n+1), W_p(:,:,n+1)] = nstat.decoding.PPAF.PPDecode_predict(x_u(:,n), W_u(:,:,n), Amat(:,:,min(size(A,3),n)), Qmat(:,:,min(size(Qmat,3))));
                        x_p(:,n+1) = x_p(:,n+1)+ut(:,n+1);
                        W_p(:,:,n+1) = W_p(:,:,n+1) + (Qn*invPitT)*An*W_u(:,:,n)*An'*(Qn*invPitT)';
                    end
                end
            end

        

            if(~isempty(yT) && estimateTarget==1)
               %decompose the augmented state space into estimates of the state
               %vector and the target position
               x_uT = x_u(ns+1:2*ns,:);
               W_uT = W_u(ns+1:2*ns,ns+1:2*ns,:);
               x_pT = x_p(ns+1:2*ns,:);
               W_pT = W_p(ns+1:2*ns,ns+1:2*ns,:);

               x_u = x_u(1:ns,:);
               W_u = W_u(1:ns,1:ns,:);
               x_p = x_p(1:ns,:);
               W_p = W_p(1:ns,1:ns,:);

            else
               x_uT = [];
               W_uT = [];
               x_pT = [];
               W_pT = [];

            end
        end
      
             %% Point Process Fixed-Interval Smoother
        function  [x_pLag, W_pLag, x_uLag, W_uLag] = PP_fixedIntervalSmoother(A, Q, dN, lags, mu,beta,fitType,delta,gamma,windowTimes,x0, Pi0)
      
        [~,N]   = size(dN); % N time samples, C cells
        ns=size(A,1); % number of states
        
        if(nargin<11 || isempty(x0))
           x0=zeros(ns,1);
           
        end
        if(nargin<10 || isempty(windowTimes))
           windowTimes=[]; 
        end
        if(nargin<9 || isempty(gamma))
            gamma=0;
        end
        if(nargin<8 || isempty(delta))
            delta = .001;
        end
        
        if(nargin<12 || isempty(Pi0))
            Pi0 = zeros(ns,ns);
        end
       
        
        minTime=0;
        maxTime=(size(dN,2)-1)*delta;
        
        C=size(dN,1);
        if(~isempty(windowTimes))
            histObj = History(windowTimes,minTime,maxTime);
            HkAll = zeros(size(dN,2),length(windowTimes)-1,C);
            for c=1:C
                nst{c} = nspikeTrain( (find(dN(c,:)==1)-1)*delta);
                nst{c}.setMinTime(minTime);
                nst{c}.setMaxTime(maxTime);
                nst{c}=nst{c}.resample(1/delta);
                HkAll(:,:,c) = histObj.computeHistory(nst{c}).dataToMatrix;
%                 HkAll{c} = histObj.computeHistory(nst{c}).dataToMatrix;
            end
            if(size(gamma,2)==1 && C>1) % if more than 1 cell but only 1 gamma
                gammaNew = repmat(gamma,1,C); % FIX (#20): was gammaNew(:,c)=gamma reusing post-loop c==C so only the last column was set
            else
                gammaNew=gamma;
            end
            gamma = gammaNew;

        else
            for c=1:C
%                 HkAll{c} = zeros(N,1);
                HkAll(:,:,c) = zeros(N,1);
                gammaNew(c)=0;
            end
            gamma=gammaNew;
            
        end
        if(size(gamma,2)~=C)
            gamma=gamma';
        end
        
        %% Initialize the PPAF
        x_p     = zeros( size(A,2), N+1 );
        x_u     = zeros( size(A,2), N );
        W_p    = zeros( size(A,2),size(A,2), N+1 );
        W_u    = zeros( size(A,2),size(A,2), N );
        
        % Assumes that the dynamics only start at time 1 so that A(:,:,0)=I
        x_p(:,1)   = x0;
        W_p(:,:,1) = Pi0;
        
        HkPerm = permute(HkAll,[2 3 1]);
        x_uLag = zeros(size(x_u));
        W_uLag = zeros(size(W_u));
        x_pLag = zeros(size(x_p));
        W_pLag = zeros(size(W_p));
        for n=1:N
            [x_u(:,n), W_u(:,:,n)] = nstat.decoding.PPAF.PPDecode_updateLinear(x_p(:,n), W_p(:,:,n), dN,mu,beta,fitType,gamma,HkPerm,n);
            [x_p(:,n+1), W_p(:,:,n+1)] = nstat.decoding.PPAF.PPDecode_predict(x_u(:,n), W_u(:,:,n), A(:,:,min(size(A,3),n)), Q(:,:,min(size(Q,3),n)));
            x_K=zeros(ns, lags);
            W_K=zeros(ns,ns,lags);
            LnMinusk=zeros(ns, ns, lags);
            if(n>(lags))
                for k=1:lags
                    
                    LnMinusk(:,:,k)=W_u(:,:,n-k)*A(:,:,min(size(A,3),n-k))'/W_p(:,:,n+1-k);
                    if(k==1)
                        x_K(:,k) = x_u(:,n-k)+LnMinusk(:,:,k)*(x_u(:,n+1-k)-x_p(:,n+1-k));
                        W_K(:,:,k)=W_u(:,:,n-k)+LnMinusk(:,:,k)*(W_u(:,:,n+1-k)-W_p(:,:,n+1-k))*LnMinusk(:,:,k)';
                    else                
                        x_K(:,k) = x_u(:,n-k)+LnMinusk(:,:,k)*(x_K(:,k-1)-x_p(:,n+1-k));
                        W_K(:,:,k)=W_u(:,:,n-k)+LnMinusk(:,:,k)*(W_K(:,:,k-1)-W_p(:,:,n+1-k))*LnMinusk(:,:,k)';
                    end
                    W_K(:,:,k) = 0.5*(W_K(:,:,k)+W_K(:,:,k)');
                end

            end
            
            x_uLag(:,n)=x_K(:,lags);
            W_uLag(:,:,n)=W_K(:,:,lags);
            if(lags>1)
                x_pLag(:,n+1)=x_K(:,lags-1);
                W_pLag(:,:,n+1)=W_K(:,:,lags);
            else
                x_pLag(:,n+1)=x_u(:,n);
                W_pLag(:,:,n+1)=W_u(:,:,n);
            end
        
        end
       
        end
        % PPAF Prediction Step 
        function [x_p, W_p] = PPDecode_predict(x_u, W_u, A, Q,Wconv)
            if((nargin<5)||isempty(Wconv))
                Wconv=[];
            end
                % The PPDecode prediction step 
                    x_p     = A * x_u;

                    if(isempty(Wconv))
                        W_p    = A * W_u * A' + Q;
                        condNum=rcond(W_p);
                        if(condNum<eps || isnan(condNum)) % FIX: isa(condNum,'nan') always false; use isnan()
                           W_p=W_u;
                        end
                    
                    else
                        W_p    = Wconv;
                    end
                    
                    W_p = 0.5*(W_p+W_p');

        end
        % PPAF Update Step 
        %PPDecode_update takes in an object of class CIF
        function [x_u, W_u,lambdaDeltaMat] = PPDecode_update(x_p, W_p, dN,lambdaIn,binwidth,time_index,WuConv)
                % The PPDecode update step that finds the state estimate based on new
                % data

                %Original Code
                if(nargin<7||isempty(WuConv))
                    WuConv=[];
                end
                   clear lambda; 
                if(isa(lambdaIn,'cell'))
                    lambda = lambdaIn;
                elseif(isa(lambdaIn,'CIF'))
                    lambda{1} = lambdaIn;
                else
                    error('Lambda must be a cell of CIFs or a CIF');
                end

                clear gradientMat lambdaDeltaMat;
                sumValVec=zeros(size(W_p,1),1);
                sumValMat=zeros(size(W_p,2),size(W_p,2));
                lambdaDeltaMat = zeros(length(lambda),1);
                for C=1:length(lambda)

                   if(isempty(lambda{C}.historyMat))
                        spikeTimes =(find(dN(C,:)==1)-1)*binwidth;
                        nst = nspikeTrain(spikeTimes);
                        nst.resample(1/binwidth);
                        lambdaDeltaMat(C,1) = lambda{C}.evalLambdaDelta(x_p,time_index,nst);
                        sumValVec = sumValVec+dN(C,end)*lambda{C}.evalGradientLog(x_p,time_index,nst)'-lambda{C}.evalGradient(x_p,time_index,nst)';
                        sumValMat = sumValMat-dN(C,end)*lambda{C}.evalJacobianLog(x_p,time_index,nst)'+lambda{C}.evalJacobian(x_p,time_index,nst)';
                   else % we already have computed the history effect and can just use it - much faster
                        lambdaDeltaMat(C,1) = lambda{C}.evalLambdaDelta(x_p,time_index); 
                        sumValVec = sumValVec+dN(C,end)*lambda{C}.evalGradientLog(x_p,time_index)'-lambda{C}.evalGradient(x_p,time_index)';
                        sumValMat = sumValMat-dN(C,end)*lambda{C}.evalJacobianLog(x_p,time_index)'+lambda{C}.evalJacobian(x_p,time_index)';
                   end


                end


                % Use pinv so that we do a SVD and ignore the zero singular values
                % Sometimes because of the state space model definition and how information
                % is integrated from distinct CIFs the sumValMat is very sparse. This
                % allows us to prevent inverting singular matrices
                if(isempty(WuConv))
                    % Phase 3 Task 3.4: Woodbury formula extracted to
                    % nstat.decoding.internal.computeGainMatrix; was 5 lines.
                    W_u = nstat.decoding.internal.computeGainMatrix(W_p, sumValMat);
                else
                    W_u=0.5*(WuConv+WuConv');
                end
               x_u     = x_p + W_u*(sumValVec);


        end       
        %PPDecode_updateLinear takes in a linear representation of the CIF
        %(much faster)
        function [x_u, W_u,lambdaDeltaMat] = PPDecode_updateLinear(x_p, W_p, dN,mu,beta,fitType,gamma,HkAll,time_index,WuConv)
            C   = size(dN,1); % N time samples, C cells
            if(nargin<10|| isempty(WuConv))
                WuConv=[];
            end
            if(nargin<9 || isempty(time_index))
                time_index=1;
            end
            if(nargin<8 || isempty(HkAll))
                [C,N]=size(dN);
                if nargin >= 8
                    numWindows = size(HkAll,2);
                else
                    numWindows = 0;
                end
                HkAll = zeros(N,numWindows,C);
%                 HkAll=cell(C,1);
%                 for c=1:C
%                     HkAll{c}=0;
%                 end
            end
            if(nargin<7 || isempty(gamma))
                % No history: set gamma to empty so the history term
                % evaluates to zero without dimension-mismatch errors.
                gamma=[];
            end
            if(nargin<6 || isempty(fitType))
                fitType = 'poisson';
            end

            
            sumValVec=zeros(size(W_p,1),1);
            sumValMat=zeros(size(W_p,2),size(W_p,2));
            lambdaDeltaMat = zeros(C,1);
            if(numel(gamma)==1 && gamma==0)
                gamma = zeros(size(mu))';
            end
            if(strcmp(fitType,'binomial'))
                %  Histtermperm = permute(HkAll,[2 3 1]); need to send it a
                %  permuted version of HkAll
                if isempty(gamma) || isempty(HkAll) || size(HkAll,2)==0
                    histEffect = zeros(C,1);
                else
                    Histterm = HkAll(:,:,time_index);
                    if(size(Histterm,2)~=size(mu,1))
                        Histterm=Histterm';
                    end
                    histEffect = diag(gamma'*Histterm);
                end
                linTerm = mu+beta'*x_p + histEffect;
                lambdaDeltaMat = exp(linTerm)./(1+exp(linTerm));
                if(any(isnan(lambdaDeltaMat))||any(isinf(lambdaDeltaMat)))
                    indNan = isnan(lambdaDeltaMat);
                    indInf = isinf(lambdaDeltaMat);
                    lambdaDeltaMat(indNan)=1;
                    lambdaDeltaMat(indInf)=1;
                end
                sumValVec=sum(repmat(((dN(:,time_index)-lambdaDeltaMat(:,1)).*(1-lambdaDeltaMat(:,1)))',size(beta,1),1).*beta,2);
                tempVec = ((dN(:,time_index)+(1-2*(lambdaDeltaMat(:,1)))).*(1-(lambdaDeltaMat(:,1))).*(lambdaDeltaMat(:,1)))';
%                 tempVec((tempVec<0))=0;
%                 tempVec((tempVec>1))=1;
                sumValMat = (repmat(tempVec,size(beta,1),1).*beta)*beta';
            elseif(strcmp(fitType,'poisson'))
                if isempty(gamma) || isempty(HkAll) || size(HkAll,2)==0
                    histEffect = zeros(C,1);
                else
                    Histterm = HkAll(:,:,time_index);
                    if(~any(gamma~=0))
                        Histterm = Histterm';
                    end
                    if(size(Histterm,2)~=size(mu,1))
                        Histterm=Histterm';
                    end
                    histEffect = diag(gamma'*Histterm);
                end
                linTerm = mu+beta'*x_p + histEffect;
                lambdaDeltaMat = exp(linTerm);
                if(any(isnan(lambdaDeltaMat))||any(isinf(lambdaDeltaMat)))
                    indNan = isnan(lambdaDeltaMat);
                    indInf = isinf(lambdaDeltaMat);
                    lambdaDeltaMat(indNan)=1;
                    lambdaDeltaMat(indInf)=1;
                end
                sumValVec=sum(repmat(((dN(:,time_index)-lambdaDeltaMat(:,1)))',size(beta,1),1).*beta,2);
                sumValMat = (repmat(lambdaDeltaMat(:,1)',size(beta,1),1).*beta)*beta';
            end
            if(isempty(WuConv))
                    usePInv=0;
                % Phase 3 Task 3.4: Woodbury formula + singularity check
                % extracted to nstat.decoding.internal.computeGainMatrix.
                % The usePInv==1 vs else branches were textually identical;
                % the original pinv() path was never reached (commented out
                % above) so the branch collapse is safe.
                [W_u, isSingular] = nstat.decoding.internal.computeGainMatrix(W_p, sumValMat);
                if isSingular
                    W_u = W_p;
                    W_u = 0.5*(W_u + W_u');
                end %#ok<NASGU> -- usePInv preserved for backwards-compat callers
            else
                W_u = WuConv;
                W_u=0.5*(W_u+W_u');
            end
%             figure(10); subplot(1,3,2);imagesc(W_u); pause(0.005);
            x_u     = x_p + W_u*(sumValVec);


        end

        function [x_u, W_u, lambdaDeltaMat, nIter] = PPDecode_updateIterated(x_p, W_p, dN, lambdaIn, binwidth, time_index, maxIters, tol)
            %PPDECODE_UPDATEITERATED Iterated-Laplace PPAF update (general CIF).
            %
            % Newton-to-convergence variant of PPDecode_update: re-evaluates
            % the gradient and Hessian of the log-likelihood at the *current*
            % posterior-mean iterate at every step, rather than at the
            % prediction mean once. Reduces exactly to PPDecode_update when
            % maxIters == 1.
            %
            % Math (negative log-posterior F at the iterate x^(i)):
            %   F(x)        = 0.5*(x - x_p)' * W_p^{-1} * (x - x_p) - ell(x)
            %   gradF(x^i)  = W_p^{-1}*(x^i - x_p) - grad ell(x^i)
            %   HessF(x^i)  = W_p^{-1} - hess ell(x^i)
            %                = W_p^{-1} + sumValMat^(i)
            % Newton step:
            %   x^{i+1} = x^i - HessF^{-1} * gradF
            %           = x^i + W_u^(i) * ( sumValVec^(i) - W_p^{-1}*(x^i - x_p) )
            % where sumValVec^(i) = grad ell(x^i) and sumValMat^(i) is the
            % per-channel sum of Fisher + data-dependent curvature terms,
            % both evaluated at x^(i) instead of x_p.
            %
            % At i = 0 with x^(0) = x_p, the prior-gradient correction term
            % W_p^{-1}*(x^i - x_p) is zero and the update collapses to the
            % single-step PPDecode_update form. For i >= 1 the correction
            % term is what distinguishes the iterated Laplace approximation
            % from the extended-Kalman one-step linearization.
            %
            % Inputs:
            %   x_p, W_p     - prior mean and covariance from PPDecode_predict.
            %   dN           - C-by-N spike-count matrix; column `time_index`
            %                  is the current bin's observation.
            %   lambdaIn     - CIF or cell array of CIFs (one per channel).
            %   binwidth     - bin width (seconds).
            %   time_index   - column index into dN selecting the current bin.
            %   maxIters     - maximum Newton iterations (default
            %                  nstat.Defaults.PPAF_NewtonIters; 1 reproduces
            %                  PPDecode_update exactly).
            %   tol          - L2 tolerance on the iterate increment
            %                  ||x^{i+1} - x^i|| (default
            %                  nstat.Defaults.FilterConvergenceTol).
            %
            % Outputs:
            %   x_u, W_u, lambdaDeltaMat - same shapes as PPDecode_update.
            %                  lambdaDeltaMat is evaluated at the final x_u.
            %   nIter        - number of Newton iterations actually performed.
            %
            % Refs:
            %   bci-curriculum chapter-04 §4.C.2 PPAF as Newton step on the
            %   variational free energy; the iterated PPAF is the standard
            %   tightening of the Laplace approximation toward the posterior
            %   mode at the cost of an inner loop per timestep.
            %
            % Phase 4 Task 4.1 of the 2026-05-19 nSTAT review action plan.

            if nargin < 7 || isempty(maxIters)
                maxIters = nstat.Defaults.PPAF_NewtonIters;
            end
            if nargin < 8 || isempty(tol)
                tol = nstat.Defaults.FilterConvergenceTol;
            end
            if maxIters < 1
                error('nSTAT:PPDecodeUpdateIterated:InvalidMaxIters', ...
                      'maxIters must be a positive integer; got %g', maxIters);
            end

            clear lambda;
            if isa(lambdaIn, 'cell')
                lambda = lambdaIn;
            elseif isa(lambdaIn, 'CIF')
                lambda{1} = lambdaIn;
            else
                error('Lambda must be a cell of CIFs or a CIF');
            end

            Wp_inv = pinv(W_p);   % pinv for robustness on rank-deficient priors
            x_cur = x_p;
            x_u   = x_p;
            W_u   = W_p;
            lambdaDeltaMat = zeros(length(lambda), 1);
            nIter = 0;

            for nIter = 1:maxIters
                % Re-linearize at the CURRENT iterate x_cur (not x_p).
                sumValVec = zeros(size(W_p,1), 1);
                sumValMat = zeros(size(W_p,2), size(W_p,2));
                for C = 1:length(lambda)
                    if isempty(lambda{C}.historyMat)
                        spikeTimes = (find(dN(C,:)==1) - 1) * binwidth;
                        nst = nspikeTrain(spikeTimes);
                        nst.resample(1/binwidth);
                        lambdaDeltaMat(C,1) = lambda{C}.evalLambdaDelta(x_cur, time_index, nst);
                        sumValVec = sumValVec + dN(C,end) * lambda{C}.evalGradientLog(x_cur, time_index, nst)' ...
                                              - lambda{C}.evalGradient(x_cur, time_index, nst)';
                        sumValMat = sumValMat - dN(C,end) * lambda{C}.evalJacobianLog(x_cur, time_index, nst)' ...
                                              + lambda{C}.evalJacobian(x_cur, time_index, nst)';
                    else
                        lambdaDeltaMat(C,1) = lambda{C}.evalLambdaDelta(x_cur, time_index);
                        sumValVec = sumValVec + dN(C,end) * lambda{C}.evalGradientLog(x_cur, time_index)' ...
                                              - lambda{C}.evalGradient(x_cur, time_index)';
                        sumValMat = sumValMat - dN(C,end) * lambda{C}.evalJacobianLog(x_cur, time_index)' ...
                                              + lambda{C}.evalJacobian(x_cur, time_index)';
                    end
                end

                % Posterior covariance W_u = (W_p^{-1} + sumValMat)^{-1}
                % via Woodbury (same formula PPDecode_update uses).
                W_u = nstat.decoding.internal.computeGainMatrix(W_p, sumValMat);

                % Full Newton step on the negative log-posterior, including
                % the prior-gradient correction. At iteration 1 with x_cur =
                % x_p, the correction vanishes and this reduces to
                % PPDecode_update's x_p + W_u*sumValVec form.
                priorGradCorr = Wp_inv * (x_cur - x_p);
                x_new = x_cur + W_u * (sumValVec - priorGradCorr);

                if norm(x_new - x_cur) < tol
                    x_u = x_new;
                    return;
                end
                x_cur = x_new;
                x_u = x_new;
            end
        end

        function [x_u, W_u, lambdaDeltaMat, nIter] = PPDecode_updateLinearIterated(x_p, W_p, dN, mu, beta, fitType, gamma, HkAll, time_index, maxIters, tol)
            %PPDECODE_UPDATELINEARITERATED Iterated-Laplace PPAF update (linear CIF).
            %
            % Linear-CIF (canonical-link Poisson or binomial) counterpart of
            % PPDecode_updateIterated. Reduces exactly to
            % PPDecode_updateLinear when maxIters == 1.
            %
            % See PPDecode_updateIterated for the math; this routine
            % specializes the gradient/Hessian evaluations to the closed-form
            % expressions used by PPDecode_updateLinear, which are linear
            % (Poisson) or quadratic (binomial) in the linear predictor
            % mu + beta'*x. Re-linearization at x_cur reduces to
            % recomputing lambdaDelta with the new x_cur.
            %
            % Inputs match PPDecode_updateLinear up through time_index, then:
            %   maxIters - maximum Newton iterations
            %              (default nstat.Defaults.PPAF_NewtonIters).
            %   tol      - L2 tolerance on the iterate increment
            %              (default nstat.Defaults.FilterConvergenceTol).
            %
            % Refs: bci-curriculum chapter-04 §4.C.2; Phase 4 Task 4.1.

            C = size(dN, 1);
            if nargin < 11 || isempty(tol)
                tol = nstat.Defaults.FilterConvergenceTol;
            end
            if nargin < 10 || isempty(maxIters)
                maxIters = nstat.Defaults.PPAF_NewtonIters;
            end
            if nargin < 9 || isempty(time_index)
                time_index = 1;
            end
            if nargin < 8 || isempty(HkAll)
                N = size(dN, 2);
                HkAll = zeros(N, 0, C);
            end
            if nargin < 7 || isempty(gamma)
                gamma = [];
            end
            if nargin < 6 || isempty(fitType)
                fitType = 'poisson';
            end
            if maxIters < 1
                error('nSTAT:PPDecodeUpdateLinearIterated:InvalidMaxIters', ...
                      'maxIters must be a positive integer; got %g', maxIters);
            end
            if numel(gamma) == 1 && gamma == 0
                gamma = zeros(size(mu))';
            end

            % Precompute history-effect contribution (constant across Newton
            % iterations because it does not depend on x).
            if isempty(gamma) || isempty(HkAll) || size(HkAll, 2) == 0
                histEffect = zeros(C, 1);
            else
                Histterm = HkAll(:, :, time_index);
                if ~any(gamma ~= 0)
                    Histterm = Histterm';
                end
                if size(Histterm, 2) ~= size(mu, 1)
                    Histterm = Histterm';
                end
                histEffect = diag(gamma' * Histterm);
            end

            Wp_inv = pinv(W_p);
            x_cur = x_p;
            x_u   = x_p;
            W_u   = W_p;
            lambdaDeltaMat = zeros(C, 1);
            nIter = 0;

            for nIter = 1:maxIters
                linTerm = mu + beta' * x_cur + histEffect;
                if strcmp(fitType, 'binomial')
                    lambdaDeltaMat = exp(linTerm) ./ (1 + exp(linTerm));
                    indNan = isnan(lambdaDeltaMat);
                    indInf = isinf(lambdaDeltaMat);
                    lambdaDeltaMat(indNan) = 1;
                    lambdaDeltaMat(indInf) = 1;
                    sumValVec = sum(repmat(((dN(:,time_index) - lambdaDeltaMat(:,1)) ...
                                            .* (1 - lambdaDeltaMat(:,1)))', ...
                                           size(beta,1), 1) .* beta, 2);
                    tempVec = ((dN(:,time_index) + (1 - 2*lambdaDeltaMat(:,1))) ...
                               .* (1 - lambdaDeltaMat(:,1)) .* lambdaDeltaMat(:,1))';
                    sumValMat = (repmat(tempVec, size(beta,1), 1) .* beta) * beta';
                elseif strcmp(fitType, 'poisson')
                    lambdaDeltaMat = exp(linTerm);
                    indNan = isnan(lambdaDeltaMat);
                    indInf = isinf(lambdaDeltaMat);
                    lambdaDeltaMat(indNan) = 1;
                    lambdaDeltaMat(indInf) = 1;
                    sumValVec = sum(repmat(((dN(:,time_index) - lambdaDeltaMat(:,1)))', ...
                                           size(beta,1), 1) .* beta, 2);
                    sumValMat = (repmat(lambdaDeltaMat(:,1)', size(beta,1), 1) .* beta) * beta';
                else
                    error('nSTAT:PPDecodeUpdateLinearIterated:UnknownFitType', ...
                          'fitType must be ''poisson'' or ''binomial''; got %s', fitType);
                end

                [W_u, isSingular] = nstat.decoding.internal.computeGainMatrix(W_p, sumValMat);
                if isSingular
                    W_u = 0.5 * (W_p + W_p');
                end

                priorGradCorr = Wp_inv * (x_cur - x_p);
                x_new = x_cur + W_u * (sumValVec - priorGradCorr);

                if norm(x_new - x_cur) < tol
                    x_u = x_new;
                    return;
                end
                x_cur = x_new;
                x_u = x_new;
            end
        end
    end
end

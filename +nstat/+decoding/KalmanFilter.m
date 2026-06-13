classdef KalmanFilter
 %KALMANFILTER Linear-Gaussian state-space filter, smoother, RTS pass.
 %
 % Extracted from DecodingAlgorithms.m (Phase 3 Task 3.2 Step B of the
 % 2026-05-19 nSTAT review action plan). DecodingAlgorithms.kalman_*
 % are now thin deprecation shims that forward here.
 %
 % Static methods:
 % kalman_filter — Forward Kalman filter (one full pass).
 % kalman_fixedIntervalSmoother — Fixed-interval smoother wrapper.
 % kalman_smootherFromFiltered — Rauch-Tung-Striebel backward pass.
 % kalman_smoother — Full forward-backward smoother.
 %
 % Refs: Kalman 1960; Rauch-Tung-Striebel 1965 (RTS smoother);
 %.B.5 PPAF as the spike-train analog;
 % chapter-01 §1.B.5 Kalman as the Wiener-filter
 % optimal linear estimator.

 methods (Static)
 function [x_p, Pe_p, x_u, Pe_u,Gn,GnConvIter] = kalman_filter(A, C, Pv, Pw, Px0, x0,y, GnConv)
 %% DT Kalman Filter
 % This implements the DT Kalman filter for the system described by
 %
 % x(:,n+1) = A(:,:,n)x(:,n) + v(:,n)
 % y(:,n) = C(:,:,n)x(:,n) + w(:,n)
 %
 % where Pv(:,:,n), Pw(:,:,n) are the covariances of v(:,n) and w(:,n)
 % and Px0 is the initial state covariance.
 %
 % v(:,n), w(:,n), x(:,1) are assumed to be zero-mean.
 %
 % Return values are
 % x_p: state estimates given the past
 % Pe_p: error covariance estimates given the past
 % x_u: state updates given the data
 % Pe_u: error covariance updates given the data

 if(nargin<8||isempty(GnConv))
 GnConv = [];
 end
 N = size(y,2); % number of time samples in the data
 x_p = zeros( size(A,2), N+1 );
 x_u = zeros( size(A,2), N );
 Pe_p = zeros( size(A,2), size(A,2), N+1 );
 Gn = zeros( size(A,2), size(C,1), N );
 Pe_u = zeros( size(A,2), size(A,2), N );
 x_p(:,1)= x0;
 Pe_p(:,:,1) = Px0;

 for n=1:N
 [x_u(:,n), Pe_u(:,:,n), Gn(:,:,n)] = kalman_update( x_p(:,n), Pe_p(:,:,n), C(:,:,min(size(C,3),n)), Pw(:,:,min(size(Pw,3),n)), y(:,n),GnConv);
 [x_p(:,n+1), Pe_p(:,:,n+1)] = kalman_predict(x_u(:,n), Pe_u(:,:,n), A(:,:,min(size(A,3),n)), Pv(:,:,min(size(Pv,3),n)),GnConv);
 if(n>1 && isempty(GnConv))
 diffGn = abs(Gn(:,:,n)-Gn(:,:,n-1));
 mAbsdiffGn = max(max(diffGn));
 if(mAbsdiffGn<1e-6)
 GnConv=Gn(:,:,n);
 GnConvIter = n;
 else
 GnConvIter=[];
 end

 end
 end

 %% Kalman Filter Update Equation
 function [x_u, Pe_u, G] = kalman_update(x_p, Pe_p, C, Pw, y, GnConv)
 % The Kalman update step that finds the state estimate based on new
 % data
 if(nargin<6 || isempty(GnConv))
 G = (Pe_p * C')/(C * Pe_p * C' + Pw);
 else
 G = GnConv;
 end
 x_u = x_p + G * (y - C * x_p);
 Pe_u = Pe_p - G * C * Pe_p;
 Pe_u = 0.5*(Pe_u + Pe_u');

% figure(10); subplot(1,3,1);imagesc(Pe_u); pause(0.005);
 end
 %% Kalman Filter Prediction Step
 function [x_p, Pe_p] = kalman_predict(x_u, Pe_u, A, Pv,GnConv)
 % The Kalman prediction step that implements the tracking system
 x_p = A * x_u;
 if(isempty(GnConv))
 Pe_p = A * Pe_u * A' + Pv;
 else
 Pe_p = Pe_u;
 end
 Pe_p = 0.5*(Pe_p + Pe_p');
 end
 end

 %% Kalman Fixed-Interval Smoother
 function [x_pLag, Pe_pLag, x_uLag, Pe_uLag] = kalman_fixedIntervalSmoother(A, C, Pv, Pw, Px0, x0,y,lags)
 %y should be zero mean gaussian
 N = size(y,2);
 nStates = size(A,2);
 nObs = size(C,1);
 Alag = zeros((lags+1)*nStates,(lags+1)*nStates,N);
 Pvlag = zeros((lags+1)*nStates,(lags+1)*nStates,N);
 Clag = zeros(nObs,(lags+1)*nStates,N);
 Pwlag = zeros(nObs,nObs,N);
 x0lag = zeros(length(x0)*(lags+1),1);
 Px0lag = zeros((lags+1)*nStates,(lags+1)*nStates);
 Px0lag((1:nStates),(1:nStates))=Px0;
 x0lag(1:nStates,1)=x0;
 for n=1:N
 offset = 0;
 for i=1:(lags+1)
 if(i==1)
 Alag((1:nStates)+offset,(1:nStates)+offset,n)=A(:,:,min(size(A,3),n));
 Pvlag((1:nStates)+offset,(1:nStates)+offset,n)=Pv(:,:,min(size(Pv,3),n));
 Clag((1:nObs),(1:nStates)+offset,n)=C(:,:,min(size(C,3),n));
 Pwlag((1:nObs),(1:nObs),n) = Pw(:,:,min(size(Pw,3),n));
 else
 Alag((1:nStates)+offset,(1:nStates)+(offset-nStates),n)=eye(nStates,nStates);
 Pvlag((1:nStates)+offset,(1:nStates)+offset,n)=zeros(nStates,nStates);
 Clag((1:nObs),(1:nStates)+offset,n)=zeros(nObs,nStates);
 end
 offset=offset+nStates;
 end
 end

 [x_p, Pe_p, x_u, Pe_u] = nstat.decoding.KalmanFilter.kalman_filter(Alag, Clag, Pvlag, Pwlag, Px0lag, x0lag,y);

 x_pLag = x_p((lags*nStates+1):(lags+1)*nStates,:);
 Pe_pLag = Pe_p((lags*nStates+1):(lags+1)*nStates,(lags*nStates+1):(lags+1)*nStates,:);
 x_uLag = x_u((lags*nStates+1):(lags+1)*nStates,:);
 Pe_uLag = Pe_u((lags*nStates+1):(lags+1)*nStates,(lags*nStates+1):(lags+1)*nStates,:);
 end
 %% Kalman Smoother
 function [x_N, P_N,Ln] = kalman_smootherFromFiltered(A, x_p, Pe_p, x_u, Pe_u)
 N=size(x_u,2);

 x_N=zeros(size(x_u));
 P_N=zeros(size(Pe_u));
 Ln = zeros(size(P_N,1),size(P_N,2),size(P_N,3)-1);
 j=fliplr(1:N-1);
 x_N(:,N) = x_u(:,N);
 P_N(:,:,N) = Pe_u(:,:,N);
% LnConv = [];
 for n=j
% if(n<round(N/100) || N<10000)
 Ln(:,:,n)=Pe_u(:,:,n)*A(:,:,min(size(A,3),n))'/Pe_p(:,:,n+1);
% elseif(~isempty(LnConv))
% Ln(:,:,n)=LnConv;
% else
% Ln(:,:,n)=Pe_u(:,:,n)*A(:,:,min(size(A,3),n))'/Pe_p(:,:,n+1);
% end
 x_N(:,n) = x_u(:,n)+Ln(:,:,n)*(x_N(:,n+1)-x_p(:,n+1));
 P_N(:,:,n)=Pe_u(:,:,n)+Ln(:,:,n)*(P_N(:,:,n+1)-Pe_p(:,:,n+1))*Ln(:,:,n)';
 P_N(:,:,n) = 0.5*(P_N(:,:,n)+P_N(:,:,n)');
% if(n<(N-1) && isempty(LnConv))
% diffLn = abs(Ln(:,:,n)-Ln(:,:,n+1));
% mAbsdiffLn = max(max(diffLn));
% if(mAbsdiffLn<1e-6)
% LnConv=Ln(:,:,n);
% LnConvIter = n;
% end
% end
 end

 end
 function [x_N, P_N,Ln,x_p, Pe_p, x_u, Pe_u] = kalman_smoother(A, C, Pv, Pw, Px0, x0, y)
 %% kalman smoother
 N=size(y,2);
 [x_p, Pe_p, x_u, Pe_u] = nstat.decoding.KalmanFilter.kalman_filter(A, C, Pv, Pw, Px0, x0, y);

 x_N=zeros(size(x_u));
 P_N=zeros(size(Pe_u));
 Ln = zeros(size(P_N,1),size(P_N,2),size(P_N,3)-1);
 j=fliplr(1:N-1);
 x_N(:,N) = x_u(:,N);
 P_N(:,:,N) = Pe_u(:,:,N);
% LnConv = [];
 for n=j
% if(n<round(N/100)|| N<10000)
 Ln(:,:,n)=Pe_u(:,:,n)*A(:,:,min(size(A,3),n))'/Pe_p(:,:,n+1);
% elseif(~isempty(LnConv))
% Ln(:,:,n)=LnConv;
% else
% Ln(:,:,n)=Pe_u(:,:,n)*A(:,:,min(size(A,3),n))'/Pe_p(:,:,n+1);
% end
 x_N(:,n) = x_u(:,n)+Ln(:,:,n)*(x_N(:,n+1)-x_p(:,n+1));
 P_N(:,:,n)=Pe_u(:,:,n)+Ln(:,:,n)*(P_N(:,:,n+1)-Pe_p(:,:,n+1))*Ln(:,:,n)';
 P_N(:,:,n) = 0.5*(P_N(:,:,n)+P_N(:,:,n)');
% if(n<(N-1) && isempty(LnConv))
% diffLn = abs(Ln(:,:,n)-Ln(:,:,n+1));
% mAbsdiffLn = max(max(diffLn));
% if(mAbsdiffLn<1e-6)
% LnConv=Ln(:,:,n);
% LnConvIter = n;
% end
% end
 end
 end
 end
end

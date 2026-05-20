classdef DecodingAlgorithms
% DECODINGALGORITHMS - Static methods for state estimation and neural decoding.
%
% Implements four major algorithm classes for decoding hidden states from
% neural point process observations:
%
%   1. PPAF  (Point Process Adaptive Filter): Eqs. (16)-(19)
%      - PPDecodeFilter: generic CIF-based (symbolic Jacobian/Hessian)
%      - PPDecodeFilterLinear: optimized for linear CIF (Poisson/binomial)
%
%   2. PPHF  (Point Process Hybrid Filter): Section 2.1.5
%      - PPHybridFilter / PPHybridFilterLinear
%      - Mixed discrete/continuous state estimation
%
%   3. SSGLM (State-Space GLM via EM): Section 2.1.6, Eqs. (9)-(10)
%      - PPSS_EM / PPSS_EMFB
%      - Across-trial plasticity with random walk model
%
%   4. Kalman filter/smoother for Gaussian observations
%      - kalman_filter, kalman_smoother, kalman_smootherFromFiltered
%
% Also includes standard Kalman filter, PPSS_EMFB (forward-backward EM),
% and Monte Carlo variants (PPLFP_EM).
%
% See Sections 2.1.5--2.1.6 in:
%   Cajigas, Malik, Brown. J Neurosci Methods 211:245-264 (2012).
%
% <a href="matlab:nstatOpenHelpPage('DecodingExample.html')">Decoding Algorithms Reference</a>
% Reference page in Help browser
% <a href="matlab:nstatOpenHelpPage('DecodingExample.html')">Decoding Algorithms Examples</a>


%
% nSTAT v1 Copyright (C) 2012 Masschusetts Institute of Technology
% Cajigas, I, Malik, WQ, Brown, EN
% This program is free software; you can redistribute it and/or 
% modify it under the terms of the GNU General Public License as published 
% by the Free Software Foundation; either version 2 of the License, or 
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful, 
% but WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
% See the GNU General Public License for more details.
%  
% You should have received a copy of the GNU General Public License 
% along with this program; if not, write to the Free Software Foundation, 
% Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

    properties
    end
    
    methods (Static)
          
        %% Point Process Adaptive Filter
        % Cluster extracted to nstat.decoding.PPAF
        % (Phase 3 Task 3.2 Step C of the 2026-05-19 nSTAT review action plan).
        % The methods below are thin deprecation shims that forward to the new
        % class via varargin/varargout.
        function varargout = PPDecodeFilter(varargin)
            %PPDECODEFILTER Deprecated. Use nstat.decoding.PPAF.PPDecodeFilter instead.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PPDecodeFilter is deprecated; use ' ...
                 'nstat.decoding.PPAF.PPDecodeFilter instead.']);
            [varargout{1:nargout}] = nstat.decoding.PPAF.PPDecodeFilter(varargin{:});
        end

        function varargout = PPDecodeFilterLinear(varargin)
            %PPDECODEFILTERLINEAR Deprecated. Use nstat.decoding.PPAF.PPDecodeFilterLinear instead.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PPDecodeFilterLinear is deprecated; use ' ...
                 'nstat.decoding.PPAF.PPDecodeFilterLinear instead.']);
            [varargout{1:nargout}] = nstat.decoding.PPAF.PPDecodeFilterLinear(varargin{:});
        end

        function varargout = PP_fixedIntervalSmoother(varargin)
            %PP_FIXEDINTERVALSMOOTHER Deprecated. Use nstat.decoding.PPAF.PP_fixedIntervalSmoother instead.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PP_fixedIntervalSmoother is deprecated; use ' ...
                 'nstat.decoding.PPAF.PP_fixedIntervalSmoother instead.']);
            [varargout{1:nargout}] = nstat.decoding.PPAF.PP_fixedIntervalSmoother(varargin{:});
        end

        function varargout = PPDecode_predict(varargin)
            %PPDECODE_PREDICT Deprecated. Use nstat.decoding.PPAF.PPDecode_predict instead.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PPDecode_predict is deprecated; use ' ...
                 'nstat.decoding.PPAF.PPDecode_predict instead.']);
            [varargout{1:nargout}] = nstat.decoding.PPAF.PPDecode_predict(varargin{:});
        end

        function varargout = PPDecode_update(varargin)
            %PPDECODE_UPDATE Deprecated. Use nstat.decoding.PPAF.PPDecode_update instead.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PPDecode_update is deprecated; use ' ...
                 'nstat.decoding.PPAF.PPDecode_update instead.']);
            [varargout{1:nargout}] = nstat.decoding.PPAF.PPDecode_update(varargin{:});
        end

        function varargout = PPDecode_updateLinear(varargin)
            %PPDECODE_UPDATELINEAR Deprecated. Use nstat.decoding.PPAF.PPDecode_updateLinear instead.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PPDecode_updateLinear is deprecated; use ' ...
                 'nstat.decoding.PPAF.PPDecode_updateLinear instead.']);
            [varargout{1:nargout}] = nstat.decoding.PPAF.PPDecode_updateLinear(varargin{:});
        end


        %% Point Process Hybrid Filter (deprecation shims)
        function varargout = PPHybridFilterLinear(varargin)
            %PPHYBRIDFILTERLINEAR Deprecated. Use nstat.decoding.PPHF.PPHybridFilterLinear instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step D of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PPHybridFilterLinear is deprecated; use ' ...
                 'nstat.decoding.PPHF.PPHybridFilterLinear instead.']);
            [varargout{1:nargout}] = nstat.decoding.PPHF.PPHybridFilterLinear(varargin{:});
        end

        function varargout = PPHybridFilter(varargin)
            %PPHYBRIDFILTER Deprecated. Use nstat.decoding.PPHF.PPHybridFilter instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step D of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PPHybridFilter is deprecated; use ' ...
                 'nstat.decoding.PPHF.PPHybridFilter instead.']);
            [varargout{1:nargout}] = nstat.decoding.PPHF.PPHybridFilter(varargin{:});
        end

        %%Unscented Transform 
        function varargout = ukf(varargin)
            %UKF Deprecated. Use nstat.decoding.UKF.ukf instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step A of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.ukf is deprecated; use ' ...
                 'nstat.decoding.UKF.ukf instead.']);
            [varargout{1:nargout}] = nstat.decoding.UKF.ukf(varargin{:});
        end

        function varargout = ukf_ut(varargin)
            %UKF_UT Deprecated. Use nstat.decoding.UKF.ukf_ut instead.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.ukf_ut is deprecated; use ' ...
                 'nstat.decoding.UKF.ukf_ut instead.']);
            [varargout{1:nargout}] = nstat.decoding.UKF.ukf_ut(varargin{:});
        end

        function varargout = ukf_sigmas(varargin)
            %UKF_SIGMAS Deprecated. Use nstat.decoding.UKF.ukf_sigmas instead.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.ukf_sigmas is deprecated; use ' ...
                 'nstat.decoding.UKF.ukf_sigmas instead.']);
            [varargout{1:nargout}] = nstat.decoding.UKF.ukf_sigmas(varargin{:});
        end


        %% Kalman Filter
        % Cluster extracted to nstat.decoding.KalmanFilter
        % (Phase 3 Task 3.2 Step B of the 2026-05-19 nSTAT review action plan).
        % The methods below are thin deprecation shims that forward to the new
        % class via varargin/varargout.
        function varargout = kalman_filter(varargin)
            %KALMAN_FILTER Deprecated. Use nstat.decoding.KalmanFilter.kalman_filter.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.kalman_filter is deprecated; use ' ...
                 'nstat.decoding.KalmanFilter.kalman_filter instead.']);
            [varargout{1:nargout}] = nstat.decoding.KalmanFilter.kalman_filter(varargin{:});
        end

        function varargout = kalman_fixedIntervalSmoother(varargin)
            %KALMAN_FIXEDINTERVALSMOOTHER Deprecated. Use nstat.decoding.KalmanFilter.kalman_fixedIntervalSmoother.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.kalman_fixedIntervalSmoother is deprecated; use ' ...
                 'nstat.decoding.KalmanFilter.kalman_fixedIntervalSmoother instead.']);
            [varargout{1:nargout}] = nstat.decoding.KalmanFilter.kalman_fixedIntervalSmoother(varargin{:});
        end

        function varargout = kalman_smootherFromFiltered(varargin)
            %KALMAN_SMOOTHERFROMFILTERED Deprecated. Use nstat.decoding.KalmanFilter.kalman_smootherFromFiltered.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.kalman_smootherFromFiltered is deprecated; use ' ...
                 'nstat.decoding.KalmanFilter.kalman_smootherFromFiltered instead.']);
            [varargout{1:nargout}] = nstat.decoding.KalmanFilter.kalman_smootherFromFiltered(varargin{:});
        end

        function varargout = kalman_smoother(varargin)
            %KALMAN_SMOOTHER Deprecated. Use nstat.decoding.KalmanFilter.kalman_smoother.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.kalman_smoother is deprecated; use ' ...
                 'nstat.decoding.KalmanFilter.kalman_smoother instead.']);
            [varargout{1:nargout}] = nstat.decoding.KalmanFilter.kalman_smoother(varargin{:});
        end
        %% Point-Process State Space GLM (deprecation shims)
        % Cluster extracted to nstat.decoding.SSGLM
        % (Phase 3 Task 3.2 Step F of the 2026-05-19 nSTAT review action plan).
        % The methods below are thin deprecation shims that forward to the new
        % class via varargin/varargout.
        function varargout = PPSS_EMFB(varargin)
            %PPSS_EMFB Deprecated. Use nstat.decoding.SSGLM.PPSS_EMFB instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step F of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PPSS_EMFB is deprecated; use ' ...
                 'nstat.decoding.SSGLM.PPSS_EMFB instead.']);
            [varargout{1:nargout}] = nstat.decoding.SSGLM.PPSS_EMFB(varargin{:});
        end

        function varargout = PPSS_EM(varargin)
            %PPSS_EM Deprecated. Use nstat.decoding.SSGLM.PPSS_EM instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step F of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PPSS_EM is deprecated; use ' ...
                 'nstat.decoding.SSGLM.PPSS_EM instead.']);
            [varargout{1:nargout}] = nstat.decoding.SSGLM.PPSS_EM(varargin{:});
        end

        function varargout = PPSS_EStep(varargin)
            %PPSS_ESTEP Deprecated. Use nstat.decoding.SSGLM.PPSS_EStep instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step F of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PPSS_EStep is deprecated; use ' ...
                 'nstat.decoding.SSGLM.PPSS_EStep instead.']);
            [varargout{1:nargout}] = nstat.decoding.SSGLM.PPSS_EStep(varargin{:});
        end

        function varargout = PPSS_MStep(varargin)
            %PPSS_MSTEP Deprecated. Use nstat.decoding.SSGLM.PPSS_MStep instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step F of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PPSS_MStep is deprecated; use ' ...
                 'nstat.decoding.SSGLM.PPSS_MStep instead.']);
            [varargout{1:nargout}] = nstat.decoding.SSGLM.PPSS_MStep(varargin{:});
        end
        function fitResults=prepareEMResults(fitType,neuronNumber,dN,HkAll,xK,WK,Q,gamma,windowTimes,delta,informationMatrix,logll)


            [numBasis, K] =size(xK);
            SE = sqrt(abs(diag(inv(informationMatrix))));
            xKbeta = reshape(xK,[numel(xK) 1]);
            seXK=[];
            for k=1:K
                seXK   = [seXK; sqrt(diag(WK(:,:,k)))];
            end
            statsStruct.beta=[xKbeta;(Q(:,end));gamma(end,:)'];
            statsStruct.se  =[seXK;SE];
            covarianceLabels = cell(1,numBasis);
            for r=1:numBasis
                if(r<10)
                    covarianceLabels{r} =  ['Q0' num2str(r)];
                else
                    covarianceLabels{r} =  ['Q' num2str(r)];
                end
            end

            minTime=0;
            maxTime=(size(dN,2)-1)*delta;
            if(~isempty(numBasis))
                basisWidth = (maxTime-minTime)/numBasis;
                sampleRate=1/delta;
                unitPulseBasis=nstColl.generateUnitImpulseBasis(basisWidth,minTime,maxTime,sampleRate);
                basisMat = unitPulseBasis.data;
            end

            nst = cell(1,K);
            if(~isempty(windowTimes))
                histObj{1} = History(windowTimes,minTime,maxTime);
            else
                histObj{1} = [];
            end

            if(isnumeric(neuronNumber))
                name=num2str(neuronNumber);
                if(neuronNumber>0 && neuronNumber<10)
                    name = strcat(num2str(0),name);
                end
                name = ['N' name];  
            else
                name = neuronNumber;
            end

            for k=1:K
                nst{k} = nspikeTrain( (find(dN(k,:)==1)-1)*delta,name);
                nst{k}.setMinTime(minTime);
                nst{k}.setMaxTime(maxTime);

            end

            nCopy = nstColl(nst);
            nCopy = nCopy.toSpikeTrain;
            lambdaData=[];
            cnt=1;

            for k=1:K
                Hk=HkAll{k};
                stimK=basisMat*xK(:,k);


                if(strcmp(fitType,'poisson'))
                    histEffect=exp(gamma(end,:)*Hk')';
                    stimEffect=exp(stimK);
                    lambdaDelta = histEffect.*stimEffect;
                    lambdaData = [lambdaData;lambdaDelta/delta];
                elseif(strcmp(fitType,'binomial'))
                    histEffect=exp(gamma(end,:)*Hk')';
                    stimEffect=exp(stimK);
                    lambdaDelta = histEffect.*stimEffect;
                    lambdaDelta = lambdaDelta./(1+lambdaDelta);
                    lambdaData = [lambdaData;lambdaDelta/delta];
                end


                for r=1:numBasis
                        if(r<10)
                            otherLabels{cnt} = ['b0' num2str(r) '_{' num2str(k) '}']; 
                        else
                            otherLabels{cnt} = ['b' num2str(r) '_{' num2str(k) '}'];
                        end
                        cnt=cnt+1;
                end
            end

            lambdaTime = minTime:delta:(length(lambdaData)-1)*delta;
            nCopy.setMaxTime(max(lambdaTime));
            nCopy.setMinTime(min(lambdaTime));

            numLabels = length(otherLabels);
            if(~isempty(windowTimes))
                histLabels  = histObj{1}.computeHistory(nst{1}).getCovLabelsFromMask;
            else
                histLabels = [];
            end
            otherLabels((numLabels+1):(numLabels+length(covarianceLabels)))=covarianceLabels;
            numLabels = length(otherLabels);

            tc{1} = TrialConfig(otherLabels,sampleRate,histObj,[]); 
            numBasisStr=num2str(numBasis);
            numHistStr = num2str(length(windowTimes)-1);
            if(~isempty(histObj))
                tc{1}.setName(['SSGLM(N_{b}=', numBasisStr,')+Hist(N_{h}=' ,numHistStr,')']);
            else
                tc{1}.setName(['SSGLM(N_{b}=', numBasisStr,')']);
            end
            configColl= ConfigColl(tc);


            otherLabels((numLabels+1):(numLabels+length(histLabels)))=histLabels;




            labels{1}  = otherLabels; % Labels change depending on presence/absense of History or ensCovHist
            if(~isempty(windowTimes))
                numHist{1} = length(histObj{1}.windowTimes)-1;
            else 
                numHist{1}=[];
            end

            ensHistObj{1} = [];
            lambdaIndexStr=1;
            lambda=Covariate(lambdaTime,lambdaData,...
                           '\Lambda(t)','time',...
                           's','Hz',strcat('\lambda_{',lambdaIndexStr,'}'));


            AIC = 2*length(otherLabels)-2*logll;
            BIC = -2*logll+length(otherLabels)*log(length(lambdaData));

            dev=-2*logll;
            b{1} = statsStruct.beta;
            stats{1} = statsStruct;

            distrib{1} =fitType;
            currSpikes=nst;%nspikeColl.getNST(tObj.getNeuronIndFromName(neuronNames));
            for n=1:length(currSpikes)
                currSpikes{n} = currSpikes{n}.nstCopy;
                currSpikes{n}.setName(nCopy.name);
            end
            XvalData{1} = [];
            XvalTime{1} = [];
            spikeTraining = currSpikes;


            fitResults=FitResult(spikeTraining,labels,numHist,histObj,ensHistObj,lambda,b, dev, stats,AIC,BIC,configColl,XvalData,XvalTime,distrib);
            DTCorrection=1;
            makePlot=0;
            Analysis.KSPlot(fitResults,DTCorrection,makePlot);
            Analysis.plotInvGausTrans(fitResults,makePlot);
            Analysis.plotFitResidual(fitResults,[],makePlot); 
        end
        function [CIs, stimulus]  = ComputeStimulusCIs(fitType,xK,Wku,delta,Mc,alphaVal)
            if(nargin<6 ||isempty(alphaVal))
                alphaVal =.05;
            end
            if(nargin<5 ||isempty(Mc))
                Mc=3000;
            end
            [numBasis,K]=size(xK);


           for r=1:numBasis  
                WkuTemp=squeeze(Wku(r,r,:,:));
    %             [vec,val]=eig(Wku ); val(val<=0)=eps;
    %             Wku =vec*val*vec';
                [chol_m,p]=chol(WkuTemp);
                if(numel(chol_m)==1)
                    chol_m = diag(repmat(chol_m,[K 1]));
                end
                for c=1:Mc % for r-th step function simulate the path of size K
                    z=zeros(K,1);
                    z=normrnd(0,1,K,1);
                    xKDraw(r,:,c)=xK(r,:)+(chol_m'*z)';
    %                 stimulusDraw(r,:,c) = exp(xKDraw(r,:,c))/delta;
                    if(strcmp(fitType,'poisson'))
                        stimulusDraw(r,:,c) =  exp(xKDraw(r,:,c))/delta;
                    elseif(strcmp(fitType,'binomial'))
                        stimulusDraw(r,:,c) = exp(xKDraw(r,:,c))./(1+exp(xKDraw(r,:,c)))/delta;
                    end
                end
           end

           CIs = zeros(size(xK,1),size(xK,2),2);
           for r=1:numBasis
               for k=1:K
                   [f,x] = ecdf(squeeze(stimulusDraw(r,k,:)));
                    CIs(r,k,1) = x(find(f<alphaVal/2,1,'last'));
                    CIs(r,k,2) = x(find(f>(1-(alphaVal/2)),1,'first'));
               end
           end

           if(nargout==2)
               if(strcmp(fitType,'poisson'))
                    stimulus =  exp(xK)/delta;
               elseif(strcmp(fitType,'binomial'))
                    stimulus = exp(xK)./(1+exp(xK))/delta;
               end
           end


        end
        function InfoMatrix=estimateInfoMat(fitType,dN,HkAll,A,x0,xK,WK,Wku,Q,gamma,windowTimes,SumXkTerms,delta,Mc)
            if(nargin<14)
                Mc=500;
            end

            [K,N]=size(dN);
            if(~isempty(windowTimes))
                J=max(size(gamma(end,:)));
            else
                J=0;
            end

            R=size(Q,1);
            numBasis = R;

            % The complete data information matrix
            Ic=zeros(J+R,J+R);
            Q=(diag(Q)); % Make sure Q is diagonal matrix


            X=((SumXkTerms));
            Ic(1:R,1:R) = K/2*eye(size(Q))/Q^2 +X'/Q^3;


            % Compute information of history terms
            minTime=0;
            maxTime=(size(dN,2)-1)*delta;
    %         nst = cell(1,K);
    %         if(~isempty(windowTimes))
    %             histObj = History(windowTimes,minTime,maxTime);
    %             for k=1:K
    %                 nst{k} = nspikeTrain( (find(dN(k,:)==1)-1)*delta);
    %                 nst{k}.setMinTime(minTime);
    %                 nst{k}.setMaxTime(maxTime);
    %                 Hn{k} = histObj.computeHistory(nst{k}).dataToMatrix;
    %             end
    %         else
    %             for k=1:K
    %                 Hn{k} = 0;
    %             end
    %             gamma=0;
    %         end

             if(~isempty(numBasis))
                basisWidth = (maxTime-minTime)/numBasis;
                sampleRate=1/delta;
                unitPulseBasis=nstColl.generateUnitImpulseBasis(basisWidth,minTime,maxTime,sampleRate);
                basisMat = unitPulseBasis.data;
             end

            jacQ =zeros(size(gamma,2),size(gamma,2));
            if(strcmp(fitType,'poisson'))
                for k=1:K
                    Hk=HkAll{k};

                    Wk = basisMat*diag(WK(:,:,k));
                    stimK=basisMat*(xK(:,k));
                    histEffect=exp(gamma*Hk')';
                    stimEffect=exp(stimK)+exp(stimK)/2.*Wk;
                    lambdaDelta = stimEffect.*histEffect;

                    jacQ  = jacQ  - (Hk.*repmat(lambdaDelta,[1 size(Hk,2)]))'*Hk;
                end

             elseif(strcmp(fitType,'binomial'))
                 for k=1:K
                    Hk=HkAll{k};
                    Wk = basisMat*diag(WK(:,:,k));
                    stimK=basisMat*(xK(:,k));

                    histEffect=exp(gamma*Hk')';
                    stimEffect=exp(stimK);
                    C = stimEffect.*histEffect;
                    M = 1./C;
                    lambdaDelta = exp(stimK+(gamma*Hk')')./(1+exp(stimK+(gamma*Hk')'));
                    ExpLambdaDelta = lambdaDelta+Wk.*(lambdaDelta.*(1-lambdaDelta).*(1-2*lambdaDelta))/2;
                    ExpLDSquaredTimesInvExp = (lambdaDelta).^2.*1./C;
                    ExpLDCubedTimesInvExpSquared = (lambdaDelta).^3.*M.^2 +Wk/2.*(3.*M.^4.*lambdaDelta.^3+12.*lambdaDelta.^3.*M.^3-12.*M.^4.*lambdaDelta.^4);

                    jacQ  = jacQ  - (Hk.*repmat(ExpLDSquaredTimesInvExp.*dN(k,:)',[1,size(Hk,2)]))'*Hk ...
                                  - (Hk.*repmat(ExpLDSquaredTimesInvExp,[1,size(Hk,2)]))'*Hk ...
                                  - (Hk.*repmat(2*ExpLDCubedTimesInvExpSquared,[1,size(Hk,2)]))'*Hk;

                 end


            end           

            Ic(1:R,1:R)=K*eye(size(Q))/(2*(Q)^2)+(eye(size(Q))/((Q)^3))*SumXkTerms;

            if(~isempty(windowTimes))
                Ic((R+1):(R+J),(R+1):(R+J)) = -jacQ;
            end
            xKDraw = zeros(numBasis,K,Mc);
            for r=1:numBasis  
                WkuTemp=squeeze(Wku(r,r,:,:));
    %             [vec,val]=eig(Wku ); val(val<=0)=eps;
    %             Wku =vec*val*vec';
                [chol_m,p]=chol(WkuTemp);
                if(numel(chol_m)==1)
                    chol_m = diag(repmat(chol_m,[K 1]));
                end
                for c=1:Mc % for r-th step function simulate the path of size K
                    z=zeros(K,1);
                    z=normrnd(0,1,K,1);
                    xKDraw(r,:,c)=xK(r,:)+(chol_m'*z)';
                end
            end



            Im=zeros(J+R,J+R);
            ImMC=zeros(J+R,J+R);

            for c=1:Mc

                gradQGammahat=zeros(size(gamma,2),1);
                gradQQhat=zeros(1,R);        
                if(strcmp(fitType,'poisson'))
                    for k=1:K
                        Hk=HkAll{k};
                        stimK=basisMat*(xKDraw(:,k,c));
                        histEffect=exp(gamma*Hk')';
                        stimEffect=exp(stimK);
                        lambdaDelta = stimEffect.*histEffect;
                        gradQGammahat = gradQGammahat + Hk'*dN(k,:)' - Hk'*lambdaDelta;
                        if(k==1)
                            gradQQhat = ((xKDraw(:,k,c)-A*x0).*(xKDraw(:,k,c)-A*x0));
                        else
                            gradQQhat = gradQQhat+((xKDraw(:,k,c)-A*xKDraw(:,k-1,c)).*(xKDraw(:,k,c)-A*xKDraw(:,k-1,c)));
                        end

                    end
                elseif(strcmp(fitType,'binomial'))
                     for k=1:K
                        Hk=HkAll{k};
                        Wk = basisMat*diag(WK(:,:,k));
                        stimK=basisMat*(xKDraw(:,k,c));

                        histEffect=exp(gamma*Hk')';
                        stimEffect=exp(stimK);
    %                   
                        C = stimEffect.*histEffect;
                        M = 1./C;
                        lambdaDelta = exp(stimK+(gamma*Hk')')./(1+exp(stimK+(gamma*Hk')'));
                        ExpLambdaDelta = lambdaDelta+Wk.*(lambdaDelta.*(1-lambdaDelta).*(1-2*lambdaDelta))/2;
                        ExpLDSquaredTimesInvExp = (lambdaDelta).^2.*1./C;
                        ExpLDCubedTimesInvExpSquared = (lambdaDelta).^3.*M.^2 +Wk/2.*(3.*M.^4.*lambdaDelta.^3+12.*lambdaDelta.^3.*M.^3-12.*M.^4.*lambdaDelta.^4);


                        gradQGammahat = gradQGammahat + (Hk.*repmat(1-ExpLambdaDelta,[1,size(Hk,2)]))'*dN(k,:)' ...
                                          - (Hk.*repmat(ExpLDSquaredTimesInvExp./lambdaDelta,[1,size(Hk,2)]))'*lambdaDelta;
                        if(k==1)
                            gradQQhat = ((xKDraw(:,k,c)-A*x0).*(xKDraw(:,k,c)-A*x0));
                        else
                            gradQQhat = gradQQhat+((xKDraw(:,k,c)-A*xKDraw(:,k-1,c)).*(xKDraw(:,k,c)-A*xKDraw(:,k-1,c)));
                        end
                     end


                end

                gradQQhat = .5*eye(size(Q))/Q*gradQQhat - diag(K/2*eye(size(Q))/Q^2);
                ImMC(1:R,1:R)=ImMC(1:R,1:R)+gradQQhat*gradQQhat';
                if(~isempty(windowTimes))
                    ImMC((R+1):(R+J),(R+1):(R+J)) = ImMC((R+1):(R+J),(R+1):(R+J))+diag(diag(gradQGammahat*gradQGammahat'));
                end
            end
            Im=ImMC/Mc;

            InfoMatrix=Ic-Im; % Observed information matrix



        end
        function [spikeRateSig, ProbMat,sigMat]=computeSpikeRateCIs(xK,Wku,dN,t0,tf,fitType,delta,gamma,windowTimes,Mc,alphaVal)
             if(nargin<11 ||isempty(alphaVal))
                alphaVal =.05;
            end
            if(nargin<10 ||isempty(Mc))
                Mc=500;
            end

            [numBasis,K]=size(xK);

            minTime=0;
            maxTime=(size(dN,2)-1)*delta;

            if(~isempty(numBasis))
                basisWidth = (maxTime-minTime)/numBasis;
                sampleRate=1/delta;
                unitPulseBasis=nstColl.generateUnitImpulseBasis(basisWidth,minTime,maxTime,sampleRate);
                basisMat = unitPulseBasis.data;
            end


    %         K=size(dN,1);
            if(~isempty(windowTimes))
                histObj = History(windowTimes,minTime,maxTime);
                for k=1:K
                    nst{k} = nspikeTrain( (find(dN(k,:)==1)-1)*delta);
                    nst{k}.setMinTime(minTime);
                    nst{k}.setMaxTime(maxTime);
                    Hk{k} = histObj.computeHistory(nst{k}).dataToMatrix;
                end
            else
                for k=1:K
                    Hk{k} = 0;
                end
                gamma=0;
            end

           for r=1:numBasis  
                WkuTemp=squeeze(Wku(r,r,:,:));
    %             [vec,val]=eig(Wku ); val(val<=0)=eps;
    %             Wku =vec*val*vec';
                [chol_m,p]=chol(WkuTemp);
                if(numel(chol_m)==1)
                    chol_m = diag(repmat(chol_m,[K 1]));
                end
                for c=1:Mc % for r-th step function simulate the path of size K
                    z=zeros(K,1);
                    z=normrnd(0,1,K,1);
                    xKDraw(r,:,c)=xK(r,:)+(chol_m'*z)';
                end
           end

           time=minTime:delta:maxTime;
           for c=1:Mc
               for k=1:K

                   if(strcmp(fitType,'poisson'))
                        stimK=basisMat*xKDraw(:,k,c);
                        histEffect=exp(gamma*Hk{k}')';
                        stimEffect=exp(stimK);
                        lambdaDelta(:,k,c) =stimEffect.*histEffect;
                   elseif(strcmp(fitType,'binomial'))
                        stimK=basisMat*xKDraw(:,k,c);
                        lambdaDelta(:,k,c)=exp(stimK+(gamma*Hk{k}')')./(1+exp(stimK+(gamma*Hk{k}')'));  
                   end  


               end
               lambdaC=Covariate(time,lambdaDelta(:,:,c)/delta,'\Lambda(t)');
               lambdaCInt= lambdaC.integral;
               spikeRate(c,:) = (1/(tf-t0))*(lambdaCInt.getValueAt(tf)-lambdaCInt.getValueAt(t0));

           end

           CIs = zeros(K,2);
           for k=1:K
               [f,x] = ecdf(spikeRate(:,k));
                CIs(k,1) = x(find(f<alphaVal,1,'last'));
                CIs(k,2) = x(find(f>(1-(alphaVal)),1,'first'));
           end
           spikeRateSig = Covariate(1:K, mean(spikeRate),['(' num2str(tf) '-' num2str(t0) ')^-1 * \Lambda(' num2str(tf) '-' num2str(t0) ')'],'Trial','k','Hz');
           ciSpikeRate = ConfidenceInterval(1:K,CIs,'CI_{spikeRate}','Trial','k','Hz');
           spikeRateSig.setConfInterval(ciSpikeRate);


           if(nargout>1)
               ProbMat = zeros(K,K);
               for k=1:K
                   for m=(k+1):K

                       ProbMat(k,m)=sum(spikeRate(:,m)>spikeRate(:,k))./Mc;
                   end
               end
           end


           if(nargout>2)
                sigMat= double(ProbMat>(1-alphaVal));
           end


        end
        function [spikeRateSig, ProbMat,sigMat]=computeSpikeRateDiffCIs(xK,Wku,dN,time1,time2,fitType,delta,gamma,windowTimes,Mc,alphaVal)
             if(nargin<11 ||isempty(alphaVal))
                alphaVal =.05;
            end
            if(nargin<10 ||isempty(Mc))
                Mc=500;
            end

            [numBasis,K]=size(xK);

            minTime=0;
            maxTime=(size(dN,2)-1)*delta;

            if(~isempty(numBasis))
                basisWidth = (maxTime-minTime)/numBasis;
                sampleRate=1/delta;
                unitPulseBasis=nstColl.generateUnitImpulseBasis(basisWidth,minTime,maxTime,sampleRate);
                basisMat = unitPulseBasis.data;
            end


    %         K=size(dN,1);
            if(~isempty(windowTimes))
                histObj = History(windowTimes,minTime,maxTime);
                for k=1:K
                    nst{k} = nspikeTrain( (find(dN(k,:)==1)-1)*delta);
                    nst{k}.setMinTime(minTime);
                    nst{k}.setMaxTime(maxTime);
                    Hk{k} = histObj.computeHistory(nst{k}).dataToMatrix;
                end
            else
                for k=1:K
                    Hk{k} = 0;
                end
                gamma=0;
            end

           for r=1:numBasis  
                WkuTemp=squeeze(Wku(r,r,:,:));
    %             [vec,val]=eig(Wku ); val(val<=0)=eps;
    %             Wku =vec*val*vec';
                [chol_m,p]=chol(WkuTemp);
                if(numel(chol_m)==1)
                    chol_m = diag(repmat(chol_m,[K 1]));
                end
                for c=1:Mc % for r-th step function simulate the path of size K
                    z=zeros(K,1);
                    z=normrnd(0,1,K,1);
                    xKDraw(r,:,c)=xK(r,:)+(chol_m'*z)';
                end
           end

           timeWindow=minTime:delta:maxTime;
           for c=1:Mc
               for k=1:K

                   if(strcmp(fitType,'poisson'))
                        stimK=basisMat*xKDraw(:,k,c);
                        histEffect=exp(gamma*Hk{k}')';
                        stimEffect=exp(stimK);
                        lambdaDelta(:,k,c) =stimEffect.*histEffect;
                   elseif(strcmp(fitType,'binomial'))
                        stimK=basisMat*xKDraw(:,k,c);
                        lambdaDelta(:,k,c)=exp(stimK+(gamma*Hk{k}')')./(1+exp(stimK+(gamma*Hk{k}')'));  
                   end  


               end
               lambdaC=Covariate(timeWindow,lambdaDelta(:,:,c)/delta,'\Lambda(t)');
               lambdaCInt= lambdaC.integral;
               spikeRate(c,:) = (1/(max(time1)-min(time1)))*(lambdaCInt.getValueAt(max(time1))-lambdaCInt.getValueAt(min(time1))) ...
                                - (1/(max(time2)-min(time2)))*(lambdaCInt.getValueAt(max(time2))-lambdaCInt.getValueAt(min(time2)));


           end

           CIs = zeros(K,2);
           for k=1:K
               [f,x] = ecdf(spikeRate(:,k));
                CIs(k,1) = x(find(f<alphaVal,1,'last')); %not alpha/2 since this is a once sided comparison
                CIs(k,2) = x(find(f>(1-(alphaVal)),1,'first'));
           end
           spikeRateSig = Covariate(1:K, mean(spikeRate),['(t_{1f}-t_{1o})^-1 * \Lambda(t_{1f}-t_{1o}) - (t_{2f}-t_{2o})^-1 * \Lambda(t_{2f}-t_{2o}) '],'Trial','k','Hz');
           ciSpikeRate = ConfidenceInterval(1:K,CIs,'CI_{spikeRate}','Trial','k','Hz');
           spikeRateSig.setConfInterval(ciSpikeRate);


           if(nargout>1)
               ProbMat = zeros(K,K);
               for k=1:K
                   for m=(k+1):K

                       ProbMat(k,m)=sum(spikeRate(:,m)>spikeRate(:,k))./Mc;
                   end
               end
           end


           if(nargout>2)
                sigMat= double(ProbMat>(1-alphaVal));
           end


        end

        %% Kalman Filter EM (deprecation shims)
        % Cluster extracted to nstat.decoding.KF_EM
        % (Phase 3 Task 3.2 Step G of the 2026-05-19 nSTAT review action plan).
        % The methods below are thin deprecation shims that forward to the new
        % class via varargin/varargout.
        function varargout = KF_EMCreateConstraints(varargin)
            %KF_EMCREATECONSTRAINTS Deprecated. Use nstat.decoding.KF_EM.KF_EMCreateConstraints instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step G of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.KF_EMCreateConstraints is deprecated; use ' ...
                 'nstat.decoding.KF_EM.KF_EMCreateConstraints instead.']);
            [varargout{1:nargout}] = nstat.decoding.KF_EM.KF_EMCreateConstraints(varargin{:});
        end

        function varargout = KF_EM(varargin)
            %KF_EM Deprecated. Use nstat.decoding.KF_EM.KF_EM instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step G of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.KF_EM is deprecated; use ' ...
                 'nstat.decoding.KF_EM.KF_EM instead.']);
            [varargout{1:nargout}] = nstat.decoding.KF_EM.KF_EM(varargin{:});
        end

        function varargout = KF_ComputeParamStandardErrors(varargin)
            %KF_COMPUTEPARAMSTANDARDERRORS Deprecated. Use nstat.decoding.KF_EM.KF_ComputeParamStandardErrors instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step G of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.KF_ComputeParamStandardErrors is deprecated; use ' ...
                 'nstat.decoding.KF_EM.KF_ComputeParamStandardErrors instead.']);
            [varargout{1:nargout}] = nstat.decoding.KF_EM.KF_ComputeParamStandardErrors(varargin{:});
        end

        function varargout = KF_EStep(varargin)
            %KF_ESTEP Deprecated. Use nstat.decoding.KF_EM.KF_EStep instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step G of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.KF_EStep is deprecated; use ' ...
                 'nstat.decoding.KF_EM.KF_EStep instead.']);
            [varargout{1:nargout}] = nstat.decoding.KF_EM.KF_EStep(varargin{:});
        end

        function varargout = KF_MStep(varargin)
            %KF_MSTEP Deprecated. Use nstat.decoding.KF_EM.KF_MStep instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step G of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.KF_MStep is deprecated; use ' ...
                 'nstat.decoding.KF_EM.KF_MStep instead.']);
            [varargout{1:nargout}] = nstat.decoding.KF_EM.KF_MStep(varargin{:});
        end

        %% Point-Process + LFP Filter (deprecation shims)
        % Cluster extracted to nstat.decoding.PPLFP
        % (Phase 3 Task 3.2 Step E of the 2026-05-19 nSTAT review action plan).
        % The methods below are thin deprecation shims that forward to the new
        % class via varargin/varargout. The legacy DecodingAlgorithms.mPPCO_*
        % shims (added in 428c344) chain through these shims.
        function varargout = PPLFP_fixedIntervalSmoother(varargin)
            %PPLFP_FIXEDINTERVALSMOOTHER Deprecated. Use nstat.decoding.PPLFP.PPLFP_fixedIntervalSmoother instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step E of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PPLFP_fixedIntervalSmoother is deprecated; use ' ...
                 'nstat.decoding.PPLFP.PPLFP_fixedIntervalSmoother instead.']);
            [varargout{1:nargout}] = nstat.decoding.PPLFP.PPLFP_fixedIntervalSmoother(varargin{:});
        end

        function varargout = PPLFP_DecodeLinear(varargin)
            %PPLFP_DECODELINEAR Deprecated. Use nstat.decoding.PPLFP.PPLFP_DecodeLinear instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step E of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PPLFP_DecodeLinear is deprecated; use ' ...
                 'nstat.decoding.PPLFP.PPLFP_DecodeLinear instead.']);
            [varargout{1:nargout}] = nstat.decoding.PPLFP.PPLFP_DecodeLinear(varargin{:});
        end

        function varargout = PPLFP_Decode_predict(varargin)
            %PPLFP_DECODE_PREDICT Deprecated. Use nstat.decoding.PPLFP.PPLFP_Decode_predict instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step E of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PPLFP_Decode_predict is deprecated; use ' ...
                 'nstat.decoding.PPLFP.PPLFP_Decode_predict instead.']);
            [varargout{1:nargout}] = nstat.decoding.PPLFP.PPLFP_Decode_predict(varargin{:});
        end

        function varargout = PPLFP_Decode_update(varargin)
            %PPLFP_DECODE_UPDATE Deprecated. Use nstat.decoding.PPLFP.PPLFP_Decode_update instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step E of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PPLFP_Decode_update is deprecated; use ' ...
                 'nstat.decoding.PPLFP.PPLFP_Decode_update instead.']);
            [varargout{1:nargout}] = nstat.decoding.PPLFP.PPLFP_Decode_update(varargin{:});
        end

        function varargout = PPLFP_EMCreateConstraints(varargin)
            %PPLFP_EMCREATECONSTRAINTS Deprecated. Use nstat.decoding.PPLFP.PPLFP_EMCreateConstraints instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step E of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PPLFP_EMCreateConstraints is deprecated; use ' ...
                 'nstat.decoding.PPLFP.PPLFP_EMCreateConstraints instead.']);
            [varargout{1:nargout}] = nstat.decoding.PPLFP.PPLFP_EMCreateConstraints(varargin{:});
        end

        function varargout = PPLFP_ComputeParamStandardErrors(varargin)
            %PPLFP_COMPUTEPARAMSTANDARDERRORS Deprecated. Use nstat.decoding.PPLFP.PPLFP_ComputeParamStandardErrors instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step E of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PPLFP_ComputeParamStandardErrors is deprecated; use ' ...
                 'nstat.decoding.PPLFP.PPLFP_ComputeParamStandardErrors instead.']);
            [varargout{1:nargout}] = nstat.decoding.PPLFP.PPLFP_ComputeParamStandardErrors(varargin{:});
        end

        function varargout = PPLFP_EM(varargin)
            %PPLFP_EM Deprecated. Use nstat.decoding.PPLFP.PPLFP_EM instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step E of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PPLFP_EM is deprecated; use ' ...
                 'nstat.decoding.PPLFP.PPLFP_EM instead.']);
            [varargout{1:nargout}] = nstat.decoding.PPLFP.PPLFP_EM(varargin{:});
        end

        function varargout = PPLFP_EStep(varargin)
            %PPLFP_ESTEP Deprecated. Use nstat.decoding.PPLFP.PPLFP_EStep instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step E of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PPLFP_EStep is deprecated; use ' ...
                 'nstat.decoding.PPLFP.PPLFP_EStep instead.']);
            [varargout{1:nargout}] = nstat.decoding.PPLFP.PPLFP_EStep(varargin{:});
        end

        function varargout = PPLFP_MStep(varargin)
            %PPLFP_MSTEP Deprecated. Use nstat.decoding.PPLFP.PPLFP_MStep instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step E of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PPLFP_MStep is deprecated; use ' ...
                 'nstat.decoding.PPLFP.PPLFP_MStep instead.']);
            [varargout{1:nargout}] = nstat.decoding.PPLFP.PPLFP_MStep(varargin{:});
        end
    
        %% Point Process EM (deprecation shims)
        % Cluster extracted to nstat.decoding.PointProcessEM
        % (Phase 3 Task 3.2 Step H -- FINAL extraction -- of the
        % 2026-05-19 nSTAT review action plan). The methods below are
        % thin deprecation shims that forward to the new class via
        % varargin/varargout.
        function varargout = PP_EMCreateConstraints(varargin)
            %PP_EMCREATECONSTRAINTS Deprecated. Use nstat.decoding.PointProcessEM.PP_EMCreateConstraints instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step H of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PP_EMCreateConstraints is deprecated; use ' ...
                 'nstat.decoding.PointProcessEM.PP_EMCreateConstraints instead.']);
            [varargout{1:nargout}] = nstat.decoding.PointProcessEM.PP_EMCreateConstraints(varargin{:});
        end

        function varargout = PP_ComputeParamStandardErrors(varargin)
            %PP_COMPUTEPARAMSTANDARDERRORS Deprecated. Use nstat.decoding.PointProcessEM.PP_ComputeParamStandardErrors instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step H of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PP_ComputeParamStandardErrors is deprecated; use ' ...
                 'nstat.decoding.PointProcessEM.PP_ComputeParamStandardErrors instead.']);
            [varargout{1:nargout}] = nstat.decoding.PointProcessEM.PP_ComputeParamStandardErrors(varargin{:});
        end

        function varargout = PP_EM(varargin)
            %PP_EM Deprecated. Use nstat.decoding.PointProcessEM.PP_EM instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step H of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PP_EM is deprecated; use ' ...
                 'nstat.decoding.PointProcessEM.PP_EM instead.']);
            [varargout{1:nargout}] = nstat.decoding.PointProcessEM.PP_EM(varargin{:});
        end

        function varargout = PP_EStep(varargin)
            %PP_ESTEP Deprecated. Use nstat.decoding.PointProcessEM.PP_EStep instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step H of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PP_EStep is deprecated; use ' ...
                 'nstat.decoding.PointProcessEM.PP_EStep instead.']);
            [varargout{1:nargout}] = nstat.decoding.PointProcessEM.PP_EStep(varargin{:});
        end

        function varargout = PP_MStep(varargin)
            %PP_MSTEP Deprecated. Use nstat.decoding.PointProcessEM.PP_MStep instead.
            %
            % Forwarded as part of Phase 3 Task 3.2 Step H of the
            % 2026-05-19 nSTAT review action plan: the DecodingAlgorithms
            % monolith is being split into the +nstat/+decoding/ package.
            warning('nSTAT:deprecated:DecodingAlgorithms', ...
                ['DecodingAlgorithms.PP_MStep is deprecated; use ' ...
                 'nstat.decoding.PointProcessEM.PP_MStep instead.']);
            [varargout{1:nargout}] = nstat.decoding.PointProcessEM.PP_MStep(varargin{:});
        end

        %% Deprecation shims: mPPCO_* -> PPLFP_*
        % The mPPCO_* method family was renamed to PPLFP_* in 2026-05 to
        % align with bci-curriculum chapter-04 §4.B.7 PPLFP terminology
        % (Point-Process + LFP filter; Cajigas 2013 unpublished derivation,
        % source/PPLFPFilter_final.pdf). The old mPPCO name is historical
        % and predates the chapter's PPLFP framing.
        %
        % These shims forward calls to the renamed canonical methods and
        % emit the warning identifier `nSTAT:deprecated:mPPCO`. They will
        % be removed in a future minor release. Callers should migrate to
        % the PPLFP_* names. To silence the warning while migrating:
        %   warning('off', 'nSTAT:deprecated:mPPCO');

        function [varargout] = mPPCO_fixedIntervalSmoother(varargin)
            %MPPCO_FIXEDINTERVALSMOOTHER Deprecated. Use PPLFP_fixedIntervalSmoother.
            % See bci-curriculum §4.B.7 PPLFP for the canonical derivation.
            warning('nSTAT:deprecated:mPPCO', ...
                ['DecodingAlgorithms.mPPCO_fixedIntervalSmoother is deprecated; ' ...
                 'use DecodingAlgorithms.PPLFP_fixedIntervalSmoother instead. ' ...
                 'See bci-curriculum §4.B.7 for the PPLFP derivation.']);
            [varargout{1:nargout}] = DecodingAlgorithms.PPLFP_fixedIntervalSmoother(varargin{:});
        end

        function [varargout] = mPPCODecodeLinear(varargin)
            %MPPCODECODELINEAR Deprecated. Use PPLFP_DecodeLinear instead.
            % See bci-curriculum §4.B.7 PPLFP for the canonical derivation.
            warning('nSTAT:deprecated:mPPCO', ...
                ['DecodingAlgorithms.mPPCODecodeLinear is deprecated; ' ...
                 'use DecodingAlgorithms.PPLFP_DecodeLinear instead. ' ...
                 'See bci-curriculum §4.B.7 for the PPLFP derivation.']);
            [varargout{1:nargout}] = DecodingAlgorithms.PPLFP_DecodeLinear(varargin{:});
        end

        function [varargout] = mPPCODecode_predict(varargin)
            %MPPCODECODE_PREDICT Deprecated. Use PPLFP_Decode_predict instead.
            % See bci-curriculum §4.B.7 PPLFP for the canonical derivation.
            warning('nSTAT:deprecated:mPPCO', ...
                ['DecodingAlgorithms.mPPCODecode_predict is deprecated; ' ...
                 'use DecodingAlgorithms.PPLFP_Decode_predict instead. ' ...
                 'See bci-curriculum §4.B.7 for the PPLFP derivation.']);
            [varargout{1:nargout}] = DecodingAlgorithms.PPLFP_Decode_predict(varargin{:});
        end

        function [varargout] = mPPCODecode_update(varargin)
            %MPPCODECODE_UPDATE Deprecated. Use PPLFP_Decode_update instead.
            % See bci-curriculum §4.B.7 PPLFP for the canonical derivation.
            warning('nSTAT:deprecated:mPPCO', ...
                ['DecodingAlgorithms.mPPCODecode_update is deprecated; ' ...
                 'use DecodingAlgorithms.PPLFP_Decode_update instead. ' ...
                 'See bci-curriculum §4.B.7 for the PPLFP derivation.']);
            [varargout{1:nargout}] = DecodingAlgorithms.PPLFP_Decode_update(varargin{:});
        end

        function [varargout] = mPPCO_EMCreateConstraints(varargin)
            %MPPCO_EMCREATECONSTRAINTS Deprecated. Use PPLFP_EMCreateConstraints.
            % See bci-curriculum §4.B.7 PPLFP for the canonical derivation.
            warning('nSTAT:deprecated:mPPCO', ...
                ['DecodingAlgorithms.mPPCO_EMCreateConstraints is deprecated; ' ...
                 'use DecodingAlgorithms.PPLFP_EMCreateConstraints instead. ' ...
                 'See bci-curriculum §4.B.7 for the PPLFP derivation.']);
            [varargout{1:nargout}] = DecodingAlgorithms.PPLFP_EMCreateConstraints(varargin{:});
        end

        function [varargout] = mPPCO_ComputeParamStandardErrors(varargin)
            %MPPCO_COMPUTEPARAMSTANDARDERRORS Deprecated. Use PPLFP_ComputeParamStandardErrors.
            % See bci-curriculum §4.B.7 PPLFP for the canonical derivation.
            warning('nSTAT:deprecated:mPPCO', ...
                ['DecodingAlgorithms.mPPCO_ComputeParamStandardErrors is deprecated; ' ...
                 'use DecodingAlgorithms.PPLFP_ComputeParamStandardErrors instead. ' ...
                 'See bci-curriculum §4.B.7 for the PPLFP derivation.']);
            [varargout{1:nargout}] = DecodingAlgorithms.PPLFP_ComputeParamStandardErrors(varargin{:});
        end

        function [varargout] = mPPCO_EM(varargin)
            %MPPCO_EM Deprecated. Use PPLFP_EM instead.
            % See bci-curriculum §4.B.7 PPLFP for the canonical derivation.
            warning('nSTAT:deprecated:mPPCO', ...
                ['DecodingAlgorithms.mPPCO_EM is deprecated; ' ...
                 'use DecodingAlgorithms.PPLFP_EM instead. ' ...
                 'See bci-curriculum §4.B.7 for the PPLFP derivation.']);
            [varargout{1:nargout}] = DecodingAlgorithms.PPLFP_EM(varargin{:});
        end

        function [varargout] = mPPCO_EStep(varargin)
            %MPPCO_ESTEP Deprecated. Use PPLFP_EStep instead.
            % See bci-curriculum §4.B.7 PPLFP for the canonical derivation.
            warning('nSTAT:deprecated:mPPCO', ...
                ['DecodingAlgorithms.mPPCO_EStep is deprecated; ' ...
                 'use DecodingAlgorithms.PPLFP_EStep instead. ' ...
                 'See bci-curriculum §4.B.7 for the PPLFP derivation.']);
            [varargout{1:nargout}] = DecodingAlgorithms.PPLFP_EStep(varargin{:});
        end

        function [varargout] = mPPCO_MStep(varargin)
            %MPPCO_MSTEP Deprecated. Use PPLFP_MStep instead.
            % See bci-curriculum §4.B.7 PPLFP for the canonical derivation.
            warning('nSTAT:deprecated:mPPCO', ...
                ['DecodingAlgorithms.mPPCO_MStep is deprecated; ' ...
                 'use DecodingAlgorithms.PPLFP_MStep instead. ' ...
                 'See bci-curriculum §4.B.7 for the PPLFP derivation.']);
            [varargout{1:nargout}] = DecodingAlgorithms.PPLFP_MStep(varargin{:});
        end
    end
end


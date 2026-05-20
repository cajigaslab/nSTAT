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
    
        %% Point Process EM
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
        %    Io(theta;y) = Ic(theta;y) - Im(theta;y)
        %    Io(theta;y) = Ic(theta;y) - cov(Sc(X;theta)Sc(X;theta)')
        % where Sc(X;theta) is the score vector of the complete log likelihood
        % function evaluated at theta. We first compute Ic term by term and then
        % approximate the covariance term using Monte Carlo approximation
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            if(nargin<19 || isempty(PPEM_Constraints))
                PPEM_Constraints=DecodingAlgorithms.PP_EMCreateConstraints;
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

            if(PPEM_Constraints.EstimatePx0==1)
                if(PPEM_Constraints.Px0Isotropic==1)
                    ISComp =  0.5*dx*Px0hat(1,1)^(-2);
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
            pools = matlabpool('size'); %number of parallel workers 
           if(strcmp(fitType,'poisson'))
                for c=1:numCells
                    HessianTerm = zeros(size(xKFinal,1),size(xKFinal,1),K);
                    for k=1:K
%                         Hk = squeeze(HkAll(:,:,c));
                        Hk = (HkAll(k,:,c));
                        Wk = WKFinal(:,:,k);
                       
%                         xk = squeeze(xKDrawExp(:,k,:));
                        xk=xkPerm(:,:,k);
                       if(size(Hk,1)==numCells)
                           Hk = Hk';
                       end
                   
                        if(numel(gammahat)==1)
                            gammaC=gammahat;
%                             gammaC=repmat(gammaC,[1 numCells]);
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
%                         Hk = squeeze(HkAll(:,:,c));
                        Hk = (HkAll(k,:,c));
                        Wk = WKFinal(:,:,k);
%                         xk = squeeze(xKDrawExp(:,k,:));
                        xk = (xkPerm(:,:,k));
                        if(size(Hk,1)==numCells)
                           Hk = Hk';
                        end
                   
                        if(numel(gammahat)==1)
                            gammaC=gammahat;
%                             gammaC=repmat(gammaC,[1 numCells]);
                        else 
                            gammaC=gammahat(:,c);
                        end
                        terms =muhat(c)+betahat(:,c)'*xk+gammaC'*Hk';
                        ld=exp(terms)./(1+exp(terms));
                        ExplambdaDeltaXkXk=1/McExp*(repmat(ld,[size(xk,1),1]).*xk)*xk';
                        ExplambdaDeltaSqXkXkT=1/McExp*(repmat(ld.^2,[size(xk,1),1]).*xk)*xk';
                        ExplambdaDeltaCubeXkXkT=1/McExp*(repmat(ld.^3,[size(xk,1),1]).*xk)*xk';
                        HessianTerm(:,:,k)+ExplambdaDeltaXkXk+ExplambdaDeltaSqXkXkT-2*ExplambdaDeltaCubeXkXkT;
                        
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
    %                         Hk = squeeze(HkAll(:,:,c));
                            Hk = (HkAll(:,:,c));
                            if(size(Hk,1)==numCells)
                               Hk = Hk';
                            end
    %                         xk = squeeze(xKDrawExp(:,k,:));
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
    %                         Hk = squeeze(HkAll(:,:,c));
                            Hk = (HkAll(:,:,c));
                            if(size(Hk,1)==numCells)
                               Hk = Hk';
                            end
    %                         xk = squeeze(xKDrawExp(:,k,:));
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
                            HessianTerm = HessianTerm -(dN(c,k)+1)*ExplambdaDelta ...
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
    %                         Hk = squeeze(HkAll(:,:,c));
                            Hk = (HkAll(k,:,c));
                            if(size(Hk,1)==numCells)
                               Hk = Hk';
                            end
    %                         xk = squeeze(xKDrawExp(:,k,:));
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
    %                         Hk = squeeze(HkAll(:,:,c));
                            Hk = (HkAll(k,:,c));
                            if(size(Hk,1)==numCells)
                               Hk = Hk';
                            end
    %                         xk = squeeze(xKDrawExp(:,k,:));
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
                            HessianTerm(k) =  -(dN(c,k)+1)*ExplambdaDelta ...
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
    %                             Hk = squeeze(HkAll(:,:,c));
                                Hk = (HkAll(:,:,c));
                                if(size(Hk,1)==numCells)
                                   Hk = Hk';
                                end
    %                             xk = squeeze(xKDrawExp(:,k,:));
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
    %                             xk = squeeze(xKDrawExp(:,k,:));
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
                                ExplambdaDeltaCubed  = 1/McExp*sum(ld.^3,2); % FIX: was ld.^2 (copy-paste); should be ld.^3 for cubic moment
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
    %                             Hk = squeeze(HkAll(:,:,c));
                                Hk = (HkAll(k,:,c));
                                if(size(Hk,1)==numCells)
                                   Hk = Hk';
                                end
    %                             xk = squeeze(xKDrawExp(:,k,:));
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
    %                             xk = squeeze(xKDrawExp(:,k,:));
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
                                ExplambdaDeltaCubed  = 1/McExp*sum(ld.^3,2); % FIX: was ld.^2 (copy-paste); should be ld.^3 for cubic moment
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
            pools = matlabpool('size'); %number of parallel workers 
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
                            Sxkm1xk   = Sxkm1xk+x_0*x_K(:,k)';
                            Sxkm1xkm1 = Sxkm1xkm1+x_0*x_0';     
                        else
                            Sxkm1xk =  Sxkm1xk+x_K(:,k-1)*x_K(:,k)';
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
                            ScoreQ  =-.5*(K*Dx*Qhat(1,1)^(-1) - Qhat(1,1)^(-2)*trace(sumXkTerms));
                        else
                            ScoreQ  =(-.5*(Qhat\(K*eye(size(Qhat)) - sumXkTerms/Qhat)));
                        end
                        ScoreQMc = diag(ScoreQ);
                    else
                        ScoreQ   =-.5*(Qhat\(K*eye(size(Qhat)) - sumXkTerms/Qhat));
                        ScoreQMc =reshape(ScoreQ',numel(ScoreQ),1);
                    end

                    if(PPEM_Constraints.Px0Isotropic==1)
                        ScoreSMc=-.5*(Dx*Px0hat(1,1)^(-1) - Px0hat(1,1)^(-2)*trace((x_0-x0hat)*(x_0-x0hat)'));
                    else
                        ScorS  =-.5*(Px0hat\(eye(size(Px0hat)) - (x_0-x0hat)*(x_0-x0hat)'/Px0hat));
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
                            Sxkm1xk   = Sxkm1xk+x_0*x_K(:,k)';
                            Sxkm1xkm1 = Sxkm1xkm1+x_0*x_0';     
                        else
                            Sxkm1xk =  Sxkm1xk+x_K(:,k-1)*x_K(:,k)';
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
                            ScoreQ  =-.5*(K*Dx*Qhat(1,1)^(-1) - Qhat(1,1)^(-2)*trace(sumXkTerms));
                        else
                            ScoreQ  =(-.5*(Qhat\(K*eye(size(Qhat)) - sumXkTerms/Qhat)));
                        end
                        ScoreQMc = diag(ScoreQ);
                    else
                        ScoreQ   =-.5*(Qhat\(K*eye(size(Qhat)) - sumXkTerms/Qhat));
                        ScoreQMc =reshape(ScoreQ',numel(ScoreQ),1);
                    end

                    if(PPEM_Constraints.Px0Isotropic==1)
                        ScoreSMc=-.5*(Dx*Px0hat(1,1)^(-1) - Px0hat(1,1)^(-2)*trace((x_0-x0hat)*(x_0-x0hat)'));
                    else
                        ScorS  =-.5*(Px0hat\(eye(size(Px0hat)) - (x_0-x0hat)*(x_0-x0hat)'/Px0hat));
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
            IObs  = IComp-IMissing;  
            invIObs = eye(size(IObs))/IObs;
%             figure(1); subplot(1,2,1); imagesc(invIObs); subplot(1,2,2); imagesc(nearestSPD(invIObs));
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

            %Q matrix
            clear h p;
            if(PPEM_Constraints.QhatDiag==1)
                if(PPEM_Constraints.QhatIsotropic==1)
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
            if(PPEM_Constraints.EstimatePx0==1)
                clear h p;
                if(PPEM_Constraints.Px0Isotropic==1)
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


            if(PPEM_Constraints.Estimatex0==1)
                clear h p;
                VecParams = x0hat;
                VecSE     = SEx0;
                for i=1:length(VecParams)
                    [h(i) p(i)] = ztest(VecParams(i),0,VecSE(i));
                end
                pX0 = p';
            end
            
            %Mu
            clear h p;
            VecParams = muhat;
            VecSE     = SEMu;
            for i=1:length(VecParams)
                [h(i) p(i)] = ztest(VecParams(i),0,VecSE(i));
            end
            pMu = p';
            
            %Beta
            clear h p;
            VecParams = reshape(betahat,[numel(betahat),1]);
            VecSE     = reshape(SEBeta, [numel(SEBeta),1]);
            for i=1:length(VecParams)
                [h(i) p(i)] = ztest(VecParams(i),0,VecSE(i));
            end    
            pBeta = reshape(p, [size(betahat,1) size(betahat,2)]);
            
            %Gamma
            clear h p;
            if((numel(gammahat)==1 && gammahat~=0) || numel(gammahat)>1)
                VecParams = reshape(gammahat,[numel(gammahat),1]);
                VecSE     = reshape(SEGamma, [numel(gammahat),1]);
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
                PPEM_Constraints = DecodingAlgorithms.PP_EMCreateConstraints;
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
    %                 numWindows =length(gamma0)+1; 
                    windowTimes = 0:delta:(length(gamma)+1)*delta;
                end
            end
            if(nargin<8)
                gamma=[];
            end
            if(nargin<7 || isempty(delta))
                delta = .001;
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
%                     HkAll{k} = histObj.computeHistory(nst{k}).dataToMatrix;
                    HkAll(:,:,k) = histObj.computeHistory(nst{k}).dataToMatrix;
                end
            else
                for k=1:K
%                     HkAll{k} = 0;
                    HkAll(:,:,k) = 0;
                end
                gamma=0;
            end



    %         tol = 1e-3; %absolute change;
            tolAbs = 1e-3;
            tolRel = 1e-3;
            llTol  = 1e-3;
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
%             x0hat = x0;
            negLL=0;
            IkedaAcc=PPEM_Constraints.EnableIkeda;
            %Forward EM
            stoppingCriteria =0;
%             logllNew= -inf;

            disp('                        Point-Process Observation EM Algorithm                        ');    
            while(stoppingCriteria~=1 && cnt<=maxIter)
                 storeInd = mod(cnt-1,numToKeep)+1; %make zero-based then mod, then add 1
                 storeIndP1= mod(cnt,numToKeep)+1;
                 storeIndM1= mod(cnt-2,numToKeep)+1;
                disp('--------------------------------------------------------------------------------------------------------');
                disp(['Iteration #' num2str(cnt)]);
                disp('--------------------------------------------------------------------------------------------------------');
                

                [x_K{storeInd},W_K{storeInd},ll(cnt),ExpectationSums{storeInd}]=...
                    DecodingAlgorithms.PP_EStep(Ahat{storeInd},Qhat{storeInd},dN, muhat{storeInd}, betahat{storeInd},fitType,gammahat{storeInd},HkAll, x0hat{storeInd}, Px0hat{storeInd});
                
                [Ahat{storeIndP1}, Qhat{storeIndP1}, muhat{storeIndP1}, betahat{storeIndP1}, gammahat{storeIndP1},x0hat{storeIndP1},Px0hat{storeIndP1}] ...
                    = DecodingAlgorithms.PP_MStep(dN,x_K{storeInd},W_K{storeInd},x0hat{storeInd}, Px0hat{storeInd}, ExpectationSums{storeInd}, fitType,muhat{storeInd},betahat{storeInd}, gammahat{storeInd},windowTimes,HkAll,PPEM_Constraints,MstepMethod);
              
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
                             tempData  = exp(dataMat*coeffsMat(cc,:)');

                             if(strcmp(fitType,'poisson'))
                                 lambdaData = tempData;
                             else
                                lambdaData = tempData./(1+tempData); % Conditional Intensity Function for ith cell
                             end
                             lambda{cc}=Covariate(time,lambdaData./delta, ...
                                 '\Lambda(t)','time','s','spikes/sec',...
                                 {strcat('\lambda_{',num2str(cc),'}')},{{' ''b'' '}});
                             lambda{cc}=lambda{cc}.resample(1/delta);

                             % generate one realization for each cell
                             tempSpikeColl{cc} = CIF.simulateCIFByThinningFromLambda(lambda{cc},1);          
                             nstNew{cc} = tempSpikeColl{cc}.getNST(1);     % grab the realization
                             nstNew{cc}.setName(num2str(cc));              % give each cell a unique name
%                              subplot(4,3,[8 11]);
%                              h2=lambda{cc}.plot([],{{' ''k'', ''LineWidth'' ,.5'}}); 
%                              legend off; hold all; % Plot the CIF

                        end
                        
                        spikeColl = nstColl(nstNew); % Create a neural spike train collection
                     else
                         time;
                     end
                     
                     dNNew=spikeColl.dataToMatrix';
                     dNNew(dNNew>1)=1; % more than one spike per bin will be treated as one spike. In
                                    % general we should pick delta small enough so that there is
                                    % only one spike per bin
                                    
                                    
%                                     [x_K,W_K,logll,ExpectationSums]=PP_EStep(A,Q,dN, mu, beta,fitType,gamma,HkAll, x0, Px0)
                     [x_KNew,W_KNew,logllNew,ExpectationSumsNew]=...
                        DecodingAlgorithms.PP_EStep(Ahat{storeInd},Qhat{storeInd},dNNew, muhat{storeInd}, betahat{storeInd},fitType,gammahat{storeInd},HkAll, x0, Px0);


                     [AhatNew, QhatNew, muhatNew, betahatNew, gammahatNew,x0new,Px0new] ...
                        = DecodingAlgorithms.PP_MStep(dNNew,x_KNew,W_KNew, x0hat{storeInd}, Px0hat{storeInd}, ExpectationSumsNew, fitType,muhat{storeInd},betahat{storeInd}, gammahat{storeInd},windowTimes,HkAll,PPEM_Constraints,MstepMethod);
               
                    Ahat{storeIndP1} = 2*Ahat{storeIndP1}-AhatNew;
                    Qhat{storeIndP1} = 2*Qhat{storeIndP1}-QhatNew;
                    Qhat{storeIndP1} = (Qhat{storeIndP1}+Qhat{storeIndP1}')/2;
                    muhat{storeIndP1}= 2*muhat{storeIndP1}-muhatNew;
                    betahat{storeIndP1} = 2*betahat{storeIndP1}-betahatNew;
                    gammahat{storeIndP1}= 2*gammahat{storeIndP1}-gammahatNew;
%                     x0hat{storeIndP1}   = 2*x0hat{storeIndP1} - x0new;
%                     Px0hat{storeIndP1}  = 2*Px0hat{storeIndP1}- Px0new;
%                     [V,D] = eig(Px0hat{storeIndP1});
%                     D(D<0)=1e-9;
%                     Px0hat{storeIndP1} = V*D*V';
%                     Px0hat{storeIndP1}  = (Px0hat{storeIndP1}+Px0hat{storeIndP1}')/2;
                    
               
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
%                 if(mod(cnt,2)==0)
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
                set(gca, 'XTick'       , 1:1:length(diag(Qhat{storeInd})));
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
                [SE, Pvals]=DecodingAlgorithms.PP_ComputeParamStandardErrors(dN,...
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
            
            K  = size(xKFinal,2); 
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
        %         function  [xKFinal,WKFinal,Ahat, Qhat, muhat, betahat, gammahat, x0hat, Px0hat, logll,nIter,negLL]=PP_EM(dN, Ahat0, Qhat0, mu, beta, fitType,delta, gamma, windowTimes, x0, Px0,MstepMethod)
%             numStates = size(Ahat0,1);
%             if(nargin<12 || isempty(MstepMethod))
%                MstepMethod='GLM'; %or NewtonRaphson 
%             end
%             if(nargin<11 || isempty(Px0))
%                 Px0=10e-10*eye(numStates,numStates);
%             end
%             if(nargin<10 || isempty(x0))
%                 x0=zeros(numStates,1);
%             end
%             
%             if(nargin<9 || isempty(windowTimes))
%                 if(isempty(gamma)||gamma==0)
%                     windowTimes =[];
%                 else
%     %                 numWindows =length(gamma0)+1; 
%                     windowTimes = 0:delta:(length(gamma)+1)*delta;
%                 end
%             end
%             if(nargin<8)
%                 gamma=[];
%             end
%             if(nargin<11 || isempty(delta))
%                 delta = .001;
%             end
%             if(nargin<6)
%                 fitType = 'poisson';
%             end
%             
%             minTime=0;
%             maxTime=(size(dN,2)-1)*delta;
%             K=size(dN,1);
%             N=size(dN,2);
%             if(~isempty(windowTimes))
%                 histObj = History(windowTimes,minTime,maxTime);
%                 for k=1:K
%                     nst{k} = nspikeTrain( (find(dN(k,:)==1)-1)*delta);
%                     nst{k}.setMinTime(minTime);
%                     nst{k}.setMaxTime(maxTime);
% %                     HkAll{k} = histObj.computeHistory(nst{k}).dataToMatrix;
%                     HkAll(:,:,k) = histObj.computeHistory(nst{k}).dataToMatrix;
%                 end
%                 if(size(gamma,1)==K)
%                     gamma=gamma';
%                 end
%                 
%             else
%                 for k=1:K
%                     HkAll(:,:,k) = zeros(N,length(windowTimes)-1);
%                 end
%                 gamma=0;
%             end
%                 
% 
% 
%     %         tol = 1e-3; %absolute change;
%             tolAbs = 1e-3;
%             tolRel = 1e-3;
%             llTol  = 1e-3;
%             cnt=1;
% 
%             maxIter = 100;
% 
%             
%             A0 = Ahat0;
%             Q0 = Qhat0;
%            
%             Ahat{1} = A0;
%             Qhat{1} = Q0;
%             x0hat{1} = x0;
%             Px0hat{1} = Px0;
%             muhat{1} = mu;
%             betahat{1} = beta;
%             gammahat{1} = gamma;
%             numToKeep=10;
%             scaledSystem=1;
%             
%             if(scaledSystem==1)
%                 Tq = eye(size(Qhat{1}))/(chol(Qhat{1}));
%                 Ahat{1}= Tq*Ahat{1}/Tq;
%                 Qhat{1}= Tq*Qhat{1}*Tq';
%                 x0hat{1} = Tq*x0;
%                 Px0hat{1} = Tq*Px0*Tq';
%                 betahat{1}=(betahat{1}'/Tq)';
%             end
% 
%             cnt=1;
%             dLikelihood(1)=inf;
%             negLL=0;
%             IkedaAcc=0;
%             %Forward EM
%             stoppingCriteria =0;
%                 
%             while(stoppingCriteria~=1 && cnt<=maxIter)
%                  storeInd = mod(cnt-1,numToKeep)+1; %make zero-based then mod, then add 1
%                  storeIndP1= mod(cnt,numToKeep)+1;
%                  storeIndM1= mod(cnt-2,numToKeep)+1;
%                 disp('---------------');
%                 disp(['Iteration #' num2str(cnt)]);
%                 disp('---------------');
%                 
%                 
%                 [x_K{storeInd},W_K{storeInd},logll(cnt),ExpectationSums{storeInd}]=...
%                     DecodingAlgorithms.PP_EStep(Ahat{storeInd},Qhat{storeInd},dN, muhat{storeInd}, betahat{storeInd},fitType,gammahat{storeInd},HkAll, x0hat{storeInd}, Px0hat{storeInd});
%                 
%                 [Ahat{storeIndP1}, Qhat{storeIndP1}, muhat{storeIndP1}, betahat{storeIndP1}, gammahat{storeIndP1},x0hat{storeIndP1},Px0hat{storeIndP1}] ...
%                     = DecodingAlgorithms.PP_MStep(dN,x_K{storeInd},W_K{storeInd},x0hat{storeInd},ExpectationSums{storeInd}, fitType,muhat{storeInd},betahat{storeInd}, gammahat{storeInd},windowTimes,HkAll,MstepMethod);
%               
%                 if(IkedaAcc==1)
%                     disp(['****Ikeda Acceleration Step****']);
%                      
%                      if(gammahat{storeIndP1}==0)% No history effect
%                         dataMat = [ones(size(dN,2),1) x_K{storeInd}']; % design matrix: X 
%                         coeffsMat = [muhat{storeIndP1} betahat{storeIndP1}']; % coefficient vector: beta
%                         minTime=0;
%                         maxTime=(size(dN,2)-1)*delta;
%                         time=minTime:delta:maxTime;
%                         clear nstNew;
%                         for cc=1:length(muhat{storeIndP1})
%                              tempData  = exp(dataMat*coeffsMat(cc,:)');
% 
%                              if(strcmp(fitType,'poisson'))
%                                  lambdaData = tempData;
%                              else
%                                 lambdaData = tempData./(1+tempData); % Conditional Intensity Function for ith cell
%                              end
%                              lambda{cc}=Covariate(time,lambdaData./delta, ...
%                                  '\Lambda(t)','time','s','spikes/sec',...
%                                  {strcat('\lambda_{',num2str(cc),'}')},{{' ''b'' '}});
%                              lambda{cc}=lambda{cc}.resample(1/delta);
% 
%                              % generate one realization for each cell
%                              tempSpikeColl{cc} = CIF.simulateCIFByThinningFromLambda(lambda{cc},1);          
%                              nstNew{cc} = tempSpikeColl{cc}.getNST(1);     % grab the realization
%                              nstNew{cc}.setName(num2str(cc));              % give each cell a unique name
% %                              subplot(4,3,[8 11]);
% %                              h2=lambda{cc}.plot([],{{' ''k'', ''LineWidth'' ,.5'}}); 
% %                              legend off; hold all; % Plot the CIF
% 
%                         end
%                         
%                         spikeColl = nstColl(nstNew); % Create a neural spike train collection
%                      else
%                          time;
%                      end
%                      
%                      dNNew=spikeColl.dataToMatrix';
%                      dNNew(dNNew>1)=1; % more than one spike per bin will be treated as one spike. In
%                                     % general we should pick delta small enough so that there is
%                                     % only one spike per bin
%                                     
%                                     
% %                                     [x_K,W_K,logll,ExpectationSums]=PP_EStep(A,Q,dN, mu, beta,fitType,gamma,HkAll, x0, Px0)
%                      [x_KNew,W_KNew,logllNew,ExpectationSumsNew]=...
%                         DecodingAlgorithms.PP_EStep(Ahat{storeInd},Qhat{storeInd},dNNew, muhat{storeInd}, betahat{storeInd},fitType,gammahat{storeInd},HkAll, x0, Px0);
% 
%                 
%                      [AhatNew, QhatNew, muhatNew, betahatNew, gammahatNew,x0new,Px0new] ...
%                         = DecodingAlgorithms.PP_MStep(dNNew,x_KNew,W_KNew, x0hat{storeInd}, ExpectationSumsNew, fitType,muhat{storeInd},betahat{storeInd}, gammahat{storeInd},windowTimes,HkAll,MstepMethod);
%                
%                     Ahat{storeIndP1} = 2*Ahat{storeIndP1}-AhatNew;
%                     Qhat{storeIndP1} = 2*Qhat{storeIndP1}-QhatNew;
%                     Qhat{storeIndP1} = (Qhat{storeIndP1}+Qhat{storeIndP1}')/2;
%                     muhat{storeIndP1}= 2*muhat{storeIndP1}-muhatNew;
%                     betahat{storeIndP1} = 2*betahat{storeIndP1}-betahatNew;
%                     gammahat{storeIndP1}= 2*gammahat{storeIndP1}-gammahatNew;
% %                     x0hat{storeIndP1}   = 2*x0hat{storeIndP1} - x0new;
% %                     Px0hat{storeIndP1}  = 2*Px0hat{storeIndP1}- Px0new;
% %                     [V,D] = eig(Px0hat{storeIndP1});
% %                     D(D<0)=1e-9;
% %                     Px0hat{storeIndP1} = V*D*V';
% %                     Px0hat{storeIndP1}  = (Px0hat{storeIndP1}+Px0hat{storeIndP1}')/2;
%                     
%                
%                 end
% 
%                 if(cnt==1)
%                     dLikelihood(cnt+1)=inf;
%                 else
%                     dLikelihood(cnt+1)=(logll(cnt)-logll(cnt-1));%./abs(logll(cnt-1));
%                 end
%                 if(cnt==1)
%                     QhatInit = Qhat{1};
%                     xKInit = x_K{1};
%                 end
%                 %Plot the progress
% %                 if(mod(cnt,2)==0)
%                 if(cnt==1)
%                     scrsz = get(0,'ScreenSize');
%                     h=figure('OuterPosition',[scrsz(3)*.01 scrsz(4)*.04 scrsz(3)*.98 scrsz(4)*.95]);
%                 end
%                     figure(h);
%                     time = linspace(minTime,maxTime,size(x_K{storeInd},2));
%                     subplot(2,4,[1 2 5 6]); plot(1:cnt,logll,'k','Linewidth', 2); hy=ylabel('Log Likelihood'); hx=xlabel('Iteration'); axis auto;
%                     set([hx, hy],'FontName', 'Arial','FontSize',12,'FontWeight','bold');
%                     subplot(2,4,3:4); hNew=plot(time, x_K{storeInd}','Linewidth', 2); hy=ylabel('States'); hx=xlabel('time [s]');
%                     set([hx, hy],'FontName', 'Arial','FontSize',12,'FontWeight','bold'); 
%                     hold on; hOrig=plot(time, xKInit','--','Linewidth', 2); 
%                     legend([hOrig(1) hNew(1)],'Initial','Current');
%                   
%                     
%                     subplot(2,4,7:8); hNew=plot(diag(Qhat{storeInd}),'o','Linewidth', 2); hy=ylabel('Q'); hx=xlabel('Diagonal Entry');
%                     set(gca, 'XTick'       , 1:1:length(diag(Qhat{storeInd})));
%                     set([hx, hy],'FontName', 'Arial','FontSize',12,'FontWeight','bold');
%                     hold on; hOrig=plot(diag(QhatInit),'r.','Linewidth', 2);
%                     legend([hOrig(1) hNew(1)],'Initial','Current');
%                     drawnow;
%                     hold off;
% %                 end
%                 
%                 if(cnt==1)
%                     dMax=inf;
%                 else
%                  dQvals = max(max(abs(sqrt(Qhat{storeInd})-sqrt(Qhat{storeIndM1}))));
%                  dAvals = max(max(abs((Ahat{storeInd})-(Ahat{storeIndM1}))));
%                  dMuvals = max(abs((muhat{storeInd})-(muhat{storeIndM1})));
%                  dBetavals = max(max(abs((betahat{storeInd})-(betahat{storeIndM1}))));
%                  dGammavals = max(max(abs((gammahat{storeInd})-(gammahat{storeIndM1}))));
%                  dMax = max([dQvals,dAvals,dMuvals,dBetavals,dGammavals]);
%                 end
% 
% % 
% %                 dQRel = max(abs(dQvals./sqrt(Qhat(:,storeIndM1))));
% %                 dGammaRel = max(abs(dGamma./gammahat(storeIndM1,:)));
% %                 dMaxRel = max([dQRel,dGammaRel]);
% 
%                  
%                 cnt=(cnt+1);
%                 if(dMax<tolAbs)
%                     stoppingCriteria=1;
%                     display(['         EM converged at iteration# ' num2str(cnt-1) ' b/c change in params was within criteria']);
%                     negLL=0;
%                 end
%             
%                 if(abs(dLikelihood(cnt))<llTol  || dLikelihood(cnt)<0)
%                     stoppingCriteria=1;
%                     display(['         EM stopped at iteration# ' num2str(cnt-1) ' b/c change in likelihood was negative']);
%                     negLL=1;
%                 end
%                 
% 
%             end
%             
%             
% 
% 
%             maxLLIndex  = find(logll == max(logll),1,'first');
%             maxLLIndMod =  mod(maxLLIndex-1,numToKeep)+1;
%             if(maxLLIndex==1)
% %                 maxLLIndex=cnt-1;
%                 maxLLIndex =1;
%                 maxLLIndMod = 1;
%             elseif(isempty(maxLLIndex))
%                maxLLIndex = 1; 
%                maxLLIndMod = 1;
% %             else
% %                maxLLIndMod = mod(maxLLIndex,numToKeep); 
%                
%             end
%             nIter   = cnt-1;  
% %             maxLLIndMod
%            
%             xKFinal = x_K{maxLLIndMod};
%             WKFinal = W_K{maxLLIndMod};
%             Ahat = Ahat{maxLLIndMod};
%             Qhat = Qhat{maxLLIndMod};
%             muhat= muhat{maxLLIndMod};
%             betahat = betahat{maxLLIndMod};
%             gammahat = gammahat{maxLLIndMod};
%             x0hat =x0hat{maxLLIndMod};
%             Px0hat=Px0hat{maxLLIndMod};
%             
%              if(scaledSystem==1)
%                Tq = eye(size(Qhat))/(chol(Q0));
%                Ahat=Tq\Ahat*Tq;
%                Qhat=(Tq\Qhat)/Tq';
%                xKFinal = Tq\xKFinal;
%                x0hat = Tq\x0hat;
%                Px0hat= (Tq\Px0hat)/(Tq');
%                tempWK =zeros(size(WKFinal));
%                for kk=1:size(WKFinal,3)
%                 tempWK(:,:,kk)=(Tq\WKFinal(:,:,kk))/Tq';
%                end
%                WKFinal = tempWK;
%                betahat=(betahat'*Tq)';
%              end
%             
%             logll = logll(maxLLIndex);
%             ExpectationSumsFinal = ExpectationSums{maxLLIndMod};
%             K=size(dN,1);
%             SumXkTermsFinal = diag(Qhat(:,:,end))*K;
%             logllFinal=logll(end);
%             McInfo=100;
%             McCI = 3000;
% 
% %             nIter = [];%[nIter1,nIter2,nIter3];
%   
%             
%             K  = size(dN,1); 
%             Dx = size(Ahat,2);
%             sumXkTerms = ExpectationSums{maxLLIndMod}.sumXkTerms;
%             logllobs = logll + Dx*K/2*log(2*pi)+K/2*log(det(Qhat))+ 1/2*trace(pinv(Qhat)*sumXkTerms); 
%                   
% %             InfoMat = DecodingAlgorithms.estimateInfoMat_PPLFP(fitType,xKFinal, WKFinal,Ahat,Qhat,Chat, Rhat,alphahat, muhat, betahat,gammahat,dN,windowTimes, HkAll,delta,ExpectationSums{maxLLIndMod},McInfo);
% %             
% %             
% %             fitResults = DecodingAlgorithms.prepareEMResults(fitType,neuronName,dN,HkAll,xKFinal,WKFinal,Qhat,gammahat,windowTimes,delta,InfoMat,logllobs);
% %             [stimCIs, stimulus] = DecodingAlgorithms.ComputeStimulusCIs(fitType,xKFinal,WkuFinal,delta,McCI);
% %             
%            
%         end
        function [x_K,W_K,logll,ExpectationSums]=PP_EStep(A,Q,dN, mu, beta,fitType,gamma,HkAll, x0, Px0)
            DEBUG = 0;
            [numCells,K]   = size(dN); 
            Dx = size(A,2);
            
            x_p     = zeros( size(A,2), K+1 );
            x_u     = zeros( size(A,2), K );
            W_p    = zeros( size(A,2),size(A,2), K+1 );
            W_u    = zeros( size(A,2),size(A,2), K );
            x_p(:,1)= A(:,:)*x0;
            W_p(:,:,1)=A*Px0*A' + Q;
            HkPerm=permute(HkAll, [2 3 1]);
            for k=1:K
                [x_u(:,k), W_u(:,:,k)] = DecodingAlgorithms.PPDecode_updateLinear(x_p(:,k), W_p(:,:,k), dN,mu,beta,fitType,gamma,HkPerm,k,[]);
                [x_p(:,k+1), W_p(:,:,k+1)] = DecodingAlgorithms.PPDecode_predict(x_u(:,k), W_u(:,:,k), A(:,:,min(size(A,3),k)), Q(:,:,min(size(Q,3),k))); % FIX: added k index for time-varying Q support
            end
            
            [x_K, W_K,Lk] = DecodingAlgorithms.kalman_smootherFromFiltered(A, x_p, W_p, x_u, W_u); 
             
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
            Sxkm1xkm1 = zeros(Dx,Dx);
            Sxkxk = zeros(Dx,Dx);
            for k=1:K
                if(k==1)
                    Sxkm1xk   = Sxkm1xk+Px0*A'/W_p(:,:,1)*Wku(:,:,1,1);
                    Sxkm1xkm1 = Sxkm1xkm1+Px0+x0*x0';     
                else
                      Sxkm1xk =  Sxkm1xk+Wku(:,:,k-1,k)+x_K(:,k-1)*x_K(:,k)';
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
%                    Hk=squeeze(HkAll(k,:,:)); 
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
%                     Hk=squeeze(HkAll(k,:,:)); 
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

            logll = -Dx*K/2*log(2*pi)-K/2*log(det(Q)) ...
                    - Dx/2*log(2*pi) -1/2*log(det(Px0))  ...
                    +sumPPll - 1/2*trace((eye(size(Q))/Q)*sumXkTerms) ...
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
        %         function [x_K,W_K,logll,ExpectationSums]=PP_EStep(A,Q,dN, mu, beta,fitType,gamma,HkAll, x0, Px0)
%              
%             DEBUG = 0;
%             [numCells,K]   = size(dN); 
%             Dx = size(A,2);
%             
%             x_p     = zeros( size(A,2), K+1 );
%             x_u     = zeros( size(A,2), K );
%             W_p    = zeros( size(A,2),size(A,2), K+1 );
%             W_u    = zeros( size(A,2),size(A,2), K );
%             x_p(:,1)= A(:,:)*x0;
%             W_p(:,:,1)=A*Px0*A' + Q;
% %             WuConv=[];
%             for k=1:K
%                 [x_u(:,k), W_u(:,:,k)] = DecodingAlgorithms.PPDecode_updateLinear(x_p(:,k), W_p(:,:,k), dN,mu,beta,fitType,gamma,HkAll,k,[]);
%                 [x_p(:,k+1), W_p(:,:,k+1)] = DecodingAlgorithms.PPDecode_predict(x_u(:,k), W_u(:,:,k), A(:,:,min(size(A,3),k)), Q(:,:,min(size(Q,3))));
% %                 if(k>1 && isempty(WuConv))
% %                     diffWu = abs(W_u(:,:,k)-W_u(:,:,k-1));
% %                     maxWu  = max(max(diffWu));
% %                     if(maxWu<5e-2)
% %                         WuConv = W_u(:,:,k);
% %                         WuConvIter = k;
% %                     end
% %                 end
%             end
%      
%             
%             [x_K, W_K,Lk] = DecodingAlgorithms.kalman_smootherFromFiltered(A, x_p, W_p, x_u, W_u);
%             
%             %Best estimates of initial states given the data
%             W1G0 = A*Px0*A' + Q;
%             L0=Px0*A'/W1G0;
%             
%             Ex0Gy = x0+L0*(x_K(:,1)-x_p(:,1));        
%             Px0Gy = Px0+L0*(eye(size(W_K(:,:,1)))/(W_K(:,:,1))-eye(size(W1G0))/W1G0)*L0';
%             Px0Gy = (Px0Gy+Px0Gy')/2;
%             numStates = size(x_K,1);
%             Wku=zeros(numStates,numStates,K,K);
%             Tk = zeros(numStates,numStates,K-1);
%             for k=1:K
%                 Wku(:,:,k,k)=W_K(:,:,k);
%             end
% 
%             for u=K:-1:2
%                 for k=(u-1):-1:(u-1)
%                     Tk(:,:,k)=A;
% %                     Dk(:,:,k)=W_u(:,:,k)*Tk(:,:,k)'*pinv(W_p(:,:,k)); %From deJong and MacKinnon 1988
%                      Dk(:,:,k)=W_u(:,:,k)*Tk(:,:,k)'/(W_p(:,:,k+1)); %From deJong and MacKinnon 1988
%                     Wku(:,:,k,u)=Dk(:,:,k)*Wku(:,:,k+1,u);
%                     Wku(:,:,u,k)=Wku(:,:,k,u)';
%                 end
%             end
%             
%             %All terms
%             Sxkm1xk = zeros(Dx,Dx);
%             Sxkxkm1 = zeros(Dx,Dx);
%             Sxkm1xkm1 = zeros(Dx,Dx);
%             Sxkxk = zeros(Dx,Dx);
%          
%             for k=1:K
%                 if(k==1)
%                     Sxkm1xk   = Sxkm1xk+Px0*A'/W_p(:,:,1)*Wku(:,:,1,1);
%                     Sxkm1xkm1 = Sxkm1xkm1+Px0+x0*x0';     
%                 else
% %                   
%                       Sxkm1xk =  Sxkm1xk+Wku(:,:,k-1,k)+x_K(:,k-1)*x_K(:,k)';
%                        
%                       Sxkm1xkm1= Sxkm1xkm1+Wku(:,:,k-1,k-1)+x_K(:,k-1)*x_K(:,k-1)';
%                 end
%                 Sxkxk = Sxkxk+Wku(:,:,k,k)+x_K(:,k)*x_K(:,k)';
%                 
%             end
%             Sx0x0 = Px0+x0*x0';
%             Sxkxk = 0.5*(Sxkxk+Sxkxk');
%             sumXkTerms = Sxkxk-A*Sxkm1xk-Sxkm1xk'*A'+A*Sxkm1xkm1*A';
%             Sxkxkm1 = Sxkm1xk';
%             
% %             if(strcmp(fitType,'poisson'))
% %                 sumPPll=0;
% %                 for c=1:numCells
% % %                     Hk=HkAll{c};
% %                     Hk=squeeze(HkAll(k,:,c));
% %                     for k=1:K
% %                         xk = x_K(:,k);
% %                         if(numel(gamma)==1)
% %                             gammaC=gamma;
% %                         else 
% %                             gammaC=gamma(:,c);
% %                         end
% % %                         terms=mu(c)+beta(:,c)'*xk+gammaC'*Hk(k,:)';
% %                         if(numel(Hk)~=1)
% %                             terms=mu(c)+beta(:,c)'*xk+gammaC'*Hk(k,:)';
% %                         else
% %                             terms=mu(c)+beta(:,c)'*xk+gammaC'*Hk';
% %                         end
% %                         Wk = W_K(:,:,k);
% %                         ld = exp(terms);
% %                         bt = beta(:,c);
% %                         ExplambdaDelta =ld+0.5*trace(bt*bt'*ld*Wk);
% %                         ExplogLD = terms;
% %                         sumPPll=sumPPll+dN(c,k).*ExplogLD - ExplambdaDelta;
% %                     end
% %                   
% %                             
% %                 end
% %             elseif(strcmp(fitType,'binomial'))
% %                 sumPPll=0;
% %                 for c=1:C
% %                     for k=1:K
% %                         Hk=squeeze(HkAll(k,:,c));
% %                         xk = x_K(:,k);
% %                         if(numel(gamma)==1)
% %                             gammaC=gamma;
% %                         else 
% %                             gammaC=gamma(:,c);
% %                         end
% %                         if(numel(Hk)~=1)
% %                             terms=mu(c)+beta(:,c)'*xk+gammaC'*Hk(k,:)';
% %                         else
% %                             terms=mu(c)+beta(:,c)'*xk+gammaC'*Hk';
% %                         end
% %                         Wk = W_K(:,:,k);
% %                         ld = exp(terms)./(1+exp(terms));
% %                         bt = beta;
% %                         ExplambdaDelta =sum(ld+0.5*sum(bt'*bt*repmat(ld.*(1-ld).*(1-2.*ld),1,2)*Wk,2));
% %                         ExplogLD = (log(ld)+0.5*sum(bt*bt'*(repmat(ld.*(1-ld),1,size(bt,1))*Wk)')');
% %                         sumPPll=sumPPll+dN(:,k)'*ExplogLD - ExplambdaDelta;
% %                     end
% %                 end
% %                 
% % %                 for c=1:numCells
% % %                     Hk=HkAll{c};
% % %                     for k=1:K
% % %                         xk = x_K(:,k);
% % %                         if(numel(gamma)==1)
% % %                             gammaC=gamma;
% % %                         else 
% % %                             gammaC=gamma(:,c);
% % %                         end
% % %                         if(numel(Hk)~=1)
% % %                             terms=mu(c)+beta(:,c)'*xk+gammaC'*Hk(k,:)';
% % %                         else
% % %                             terms=mu(c)+beta(:,c)'*xk+gammaC'*Hk';
% % %                         end
% % %                         Wk = W_K(:,:,k);
% % %                         ld = exp(terms)./(1+exp(terms));
% % %                         bt = beta(:,c);
% % %                         ExplambdaDelta =ld+0.5*trace(bt*bt'*ld*(1-ld)*(1-2*ld)*Wk);
% % %                         ExplogLD = log(ld)+0.5*trace(-(bt*bt'*ld*(1-ld))*Wk);
% % %                         sumPPll=sumPPll+dN(c,k).*ExplogLD - ExplambdaDelta;
% % %                     end
% % %                   
% % %                             
% % %                 end
% %             end
% 
%             %Vectorize for loop over cells
%             if(strcmp(fitType,'poisson'))
%                 sumPPll=0;
%                 for k=1:K
%                    Hk=squeeze(HkAll(k,:,:)); 
%                    if(size(Hk,1)==numCells)
%                     Hk = Hk';
%                    end
%                    xk = x_K(:,k);
%                    if(numel(gamma)==1)
%                         gammaC=repmat(gamma,1,numCells);
%                    else 
%                         gammaC=gamma;
%                    end
% %                    if(size(gammaC,1)~=size(mu,1))
% %                         gammaC = gammaC';
% %                     end
% %                     if(size(Hk,1)~=size(mu,1))
% %                         Hk=Hk';
% %                     end
%                    terms=mu+beta'*xk+diag(gammaC'*Hk);
%                    Wk = W_K(:,:,k);
%                    ld = exp(terms);
%                    bt = beta;
%                    ExplambdaDelta =ld+0.5*(ld.*diag((bt'*Wk*bt)));
%                    ExplogLD = terms;
%                    sumPPll=sumPPll+sum(dN(:,k).*ExplogLD - ExplambdaDelta);
%                         
%                 end
%                 
%             %Vectorize over number of cells
%             elseif(strcmp(fitType,'binomial'))
%                 sumPPll=0;
%                 for k=1:K
%                     Hk=squeeze(HkAll(k,:,:));
%                     if(size(Hk,1)==numCells)
%                        Hk = Hk';
%                     end
%                     xk = x_K(:,k);
%                     if(numel(gamma)==1)
%                         gammaC=repmat(gamma,1,numCells);
%                     else 
%                         gammaC=gamma;
%                     end
% %                     if(size(gammaC,1)~=size(mu,1))
% %                         gammaC = gammaC';
% %                     end
% %                     if(size(Hk,1)~=size(mu,1))
% %                         Hk=Hk';
% %                     end
%                    terms=mu+beta'*xk+diag(gammaC'*Hk);
%                    Wk = W_K(:,:,k);
%                    ld = exp(terms)./(1+exp(terms));
%                    bt = beta;     
%                    ExplambdaDelta = ld+0.5*(ld.*(1-ld).*(1-2.*ld)).*diag((bt'*Wk*bt));
%                    ExplogLD = log(ld)+0.5*(-ld.*(1-ld)).*diag(bt'*Wk*bt);
%                    sumPPll=sumPPll+sum(dN(:,k).*ExplogLD - ExplambdaDelta); 
%                     
%                 end
% 
%                 
%             end
% 
%             logll = -Dx*K/2*log(2*pi)-K/2*log(det(Q)) ...
%                     - Dx/2*log(2*pi) -1/2*log(det(Px0))  ...
%                     +sumPPll - 1/2*trace((eye(size(Q))/Q)*sumXkTerms) ...
%                     -Dx/2;
%                 string0 = ['logll: ' num2str(logll)];
%                 disp(string0);
%                 if(DEBUG==1)
%                     string1 = ['-K/2*log(det(Q)):' num2str(-K/2*log(det(Q)))];
%                     string12= ['Constants: ' num2str(-Dx*K/2*log(2*pi)-Dx/2*log(2*pi) -Dx/2 -1/2*log(det(Px0)))];
%                     string2 = ['SumPPll: ' num2str(sumPPll)];
%                     string3 = ['-.5*trace(Q\sumXkTerms): ' num2str(-.5*trace(Q\sumXkTerms))];
%                     
%                     disp(string1);
%                     disp(['Q=' num2str(diag(Q)')]);
%                     disp(string12);
%                     disp(string2);
%                     disp(string3);
%                  
%                 end
% 
%                 ExpectationSums.Sxkm1xkm1=Sxkm1xkm1;
%                 ExpectationSums.Sxkm1xk=Sxkm1xk;
%                 ExpectationSums.Sxkxkm1=Sxkxkm1;
%                 ExpectationSums.Sxkxk=Sxkxk;
%                 ExpectationSums.sumXkTerms=sumXkTerms;
%                 ExpectationSums.sumPPll=sumPPll;
%                 ExpectationSums.Sx0 = Ex0Gy;
%                 ExpectationSums.Sx0x0 = Px0Gy + Ex0Gy*Ex0Gy';
%                 ExpectationSums.A = A;
%                 ExpectationSums.Q = Q;
%                 ExpectationSums.mu = mu;
%                 ExpectationSums.beta = beta;
%                 ExpectationSums.gamma = gamma;
% 
%         end
        function [Ahat, Qhat, muhat_new, betahat_new, gammahat_new, x0hat, Px0hat] = PP_MStep(dN, x_K,W_K,x0, Px0, ExpectationSums,fitType, muhat, betahat,gammahat, windowTimes, HkAll,PPEM_Constraints,MstepMethod)
            if(nargin<14 || isempty(MstepMethod))
                MstepMethod = 'GLM'; %GLM or NewtonRaphson
            end
            if(nargin<13 || isempty(PPEM_Constraints))
                PPEM_Constraints = DecodingAlgorithms.PP_EMCreateConstraints;
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
                pool = matlabpool('size');
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
%                                     xk = squeeze(xKDrawExp(:,k,:));
                                    xk = xkPerm(:,:,k);
                                   if(size(Hk,1)==numCells)
                                       Hk = Hk';
                                   end

                                    if(numel(gammahat)==1)
                                        gammaC=gammahat;
                                    %                             gammaC=repmat(gammaC,[1 numCells]);
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
%                                     xk = squeeze(xKDrawExp(:,k,:));
                                    xk = xkPerm(:,:,k);
                                   if(size(Hk,1)==numCells)
                                       Hk = Hk';
                                   end

                                    if(numel(gammahat)==1)
                                        gammaC=gammahat;
                                    %                             gammaC=repmat(gammaC,[1 numCells]);
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
%                                     xk = squeeze(xKDrawExp(:,k,:));
                                    xk = xkPerm(:,:,k);
                                   if(size(Hk,1)==numCells)
                                       Hk = Hk';
                                   end

                                    if(numel(gammahat)==1)
                                        gammaC=gammahat;
                                    %                             gammaC=repmat(gammaC,[1 numCells]);
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
%                                     xk = squeeze(xKDrawExp(:,k,:));
                                    xk=xKDrawExp(:,:,k);
                                   if(size(Hk,1)==numCells)
                                       Hk = Hk';
                                   end

                                    if(numel(gammahat)==1)
                                        gammaC=gammahat;
                                    %                             gammaC=repmat(gammaC,[1 numCells]);
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
    %                     fprintf(['neuron:' num2str(c) ' iter: ']);
                        while(~converged && iter<maxIter)
    %                         if(iter==1)
    %                             fprintf('%d',iter);
    %                         else
    %                             fprintf(',%d',iter);
    %                         end
                            if(strcmp(fitType,'poisson'))
                                HessianTerm = zeros(size(1,1),size(1,1));
                                GradTerm = zeros(size(1,1),1);
                                xkPerm = permute(xKDrawExp, [1 3 2]);
                                for k=1:K
                                    Hk = (HkAll(:,:,c));
                                    Wk = W_K(:,:,k);
%                                     xk = squeeze(xKDrawExp(:,k,:));
                                    xk = xkPerm(:,:,k);
                                   if(size(Hk,1)==numCells)
                                       Hk = Hk';
                                   end

                                    if(numel(gammahat)==1)
                                        gammaC=gammahat;
                                    %                             gammaC=repmat(gammaC,[1 numCells]);
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
%                                     xk = squeeze(xKDrawExp(:,k,:));
                                    xk = xkPerm(:,:,k);
                                   if(size(Hk,1)==numCells)
                                       Hk = Hk';
                                   end

                                    if(numel(gammahat)==1)
                                        gammaC=gammahat;
                                    %                             gammaC=repmat(gammaC,[1 numCells]);
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
    %                     fprintf('\n');              
                     end 
                 else
                    HessianTerm = zeros(1,numCells);
                    GradTerm = zeros(1,numCells);
                    for c=1:numCells
                        converged=0;
                        iter = 1;
                        maxIter=100;
    %                     fprintf(['neuron:' num2str(c) ' iter: ']);
                        while(~converged && iter<maxIter)
    %                         if(iter==1)
    %                             fprintf('%d',iter);
    %                         else
    %                             fprintf(',%d',iter);
    %                         end
                            if(strcmp(fitType,'poisson'))
                                xkPerm = permute(xKDrawExp, [1 3 2]);
                                for k=1:K
                                    Hk = (HkAll(:,:,c));
                                    Wk = W_K(:,:,k);
%                                     xk = squeeze(xKDrawExp(:,k,:));
                                    xk = xkPerm(:,:,k);
                                   if(size(Hk,1)==numCells)
                                       Hk = Hk';
                                   end

                                    if(numel(gammahat)==1)
                                        gammaC=gammahat;
                                    %                             gammaC=repmat(gammaC,[1 numCells]);
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
%                                     xk = squeeze(xKDrawExp(:,k,:));
                                    xk = xkPerm(:,:,k);
                                   if(size(Hk,1)==numCells)
                                       Hk = Hk';
                                   end

                                    if(numel(gammahat)==1)
                                        gammaC=gammahat;
                                    %                             gammaC=repmat(gammaC,[1 numCells]);
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
    %                     fprintf('\n');              
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
        %                     fprintf(['neuron:' num2str(c) ' iter: ']);
                            while(~converged && iter<maxIter)
        %                         if(iter==1)
        %                             fprintf('%d',iter);
        %                         else
        %                             fprintf(',%d',iter);
        %                         end
                                if(strcmp(fitType,'poisson'))
                                    HessianTerm = zeros(size(gammahat,1),size(gammahat,1));
                                    GradTerm = zeros(size(gammahat,1),1);
                                    xkPerm = permute(xKDrawExp, [1 3 2]);
                                    for k=1:K
                                        Hk = (HkAll(:,:,c));
                                        Wk = W_K(:,:,k);
%                                         xk = squeeze(xKDrawExp(:,k,:));
                                        xk = xkPerm(:,:,k);
                                       if(size(Hk,1)==numCells)
                                           Hk = Hk';
                                       end

                                        if(numel(gammahat_new)==1)
                                            gammaC=gammahat_new;
                                        %                             gammaC=repmat(gammaC,[1 numCells]);
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
%                                         xk = squeeze(xKDrawExp(:,k,:));
                                        xk=xkPerm(:,:,k);
                                       if(size(Hk,1)==numCells)
                                           Hk = Hk';
                                       end

                                        if(numel(gammahat_new)==1)
                                            gammaC=gammahat_new;
                                        %                             gammaC=repmat(gammaC,[1 numCells]);
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
        %                     fprintf('\n');              
                         end 
                     else
                         HessianTerm = zeros(size(gammahat,1),size(gammahat,1),numCells);
                         GradTerm = zeros(size(gammahat,1),numCells);
                         for c=1:numCells
                            converged=0;
                            iter = 1;
                            maxIter=100;
        %                     fprintf(['neuron:' num2str(c) ' iter: ']);
                            if(numel(gammahat_new)==1)
                                gammaC=gammahat_new;
                                        %                             gammaC=repmat(gammaC,[1 numCells]);
                            else 
                                gammaC=gammahat_new(:,c);
                            end
                            while(~converged && iter<maxIter)
        %                         if(iter==1)
        %                             fprintf('%d',iter);
        %                         else
        %                             fprintf(',%d',iter);
        %                         end
                                xkPerm = permute(xKDrawExp, [1 3 2]);
                                if(strcmp(fitType,'poisson'))
                                    for k=1:K
                                        Hk = (HkAll(:,:,c));
                                        Wk = W_K(:,:,k);
%                                         xk = squeeze(xKDrawExp(:,k,:));
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
%                                         xk = squeeze(xKDrawExp(:,k,:));
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
        %                     fprintf('\n');              
                         end 
                     end
                 end
                 clear HessianTerm GradTerm; 
            end
        end

%         function [Ahat, Qhat, muhat_new, betahat_new, gammahat_new, x0hat, Px0hat] = PP_MStep(dN,x_K,W_K,x0, ExpectationSums,fitType, muhat, betahat,gammahat, windowTimes, HkAll,MstepMethod)
%             if(nargin<12 || isempty(MstepMethod))
%                 MstepMethod = 'GLM'; %GLM or NewtonRaphson
%             end
%             Sxkm1xkm1=ExpectationSums.Sxkm1xkm1;
%             Sxkxkm1=ExpectationSums.Sxkxkm1;
%             Sxkxk=ExpectationSums.Sxkxk;
%             sumXkTerms = ExpectationSums.sumXkTerms;
%             Sx0 = ExpectationSums.Sx0;
%             Sx0x0 = ExpectationSums.Sx0x0;
%             K = size(x_K,2);   
%             numCells=size(dN,1);
%             numStates = size(x_K,1);
%             Ahat = Sxkxkm1/Sxkm1xkm1;
%         
%             Px0hat =(Sx0x0 - x0*Sx0' - Sx0*x0' +(x0*x0'));
%              
% %              [V,D] = eig(Px0hat);
% %              D(D<0)=1e-9;
% %              Px0hat = V*D*V';
%             Px0hat = (Px0hat+Px0hat')/2;
% %              Px0hat = diag(diag(Px0hat));
%             x0hat  = Sx0;
%         
%             Qhat=1/K*sumXkTerms;
% %             [V,D] = eig(Qhat);
% %             D(D<=0)=1e-9;
% %             Qhat = V*D*V';
%             Qhat = (Qhat + Qhat')/2;
%             if(det(Qhat)<=0)
%                 Qhat = ExpectationSums.Q; % Keep prior value
%             end
%             
%                
%              
%             betahat_new =betahat;
%             gammahat_new = gammahat;
%             muhat_new = muhat;
%              
%             %Compute the new CIF beta using the GLM
%             if(strcmp(fitType,'poisson'))
%                 algorithm = 'GLM';
%             else
%                 algorithm = 'BNLRCG';
%             end
%             
%             % Estimate params via GLM
%             if(strcmp(MstepMethod,'GLM'))
%                 clear c; close all;
%                 time=(0:length(x_K)-1)*.001;
%                 labels = cell(1,numStates);
%                 labels2 = cell(1,numStates+1);
%                 labels2{1} = 'vel';
%                 for i=1:numStates
%                     labels{i} = strcat('v',num2str(i));
%                     labels2{i+1} = strcat('v',num2str(i));
%                 end
%                 vel = Covariate(time,x_K','vel','time','s','m/s',labels);
%                 baseline = Covariate(time,ones(length(time),1),'Baseline','time','s','',...
%                     {'constant'});
%                 for i=1:size(dN,1)
%                     spikeTimes = time(dN(i,:)==1);
%                     nst{i} = nspikeTrain(spikeTimes);
%                 end
%                 nspikeColl = nstColl(nst);
%                 cc = CovColl({vel,baseline});
%                 trial = Trial(nspikeColl,cc);
%                 selfHist = windowTimes ; NeighborHist = []; sampleRate = 1000; 
%                 clear c;
%                 
%                 
% 
%                 if(gammahat==0)
%                     c{1} = TrialConfig({{'Baseline','constant'},labels2},sampleRate,[],NeighborHist); 
%                 else
%                     c{1} = TrialConfig({{'Baseline','constant'},labels2},sampleRate,selfHist,NeighborHist); 
%                 end
%                 c{1}.setName('Baseline');
%                 cfgColl= ConfigColl(c);
%                 warning('OFF');
% 
%                 results = Analysis.RunAnalysisForAllNeurons(trial,cfgColl,0,algorithm);
%                 temp = FitResSummary(results);
%                 tempCoeffs = squeeze(temp.getCoeffs);
%                 if(gammahat==0)
%                     betahat(1:numStates,:) = tempCoeffs(2:(numStates+1),:);
%                     muhat = tempCoeffs(1,:)';
%                 else
%                     betahat(1:numStates,:) = tempCoeffs(2:(numStates+1),:);
%                     muhat = tempCoeffs(1,:)';
%                     histTemp = squeeze(temp.getHistCoeffs);
%                     histTemp = reshape(histTemp, [length(windowTimes)-1 numCells]);
%                     histTemp(isnan(histTemp))=0;
%                     gammahat=histTemp;
%                     if(size(gammahat,2)~=size(muhat,1))
%                         gammahat = gammahat';
%                     end
%                 end
%             else
%                 
%             % Estimate via Newton-Raphson
%                  fprintf(['****M-step for beta**** \n']);
%                  for c=1:numCells
%     %                  c
% 
% 
%                      converged=0;
%                      iter = 1;
%                      maxIter=100;
%     %                  disp(['M-step for beta, neuron:' num2str(c) ' iter: ' num2str(c) ' of ' num2str(maxIter)]); 
%                      fprintf(['neuron:' num2str(c) ' iter: ']);
%                      while(~converged && iter<maxIter)
% 
%                         if(iter==1)
%                             fprintf('%d',iter);
%                         else
%                             fprintf(',%d',iter);
%                         end
%                         if(strcmp(fitType,'poisson'))
%                             gradQ=zeros(size(betahat_new(:,c),1),1);
%                             jacQ =zeros(size(betahat_new(:,c),1),size(betahat_new(:,c),1));
%                             for k=1:K
% %                                 Hk=HkAll{c};
%                                 Hk = squeeze(HkAll(:,:,c));
%                                 Wk = W_K(:,:,k);
%                                 xk = x_K(:,k);
%                                 if(numel(gammahat)==1)
%                                     gammaC=gammahat;
%                                 else 
%                                     gammaC=gammahat(:,c);
%                                 end
%                                 terms =muhat(c)+betahat_new(:,c)'*xk+gammaC'*Hk(k,:)';
%                                 ld=exp(terms);
% 
%                                 numStates =length(xk);
%                                 ExplambdaDeltaXk = zeros(numStates,1);
%                                 ExplambdaDeltaXkXkT = zeros(numStates,numStates);
%                                 for m=1:numStates
%                                      sm = zeros(numStates,1);
%                                      sm(m) =1;
%                                      bt=betahat_new(:,c);
%                                      ExplambdaDeltaXk(m) = ld*sm'*xk+...
%                                          .5*trace(ld*(bt*xk'*sm*bt'+sm*bt'+bt*sm')*Wk);
%                                     for n=1:m
%                                         sn = zeros(numStates,1);
%                                         sn(n) =1; 
%                                         ExplambdaDeltaXkXkT(n,m) = ld*xk'*sm*sn'*xk+...
%                                             +trace(ld*(2*bt*xk'*sn*sm'*xk*bt'+bt*xk'*sn*sm'+sn*sm'*xk*bt'+sn*sm')*Wk);
%                                         if(n~=m)
%                                             ExplambdaDeltaXkXkT(n,m)=ExplambdaDeltaXkXkT(m,n);
%                                         end
%                                     end
%                                 end
% 
%                                 gradQ = gradQ + (dN(c,k)*xk - ExplambdaDeltaXk);
%                                 jacQ  = jacQ  - ExplambdaDeltaXkXkT;
%                             end
% 
% 
%                         elseif(strcmp(fitType,'binomial'))
%                             gradQ=zeros(size(betahat_new(:,c),1),1);
%                             jacQ =zeros(size(betahat_new(:,c),1),size(betahat_new(:,c),1));
%                             for k=1:K
% %                                 Hk=HkAll{c};
%                                 Hk = squeeze(HkAll(:,:,c));
%                                 Wk = W_K(:,:,k);
%                                 xk = x_K(:,k);                    
%                                 if(numel(gammahat)==1)
%                                     gammaC=gammahat;
%                                 else 
%                                     gammaC=gammahat(:,c);
%                                 end
%                                 terms =muhat(c)+betahat_new(:,c)'*xk+gammaC'*Hk(k,:)';
%                                 ld=exp(terms)./(1+exp(terms));
% 
%                                 numStates =length(xk);
%                                 ExplambdaDeltaXk = zeros(numStates,1);
%                                 ExplambdaDeltaSqXk = zeros(numStates,1);
%                                 ExplambdaDeltaXkXkT = zeros(numStates,numStates);
%                                 ExplambdaDeltaSqXkXkT = zeros(numStates,numStates);
%                                 ExplambdaDeltaCubedXkXkT = zeros(numStates,numStates);
%                                 for m=1:numStates
%                                      sm = zeros(numStates,1);
%                                      sm(m) =1;
%                                      bt=betahat_new(:,c);
%                                      ExplambdaDeltaXk(m) = ld*sm'*xk+...
%                                          +.5*trace(ld*(bt*xk'*sm*bt'+sm*bt'+bt*sm')*Wk)...
%                                          -.5*trace((ld^2)*(3*bt*xk'*sm*bt'+sm*bt'+bt*sm')*Wk)...
%                                          +.5*trace((ld^3)*(2*bt*xk'*sm*bt')*Wk);
%                                      ExplambdaDeltaSqXk(m) = (ld)^2*sm'*xk+...
%                                          +trace((ld^2)*(2*bt*xk'*sm*bt'+sm*bt'+bt*sm')*Wk)...
%                                          -trace((ld^3)*(2*bt*xk'*sm*bt'+3*bt*xk'*sm*bt'+sm*bt'+bt*sm')*Wk)...
%                                          +trace(3*(ld^4)*(bt*xk'*sm*bt')*Wk);
% 
%                                     for n=1:m
%                                         sn = zeros(numStates,1);
%                                         sn(n) =1; 
%                                         ExplambdaDeltaXkXkT(n,m) = ld*xk'*sm*sn'*xk+...
%                                             +0.5*trace((ld)*(bt*xk'*sn*sm'*xk*bt'+2*sn*sm'*xk*bt'+2*bt*xk'*sn*sm'+2*sn*sm')*Wk)...
%                                             -0.5*trace((ld)^2*(3*bt*xk'*sn*sm'*xk*bt'+2*sn*sm'*xk*bt'+2*bt*xk'*sn*sm')*Wk)...
%                                             +0.5*trace((ld)^3*(2*bt*xk'*sn*sm'*xk*bt')*Wk);
%                                         ExplambdaDeltaSqXkXkT(n,m) = (ld)^2*xk'*sm*sn'*xk+...
%                                             +trace((ld)^2*(2*bt*xk'*sn*sm'*xk*bt'+2*sn*sm'*xk*bt'+2*bt*xk'*sn*sm'+sn*sm')*Wk)...
%                                             -trace((ld)^3*(5*bt*xk'*sn*sm'*xk*bt'+2*sn*sm'*xk*bt'+2*bt*xk'*sn*sm')*Wk)...
%                                             +trace((ld)^4*(3*bt*xk'*sn*sm'*xk*bt')*Wk);
% 
%                                         ExplambdaDeltaCubedXkXkT(n,m) = (ld)^3*xk'*sm*sn'*xk+...
%                                             +0.5*trace((ld)^3*(9*bt*xk'*sn*sm'*xk*bt'+6*sn*sm'*xk*bt'+6*bt*xk'*sn*sm'+2*sn*sm')*Wk)...
%                                             -0.5*trace((ld)^4*(21*bt*xk'*sn*sm'*xk*bt'+6*sn*sm'*xk*bt'+6*bt*xk'*sn*sm')*Wk)...
%                                             +0.5*trace((ld)^5*(12*bt*xk'*sn*sm'*xk*bt')*Wk);
% 
%                                         if(n~=m)
%                                             ExplambdaDeltaXkXkT(n,m)=ExplambdaDeltaXkXkT(m,n);
%                                             ExplambdaDeltaSqXkXkT(n,m)=ExplambdaDeltaSqXkXkT(m,n);
%                                             ExplambdaDeltaCubedXkXkT(n,m)=ExplambdaDeltaCubedXkXkT(m,n);
%                                         end
%                                     end
%                                 end
% 
%                                 gradQ = gradQ + dN(c,k)*x_K(:,k) - (dN(c,k)+1)*ExplambdaDeltaXk+ExplambdaDeltaSqXk;
%                                 jacQ  = jacQ  + ExplambdaDeltaXkXkT+ExplambdaDeltaSqXkXkT-2*ExplambdaDeltaCubedXkXkT;
%                             end
%                         end
% 
% 
%     %                    gradQ=0.01*gradQ;
% 
% 
%                         if(any(any(isnan(jacQ))) || any(any(isinf(jacQ))))
%                             betahat_newTemp = betahat_new(:,c);
%                         else
%                             betahat_newTemp = (betahat_new(:,c)-jacQ\gradQ);
%                             if(any(isnan(betahat_newTemp)))
%                                 betahat_newTemp = betahat_new(:,c);
% 
%                             end
%                         end
%                         mabsDiff = max(abs(betahat_newTemp - betahat_new(:,c)));
%                         if(mabsDiff<10^-2)
%                             converged=1;
%                         end
%                         betahat_new(:,c)=betahat_newTemp;
%                         iter=iter+1;
%                     end
%                     fprintf('\n');              
%                  end 
% 
% 
%                  %Compute the new CIF means
%                  muhat_new =muhat;
%                  for c=1:numCells
%                      converged=0;
%                      iter = 1;
%                      maxIter=100;
%                      while(~converged && iter<maxIter)
%                         if(strcmp(fitType,'poisson'))
%                             gradQ=zeros(size(muhat_new(c),2),1);
%                             jacQ =zeros(size(muhat_new(c),2),size(muhat_new(c),2));
%                             for k=1:K
% %                                 Hk=HkAll{c};
%                                 Hk = squeeze(HkAll(:,:,c));
%                                 Wk = W_K(:,:,k);
%                                 if(numel(gammahat)==1)
%                                     gammaC=gammahat;
%                                 else 
%                                     gammaC=gammahat(:,c);
%                                 end
%                                 terms=muhat_new(c)+betahat(:,c)'*x_K(:,k)+gammaC'*Hk(k,:)';
%                                 ld = exp(terms);
%                                 bt = betahat(:,c);
%                                 ExplambdaDelta =ld +0.5*trace(ld*bt*bt'*Wk);
% 
% 
%                                 gradQ = gradQ + dN(c,k)' - ExplambdaDelta;
%                                 jacQ  = jacQ  - ExplambdaDelta;
%                             end
% 
% 
%                         elseif(strcmp(fitType,'binomial'))
%                             gradQ=zeros(size(muhat_new(c),2),1);
%                             jacQ =zeros(size(muhat_new(c),2),size(muhat_new(c),2));
%                             for k=1:K
% %                                 Hk=HkAll{c};
%                                 Hk = squeeze(HkAll(:,:,c));
%                                 Wk = W_K(:,:,k);
%                                 if(numel(gammahat)==1)
%                                     gammaC=gammahat;
%                                 else 
%                                     gammaC=gammahat(:,c);
%                                 end
%                                 terms=muhat_new(c)+betahat(:,c)'*x_K(:,k)+gammaC'*Hk(k,:)';
%                                 ld = exp(terms)./(1+exp(terms));
%                                 bt = betahat(:,c);
%                                 ExplambdaDelta = ld+0.5*trace(bt*bt'*(ld)*(1-ld)*(1-2*ld)*Wk);
%                                 ExplambdaDeltaSq = (ld)^2+...
%                                     0.5*trace((ld)^2*(1-ld)*(2-3*ld)*bt*bt'*Wk);
%                                 ExplambdaDeltaCubed = (ld)^3+...
%                                     0.5*trace(3*(ld)^3*(3-7*ld+4*(ld)^2)*bt*bt'*Wk);
% 
%                                 gradQ = gradQ + dN(c,k)' -(dN(c,k)+1)*ExplambdaDelta...
%                                     +ExplambdaDeltaSq;
%                                 jacQ  = jacQ  - (dN(c,k)+1)*ExplambdaDelta...
%                                     +(dN(c,k)+3)*ExplambdaDeltaSq...
%                                     -3*ExplambdaDeltaCubed;
%                             end
% 
%                         end
%     %                     gradQ=0.01*gradQ;
%                         muhat_newTemp = (muhat_new(c)'-(1/jacQ)*gradQ)';
%                         if(any(isnan(muhat_newTemp)))
%                             muhat_newTemp = muhat_new(c);
% 
%                         end
%                         mabsDiff = max(abs(muhat_newTemp - muhat_new(c)));
%                         if(mabsDiff<10^-2)
%                             converged=1;
%                         end
%                         muhat_new(c)=muhat_newTemp;
%                         iter=iter+1;
%                      end
% 
%                 end
% 
%     %             Compute the history parameters
%                 gammahat_new = gammahat;
%                 if(~isempty(windowTimes) && any(any(gammahat_new~=0)))
%                      for c=1:numCells
%                          converged=0;
%                          iter = 1;
%                          maxIter=100;
%                          while(~converged && iter<maxIter)
%                             if(strcmp(fitType,'poisson'))
%                                 gradQ=zeros(size(gammahat_new(c),2),1);
%                                 jacQ =zeros(size(gammahat_new(c),2),size(gammahat_new(c),2));
%                                 for k=1:K
% %                                     Hk=HkAll{c};
%                                     Hk = squeeze(HkAll(:,:,c));
%                                     Wk = W_K(:,:,k);
%                                     if(numel(gammahat)==1)
%                                         gammaC=gammahat;
%                                     else 
%                                         gammaC=gammahat(:,c);
%                                     end
%                                     terms=muhat_new(c)+betahat(:,c)'*x_K(:,k)+gammaC'*Hk(k,:)';
%                                     ld = exp(terms);
%                                     bt = betahat(:,c);
%                                     ExplambdaDelta =ld +0.5*trace(bt*bt'*ld*Wk);
% 
% 
%                                     gradQ = gradQ + (dN(c,k)' - ExplambdaDelta)*Hk;
%                                     jacQ  = jacQ  - ExplambdaDelta*Hk*Hk';
%                                 end
% 
% 
%                             elseif(strcmp(fitType,'binomial'))
%                                 gradQ=zeros(size(gammahat_new(c),2),1);
%                                 jacQ =zeros(size(gammahat_new(c),2),size(gammahat_new(c),2));
%                                 for k=1:K
% %                                     Hk=HkAll{c};
%                                     Hk = squeeze(HkAll(:,:,c));
%                                     Wk = W_K(:,:,k);
%                                     if(numel(gammahat)==1)
%                                         gammaC=gammahat;
%                                     else 
%                                         gammaC=gammahat(:,c);
%                                     end
%                                     terms=muhat_new(c)+betahat(:,c)'*x_K(:,k)+gammaC'*Hk(k,:)';
%                                     ld = exp(terms)./(1+exp(terms));
%                                     bt = betahat(:,c);
%                                     ExplambdaDelta =ld...
%                                         +0.5*trace(bt*bt'*ld*(1-ld)*(1-2*ld)*Wk);
%                                     ExplambdaDeltaSq=ld^2 ...
%                                         +trace((ld^2*(1-ld)*(2-3*ld)*bt*bt')*Wk);
%                                     ExplambdaDeltaCubed=ld^3 ...
%                                         +0.5*trace((9*(ld^3)*(1-ld)^2*bt*bt'-3*(ld^4)*(1-ld)*bt*bt')*Wk);
%                                     gradQ = gradQ + (dN(c,k) - (dN(c,k)+1)*ExplambdaDelta+ExplambdaDeltaSq)*Hk;
%                                     jacQ  = jacQ  + -ExplambdaDelta*(dN(c,k)+1)*Hk*Hk'...
%                                         +ExplambdaDeltaSq*(dN(c,k)+3)*Hk*Hk'...
%                                         -ExplambdaDeltaCubed*2*Hk*Hk';
%                                 end
% 
%                             end
% 
% 
%     %                         gradQ=0.01*gradQ;
% 
%                             gammahat_newTemp = (gammahat_new(:,c)-(eye(size(Hk,2),size(Hk,2))/jacQ)*gradQ');
%                             if(any(isnan(gammahat_newTemp)))
%                                 gammahat_newTemp = gammahat_new(:,c);
% 
%                             end
%                             mabsDiff = max(abs(gammahat_newTemp - gammahat_new(:,c)));
%                             if(mabsDiff<10^-2)
%                                 converged=1;
%                             end
%                             gammahat_new(:,c)=gammahat_newTemp;
%                             iter=iter+1;
%                          end
% 
%                     end
%     %                  gammahat(:,c) = gammahat_new;
%                 end
% %              betahat =betahat_new;
% %              gammahat = gammahat_new;
% %              muhat = muhat_new;
%             end
%         end

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


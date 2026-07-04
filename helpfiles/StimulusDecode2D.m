%% 2-D Stimulus Decode
% Here we simulate hippocampal place cell receptive fields and their firing
% during a 2-d spatial task. We then use the ensemble firing activity to
% estimate the path based on the only the point process observations

delta = 0.001;
Tmax = 1;
time = 0:delta:Tmax;
px = zeros(1,length(time));
py = zeros(1,length(time));
% Drive the velocity walk hard enough that the integrated position sweeps
% most of the [-2,2] arena the place fields tile below.  The original 0.01
% produced a ~+-0.12 path that never left the flat centre of every field,
% so the ensemble carried almost no positional information and the decoded
% path barely moved.  See cajigaslab/nSTAT StimulusDecode2D decode issue.
Q=.12;
r =  Q.*randn(2,length(time));
vx = cumsum(r(1,:))';
vy = cumsum(r(2,:))';

velSig = SignalObj(time, [vx, vy],'vel');
posSig = velSig.integral;
posData = posSig.data;
px = posData(:,1);
py = posData(:,2);
% Keep the trajectory inside the tiled-field arena so every visited point is
% covered by nearby place fields.
px = max(min(px, 1.8), -1.8);
py = max(min(py, 1.8), -1.8);
% N=100; A=1; B=ones(1,N)./N;
% px = filtfilt(B,A,px);
% py = filtfilt(B,A,py);
figure;
plot(px,py);
title('Simulated X-Y trajectory');
xlabel('x'); ylabel('y');


%% Generate random receptive fields to simulate different neurons
clear lambdaCIF lambda tempSpikeColl n spikeColl
numRealizations=80;

% Tiled Gaussian place fields: centres on a 10x8 grid spanning the arena
% (plus a little jitter) give a well-posed population code, unlike the
% original coeffs = -abs(randn(...)) fields, which were broad, similarly
% oriented negative-quadratic blobs whose centres did not tile space -- so
% the ensemble could not disambiguate position even over a full-arena path.
% Each Gaussian bump exp(-||p-mu||^2/(2 sigma^2)) with peak firing p_peak is
% written in the same quadratic-logistic log-rate the CIF below consumes:
%   logit(lambdaDelta) = c0 + c1 x + c2 y + c3 x^2 + c4 y^2 + c5 xy
% with c3=c4=-1/(2 sigma^2), c5=0, c1=mu_x/sigma^2, c2=mu_y/sigma^2,
%      c0 = logit(p_peak) - (mu_x^2 + mu_y^2)/(2 sigma^2).
[cx,cy] = meshgrid(linspace(-1.6,1.6,10), linspace(-1.6,1.6,8));
centers = [cx(:) cy(:)] + 0.08*randn(numRealizations,2);
sigma = 0.6; p_peak = 0.7; s2 = sigma^2;
coeffs = zeros(numRealizations,6);
for i=1:numRealizations
    mx = centers(i,1); my = centers(i,2);
    coeffs(i,:) = [log(p_peak/(1-p_peak)) - (mx^2+my^2)/(2*s2), ...
                   mx/s2, my/s2, -1/(2*s2), -1/(2*s2), 0];
end
dataMat = [ones(length(time),1) px py px.^2 py.^2 px.*py];
 for i=1:numRealizations
     tempData  = exp(dataMat*coeffs(i,:)');
     lambdaData = tempData./(1+tempData);
     lambda{i}=Covariate(time,lambdaData./delta, '\Lambda(t)','time','s','Hz',{strcat('\lambda_{',num2str(i),'}')},{{' ''b'', ''LineWidth'' ,2'}});
     
     tempSpikeColl{i} = CIF.simulateCIFByThinningFromLambda(lambda{i},1);
     n{i} = tempSpikeColl{i}.getNST(1);
     n{i}.setName(num2str(i));
    
     try
         lambdaCIF{i} = CIF(coeffs(i,:),{'one','x','y','x^2','y^2','x*y'},{'x','y'},'binomial');
     catch ME_sym
         if(i==1)
             warning('StimulusDecode2D:SymbolicCIFFallback', ...
                 ['CIF symbolic setup failed (' ME_sym.identifier '). Decoder will use linear fallback.']);
         end
         lambdaCIF{i} = [];
     end
 end

 
 % View the different neuron conditional intensity functions
 figure;
 for i=1:length(lambda)
    lambda{i}.plot; 
 end
 legend off;

% Visualize Simulated Receptive Fields
clear placeField;
[X,Y]=meshgrid(-2:.1:2,-2:.1:2);
figure;

for i=1:numRealizations
tempData = coeffs(i,1) + coeffs(i,2)*X + coeffs(i,3)*Y +coeffs(i,4)*X.^2 + coeffs(i,5)*Y.^2 + coeffs(i,6).*X.*Y;
placeField{i} = exp(tempData)./(1+exp(tempData))./delta; %rate based on logistic link function

end

fact=factor(numRealizations);

for i=1:numRealizations
   if(length(fact)==1)
    subplot(1,numRealizations,i);
   elseif(length(fact)==2)
    subplot(fact(1),fact(2),i);
   elseif(length(fact)==3)
    subplot(fact(1)*fact(2),fact(3),i);
   end
    pcolor(X,Y,placeField{i}), shading interp 
    axis square;
    set(gca,'xtick',[],'ytick',[]);
    
end
%% Decode the x-y trajectory

 spikeColl = nstColl(n);
 spikeColl.resample(1/delta);
 dN = spikeColl.dataToMatrix; 

%%
vx=var(px(2:end)-px(1:end-1));
vy=var(py(2:end)-py(1:end-1));
Q=[vx 0;0 vy];
Px0=.1*eye(2,2); A=1*eye(2,2);
decode_method = 'PPDecodeFilter';
try
    [x_p, Pe_p, x_u, Pe_u] = nstat.decoding.PPAF.PPDecodeFilter(A, Q, Px0, dN',lambdaCIF,delta);
catch ME_decode
    warning('StimulusDecode2D:SymbolicDecodeFallback', ...
        ['PPDecodeFilter failed (' ME_decode.identifier '). Falling back to PPDecodeFilterLinear.']);
    decode_method = 'PPDecodeFilterLinear';
    mu_linear = coeffs(:,1);
    beta_linear = coeffs(:,2:3)';
    [x_p, Pe_p, x_u, Pe_u] = nstat.decoding.PPAF.PPDecodeFilterLinear(A, Q, dN', mu_linear, beta_linear, 'binomial', delta);
end
nCommon = min(length(px),size(x_u,2));
decode_rmse = sqrt(mean((x_u(1,1:nCommon)'-px(1:nCommon)).^2 + (x_u(2,1:nCommon)'-py(1:nCommon)).^2));
num_cells = numRealizations;
figure;
plot(x_u(1,:),x_u(2,:),'b',px,py,'k')
legend('predicted path','actual path');

% Parity contract scalars for MATLAB/Python verification.
parity = struct();
parity.num_cells = num_cells;
parity.decode_rmse = decode_rmse;


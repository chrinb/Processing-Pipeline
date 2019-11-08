function tauRd = getTauFromMCMC(dff, fps)
%getTauFromMCMC Get calcium transient time constants from the MCMC sampler
%
% INPUT: dff (nRois x nSamples)
%        fps int - default = 31
% OUTPUT: tauRd [tauRise, tauDecay] in milliseconds

if nargin < 2
    % get time constants in ms
    fps = 31;
end

[nRois, nSamples] = size(dff);
winSize = 2999;
tauRd = zeros(nRois, 2);

for roiNum = 1:nRois

    roidff = dff(roiNum,:);

    % Integrate roisignal which is above a noise threshold
    noiseSd = 4*GetSn(roidff);
    
    roiDffThresholded = roidff;
    roiDffThresholded(roiDffThresholded < noiseSd) = 0;
    roidffIntgr = movmax(roiDffThresholded, winSize);
    
    [~, maxInd] = max(roidffIntgr);
    if maxInd < ceil(winSize/2); maxInd = ceil(winSize/2); end
    if maxInd > floor(nSamples-winSize/2); maxInd = floor(nSamples-winSize/2); end
        
    samplesInd = maxInd + (round(-winSize/2)+1:round(winSize/2));
    roidffShort = roidff(samplesInd);
    
    mcmcparams.p = 2;
    samples = cont_ca_sampler(roidffShort, mcmcparams);
    
    mcmcTimeConst = exp2ar(mean(samples.g));
    [tauRise1, tauDecay1] = signalExtraction.CaImAn.getArConstantsInMs(mcmcTimeConst, fps);

    tauRd(roiNum, :) = [tauRise1, tauDecay1];

end





end



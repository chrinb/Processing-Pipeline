function [dff] = neurophilSubtraction(roiSignal, neurophilSignal, movingBaseLineCal)

% roiSignal = nSamples x nRois
% neurophilSignal = nSamples x nRois

if nargin < 3
    movingBaseLineCal = false;
end

if movingBaseLineCal

    
else
    dff = roiSignal-neurophilSignal;
    
end

dff(dff<0) = 0;

end
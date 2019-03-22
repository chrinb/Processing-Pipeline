function dFoverF = preprocess_deltaFoverF(signal,nCh)
% PREPROCESS_DELTAFOVERF Calculates the delta f over f for the signal used
% as input. 
%
% Input
%   signal: NxM matrix of the signal for each ROI, where N are each ROI and
%   M is each sample point for that ROI in the signal.
%   nCh: number of channels.
%
% Output
%   dFoverF: Same structure as the signal input but with a calculated delta
%   f over f based on a baseline period of the 2 first minutes in the
%   recording.
%
% Written by Andreas Lande and Eivind Hennestad

% --- If the number of channels are not specified, use 1
if nargin < 2
    nCh = 1;
end

signal = signal';
dFoverF = zeros(size(signal));
nROIs = size(signal,2);

for ch = 1:nCh
    baseline = zeros(size(signal)); 
    for roi = 1:nROIs 

        cellSignal = squeeze(signal(:, roi, :)); 
        if size(signal, 1) == 1 
            cellSignal = cellSignal';
        end
                
        sorted = sort(cellSignal);
            
        f0 = median(sorted(1:round(end*0.05)));
        baseline(:, roi, :) = f0;
    end

    dFoverF = (signal - baseline) ./ baseline; 

end


dFoverF = dFoverF';


end
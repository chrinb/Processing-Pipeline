function dFoverF_np_subtracted = preprocess_dFoverF_subtractNeuropil(ROIsignals_raw,ROIsignals_neuropil,ROI_metadata)
% PREPROCESS_DFOVERF_SUBTRACTNEUROPIL Produces as output the dFoverF for
% the input signal ROIsignals_raw with a subtraction of the surrounding
% neuropil.
%
% Input
%   ROIsignals_raw: Raw signal from each ROI in a MxN matrix, M: num ROIs, N: recording.
%   ROIsignals_neuropil: Raw signal from the neuropil surrounding each ROI,
%   ROI_metadata: A struct containing the ROI metadata as found in the
%       mousedata struct.
% 
% Output
%   dFoverF_np_subtracted: Delta F over F with neuropil subtracted.
%
% (Mostly) written by Eivind Hennestad

npMask = rmSignalExtraction.createNeuropilMask(ROI_metadata);

%-- Extract signal using extractRoiFluorescence function
dFoverF_np_subtracted = zeros(size(ROIsignals_raw));

for x = 1:size(ROIsignals_raw,1)
    signal_ROI = ROIsignals_raw(x,:);
    signal_np = ROIsignals_neuropil(x,:);
    sorted = sort(signal_ROI);
    sorted_np = sort(signal_np);
    
    % Calculate delta f over f.
    f0 = median(sorted(1:round(end*0.05)));
    f0_np = median(sorted_np(1:round(end*0.05)));
    
    deltaFoverF = (signal_ROI - f0) ./ f0;
    deltaFoverFnp = (signal_np - f0_np) ./ f0_np;
    dFoverF = deltaFoverF;
    np_signal = deltaFoverFnp;
    %signal_smoothed = smooth(dFoverF, 3) - smooth(np_signal, 3);
    dFoverF_np_subtracted(x,:) = dFoverF - np_signal;
    
end


end
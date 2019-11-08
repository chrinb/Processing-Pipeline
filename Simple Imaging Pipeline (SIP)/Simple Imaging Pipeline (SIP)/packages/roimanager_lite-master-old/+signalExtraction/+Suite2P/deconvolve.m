function s2p_dec = deconvolve(dff, fps)

% Use suite2p to deconvolve signal and estimate spikerate.
ops.fs = fps;
ops.sensorTau = 2;
ops.estimateNeuropil = 0;

s2p_dec = zeros(size(dff));

% Transpose the dff for suite2p wrapper deconvolution function
[s2p_dec, ~, ~, ~, ~, ~, ~] = wrapperDECONV(ops, dff');

s2p_dec = s2p_dec';

end


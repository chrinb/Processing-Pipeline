function [s2p_dec, s2p_den] = deconvolve(dff, fps, neu)

% dff contains the NT by NN somatic traces
% neu (optional) contains NT by NN surroundnig neuropil traces

if nargin == 3
   ops.estimateNeuropil = 1;
end


% Use suite2p to deconvolve signal and estimate spikerate.
ops.fs = fps;
ops.sensorTau = 2;
ops.estimateNeuropil = 0;

ops.lam = 0.0; % no penalty
ops.deconvType = 'OASIS';

% s2p_dec = zeros(size(dff));
% s2p_den = zeros(size(dff));

% Transpose the dff for suite2p wrapper deconvolution function
if ops.estimateNeuropil
    [s2p_dec, s2p_den, ~, ~, ~, ~, ~] = wrapperDECONV(ops, dff', neu');
else
    [s2p_dec, s2p_den, ~, ~, ~, ~, ~] = wrapperDECONV(ops, dff');
end

s2p_dec = s2p_dec';
s2p_den = s2p_den';

if nargout == 1
    clearvars s2p_den
end

end


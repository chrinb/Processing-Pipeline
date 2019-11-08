function spikes = discretizeDeconvolved(deconvDff)
% Discretize the deconvolved signal based on the 20th percentile
%
% Very simple way of doing it for now...

deconvNonZero = deconvDff(deconvDff>0);
spikes = ceil(deconvDff / prctile(deconvNonZero, 10)); return   

end 
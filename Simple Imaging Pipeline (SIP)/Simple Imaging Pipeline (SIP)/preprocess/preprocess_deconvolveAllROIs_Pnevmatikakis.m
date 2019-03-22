function [deconv,raw,spike_vec,estimated_spike_rate] = preprocess_deconvolveAllROIs_Pnevmatikakis(ROIsignals,upsample,im_fs)

if nargin < 3
    im_fs = 31;
end

if nargin < 2
    upsample = 0;
end

% For recordings using piezo, the signal is interpolated
if upsample == 1
    ROIsignals = upsample_signalWithInterpolation(ROIsignals,4);
end

fprintf('\n');
count = 1;
for x = 1:size(ROIsignals,1)
    fprintf('%i - ',x);
    [~,deconv(count,:)] = deconvolveCa(ROIsignals(x,:));
    raw(count,:) = ROIsignals(x,:);
    count = count+1;
end

fprintf('\n');

sp = deconv;
spikethreshold = 0.11; % Just based on trial and error = 0.24

% The sum of integrating the spike rate
cumSum = 0;
% Memory of last second. I want to reset the sum if nothing happened 
% for the last second. Could maybe be shorter period.
lastSecSamples = zeros(1, round(im_fs)); 

% Create vector to put spikes in
spike_vec = zeros(size(sp));

% Run through the deconvolved signal from Suite2p
for s = 1:length(sp)
    
	% Put current sample at the end of "memory" vector
    lastSecSamples = horzcat(lastSecSamples(2:end), sp(s)) ;
    
	% Integrate or reset.
    if sum(lastSecSamples) == 0
        cumSum = 0;
    else 
        cumSum = cumSum + sp(s);
    end
    
	% Check if sum is over threshold. Count spikes and reset.
    if floor(cumSum/spikethreshold) >= 1
        spike_vec(s) = floor(cumSum/spikethreshold);
        cumSum = cumSum - floor(cumSum/spikethreshold)*spikethreshold;
    end
end


estimated_spike_rate = zeros(size(spike_vec));
for r = 1:size(spike_vec,1)
    estimated_spike_rate(r,:) = spike_vec(r,:)./(1/im_fs); 
end



end
function [estimatedSpikes,deconv_sig] = preprocess_deconvolveAllROIs_suite2P(ROIsignals)

ROIsignals = upsample_signalWithInterpolation(ROIsignals,4);

% Suite2p
ops.fs = 31;
ops.sensorTau = 2;
ops.estimateNeuropil = 0;
estimatedSpikes = zeros(size(ROIsignals));
deconv_sig = zeros(size(ROIsignals));
for roi = 1:size(ROIsignals,1)
    signal = ROIsignals(roi,:)';

    [sp, ca, coefs, B, sd, ops, baselines] = wrapperDECONV(ops, signal);

    % figure(3);
    % clf;
    % plot(sp);
    % hold on
    % plot(ca/max(ca(:)/max(sp(:))))
    % hold off

    %--- Estimate spikes
    spikethreshold = 0.24; % Just based on trial and error

    % The sum of integrating the spike rate
    cumSum = 0;
    % Memory of last second. I want to reset the sum if nothing happened 
    % for the last second. Could maybe be shorter period.
    lastSecSamples = zeros(1, 31); 

    % Create vector to put spikes in
    spike_vec = nan(size(sp));

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

    spike_vec(isnan(spike_vec)) = 0;
    estimatedSpikes(roi,:) = spike_vec;
    deconv_sig(roi,:) = sp;
end

% figure(88);
% plot(spike_vec(1:3100));


end
function spikes = integrateAndFire(deconvolvedSignal, opt)
%integrateAndFire Return an array of spikes time series
%
%   spikes = integrateAndFire(deconvolvedSignal, rois, opt) (guess-) 
%   estimates spikes from a deconvolved dff signal by applying an integrate
%   and fire moving window.
%   opt is a struct with options.
%
%   spikes is an array of size nRois x nSamples/nTimePoints
%
%   opt contains the following fields
%       spikethreshold : arbitrary number used as spikethreshold when
%       integrating the deconvolved signal.
%       windowSize : size of moving window.

% % Set default options if missing in input.
if nargin < 2
    opt.spikethreshold = ones(size(deconvolvedSignal, 1), 1) * 0.24;  % Just based on trial and error
    opt.windowSize = 31;
end

if ~isfield(opt, 'windowSize'); opt.windowSize = 31; end


% % Initialize array for spikes

spikes = zeros(size(deconvolvedSignal));

nRois = size(deconvolvedSignal, 1);

for i = 1:nRois

    roiSignal = squeeze(deconvolvedSignal(i, :));
    
    if all(isnan(roiSignal))
        continue
    end
    
    % The sum of integrating the spike rate
    cumSum = 0;
    
    % "Memory vector" or sliding window
    lastNSamples = zeros(1, opt.windowSize); 
    
    % Run through the deconvolved signal
    for s = 1:length(roiSignal)

        % Put current sample at the end of "memory" vector
        lastNSamples = horzcat(lastNSamples(2:end), roiSignal(s)) ;

        % Integrate or reset.
        if sum(lastNSamples) == 0
            cumSum = 0;
        else 
            cumSum = cumSum + roiSignal(s);
        end

        % Check if sum is over threshold. Count spikes and reset.
        if floor(cumSum/opt.spikethreshold(i)) >= 1
            spikes(i, s) = floor(cumSum/opt.spikethreshold(i));
            cumSum = cumSum - floor(cumSum/opt.spikethreshold(i))*opt.spikethreshold(i);
        end
    end
end


end
function spikes = integrateAndFire(deconvDff, opt)
%integrateAndFire Return an array of spikes time series
%   SPIKES = integrateAndFire(DECONVDFF, OPT) (guess-) estimates spikes 
%   from a deconvolved dff signal by applying an integrate and fire moving 
%   window. SPIKES and DECONVDFF is a nRois x nSamples/nTimePoints matrix 
%   and OPT is a options struct, containing the following fields:
%       spikethreshold  : arbitrary number used as spikethreshold when
%                         integrating the deconvolved signal.
%       windowSize      : size of moving window.



% % Set default options if missing in input.
if nargin < 2
    opt.spikethreshold = ones(size(deconvDff, 1), 1) * 0.24;  % Just based on trial and error
    opt.windowSize = 15;
end

if ~isfield(opt, 'windowSize'); opt.windowSize = 15; end
if ~isfield(opt, 'spikethreshold'); opt.spikethreshold = 0.24; end

% % Initialize array for spikes

spikes = zeros(size(deconvDff));
nRois = size(deconvDff, 1);

if nRois > 1 && numel(opt.spikethreshold) == 1
    opt.spikethreshold = repmat(opt.spikethreshold, 1, nRois);
end

for i = 1:nRois

    roiSignal = squeeze(deconvDff(i, :));
    
    if isfield(opt, 'nSpikes')
        opt.spikethreshold(i) = sum(roiSignal)*1.1 ./ opt.nSpikes(i);

    end
    
    maxDec = max(roiSignal);
    ratio = opt.spikethreshold(i) / maxDec;

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
            % Correct for delay if spikethreshold is high compared to the
            % deconvolved signal...
            if ratio > 2
                windowBeg = max([1, s-opt.windowSize]);
                ind = (windowBeg-1) + find(roiSignal(windowBeg:s)~=0, 1, 'first');
            else
                ind = s;
            end
            spikes(i, ind) = floor(cumSum/opt.spikethreshold(i));
            cumSum = cumSum - floor(cumSum/opt.spikethreshold(i))*opt.spikethreshold(i);
        end
    end
end


end
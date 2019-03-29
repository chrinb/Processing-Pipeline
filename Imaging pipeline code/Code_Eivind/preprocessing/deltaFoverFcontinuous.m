function [ sessionData ] = deltaFoverFcontinuous( sessionData )
%deltaFoverFcontinuous Calculate the delta F over F for continuous 
% rotations, using a moving window.

nCh = sessionData.nCh;

% Get signal for each channel present in sessionData. Create cell with
% empty array for each channel for placing calculated delta f over f.
signal = arrayfun(@(ch) sessionData.(['signalCh', num2str(ch)]), sessionData.channels, 'uni', 0);
deltaFoverF = arrayfun(@(ch) [], sessionData.channels, 'uni', 0);

% percentile used to find baseline
percentile = 0.4;
cutoff = percentile*double(sessionData.nBlocks)*20; % use 20neighbor samples

for ch = 1:nCh

    baseline = zeros(size(signal{ch}));

    for roi = 1:sessionData.nRois

        cellSignal = squeeze(signal{ch}(:, roi, :));
        if size(signal{ch}, 1) == 1 % If only 1 block
            cellSignal = cellSignal';
        end
        
        cellBaseline = zeros(size(cellSignal));
        
        for sample = 1:sessionData.nFrames

            if sample < 11 % Use samples on the right in the beginning
                neighbor_samples = reshape(cellSignal(:, sample+(1:20)), [], 1);
            elseif sample > sessionData.nFrames - 11 % Use samples on the left in the end
                neighbor_samples = reshape(cellSignal(:, sample+(-20:-1)), [], 1);
            else % use samples on left and right 
                neighbor_samples = reshape(cellSignal(:, sample+(-10:10)), [], 1);
            end
            sorted_samples = sort(neighbor_samples);
            cellBaseline(:,sample) = mean(sorted_samples(1:cutoff));
        end
        baseline(:, roi, :) = cellBaseline;
    end

    deltaFoverF{ch} = (signal{ch} - baseline) ./ baseline;

end

% Add deltaFoverF to sessionData
for ch = 1:nCh
    sessionData.(['deltaFoverFch', num2str(sessionData.channels(ch))]) = deltaFoverF{ch};
end
    
end


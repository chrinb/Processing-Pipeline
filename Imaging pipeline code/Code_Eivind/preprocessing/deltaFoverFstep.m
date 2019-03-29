function [ sessionData ] = deltaFoverFstep( sessionData )
%deltaFoverFstep Calculate the delta F over F for stepwise 
% rotations, using a moving window.

nCh = sessionData.nCh;

% Get signal for each channel present in sessionData. Create cell with
% empty array for each channel for placing calculated delta f over f.
signal = arrayfun(@(ch) sessionData.(['signalCh', num2str(ch)]), sessionData.channels, 'uni', 0);
deltaFoverF = arrayfun(@(ch) [], sessionData.channels, 'uni', 0);

% percentile used to find baseline
percentile = 0.4;

angles = sessionData.stagePositions;

for ch = 1:nCh
    
    baseline = zeros(size(signal{ch}));

    for roi = 1:sessionData.nRois
        
        cellSignal = squeeze(signal{ch}(:, roi, :));
        
        cellBaseline = zeros(size(cellSignal));

        % Create looong 1dim column vectors
        transitions = reshape(sessionData.transitions.', [], 1);
        cellBaseline = reshape(cellBaseline.', [], 1);
        angles1D = reshape(sessionData.stagePositions.', [], 1);
        rotating1D = reshape(sessionData.rotating.', [], 1);
        
        stationaryPositions = unique(round(angles1D(~rotating1D)));
        
        % Find indices where trial starts and stop (e.g transitions)
        stationaryStartIdx = vertcat(1, find(transitions == -1));
        stationaryStopIdx = vertcat(find(transitions == 1), size(cellBaseline, 1));
        
        baselineValues = zeros(1, length(stationaryPositions));  %Need revision.

        % Find baseline values for each orientation
        for i = 1:length(stationaryPositions)
           pos = stationaryPositions(i);
           samples = cellSignal(abs(angles - pos) < 0.2 );
           sortedSamples = sort(samples);
           numSamples = size(samples, 1);
           cutoff = round( percentile * numSamples );
           baselineValues(i) = mean(sortedSamples(1:cutoff));
        end

        % Set the baseline value for the stationary parts
        for t = 1:size(stationaryStartIdx, 1)
            trialStart = stationaryStartIdx(t);
            trialEnd = stationaryStopIdx(t);
            trialAngle = round(median( angles1D(trialStart:trialEnd) ));
            trialBaseline = baselineValues(stationaryPositions == trialAngle);
            cellBaseline(trialStart:trialEnd) = trialBaseline;
        end

        rotationStartIdx = find(transitions == 1);
        rotationStopIdx = find(transitions == -1);

        % Set the baseline value for the rotation parts 
        for t = 1:size(rotationStartIdx, 1)
            trialStart = rotationStartIdx(t);
            trialEnd = rotationStopIdx(t);
            firstValue = cellBaseline(trialStart);
            lastValue = cellBaseline(trialEnd);
            deltaY = lastValue - firstValue;
            segment_length = trialEnd-trialStart;
            stepY = deltaY / segment_length;

            segment = firstValue:stepY:lastValue;
            cellBaseline(trialStart:trialEnd, 1) = segment;

        end

        cellBaseline = reshape(cellBaseline, [], sessionData.nBlocks).';
        cellBaseline = reshape(cellBaseline, sessionData.nBlocks, 1, []);
        baseline(:, roi, :) = cellBaseline;

    end
    
    deltaFoverF{ch} = (signal{ch} - baseline) ./ baseline;
    
end

for ch = 1:nCh
    sessionData.(['deltaFoverFch', num2str(sessionData.channels(ch))]) = deltaFoverF{ch};
end


% figure()
% hold on
% cell = 4;
% 
% for block=1:10
%     plot(squeeze(signal(block, cell, :)))
% end
% plot(squeeze(baseline(1, cell, :)))


end


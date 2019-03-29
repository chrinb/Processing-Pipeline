function [ deltaFoverF ] = deltaFoverFsimple( signal )
%deltaFoverFcontinuous Calculate the delta F over F for continuous 
% rotations, using a moving window.

nCh = 1;

% Get signal for each channel present in sessionData. Create cell with
% empty array for each channel for placing calculated delta f over f.
%signal = arrayfun(@(ch) sessionData.(['signalCh', num2str(ch)]), sessionData.channels, 'uni', 0);
%deltaFoverF = arrayfun(@(ch) [], sessionData.channels, 'uni', 0);
deltaFoverF = zeros(size(signal));
nROIs = size(signal,1);

for ch = 1:nCh

    baseline = zeros(size(signal)); %baseline = zeros(size(signal{ch}));

    for roi = 1:nROIs %sessionData.nRois

        cellSignal = squeeze(signal(:, roi, :)); %squeeze(signal{ch}(:, roi, :));
        if size(signal, 1) == 1 % size(signal{ch}, 1) == 1 % If only 1 block
            cellSignal = cellSignal';
        end
                
        sorted = sort(cellSignal);
            
        f0 = median(sorted(1:round(end*0.2)));
        baseline(:, roi, :) = f0;
    end

    deltaFoverF = (signal - baseline) ./ baseline; %deltaFoverF{ch} = (signal{ch} - baseline) ./ baseline;

end

% % Add deltaFoverF to sessionData
% for ch = 1:nCh
%     sessionData.deltaFoverF = deltaFoverF;%sessionData.(['deltaFoverFch', num2str(sessionData.channels(ch))]) = deltaFoverF; % deltaFoverF{ch};
% end
%     
end


function dFoverF = preprocess_dFoverF(signal)

% Calculate dFoverF for all ROIs individually and uses a baseline as the
% fifth percentile of signal for the entire recording.

dFoverF = zeros(size(signal));
nROIs = size(signal,1);

baseline = zeros(size(signal)); %baseline = zeros(size(signal{ch}));

for roi = 1:nROIs %sessionData.nRois
    cellSignal = squeeze(signal(roi,:)); %squeeze(signal{ch}(:, roi, :));
    sorted = sort(cellSignal);
    f0 = sorted(1:round(end*0.05));
    baseline(roi,:) = f0(end);
end

dFoverF = (signal - baseline) ./ baseline; %deltaFoverF{ch} = (signal{ch} - baseline) ./ baseline;

end
function normalized = zScoreNormalize(signals)
% zScoreNormalize: Produces a z score normalized version of the signal.
% Input
%   signals: a NxM matrix containing the signals to be normalized, where N
%   is the number of ROIs
% Output
%   normalized: z-score normalized version of the input varible signals

normalized = zeros(size(signals));

for x = 1:size(signals,1)
    normalized(x,:) = (signals(x,:) - mean(signals(x,:)))/std(signals(x,:));
end



end
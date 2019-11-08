function ROIsignals_dFF = dffcalcNora(ROIsignals_rawOrig,ROIsignals_Npil) 
% input is two arrays of size nSamples x nRois, one containing roi signals and the other containing neuropil signals.

% Neuropil signal subtraction
ROIsignals_raw = ROIsignals_rawOrig - ROIsignals_Npil;

%%% Init variables
[nROIs,nSamples] = size(ROIsignals_raw);
FrameRate = 31;

%%% Remove slow time-scale changes in fluoresence and baseline subtraction (5 percentile), baseline subtraction is not perfect (always above zero)
%Inspired Andreas by Dombeck et al (2010, Nat Neuro), code written by Andreas. Calculate basline in every 15 sec (in a moveing window) and subtract from data
Window1 = 15; % seconds, can be changed... , 10-15s
Percentile = 10; % I used 20%, but the transients became negative in baseline
Samples = ceil(Window1*FrameRate); % samples to be used
SignalTemp1 = zeros(nROIs,nSamples); % temporary array for signal calculation
MeanBaseline = zeros(nROIs,1); % mean baseline for each ROI recording for calculate dFF
CollectBaseline = zeros(1,nSamples); % temporary collection of baseline value for a ROI
for i = 1:1:nROIs 
    % duplicate the beginning and end of the signal, and concatenate the first (and last) 15s of the signal to the beginning (and end) of the original signal
    SignalTemp2 = [ROIsignals_raw(i,1:Samples),ROIsignals_raw(i,:),ROIsignals_raw(i,(end-Samples+1):end)]; % concatenate the duplicates and the original signal
    % Use a window of Window seconds around each data point to obtain X th percentile and subtract this from original signal to make the basline flat
    for j = Samples:1:(nSamples+Samples-1)
        Signal_window = SignalTemp2(1,(j-round(Samples/2)):(j+round(Samples/2))); % collect the data witihn the actual window to calculate baseline for datapoint 
        SignalTemp1(i,(j-Samples+1)) = SignalTemp2(j) - prctile(Signal_window,Percentile); % calculate X percentile of data and subtract
        CollectBaseline(1,(j-Samples+1)) = prctile(Signal_window,Percentile);
    end
    MeanBaseline(i,1) = mean(CollectBaseline(1,:)); % mean baseline for the whole ROI session, used for dF/F division
end
ROIsignals_raw_slow_removed = SignalTemp1;

% Baseline already subtracted, generate dFF (devide with baseline)
ROIsignals_dFF = ROIsignals_raw_slow_removed ./ abs(MeanBaseline); % calculate dFF (baseline was subtracted in previous session)


end
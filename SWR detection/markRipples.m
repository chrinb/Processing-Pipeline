function [sData] = markRipples(sData,makeSpectrogramPlot, removeEMGSWRs)

%detectRipples is used to automatically detect peaks in the ripple
%frequency and extract indices of these peaks so that snippets of the LFP
%signals containing putative ripples may be plotted for visual verification.

%HOW TO PERFORM MANUAL SCORING 
%in response to the prompt "Keep ripple? X of X", type 'y' to keep the
%ripple that is at the center of the plot. Type 'b' to go back to a
%previous ripple and re-inspect, type 'm' to manually click on a ripple
%waveform in the plot that may have been missed. NB! When you type 'm' and hit
%enter, crosshairs will appear and you can click on the LFP line plot
%roughly in the center of the ripple (aligning the crosshairs with the
%spectrogram helps to estimate the ripple peak). You can click as many
%times as you want if there are multiple missed ripples in the plot. When
%you are done clicking, hit enter. The "extra" ripple locations will be
%saved and you will be prompted again to save or discard the ripple that
%was detected at the center of the plot. To discard a ripple, simply hit
%enter.

%%INPUTS: 
%sData struct, containing the lfp recording from one animal, one session
%makeSpectrogramPlot, a logical (1/0) indicating whether to include a
%spectrogram when plotting the ripple traces for manual scoring

%%OUTPUTS:
%sData, updated with ripple locations, ripple waveform snippets, and
%parameters of the scoring (freq filter, threshold)


fs = 2500;
freqFilter = [100 300];
lfpSignal = sData.ephysdata.lfp;
try 
    runSignal = sData.daqdata.run_speed;
catch
    runSignal = sData.daqdata.runSpeed;
end
lfp = lfpSignal;
rawLFP = lfpSignal;

nSnips = floor(length(rawLFP)/(fs)) - 1;
time = linspace(0,length(lfp),length(lfp))/(fs);
timeRound = round(time,3);
rippleLocs = [];

window_size = 5;
window_size_index = window_size * fs;


    
% Filter LFP between 150-250 hz for sharp wave ripple detection
freqL = freqFilter(1);
freqU = freqFilter(2);
nyquistFs = fs/2;
%min_ripple_width = 0.015; % minimum width of envelop at upper threshold for ripple detection in ms
    
% Thresholds for ripple detection 
U_threshold = 3;  % in standard deviations
% L_threshold = 1; % in standard deviations
    
% Create filter and apply to LFP data
filter_kernel = fir1(600,[freqL freqU]./nyquistFs); % Different filters can also be tested her e.g. butter and firls

filtered_lfp = filtfilt(filter_kernel,1,lfp); % Filter LFP using the above created filter kernel

% Hilbert transform LFP to calculate envelope
lfp_hil_tf = hilbert(filtered_lfp);
lfp_envelop = abs(lfp_hil_tf);

% Smooth envelop using code from 
smoothed_envelop = gaussfilt_2017(time,lfp_envelop,.004);
moving_mean = movmean(smoothed_envelop, window_size_index);
moving_std = movstd(smoothed_envelop, window_size_index);
moving_mean_move = movmean(runSignal, window_size_index);


% Find upper/lower threshold values of the LFP
upper_thresh = moving_mean + U_threshold*moving_std;
    

% Find peaks of envelop. NB: The parameters of this function have to be properly
% chosen for best result.
[~,locs,~,~] = findpeaks(smoothed_envelop-upper_thresh,fs,'MinPeakHeight',0,'MinPeakDistance',0.025,'MinPeakWidth',0.010,'WidthReference','halfhprom','Annotate','extents','WidthReference','halfprom');
rippleLocs = round(locs,3);    

if removeEMGSWRs == 1
    % Compute filtered EMG (100-1000Hz) amplitude envelope and remove putative
    % SWR-events occurring inside epochs where amplitude envelope > 5*mean of
    % the envelope
    emg_hilbert  = hilbert(sData.ephysdata3.EMGfilt); % hilbert transform
    emg_envelope = abs(emg_hilbert); % find amplitude envelope
    emg_thresh   = mean(emg_envelope)*5; % compute threshold
    emg_envelope(emg_envelope < emg_thresh) = 0; % set values below threshold to zero
    emg_envelope           = smoothdata(emg_envelope, 'gaussian', 500); % smooth remaining amp. envelope
    log_idx                = emg_envelope > 0;
    data_length            = 1:length(emg_envelope);
    emg_samples_to_exclude = ( data_length(log_idx) )/2500; % divide by sample rate to get time same time units as SWR locs
    swr_locs_to_exclude = rippleLocs;
    
    % loop over nr of putative SWRs
    for swr_nr = 1:numel(rippleLocs)
        
        % Check if putative SWR coincides with high amplitude EMG activity. If
        % so, set value to zero for later removal
        if ismember( locs(swr_nr), emg_samples_to_exclude)
            rippleLocs(swr_nr) = 0;
        % just for plotting those excluded SWRs
        elseif ~ismember( locs(swr_nr), emg_samples_to_exclude)
            swr_locs_to_exclude(swr_nr) = 0;
        end
    
    end
    
    % Optional: visualize results
    plot_var = ones(1, length(rippleLocs))*0.01;
    figure,
    plot(time, emg_envelope)
    hold on
    plot(rippleLocs', plot_var, 'd')
    plot(swr_locs_to_exclude', plot_var, 'd')
    
    % Remove SWRs occurring inside epochs of high EMG activity
    rippleLocs(rippleLocs == 0) = [];
end


rippleSnips = struct();
rippleIdx = zeros(1,length(rippleLocs));
rippleLocs = round(rippleLocs,3);
%convert the ripple locations from time to sample
for i = 1:length(rippleLocs)
        lfpPeakIdx = find(timeRound == rippleLocs(i));
        lfpStartIdx = lfpPeakIdx(1) - (0.5*fs);
        %if the ripple timepoint is near the beginning of the trace
        if lfpStartIdx < 0; lfpStartIdx = 1; end
        lfpEndIdx = lfpPeakIdx(1) + (0.5*fs);
        %if the ripple timepoint is near the end of the trace
        if lfpEndIdx > length(lfpSignal); lfpEndIdx = length(lfpSignal); end
        rippleSnips(i).lfp = rawLFP(lfpStartIdx:lfpEndIdx);
        rippleIdx(i) = lfpPeakIdx(1);
    
        %take out timepoints when animal is walking. Slight movement of the
        %running wheel results in a value of 0.3456. Therefore threshold is
        %set to > 0.4, as these movements do not reflect walking per se
        if runSignal(rippleIdx(i)) > 0.4
            rippleIdx(i) = NaN; 
        end 
%     if runSignal(moving_mean_move(i)) ~= 0; rippleIdx(i) = NaN; end %take out timepoints when animal is walking
    
end

%remove NaNs and timepoints too close together (likely identifying the same ripple
%waveform)
rippleSnips(isnan(rippleIdx)) = [];
rippleIdx(isnan(rippleIdx)) = [];

[final_rippleLFP,final_rippleLocs] = inspectRipples(rippleSnips,rippleIdx,lfp,makeSpectrogramPlot);
sData.ephysdata.absRipIdx = final_rippleLocs;
sData.ephysdata.rippleSnips = final_rippleLFP;
try frames = sData.daqdata.frame_onset_reference_frame;
catch frames = sData.daqdata.frameIndex;
end
sData.ephysdata.frameRipIdx   = frames(sData.ephysdata.absRipIdx);
sData.ephysdata.freqFilterSWR = freqFilter;
sData.ephysdata.SWREnvThr     = U_threshold;
sData.ephysdata.SWRwinsize    = window_size;
% timeBetweenRipples = diff(rippleIdx);
% %must have at least 100 ms between ripples, if there are 2 close together,
% %keep the later one
% extraRipples = find(timeBetweenRipples < 250);
% rippleIdx(extraRipples + 1) = [];
% rippleSnips(extraRipples + 1) = [];






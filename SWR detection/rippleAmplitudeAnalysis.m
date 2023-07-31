function [rippleAmpResp] = rippleAmplitudeAnalysis(rippleAmpResp,sData,n_sData,window, swr_idx)

%INPUTS: rippleAmpResp is a structure containing the dff response and a
%list of normalized ripple amplitudes. Created for each sData file. When
%running code for the first sData file, define rippleAmpResp as "[]" and
%n_sData as 1. For subsequent files, the code will add a field for every
%sData file.
%sData is the file containing the imdata and ephysdata.
%n_sData is the number of sData files to be analyzed.
%window is the time window of analysis, in seconds.

if isempty(swr_idx)
    swr_idx = true([1,length(sData.ephysdata.absRipIdx)]);
else
    swr_idx = swr_idx; % for specifying subset of SWRs, for example NREM SWRs.
end
i = n_sData;
ripWindow = window; %define how many seconds before and after ripple you want to look at 

enumerate_swr = 1:length(sData.ephysdata.rippleSnips);
% swr_idx_to_use = enumerate_swr(swr_idx);
% for i = 1:enumerate_swr
    
ripples = sData.ephysdata.rippleSnips;
ripLocs = sData.ephysdata.frameRipIdx;
imgFs = 31;
nFrames = max(sData.daqdata.frame_onset_reference_frame);
nFrames_window = imgFs*ripWindow;

fs = 2500;
nyquistFs = fs/2;
filter_kernel = fir1(600,[100 250]./nyquistFs);
time = linspace(0,1,2500);


% dF = sData.imdata.roiSignals(2).newdff;

%eliminate all ripples that don't have enough time before or after to
%perform analysis (happen too early or too late in the recording)
minTimeWindow = nFrames_window + 1;
maxTimeWindow = nFrames-(nFrames_window);
% outOfBoundsIdx = find(ripLocs < minTimeWindow);
% ripLocs(outOfBoundsIdx) = [];
% ripples(outOfBoundsIdx) = [];
% outOfBoundsIdx = find(ripLocs > maxTimeWindow);
% ripLocs(outOfBoundsIdx) = [];
% ripples(outOfBoundsIdx) = [];

for j = enumerate_swr
        lfp = ripples(j).lfp;
        % Check that ripple snippet is not NaNs (indicated it was "deleted"
        % because it was a duplicate) and that snippet is not shorter than
        % 2501 samples
        if length(lfp) ~= sum(isnan(lfp)) && ~lt(length(lfp), 2501)
            filtered_lfp = filtfilt(filter_kernel,1,lfp);
            lfp_hil_tf = hilbert(filtered_lfp);
            lfp_envelope = abs(lfp_hil_tf);
            smoothed_envelope = gaussfilt_2017(time,lfp_envelope,.004);
            env_zScore = zscore(smoothed_envelope);
            
            %ripple amplitude is the magnitude (zscore) of the smoothened envelope at
            %ripple peak
            midPt = round(length(lfp)/2);
            try
                rippleAmpResp(i).zScoreAmp(j,1) = max(env_zScore(midPt-150:midPt+150));
    %         rippleAmpResp(i).zScoreAmp(j,1) = max(smoothed_envelope(midPt-150:midPt+150));
                rippleAmpResp(i).lfpTrace(j,:) = lfp;
    %         rippleAmpResp(i).slowEnv(j,:) = env_zScore;
            
                %define time window (in imaging frames) surrounding ripple
                ripWindowIdx = ripLocs(j) - nFrames_window : ripLocs(j) + ...
                    nFrames_window;
    
%                 rippleAmpResp(i).dff(j,:) = nanmean(dF(:,ripWindowIdx));
            end
        end
end

%normalize the amplitude of ripples within each session SKIP THIS STEP FOR
%MULTIPLE SESSION COMPARISON
% rippleAmpResp(i).zScoreAmp = rippleAmpResp(i).zScoreAmp./max(rippleAmpResp(i).zScoreAmp);

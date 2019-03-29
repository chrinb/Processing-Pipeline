function sortedROIresponsesAfterPeak = plot_populationPeakResponses_perTrial_ADAA(sessionData,sortedROIresponsesAfterPeak)

tri = 1;

%--- Initialize variables
Fs = 31;
pre_window_size = 5*Fs; % window size in seconds * sampling frequency of imaging.
stim_window_size = 4*Fs;
post_window_size = 10*Fs;

total_window_size = pre_window_size + stim_window_size + post_window_size;
tickValuesSamples = [-pre_window_size:0, 1:stim_window_size+post_window_size-1];
tickValuesSeconds = tickValuesSamples/Fs;

signals = sessionData.ROIsignals_dFoverF_zScored;
numROIs = size(sessionData.ROIsignals_dFoverF,1);

%--- Sort and calculate mean respones for each trial sorted with respect to trial onset
%- Get time onset for HIT, Miss, C.R. and F.A. trials
response_type = sessionData.daqdata.experiment_data.trial_response_type;

% Get the tone_onset signal obtained by the speaker signal.
tone_onset = sessionData.daqdata.tone_onset;
tone_onset_start_response = zeros(length(tone_onset),1);
tracker = 1;

%- For each tone onset set a 1 on the rising of the onset such that each response type onset has a marker where it starts
while tracker<length(tone_onset)
    if tone_onset(tracker) == 1
        tone_onset_start_response(tracker) = 1;
        tracker = tracker + 150;
    else
        tracker = tracker + 1;
    end
end

%- Similar to above, but now set the response type (i.e. hit, miss, f.a. or c.r.) at the stimulus start point.
nxt_stimulus_type = 1;
for x = 1:length(tone_onset_start_response)
    if tone_onset_start_response(x) == 1
       tone_to_set = response_type(nxt_stimulus_type);
       tone_onset_start_response(x) = tone_to_set; 
       nxt_stimulus_type = nxt_stimulus_type + 1;
    end
end

%--- Sort response type onsets into vectors
tone_onset_hit = [];%zeros(size(tone_onset));
tone_onset_miss = [];%zeros(size(tone_onset));
tone_onset_cr = [];%zeros(size(tone_onset));
tone_onset_fa = [];%zeros(size(tone_onset));
tone_onset_hit_count = 1;
tone_onset_miss_count = 1;
tone_onset_cr_count = 1;
tone_onset_fa_count = 1;

for x = 1:length(tone_onset_start_response)
    if(tone_onset_start_response(x) == 1)
           tone_onset_hit(tone_onset_hit_count) = x; 
           tone_onset_hit_count = tone_onset_hit_count + 1;
    end
    if tone_onset_start_response(x) == 2
           tone_onset_cr(tone_onset_cr_count) = x; 
           tone_onset_cr_count = tone_onset_cr_count + 1;
    end
    if tone_onset_start_response(x) == 3
            tone_onset_miss(tone_onset_miss_count) = x;
            tone_onset_miss_count = tone_onset_miss_count + 1;
    end
    if tone_onset_start_response(x) == 4
            tone_onset_fa(tone_onset_fa_count) = x; 
            tone_onset_fa_count = tone_onset_fa_count + 1;
    end
end

%--- Plot peak plot for hit, miss, fa and cr responses
sesNum = sessionData.daqdata.metadata.sessionNumber;
figure(sesNum);
set(gcf,'rend','painters','pos',[10 10 950 700])
sessionID = sessionData.daqdata.metadata.sessionID;
sessionID = strrep(sessionID,'_','-');
clf;
[ha, pos] = tight_subplot(4,1); 

for hit = 1 

% Calculate means for HITs
roi_responses = zeros(length(tone_onset_hit),total_window_size,numROIs);
mean_responses = zeros(numROIs,total_window_size);
for ROI = 1:numROIs
    for x = 1:length(tone_onset_hit)% skip first trial because of lack in prewindow on early recordings
        roi_responses(x,:,ROI) = signals(ROI,tone_onset_hit(x)-pre_window_size:tone_onset_hit(x)+(stim_window_size + post_window_size)-1);
    end  
    mean_responses(ROI,:) = mean(roi_responses(:,:,ROI));
end 

peakIndex = zeros(numROIs,2,length(tone_onset_hit));

for numHITtrials = tri%:length(tone_onset_hit)
    for ROI = 1:numROIs
        [~, ind] = max(roi_responses(numHITtrials,:,ROI));
        peakIndex(ROI,1,numHITtrials) = ind(1);
        peakIndex(ROI,2,numHITtrials) = ROI; 
    end
end

if nargin<2

    sortedROIresponsesAfterPeak = zeros(size(roi_responses(length(tone_onset_hit),:,:)));
    peakIndex = sortrows(peakIndex(:,:,tri));
    for numHITtrials = tri%:length(tone_onset_hit)
        for ROI = 1:numROIs
           sortedROIresponsesAfterPeak(numHITtrials,:,ROI) = roi_responses(numHITtrials,:,peakIndex(ROI,2));
        end
    end
end
end% All code for HIT plot

subplot_num = 1;
axes(ha(subplot_num)); 
imagesc(normalizeROIsignals(squeeze(sortedROIresponsesAfterPeak(tri,:,:))'));
%imagesc(normalizeROIsignals(sortedROIresponsesAfterPeak(1,:,:)')');
ylabel('HIT');
xticks([]);
line([pre_window_size,pre_window_size],[0,numROIs+1],'LineWidth',0.5,'Color',[1,1,1]) % Draw stimulus onset line
line([pre_window_size+(stim_window_size)-(0.5*Fs),pre_window_size+(stim_window_size)-(0.5*Fs)],[0,numROIs+1],'LineWidth',0.5,'Color',[.8,.2,.1])   
line([pre_window_size+(stim_window_size),pre_window_size+(stim_window_size)],[0,numROIs+1],'LineWidth',0.5,'Color',[1,1,1]) % Draw stimulus offset line
set(gca,'FontSize',8);
title(['Session: ',sessionID],'FontSize',9);




end
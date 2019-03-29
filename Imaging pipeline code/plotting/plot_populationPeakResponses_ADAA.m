function plot_populationPeakResponses_ADAA(sessionData)

%--- Initialize variables
Fs = 31;
pre_window_size = 3*Fs; % window size in seconds * sampling frequency of imaging.
stim_window_size = 6*Fs;
post_window_size = 1*Fs;

total_window_size = pre_window_size + stim_window_size + post_window_size;
tickValuesSamples = [-pre_window_size:0, 1:stim_window_size+post_window_size-1];
tickValuesSeconds = tickValuesSamples/Fs;

signals = sessionData.ROIsignals_dFoverF_zScored;
new_signals = zeros(size(signals,1),size(signals,2)*4);
for x = 1:size(signals,1)
    new_signals(x,:) = interp(signals(x,:),4);
end
signals = new_signals;
numROIs = size(sessionData.ROIsignals_dFoverF,1);
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

peakIndex = zeros(numROIs,2);

for ROI = 1:numROIs
    [~, ind] = max(mean_responses(ROI,:));
    peakIndex(ROI,1) =ind(1);
    peakIndex(ROI,2) = ROI; 
end

sortedROIresponsesAfterPeak = zeros(size(mean_responses));
peakIndex = sortrows(peakIndex);
for ROI = 1:numROIs
   sortedROIresponsesAfterPeak(ROI,:) = mean_responses(peakIndex(ROI,2),:);
end

end% All code for HIT plot
subplot_num = 1;
axes(ha(subplot_num)); 
%imagesc(normalizeROIsignals(sortedROIresponsesAfterPeak')');
imagesc(sortedROIresponsesAfterPeak,[0,3]);

ylabel('HIT');
xticks([]);
line([pre_window_size,pre_window_size],[0,numROIs+1],'LineWidth',0.5,'Color',[1,1,1]) % Draw stimulus onset line
line([pre_window_size+(stim_window_size)-(0.5*Fs),pre_window_size+(stim_window_size)-(0.5*Fs)],[0,numROIs+1],'LineWidth',0.5,'Color',[.8,.2,.1])   
line([pre_window_size+(stim_window_size),pre_window_size+(stim_window_size)],[0,numROIs+1],'LineWidth',0.5,'Color',[1,1,1]) % Draw stimulus offset line
set(gca,'FontSize',8);
title(['Session: ',sessionID],'FontSize',9);

for cr = 1
   
    % Calculate means for CRs
    roi_responses = zeros(length(tone_onset_cr),total_window_size,numROIs);
    mean_responses = zeros(numROIs,total_window_size);
    for ROI = 1:numROIs
        for x = 1:length(tone_onset_cr)% skip first trial because of lack in prewindow on early recordings
            roi_responses(x,:,ROI) = signals(ROI,tone_onset_cr(x)-pre_window_size:tone_onset_cr(x)+(stim_window_size + post_window_size)-1);
        end  
        mean_responses(ROI,:) = mean(roi_responses(:,:,ROI));
    end 

    peakIndex = zeros(numROIs,2);

    for ROI = 1:numROIs
        [~, ind] = max(mean_responses(ROI,:));
        peakIndex(ROI,1) =ind(1);
        peakIndex(ROI,2) = ROI; 
    end

    sortedROIresponsesAfterPeak = zeros(size(mean_responses));
    peakIndex = sortrows(peakIndex);
    for ROI = 1:numROIs
       sortedROIresponsesAfterPeak(ROI,:) = mean_responses(peakIndex(ROI,2),:);
    end
    
    
end % All code for CR plot
subplot_num = 2;
axes(ha(subplot_num)); 
%imagesc(normalizeROIsignals(sortedROIresponsesAfterPeak')');
imagesc(sortedROIresponsesAfterPeak,[0,3]);
ylabel('Correct Rejection');
xticks([]);
line([pre_window_size,pre_window_size],[0,numROIs+1],'LineWidth',0.5,'Color',[1,1,1]) % Draw stimulus onset line
line([pre_window_size+(stim_window_size)-(0.5*Fs),pre_window_size+(stim_window_size)-(0.5*Fs)],[0,numROIs+1],'LineWidth',0.5,'Color',[.8,.2,.1])   
line([pre_window_size+(stim_window_size),pre_window_size+(stim_window_size)],[0,numROIs+1],'LineWidth',0.5,'Color',[1,1,1]) % Draw stimulus offset line
set(gca,'FontSize',8);

for miss = 1
   
    % Calculate means for MISSs
    roi_responses = zeros(length(tone_onset_miss),total_window_size,numROIs);
    mean_responses = zeros(numROIs,total_window_size);
    for ROI = 1:numROIs
        for x = 1:length(tone_onset_miss)% skip first trial because of lack in prewindow on early recordings
            roi_responses(x,:,ROI) = signals(ROI,tone_onset_miss(x)-pre_window_size:tone_onset_miss(x)+(stim_window_size + post_window_size)-1);
        end  
        mean_responses(ROI,:) = mean(roi_responses(:,:,ROI));
    end 

    peakIndex = zeros(numROIs,2);

    for ROI = 1:numROIs
        [~, ind] = max(mean_responses(ROI,:));
        peakIndex(ROI,1) =ind(1);
        peakIndex(ROI,2) = ROI; 
    end

    sortedROIresponsesAfterPeak = zeros(size(mean_responses));
    peakIndex = sortrows(peakIndex);
    for ROI = 1:numROIs
       sortedROIresponsesAfterPeak(ROI,:) = mean_responses(peakIndex(ROI,2),:);
    end

end % All code for MISS plot
subplot_num = 3;
axes(ha(subplot_num)); 
imagesc(normalizeROIsignals(sortedROIresponsesAfterPeak')');
%imagesc(sortedROIresponsesAfterPeak,[0,2]);
ylabel('MISS');
xticks([]);
line([pre_window_size,pre_window_size],[0,numROIs+1],'LineWidth',0.5,'Color',[1,1,1]) % Draw stimulus onset line
line([pre_window_size+(stim_window_size)-(0.5*Fs),pre_window_size+(stim_window_size)-(0.5*Fs)],[0,numROIs+1],'LineWidth',0.5,'Color',[.8,.2,.1])   
line([pre_window_size+(stim_window_size),pre_window_size+(stim_window_size)],[0,numROIs+1],'LineWidth',0.5,'Color',[1,1,1]) % Draw stimulus offset line
set(gca,'FontSize',8);

for fa = 1
   
    % Calculate means for MISSs
    roi_responses = zeros(length(tone_onset_fa),total_window_size,numROIs);
    mean_responses = zeros(numROIs,total_window_size);
    for ROI = 1:numROIs
        for x = 1:length(tone_onset_fa)% skip first trial because of lack in prewindow on early recordings
            roi_responses(x,:,ROI) = signals(ROI,tone_onset_fa(x)-pre_window_size:tone_onset_fa(x)+(stim_window_size + post_window_size)-1);
        end  
        mean_responses(ROI,:) = mean(roi_responses(:,:,ROI));
    end 

    peakIndex = zeros(numROIs,2);

    for ROI = 1:numROIs
        [~, ind] = max(mean_responses(ROI,:));
        peakIndex(ROI,1) =ind(1);
        peakIndex(ROI,2) = ROI; 
    end

    sortedROIresponsesAfterPeak = zeros(size(mean_responses));
    peakIndex = sortrows(peakIndex);
    for ROI = 1:numROIs
       sortedROIresponsesAfterPeak(ROI,:) = mean_responses(peakIndex(ROI,2),:);
    end

    
    
end % All code for FA plot
subplot_num = 4;
axes(ha(subplot_num)); 
imagesc(normalizeROIsignals(sortedROIresponsesAfterPeak')');
ylabel('False Alarm');
xticks([1 pre_window_size pre_window_size+stim_window_size total_window_size])
xticklabels([round([-pre_window_size/Fs,0,stim_window_size/Fs,((stim_window_size+post_window_size)/Fs)])])
line([pre_window_size,pre_window_size],[0,numROIs+1],'LineWidth',0.5,'Color',[1,1,1]) % Draw stimulus onset line
line([pre_window_size+(stim_window_size)-(0.5*Fs),pre_window_size+(stim_window_size)-(0.5*Fs)],[0,numROIs+1],'LineWidth',0.5,'Color',[.8,.2,.1])   
line([pre_window_size+(stim_window_size),pre_window_size+(stim_window_size)],[0,numROIs+1],'LineWidth',0.5,'Color',[1,1,1]) % Draw stimulus offset line
xlabel('Time (s)');
set(gca,'FontSize',8);










% 
% %-------------------------- PLOT total CS+ and CS- trial peaks
% 
% %--- Sort CS+ and CS- time onsets into two vectors
% CSP = sessionData.daqdata.metadata.CSplus_hertz;
% tone_onset_times = sessionData.daqdata.experiment_data.tone_onset_times;
% 
% if (tone_onset_times(1,1) == CSP)
%     CSpStimOnset = sessionData.daqdata.experiment_data.tone_onset_times(1,2:end);
%     CSmStimOnset = sessionData.daqdata.experiment_data.tone_onset_times(2,2:end);
% else
%     CSpStimOnset = sessionData.daqdata.experiment_data.tone_onset_times(2,2:end);
%     CSmStimOnset = sessionData.daqdata.experiment_data.tone_onset_times(1,2:end);
% end
% 
% %- Plot CS+ trials
% figure(6);
% clf;
% roi_responses_CSP = zeros(length(CSpStimOnset),total_window_size,numROIs);
% mean_responses_CSP = zeros(numROIs,total_window_size);
% for ROI = 1:numROIs
%     for x = 1:length(CSpStimOnset)% skip first trial because of lack in prewindow on early recordings
%         roi_responses_CSP(x,:,ROI) = signals(ROI,CSpStimOnset(x)-pre_window_size:CSpStimOnset(x)+(stim_window_size + post_window_size)-1);
%     end  
%     mean_responses_CSP(ROI,:) = mean(roi_responses_CSP(:,:,ROI));
% end
% 
% peakIndex = zeros(numROIs,2);
% 
% for ROI = 1:numROIs
%     [~, ind] = max(mean_responses_CSP(ROI,:));
%     peakIndex(ROI,1) =ind(1);
%     peakIndex(ROI,2) = ROI; 
% end
% 
% sortedROIresponsesAfterPeak = zeros(size(mean_responses_CSP));
% peakIndex = sortrows(peakIndex);
% for ROI = 1:numROIs
%    sortedROIresponsesAfterPeak(ROI,:) = mean_responses_CSP(peakIndex(ROI,2),:);
% end
% 
% colorbar
% imagesc(normalizeROIsignals(sortedROIresponsesAfterPeak')');
% 
% title('Normalized mean dF/F across all CS+ trials plotted based on ROIs peak','FontSize',10);
% xlabel('Time (seconds)','FontSize',9);
% xticks([1 pre_window_size pre_window_size+stim_window_size total_window_size])
% xticklabels([round([-pre_window_size/Fs,0,stim_window_size/Fs,((stim_window_size+post_window_size)/Fs)])])
% line([pre_window_size,pre_window_size],[0,numROIs+1],'LineWidth',0.5,'Color',[1,1,1]) % Draw stimulus onset line
% line([pre_window_size+(stim_window_size)-(0.5*Fs),pre_window_size+(stim_window_size)-(0.5*Fs)],[0,numROIs+1],'LineWidth',0.5,'Color',[.8,.2,.1])   
% line([pre_window_size+(stim_window_size),pre_window_size+(stim_window_size)],[0,numROIs+1],'LineWidth',0.5,'Color',[1,1,1]) % Draw stimulus offset line
% hold off
% 


end
function plot_trialDependentResponses_ADAA(sessionData)


%---- For each ROI, get the mean response in a window around each CS+ and CS- trials
%-- Initialize variables
Fs = 31;
pre_window_size = 4*Fs; % window size in seconds * sampling frequency of imaging.
stim_window_size = 6*Fs;
post_window_size = 8*Fs;

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


%-----------------------------------------------------------------------------------------------------------
%------- Plot mean respones for each trial sorted with respect to trial onset

% % % Sort CS+ and CS- time onsets into two vectors
% % CSP = sessionData.daqdata.metadata.CSplus_hertz;
% % tone_onset_times = sessionData.daqdata.experiment_data.tone_onset_times;
% % 
% % if (tone_onset_times(1,1) == CSP)
% %     CSpStimOnset = sessionData.daqdata.experiment_data.tone_onset_times(1,2:end);
% %     CSmStimOnset = sessionData.daqdata.experiment_data.tone_onset_times(2,2:end);
% % else
% %     CSpStimOnset = sessionData.daqdata.experiment_data.tone_onset_times(2,2:end);
% %     CSmStimOnset = sessionData.daqdata.experiment_data.tone_onset_times(1,2:end);
% % end
% % 
%--- Sort CS+ and CS- time onsets into two vectors
CSP = sessionData.daqdata.metadata.CSplus_hertz;
CSpIndx = 46;
tone_onset_times = sessionData.daqdata.experiment_data.tone_onset_times;

if (tone_onset_times(1,1) == CSP)
    CSpStimOnset = sessionData.daqdata.experiment_data.tone_onset_times(1,2:end);
    CSmStimOnset = sessionData.daqdata.experiment_data.tone_onset_times(2,2:end);
else
    CSpStimOnset = sessionData.daqdata.experiment_data.tone_onset_times(2,2:end);
    CSmStimOnset = sessionData.daqdata.experiment_data.tone_onset_times(1,2:end);
end

roi_responses_CSP = zeros(length(CSpStimOnset),total_window_size,numROIs);
mean_responses_CSP = zeros(numROIs,total_window_size);
for ROI = 1:numROIs
    for x = 1:length(CSpStimOnset)% skip first trial because of lack in prewindow on early recordings
        roi_responses_CSP(x,:,ROI) = signals(ROI,CSpStimOnset(x)-pre_window_size:CSpStimOnset(x)+(stim_window_size + post_window_size)-1);
    end  
    mean_responses_CSP(ROI,:) = mean(roi_responses_CSP(:,:,ROI));
end

figure(3);
clf;
x = 1;
subplotDimX = 8;
subplotDimY = 8;
CSpOnsetCells = [60 61 89 90 94 97 91 115 118 119 130 136 139 144 146 171 211 212 218 220 241 242 246];
CSpOther = [178 184 253];
CSpOffsetCells = [11 30 31 32 57 63 67 70 79 82 84 122 129 145 168 198 226 227];
%something wrong? 74 51 64
InterestingResponses = sort([60 61 89 90 94 97 118 119 130 146 211 212 218 241 246  30 31 57 63 67 79 82 84 122 129]);
size(InterestingResponses)

for y = 196:260
    subplot(subplotDimX,subplotDimY,x)
    hold on
    roiName = sprintf('ROI %d',y);
    title(roiName,'FontSize',8)
    %colorbar
    imagesc(roi_responses_CSP(:,:,y),[-2,3]);
    xlim([0,total_window_size]);
    ylim([1,CSpIndx-1])
    yticks([1 CSpIndx-1])
    yticklabels([CSpIndx-1 1]);
    % Add "Trial" on left side of plots
    if mod(x,5) == 1
       ylabel('Trial','FontSize',8); 
    end
    
    % Add "Time" on bottom plots
    if x > ((subplotDimY-1)*subplotDimX)
        xlabel('Time (seconds)','FontSize',8);
    end
    
    xticks([1 pre_window_size pre_window_size+stim_window_size total_window_size])
    xticklabels([round([-pre_window_size/Fs,0,stim_window_size/Fs,((stim_window_size+post_window_size)/Fs)])])
    line([pre_window_size,pre_window_size],[0,CSpIndx],'LineWidth',0.5,'Color',[1,1,1]) % Draw stimulus onset line
    line([pre_window_size+(stim_window_size)-(0.5*Fs),pre_window_size+(stim_window_size)-(0.5*Fs)],[0,CSpIndx],'LineWidth',0.5,'Color',[.8,.2,.1])   
    line([pre_window_size+(stim_window_size),pre_window_size+(stim_window_size)],[0,CSpIndx],'LineWidth',0.5,'Color',[1,1,1]) % Draw stimulus offset line
    hold off
    x = x+1;
end

%--------------------------------------------------------------------------


end
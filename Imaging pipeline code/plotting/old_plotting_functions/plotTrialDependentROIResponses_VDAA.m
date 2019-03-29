function plotTrialDependentROIResponses_VDAA(sessionData)
% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% NOW THE PLOTS ARE NORMALIZED WHEN THEY ARE PLOTTED, THUS IT IS NOT THE
% TRUE dF/F!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! PROBLEM?


%---- Detect trial time onsets for CS+ and CS- respectively based on photodiode signal
[gratingDirectionTriggers, dgOnEachDirection] = setGratingDirectionAtPhotoDiodeMeasure(sessionData);
CSP =  sessionData.daqdata.metadata.CSPluss_orientation;
CSM =  sessionData.daqdata.metadata.CSMinus_orientation;

CSpStimOnsets = [];
CSpIndx = 1;
CSmStimOnsets = [];
CSmIndx = 1;

% Find all onset times for each stimulus type
for x = 1:length(gratingDirectionTriggers)
   
    % Add sample index if sample x is onset of CS+
    if gratingDirectionTriggers(x) == CSP
        CSpStimOnsets(CSpIndx) = x;
        CSpIndx = CSpIndx + 1;
    end
    % Add sample index if sample x is onset of CS-
    if gratingDirectionTriggers(x) == CSM
       CSmStimOnsets(CSmIndx) = x;
       CSmIndx = CSmIndx + 1;
    end
    
end


%---- For each ROI, get the mean response in a window around each CS+ and CS- trials
Fs = 31;
pre_window_size = 4*Fs; % window size in seconds * sampling frequency of imaging.
stim_window_size = 4*Fs;
post_window_size = 8*Fs;

total_window_size = pre_window_size + stim_window_size + post_window_size;
tickValuesSamples = [-pre_window_size:0, 1:stim_window_size+post_window_size-1];
tickValuesSeconds = tickValuesSamples/Fs;

%signals = normalizeROIsignals(sessionData.ROIsignals_dFoverF);
%signals = zScoreNormalize(sessionData.ROIsignals_dFoverF);
signals = sessionData.ROIsignals_dFoverF;
numROIs = size(sessionData.ROIsignals_dFoverF,1);


% TEST RANDOMIZE

% ind=randperm(size(signals,2));
% C=zeros(size(signals));
% signalsb=signals(:,ind);
% signals = signalsb;

% %------------------------------------------------------------------------------------------------
% % %----- ALL CS+ CELLS
% roi_responses_CSP = zeros(CSpIndx-1,total_window_size,numROIs);
% 
% for ROI = 1:numROIs
%     
%     for x = 2:length(CSpStimOnsets)% skip first trial because of lack in prewindow on early recordings
%         roi_responses_CSP(x,:,ROI) = signals(ROI,CSpStimOnsets(x)-pre_window_size:CSpStimOnsets(x)+(stim_window_size + post_window_size)-1);
%     end
%     
% end
% 
% figure(3);
% clf;
% x = 1;
% subplotDimX = 5;
% subplotDimY = 5;
% CSpOnsetCells = [60 61 89 90 94 97 91 115 118 119 130 136 139 144 146 171 211 212 218 220 241 242 246];
% CSpOther = [178 184 253];
% CSpOffsetCells = [11 30 31 32 57 63 67 70 79 82 84 122 129 145 168 198 226 227];
% %something wrong? 74 51 64
% InterestingResponses = sort([60 61 89 90 94 97 118 119 130 146 211 212 218 241 246  30 31 57 63 67 79 82 84 122 129]);
% size(InterestingResponses)
% for y = 51:75
%     subplot(subplotDimX,subplotDimY,x)
%     hold on
%     roiName = sprintf('ROI %d',y);
%     title(roiName,'FontSize',8)
%     %colorbar
%     imagesc(roi_responses_CSP(:,:,y),[0,1]);
%     xlim([0,total_window_size]);
%     ylim([1,CSpIndx-1])
%     yticks([1 CSpIndx-1])
%     yticklabels([CSpIndx-1 1]);
%     % Add "Trial" on left side of plots
%     if mod(x,5) == 1
%        ylabel('Trial','FontSize',8); 
%     end
%     
%     % Add "Time" on bottom plots
%     if x > ((subplotDimY-1)*subplotDimX)
%         xlabel('Time (seconds)','FontSize',8);
%     end
%     
%     xticks([1 pre_window_size pre_window_size+stim_window_size total_window_size])
%     xticklabels([round([-pre_window_size/Fs,0,stim_window_size/Fs,((stim_window_size+post_window_size)/Fs)])])
%     line([pre_window_size,pre_window_size],[0,CSpIndx],'LineWidth',0.5,'Color',[1,1,1]) % Draw stimulus onset line
%     line([pre_window_size+(stim_window_size)-(0.5*Fs),pre_window_size+(stim_window_size)-(0.5*Fs)],[0,CSpIndx],'LineWidth',0.5,'Color',[.8,.2,.1])   
%     line([pre_window_size+(stim_window_size),pre_window_size+(stim_window_size)],[0,CSpIndx],'LineWidth',0.5,'Color',[1,1,1]) % Draw stimulus offset line
%     hold off
%     x = x+1;
% end

% %--------------------------------------------------------------------------


% %---------------------------------------------------------------------------------------------
% %---- ALL CS- CELLS
% roi_responses_CSM = zeros(CSmIndx-1,total_window_size,numROIs);
% 
% % Loop through each ROI that is to be plotted
% for ROI = 1:numROIs
%     
%     for x = 2:length(CSmStimOnsets)% skip first trial because of lack in prewindow on early recordings
%         roi_responses_CSM(x,:,ROI) = signals(ROI,CSmStimOnsets(x)-pre_window_size:CSmStimOnsets(x)+(stim_window_size + post_window_size)-1);
%     end
%     
% end
% 
% figure(4);
% clf;
% x = 1;
% subplotDimX = 5;
% subplotDimY = 5;
% 
% CSmOnsetCells = [22 60 65 89 211 222];
% CSmOffsetCells = [28 29 30 31 32 57 63 67 82 102 111 122 168 198 231];
% CSmOther = [26 40 50 52 61 71 74 79 83 86 91 94 99 101 114 115 126 130 154 156 201 206 214 218 225 226 247 251 253];
% % something wrong? 1 13 16 5
% 
% for y = 251:275
%     subplot(subplotDimX,subplotDimY,x)
%     hold on
%     roiName = sprintf('ROI %d',y);
%     title(roiName,'FontSize',8)
%     %colorbar
%     imagesc(roi_responses_CSM(:,:,y));
%     xlim([0,total_window_size]);
%     ylim([1,CSmIndx-1])
%     yticks([1 CSmIndx-1])
%     yticklabels([CSmIndx-1 1]);
%     % Add "Trial" on left side of plots
%     if mod(x,5) == 1
%        ylabel('Trial','FontSize',8); 
%     end
%     
%     % Add "Time" on bottom plots
%     if x > ((subplotDimY-1)*subplotDimX)
%         xlabel('Time (seconds)','FontSize',8);
%     end
%     
%     xticks([1 pre_window_size pre_window_size+stim_window_size total_window_size])
%     xticklabels([round([-pre_window_size/Fs,0,stim_window_size/Fs,((stim_window_size+post_window_size)/Fs)])])
%     line([pre_window_size,pre_window_size],[0,CSmIndx],'LineWidth',0.5,'Color',[1,1,1]) % Draw stimulus onset line
%     line([pre_window_size+(stim_window_size)-(0.5*Fs),pre_window_size+(stim_window_size)-(0.5*Fs)],[0,CSmIndx],'LineWidth',0.5,'Color',[.8,.2,.1])   
%     line([pre_window_size+(stim_window_size),pre_window_size+(stim_window_size)],[0,CSmIndx],'LineWidth',0.5,'Color',[1,1,1]) % Draw stimulus offset line
%     hold off
%     x = x+1;
% end
% 
% %---------------------------------------------------------------------------------------------------------

%-----------------------------------------------------------------------------------------------------------
%------- Plot mean respones for each trial sorted with respect to trial onset

%---------- CS +
figure(6);
clf;
roi_responses_CSP = zeros(CSpIndx-1,total_window_size,numROIs);
mean_responses_CSP = zeros(numROIs,total_window_size);
for ROI = 1:numROIs
    for x = 2:length(CSpStimOnsets)% skip first trial because of lack in prewindow on early recordings
        roi_responses_CSP(x,:,ROI) = signals(ROI,CSpStimOnsets(x)-pre_window_size:CSpStimOnsets(x)+(stim_window_size + post_window_size)-1);
    end  
    mean_responses_CSP(ROI,:) = mean(roi_responses_CSP(:,:,ROI));
end

peakIndex = zeros(numROIs,2);

for ROI = 1:numROIs
   
    [~, ind] = max(mean_responses_CSP(ROI,:));
    peakIndex(ROI,1) =ind(1);
    peakIndex(ROI,2) = ROI;
    
end

sortedROIresponsesAfterPeak = zeros(size(mean_responses_CSP));
peakIndex = sortrows(peakIndex);
for ROI = 1:numROIs
   sortedROIresponsesAfterPeak(ROI,:) = mean_responses_CSP(peakIndex(ROI,2),:);
end
% hold on


%imagesc(sortedROIresponsesAfterPeak,[-1,3]);
colorbar
imagesc(normalizeROIsignals(sortedROIresponsesAfterPeak')');



title('Normalized mean dF/F across all CS+ trials plotted based on ROIs peak','FontSize',10);
xlabel('Time (seconds)','FontSize',9);
xticks([1 pre_window_size pre_window_size+stim_window_size total_window_size])
xticklabels([round([-pre_window_size/Fs,0,stim_window_size/Fs,((stim_window_size+post_window_size)/Fs)])])
line([pre_window_size,pre_window_size],[0,numROIs+1],'LineWidth',0.5,'Color',[1,1,1]) % Draw stimulus onset line
line([pre_window_size+(stim_window_size)-(0.5*Fs),pre_window_size+(stim_window_size)-(0.5*Fs)],[0,numROIs+1],'LineWidth',0.5,'Color',[.8,.2,.1])   
line([pre_window_size+(stim_window_size),pre_window_size+(stim_window_size)],[0,numROIs+1],'LineWidth',0.5,'Color',[1,1,1]) % Draw stimulus offset line
hold off




end
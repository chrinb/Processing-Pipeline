function plotDriftingGratingROIsignals(sessionData)

gratingOnsetTimes = sessionData.daqdata.gratingTypeOnsetTimes; %dgTrialOnsetTimes;
preWindowSize = 60;
plotX = 5;
plotY = 5;
plotIndx = 0;
for ROInum = 126:150
plotIndx = plotIndx+1;
stimResp = [];

for grat_orient_trial = 1:8
allTrialWindows = [];
stimulusWindowResponses =[];
preStimWindowResponses = [];

for repeat = 2:length(gratingOnsetTimes(grat_orient_trial,:))
    curr_onset = gratingOnsetTimes(grat_orient_trial,repeat);
    if gratingOnsetTimes(grat_orient_trial,repeat) <  preWindowSize
        %fprintf('%d was skipped because of short prewindow size',x);
    elseif (gratingOnsetTimes(grat_orient_trial,repeat) + preWindowSize) > length(sessionData.daqdata.run_speed)
        %fprintf('%d was skipped because of too long postwindow size',x);
    else
        currentROI = sessionData.normalizedROIsignals(:,ROInum);
        stimulusResponse = currentROI(curr_onset:curr_onset+123);
        preStimulusResponse = currentROI(curr_onset-preWindowSize:curr_onset-1);
        toPlot = currentROI(curr_onset-preWindowSize:gratingOnsetTimes(grat_orient_trial,repeat)+180);
        allTrialWindows(end+1,:) = toPlot;
        stimulusWindowResponses(end+1,:) = stimulusResponse;
        preStimWindowResponses(end+1,:) = preStimulusResponse;
    end
end

stimulusResponsesSubtractedBaseline = [];
for i = 1:size(stimulusWindowResponses,1)
   
    stimulusResponsesSubtractedBaseline(i) = mean(stimulusWindowResponses(i,:)) - mean(preStimWindowResponses(i,:));
    
end

    stimResp(grat_orient_trial) = mean(stimulusResponsesSubtractedBaseline);
end

% Plot tuning curve
subplot(plotX,plotY,plotIndx);
hold on
plot(stimResp);
ylim([-10,40]);
title(ROInum);
%xticklabels(sessionData.daqdata.gratingTypeOnsetTimes(:,1))
xticks([1:8]);
%xlabel('Drifting grating orientation')
hold off
end

end
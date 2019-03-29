function plotDriftingGratingRunSpeed(sessionData)

gratingOnsetTimes = sessionData.daqdata.dgTrialOnsetTimes;

preWindowSize = 60;

for y = 1:8
figure(y);
allTrialWindows = [];
hold on

for x = 2:length(gratingOnsetTimes(y,:))
    curr_onset = gratingOnsetTimes(y,x);
    if gratingOnsetTimes(y,x) <  preWindowSize
        fprintf('%d was skipped because of short prewindow size',x);
    elseif (gratingOnsetTimes(y,x) + preWindowSize) > length(sessionData.daqdata.run_speed)
        fprintf('%d was skipped because of too long postwindow size',x);
    else
        
        toPlot = sessionData.daqdata.run_speed(curr_onset-preWindowSize:gratingOnsetTimes(y,x)+180);
        allTrialWindows(end+1,:) = toPlot;
        plot(toPlot,'k');
        
    end
  
end

full_window_size = zeros(preWindowSize+180);
full_window_size(preWindowSize+1:123) = 200;
plot(full_window_size);
plot(mean(allTrialWindows),'r')
ylim([0,50]);
text(230,47,num2str(gratingOnsetTimes(y,1)))
ylabel('Speed (cm/s)');

hold off


end
end
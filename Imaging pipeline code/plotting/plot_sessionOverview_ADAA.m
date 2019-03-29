function plot_sessionOverview_ADAA(sessionData)
% PLOT_SESSIONOVERVIEW_ADAA plots an overview images for Auditory
% Discriminoatory Active Avoidance (ADAA) tasks.
%
% Input
%   sessionData: common data struct containing all data related to the
%       session.
%
% Written by AL

%--- Initialize variables
signals = sessionData.ROIsignals_dFoverF_zScored;

numROIs = size(signals,1);
start = 1;
stop = 3800;%length(signals);
sample_times = (1:stop)/31;

%--- Plot overview figure
figure(10);
clf;
[ha, pos] = tight_subplot(3,1); 

% Plot ROIs
subplot_num = 1;
axes(ha(subplot_num)); 
imagesc(signals(:,start:stop),[-2,3]);
xlim([1,length(sample_times)]);
xticks([]);
ylabel('ROI','FontSize',8);
sessionID = sessionData.daqdata.metadata.sessionID;
sessionID = strrep(sessionID,'_','-');
title(['Session: ',sessionID],'FontSize',9);
set(gca,'FontSize',8);
%title('ROIs','FontSize',8);

% Plot stimuli type onsets
subplot_num = 3;
axes(ha(subplot_num)); 
set(ha(subplot_num),'XTickLabelMode','auto');
set(gca,'FontSize',8);
hold on
xlim([1,sample_times(end)]);
ylim([0.5,1])
yticks([]);
ylabel('Stimulus type');
xlabel('Time (s)','FontSize',8);

plot(sample_times,sessionData.daqdata.experiment_data.tone_onset_csplus(start:stop),'r');
plot(sample_times,sessionData.daqdata.experiment_data.tone_onset_csminus(start:stop),'g');

% Plot running speed
subplot_num = 2;
axes(ha(subplot_num)); 
set(gca,'FontSize',8);
hold on
plot(sample_times,sessionData.daqdata.run_speed(start:stop));
ylabel('Speed cm/s');
%yticklabels([1,max(sessionData.daqdata.run_speed(start:stop))]);
xlim([1,sample_times(end)]);
end
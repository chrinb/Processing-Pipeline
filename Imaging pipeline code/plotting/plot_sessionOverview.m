function plot_sessionOverview(sessionData)
% PLOT_SESSIONOVERVIEW plots overview of the experiment dependent on which
% experiment type which is used. This requires Experiment_type to be
% defined in the sessionData struct. Also, the experiment type must be
% added as a case in this function.
%
% Input
%   sessionData: common data struct containing all data related to the
%       session.
%
% Written by AL




%--- Plotting parameters
imagesc_low_threshold = 0;
imagesc_upper_threshold = 4;

%--- Initialize variables
signals = sessionData.ROIsignals_dFoverF_zScored(20:80,:);
numROIs = size(signals,1);
%%%sample_times = (1:stop)/31;

%-- Plot different overview dependent on the experiment 
exp_type = sessionData.daqdata.metadata.Experiment_type;

%-- Auditory experiments
if (strcmp(exp_type,'ADAA') || strcmp(exp_type,'ADAAT') || strcmp(exp_type,'PreADAA') || strcmp(exp_type,'PreADAAT'))
    %--- Plot overview figure
    figure(10);
    clf;
    [ha, pos] = tight_subplot(3,1); 

    % Plot ROIs
    subplot_num = 1;
    axes(ha(subplot_num)); 
    imagesc(signals,[imagesc_low_threshold,imagesc_upper_threshold]);
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

    ylim([0.5,1])
    yticks([]);
    ylabel('Stimulus type');
    xlabel('Time (s)','FontSize',8);
    tone_csp = downsample(sessionData.daqdata.experiment_data.tone_onset_csplus,4);
    tone_csm = downsample(sessionData.daqdata.experiment_data.tone_onset_csminus,4);
    plot(tone_csp,'r');
    plot(tone_csm,'g');

    % Plot running speed
    subplot_num = 2;
    axes(ha(subplot_num)); 
    set(gca,'FontSize',8);
    hold on
    run_data = sessionData.daqdata.run_speed;
    plot(run_data(start:stop));
    ylabel('Speed cm/s');
    %yticklabels([1,max(sessionData.daqdata.run_speed(start:stop))]);

    %ylim([0,0.05]);
 
    
%-- CSD experiment
elseif strcmp(exp_type,'CSD')

    %--- Plot overview figure
    figure(10);
    clf;
    [ha, pos] = tight_subplot(3,1); 

    % Plot ROIs
    subplot_num = 1;
    axes(ha(subplot_num)); 
    imagesc(signals,[imagesc_low_threshold,imagesc_upper_threshold]);
    xticks([]);
    ylabel('ROI','FontSize',8);
    sessionID = sessionData.daqdata.metadata.sessionID;
    sessionID = strrep(sessionID,'_','-');
    title(['Session: ',sessionID],'FontSize',9);
    set(gca,'FontSize',8);
    %title('ROIs','FontSize',8);

    % Plot stimuli type onsets
    [drifting_grating_onset,drifting_grating_onset_times] = preprocess_findAllDriftingGratingOnsetTimes(sessionData);
    subplot_num = 2;
    axes(ha(subplot_num)); 
    set(gca,'FontSize',8);
    hold on
    xlim([1,length(drifting_grating_onset)])
    plot(drifting_grating_onset);
    
 
    % Plot running speed
    subplot_num = 3;
    axes(ha(subplot_num)); 
    set(gca,'FontSize',8);
    hold on
    run_data = sessionData.daqdata.run_speed;
    plot(run_data);
    %ylabel('Speed cm/s');
    yticklabels([1, max(sessionData.daqdata.run_speed)]);

    %ylim([0,0.05]);
    
    
%-- FREE run experiment
else
       %--- Plot overview figure
    figure(10);
    clf;
    [ha, pos] = tight_subplot(2,1); 

    % Plot ROIs
    subplot_num = 1;
    axes(ha(subplot_num)); 
    imagesc(signals(:,start:stop),[imagesc_low_threshold,imagesc_upper_threshold]);
    xlim([1,stop-start]);
    xticks([]);
    ylabel('ROI','FontSize',8);
    sessionID = sessionData.daqdata.metadata.sessionID;
    sessionID = strrep(sessionID,'_','-');
    title(['Session: ',sessionID],'FontSize',9);
    set(gca,'FontSize',8);
    %title('ROIs','FontSize',8);

    % Plot running speed
    subplot_num = 2;
    axes(ha(subplot_num)); 
    set(gca,'FontSize',8);
    hold on
    run_data = sessionData.daqdata.run_speed;
    plot(run_data(start:stop));
    ylabel('Speed cm/s');
    %yticklabels([1,max(sessionData.daqdata.run_speed(start:stop))]);
    xlim([1,stop-start]);
    %ylim([0,0.05]);
    
end
end
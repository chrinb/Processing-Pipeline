function plot_tuningCurvesDriftingGratings(sessionData)

% Get onset times for each drifting grating direction
[drifting_grating_onset,drifting_grating_onset_times] = preprocess_findAllDriftingGratingOnsetTimes(sessionData);
number_of_trials = size(drifting_grating_onset_times,2)-1;

fs = 1000;

pre_window_size = 3*fs;
stim_window_size = 4*fs;
post_window_size = 3*fs;

signal = [];
% Upsample values for ROI signal
for x = 1:size(sessionData.ROIsignals_dFoverF_zScored,1)
    count = 1;
    for y = 1:size(sessionData.ROIsignals_dFoverF_zScored,2)
    
        signal(x,count:count+3) = sessionData.ROIsignals_dFoverF(x,y);
        count = count+4;
    end
end

for direction = 1

for trial = 2:size(drifting_grating_onset_times,2)
    samp_window_start = drifting_grating_onset_times(direction,trial)-pre_window_size;
    samp_window_end = drifting_grating_onset_times(direction,trial)+stim_window_size+post_window_size;
    start_imaging_frame = sessionData.daqdata.frame_onset_reference_frame(samp_window_start);
    end_imaging_frame = sessionData.daqdata.frame_onset_reference_frame(samp_window_end);
    current_sample = signal(:,start_imaging_frame:end_imaging_frame);
    if trial==2
        direction_sample = zeros(size(current_sample));
    else
      if size(current_sample,2) == size(direction_sample)
      else
          diff = size(direction_sample,2)-size(current_sample,2);
          if isempty(diff(diff>0))
              current_sample = current_sample(:,1:end-abs(diff));
          else
              for xx = 1:diff
                 current_sample(:,end+xx) = current_sample(:,end); 
              end
          end
      end
    end
    
    direction_sample = direction_sample + current_sample;

 
end
mean_samp = direction_sample/number_of_trials;
figure(direction);
imagesc(mean_samp,[0,2]);
end
% 
% fs = 31;
% pre_window_size = 3*fs;
% stim_window_size = 4*fs + pre_window_size;
% post_window_size = 3*fs;
% 
% for x = 141:180
% figure(4);
% plot(mean_samp(x,:))
% ylim([0,2]);
% title(x);
% line([pre_window_size,pre_window_size],[-3,3]);
% line([stim_window_size,stim_window_size],[-3,3]);
% pause(2)
% end
% 
% 
% 
% hold off
% 
% a = 1;
% 

ROI = 1;




end
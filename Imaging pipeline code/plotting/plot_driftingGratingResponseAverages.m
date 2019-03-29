function plot_driftingGratingResponseAverages(sessionData)

%-- Parameters
fs = sessionData.daqdata.metadata.Sampling_rate_downsampled;
run_speed = sessionData.daqdata.run_speed;
signal_dFoverF = sessionData.ROIsignals_dFoverF;
num_planes = sessionData.imaging_metadata.number_of_planes;
piezo_active = sessionData.imaging_metadata.piezo_active;
frame_onsets = sessionData.daqdata.frame_onset;
photodiode_signal = sessionData.daqdata.photodiode_filtered;

%-- Upsample imaging data if piezo is used
if piezo_active 
    signal = preprocess_upsampleSignalsToClock(signal_dFoverF,num_planes);
else
    signal = signal_dFoverF;
end

%-- Downsample runspeed to the frame clock for imaging
run_speed_downsampled = preprocess_downsampleSignalToClock(run_speed,frame_onsets);

%-- Get DG onset times after the photodiode signal is downsampled to 2P frame clock speed
[~,drifting_grating_onset_times] = preprocess_findAllDriftingGratingOnsetTimes(sessionData,preprocess_downsampleSignalToClock(photodiode_signal,frame_onsets));
number_of_trials = size(drifting_grating_onset_times,2)-1;

fs = round(sessionData.imaging_metadata.frames_per_sec);
pre_window_size = 2*fs;
stim_window_size = 4*fs;
post_window_size = 2*fs;

for direction = 1

    for trial = 2:size(drifting_grating_onset_times,2)
        start_imaging_frame = drifting_grating_onset_times(direction,trial)-pre_window_size;
        end_imaging_frame = drifting_grating_onset_times(direction,trial)+stim_window_size+post_window_size;
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
    
end






end
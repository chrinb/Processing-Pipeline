function RUN_periods = detect_RUN_periods(sessionData)

%-- Set parameters
fs = sessionData.daqdata.metadata.Sampling_rate_downsampled;
run_speed = sessionData.daqdata.run_speed;

%-- Upsample values for ROI signal to fit 2p clock
signal = [];
for x = 1:size(sessionData.ROIsignals_dFoverF_zScored,1)
    count = 1;
    for y = 1:size(sessionData.ROIsignals_dFoverF_zScored,2)
        signal(x,count:count+3) = sessionData.ROIsignals_dFoverF(x,y);
        count = count+4;
    end
end

%-- Downsample runspeed to the frame clock for imaging
down_sampled_frame_ref = [];
indx = 1;
for y = 1:length(sessionData.daqdata.frame_onset)
    if sessionData.daqdata.frame_onset(y) == 1
        down_sampled_frame_ref(indx) = y;
        indx = indx+1;
    end
end
signal(signal<0) = 0;
new_run_speed = [];
for t = 1:length(down_sampled_frame_ref)
   new_run_speed(t) = run_speed(down_sampled_frame_ref(t)); 
end

run_speed = new_run_speed;

%-- Find movement onsets
no_movement = zeros(size(run_speed)); % movement =<0.1 cm/s
movement = zeros(size(run_speed)); % 0.1 cm/s < movement =< 1cm/s
run = zeros(size(run_speed)); % movement > 1cm/s


for x = 1:length(run_speed)
   if run_speed(x) <= 0.1
       no_movement(x) = 1;
   elseif run_speed(x) <= 1
       movement(x) = 1;
   else
       run(x) = 1;
   end
end

%-- For each ROI, get modulation value
num_ROIs = size(signal,1);
run_responses = [];
run_count = 1;
no_movement_responses = [];
no_movement_count = 1;
responses = zeros(num_ROIs,3);

for x = 1:num_ROIs
    run_responses = [];
    run_count = 1;
    no_movement_responses = [];
    no_movement_count = 1;
   for y = 1:length(run)
       % Run
       if run(y) ==1
           run_responses(run_count) = signal(x,y);
           run_count = run_count+1;
           
       % No movement
       elseif no_movement(y) == 1
          no_movement_responses(no_movement_count) = signal(x,y);
          no_movement_count = no_movement_count + 1;
       end
   end
    responses(x,1) = mean(run_responses);
    responses(x,2) = mean(no_movement_responses);

end


indx_count = 1;

figure(10);
subplot(2,1,1)
plot(signal(651,:));
subplot(2,1,2)
plot(run_speed);


%-- Plot response index histogram
figure(22);
hist(responses(:,1)./responses(:,2),100);
roi_ratios = zeros(1,length(responses(:,1)));
roi_ratios(1,:) = responses(:,1)./responses(:,2);

[roi_ratios_sorted, sort_index] = sortrows(roi_ratios');
roi_ratios_sorted = roi_ratios_sorted';
sort_index = sort_index';

run_modulated_rois = roi_ratios_sorted>1.5;
run_modulated_rois = sort_index(run_modulated_rois);


% %% Detect visual stimulus modulation
% 
% % Downsample photodiode signal to fit imaging clock
% photodiode = sessionData.daqdata.photodiode_filtered;
% new_photodiode_signal = [];
% for t = 1:length(down_sampled_frame_ref)
%    new_photodiode_signal(t) = photodiode(down_sampled_frame_ref(t)); 
% end
% 
% %-- For each ROI, get modulation value for photodiode
% num_ROIs = size(signal,1);
% stim_responses = [];
% stim_count = 1;
% nostim_responses = [];
% nostim_count = 1;
% responses = zeros(num_ROIs,2);
% 
% for x = 1:num_ROIs
%     stim_responses = [];
%     stim_count = 1;
%     nostim_responses = [];
%     nostim_count = 1;
%    for y = 1:length(run)
%        % stimulus on
%        if new_photodiode_signal(y) ==1
%            stim_responses(stim_count) = signal(x,y);
%            stim_count = stim_count+1;
%            
%        % No stim
%        else
%           nostim_responses(nostim_count) = signal(x,y);
%           nostim_count = nostim_count + 1;
%        end
%    end
%     responses(x,1) = mean(stim_responses);
%     responses(x,2) = mean(nostim_responses);
% 
% end
% hist(responses(:,1)./responses(:,2),100);
% 
% figure;
% subplot(2,1,1)
% plot(signal(551,:))
% subplot(2,1,2)
% plot(new_photodiode_signal);



end

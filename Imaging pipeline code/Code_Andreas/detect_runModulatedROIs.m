function run_modulated_rois = detect_runModulatedROIs(sessionData)

%-- Set parameters
modulation_threshold = 100; % Indicates the % increase in dF/F for running compared to no movement. This is the threshold used to select if a cell is running modulated or not.

fs = sessionData.daqdata.metadata.Sampling_rate_downsampled;
run_speed = sessionData.daqdata.run_speed;

%-- Upsample imaging data if piezo is used
if sessionData.imaging_metadata.piezo_active 
    signal = preprocess_upsampleSignalsToClock(sessionData.ROI_signals_dFoverF,sessionData.imaging_metadata.number_of_planes);
else
    signal = sessionData.ROIsignals_dFoverF;
end

%-- Downsample runspeed to the frame clock for imaging
run_speed_downsampled = preprocess_downsampleSignalToClock(sessionData.daqdata.run_speed,sessionData.daqdata.frame_onset);

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
num_ROIs = size(signal,1)-1;
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
    
   for y = 1:min(length(signal),length(run))
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

converted_modulation_threshold = (modulation_threshold/100)+1;

%-- Plot response index histogram
figure(23);
max_num = hist(responses(:,1)./responses(:,2),100);
hist(responses(:,1)./responses(:,2),100);
h = findobj(gca,'Type','patch');
h.FaceColor = [0.6 0.6 0.6];
h.EdgeColor = 'k';
ylabel('Number of ROIs');
xlabel('Run modulation index (% difference in dF/F for running compared with no movement)');
tick_values = xticklabels;
new_tick_values = [];
for x = 1:length(tick_values)
    new_tick_values(x) = (str2num(tick_values{x})-1)*100;
end

xticklabels(new_tick_values);

line([converted_modulation_threshold,converted_modulation_threshold],[0,max(max_num)])
roi_ratios = zeros(1,length(responses(:,1)));
roi_ratios(1,:) = responses(:,1)./responses(:,2);

[roi_ratios_sorted, sort_index] = sortrows(roi_ratios');
roi_ratios_sorted = roi_ratios_sorted';
sort_index = sort_index';
run_modulated_rois = roi_ratios_sorted>converted_modulation_threshold;
run_modulated_rois = sort_index(run_modulated_rois);

%-- Plot the most run modulated ROI
figure;
title('Most run modulated ROI');
subplot(2,1,1)
plot(signal(run_modulated_rois(end),:)); 
subplot(2,1,2)
plot(run_speed_downsampled);


%-- Print summary
fprintf('%.2f percent of cells (%i/%i) show at least a %i percent increase in dF/F during running compared to no movement.\n',(length(run_modulated_rois)/num_ROIs)*100,length(run_modulated_rois),num_ROIs,modulation_threshold);


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
% % 

end

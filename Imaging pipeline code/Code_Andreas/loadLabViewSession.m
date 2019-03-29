function daqdata = loadLabViewSession(sessionID)
% loadLabViewSession gets all data obtained from the DAQ during the
% experiment. This includes for instance the photo diode signal, clock
% signal from 2P microscope and every other output/input carried out.
% Because of the diversity in experiments, this function allow loading
% different subfeatures and therefor treat the input differently if the
% experiment session is a visual active avoidance task, a auditory
% discriminatory active avoidance task or a pure drifting grating
% experiment.
%
% Input
%   sessionID: The session ID for the experiment. This is used throughout
%   and it is therefor important that the folder structure is in compliance
%   with the sessionID nomenclature.
% Output
%   daqdata: a struct containing all the related data obtained in the
%   labview VI running during the experiment. 
%
% Written by AL

% Locate labview session folder
sessionFolder = getSessionFolder(sessionID);
labviewFolder = fullfile(sessionFolder, 'labview_data');
blockFolder = dir(fullfile(labviewFolder, '*labview*'));
labviewFolder = fullfile(labviewFolder, blockFolder(1).name);

% Does a .mat file exist in the session folder? If so, skip this process.
% The .mta file is created as a result of this code, and this is
% thus a way of detecting if it has already been executed and can be
% skipped.

found = 0;
mat_file_name = [sessionID '-processed_setup_data.mat'];
files_found = dir(labviewFolder);

for x = 1:length(files_found) % Look through folder
    if strcmp(files_found(x).name,mat_file_name)
       found = 1; 
       answ = inputdlg('A .mat file has been detecting, indicating that you have already extracted data from this session. Do you still want to re-run this? Type Y to re-run, type N to skip');
       % Allow user to rerun or not
       if strcmpi(answ{1},'y')
            found = 0;
       end
       
    end   
end

if found == 0
   extractedTDMS = extractLabViewTDMS_originalFs(sessionID); 

    %------ Create struct and fetch metadata
    daqdata = struct();
    daqdata.metadata = extractedTDMS.metadata;
    daqdata.metadata.sessionID = sessionID;
    daqdata.metadata.session_num = sessionID(end-2:end);
    daqdata.metadata.mouse_num = sessionID(2:5);

    %-- Get running wheel data
    daqdata.sample_index = extractedTDMS.sample_index;
    daqdata.run_speed_low_fs = extractedTDMS.run_speed;
    [run_speed,wheel_movement] = preprocess_estimateRunningSpeed(extractedTDMS.wheel_count,daqdata.metadata.Sampling_rate_downsampled);
    daqdata.run_speed = run_speed;
    daqdata.wheel_movement = wheel_movement;
    
    %-- Get Frame signal
    if isfield(extractedTDMS,'frame_onset')
        daqdata.frame_onset = extractedTDMS.frame_onset;

        % Make an accumulative vector containing the imaging frame number
        % at each frame onset
        frame_onset_reference_frame = zeros(1,length(daqdata.frame_onset));
        count = 1;
        for z = 1:length(daqdata.frame_onset)
           if daqdata.frame_onset(z) == 1
               frame_onset_reference_frame(z) = count;
               count = count+1;
           end
        end

        % Find closes frame to all 
        frame_onset_closest = zeros(1,length(daqdata.frame_onset));
        distance = bwdist(frame_onset_reference_frame);
        distance = distance.*([0 diff(distance)]);
        for z = 1:length(distance)
            frame_onset_closest(z) = frame_onset_reference_frame(z-distance(z));
            if frame_onset_closest(z) == 0
               frame_onset_closest(z) = frame_onset_closest(z-1);
            end
        end

        daqdata.frame_onset_reference_frame = frame_onset_closest;  
    end
    
    %-- Get Photodiode signal
    if isfield(extractedTDMS,'photoDiode')
        daqdata.photodiode_raw = extractedTDMS.photoDiode;
        daqdata.photodiode_filtered = extractedTDMS.filtered_pdSignal;
    end
    
    %-- Get Tone onset
    if isfield(extractedTDMS,'tone_onset')
        daqdata.tone_onset = extractedTDMS.tone_onset;
    end
    
    %-- Get Raw speaker signal
    if isfield(extractedTDMS,'speaker_signal')
        daqdata.speaker_signal_raw = extractedTDMS.speaker_signal;
    end
    
    %-- Get Shock signal
    if isfield(extractedTDMS,'shock_signal')
        daqdata.shock_signal = extractedTDMS.shock_signal;
    end
    
    %-- Get LFP signal
    if isfield(extractedTDMS,'LFP_signal_raw')
        daqdata.LFP_signal_raw = extractedTDMS.LFP_signal_raw;
    end
    
    %--- Get trials (depending on the experiment type)
    exp_type = daqdata.metadata.Experiment_type;
    trialDataFile =  dir(fullfile(labviewFolder, '*trials.txt'));
    if isempty(trialDataFile) % skip loading
    else % load file
        trialData = importTrialfile([labviewFolder '\' trialDataFile(1).name]);

        %-- For ADAA experiments
        if strcmp(exp_type,'ADAA') 
            daqdata.experiment_data.stimulus_type = trialData(1,:);
            daqdata.experiment_data.trial_response_corr_or_false = trialData(2,:);
            daqdata.experiment_data.trial_response_type = trialData(3,:);
            daqdata.experiment_data.trial_performance_percent = trialData(4,:);
            daqdata.experiment_data.dPrime = trialData(5,:);
            daqdata.experiment_data.ITI_delay_time = trialData(6,:);
            daqdata.experiment_data.stimulus_trigger_time = trialData(7,:);

        elseif strcmp(exp_type, 'PreADAA') % THIS IS THE OLD STRUCTURE OF PREADAA
            daqdata.experiment_data.stimulus_type = trialData(1,:);
            
        elseif strcmp(exp_type, 'AAA') % THIS IS THE OLD STRUCTURE OF PREADAA
            daqdata.experiment_data.stimulus_type = trialData(1,:);
            daqdata.experiment_data.trial_response_type = trialData(3,:);
            daqdata.experiment_data.trial_performance_percent = trialData(4,:);
            daqdata.experiment_data.dPrime = trialData(5,:);
            daqdata.experiment_data.ITI_delay_time = trialData(6,:);
            daqdata.experiment_data.stimulus_trigger_time = trialData(7,:);

        %-- For ADAAT experiments    
        elseif strcmp(exp_type,'ADAAT')
            daqdata.experiment_data.stimulus_type = trialData(1,:);
            daqdata.experiment_data.trial_response_corr_or_false = trialData(2,:);
            daqdata.experiment_data.trial_response_type = trialData(3,:);
            daqdata.experiment_data.trial_performance_percent = trialData(4,:);
            daqdata.experiment_data.dPrime = trialData(5,:);
            daqdata.experiment_data.delay_time = trialData(6,:);
            daqdata.experiment_data.stimulus_trigger_time = trialData(7,:);

        elseif strcmp(exp_type, 'PreADAAT')
            daqdata.experiment_data.stimulus_type = trialData(1,:);
            daqdata.experiment_data.trial_response_corr_or_false = trialData(2,:);
            daqdata.experiment_data.trial_response_type = trialData(3,:);
            daqdata.experiment_data.trial_performance_percent = trialData(4,:);
            daqdata.experiment_data.dPrime = trialData(5,:);
            daqdata.experiment_data.delay_time = trialData(6,:);
            daqdata.experiment_data.stimulus_trigger_time = trialData(7,:);

        %-- For Solveigs CSD experiment
        elseif strcmp(exp_type,'CSD')
            daqdata.experiment_data.grating_direction = trialData(1,:);
            
        %-- For plain DG type experiment
        elseif strcmp(exp_type,'DG')
            daqdata.experiment_data.grating_direction = trialData(1,:);

        %-- For VDAA experiments
        elseif strcmp(exp_type, 'VDAA')

        %-- For VAA experiments
        elseif strcmp(exp_type, 'VAA')
            daqdata.experiment_data.grating_direction = trialData(1,:);

        %-- For FREE running experiments
        elseif strcmp(exp_type,'FREE')

        %-- If non of the above experiments are detected
        else
            warning('The loaded experiment contains an experiment type not known in the loadLabViewSession function');
        end
    end

end

end

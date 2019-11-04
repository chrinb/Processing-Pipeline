function daqdata = loadLabViewTDMS(sessionID)
% loadLabViewTDMS gets all data obtained from the DAQ during the
% experiment. This includes for instance the photo diode signal, clock
% signal from 2P microscope and every other output/input carried out.
% NB! If you add new acquisition channels in labview, you must specify the
% channels name in this function.
%
% Input
%   sessionID: The session ID for the experiment. This is used throughout
%   and it is therefor important that the folder structure is in compliance
%   with the sessionID nomenclature.
% Output
%   daqdata: a struct containing all the related data obtained in the
%   labview VI running during the experiment. 
%
% Written by Andreas Lande and Eivind Hennestad

% Locate labview session folder
sessionFolder = getSessionFolder(sessionID);
labviewFolder = fullfile(sessionFolder, 'labview_data');
blockFolder = dir(fullfile(labviewFolder, '*labview*'));
labviewFolder = fullfile(labviewFolder, blockFolder(1).name);

mat_file_name = [sessionID '-processed_setup_data.mat'];
files_found = dir(labviewFolder);

% Extract daqdata from TDMS file
daqdata = extractLabViewTDMS_originalFs(sessionID);

% Add metadata
% daqdata.metadata.sessionID = sessionID;
% daqdata.metadata.session_num = sessionID(end-2:end);
% daqdata.metadata.mouse_num = sessionID(2:5);


% Estimate running speed
try
    [daqdata.run_speed] = preprocess_estimateRunningSpeed(daqdata.wheel_count,daqdata.metadata.Sampling_rate_downsampled,sessionID);
end

% Make reference for each index to the current frame if imaging session
if isfield(daqdata,'frame_onset')

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

%-- Get trial data (optional; if you have a trials.txt file)
try
    daqdata = pipe_loadTrialData(daqdata,labviewFolder);
end

end

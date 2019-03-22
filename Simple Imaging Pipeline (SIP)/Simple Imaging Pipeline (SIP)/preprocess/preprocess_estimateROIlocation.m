function sessionData = preprocess_estimateROIlocation(sessionData,roidata_sorted_by_plane)
% PREPROCESS_ESTIMATEROILOCATION is applicable for volume imaging
% using the piezo. The function use a lookup table to estimate the true
% movement pattern of the piezo for a given seting and use this to further
% infere the depth of each ROI. The function requires imaging_depth_upper
% and imaging_depth_lower to be set in mouse.daqdata.metadata. If it is
% detected that the piezo is not used, the estimated_depth_z is set to be
% equal to the imaging_depth_upper value.
%
% Input
%   sessionData: struct containing the session data
%   session_number: session_number for the given session that is involved.
%   roidata_sorted_by_plane: a struct containing both the ROIs for each
%       plane and the related plane id number.
%
% Output
%   sessionData: struct containing the session data
%
% Written by AL.

%-- Validate that the imaging depths correspond between user entered value in the labview software and what is stored by the 2P microscope.
if isfield(sessionData.daqdata.metadata,'imaging_depth_upper')
        if sessionData.daqdata.metadata.imaging_depth_upper == 0
           sessionData.daqdata.metadata.imaging_depth_upper = inputdlg('Imaging depth upper does not exist for this session. Enter the correct value'); 
        end
    else
        sessionData.daqdata.metadata.imaging_depth_upper = inputdlg('Imaging depth upper does not exist for this session. Enter the correct value (If using the piezo, this value is the most superficial depth used in the recording):'); 
end

if sessionData.imaging_metadata.piezo_active
    if isfield(sessionData.daqdata.metadata,'imaging_depth_lower')
        if sessionData.daqdata.metadata.imaging_depth_lower == 0
            sessionData.daqdata.metadata.imaging_depth_lower = inputdlg('Imaging depth lower does not exist for this session. Enter the correct value');
        end
    else
        sessionData(session_number).daqdata.metadata.imaging_depth_lower = inputdlg('Imaging depth lower does not exist for this session. Enter the correct value (If this recording only used 1 plane (i.e. no piezo) put 0):');
    end
    
end

%-- If piezo is active 
if sessionData.imaging_metadata.piezo_active
    %-- Check that the z step size for volume imaging is correctly reported by user and the 2P microscope.
    imagingdata_z_depth = sessionData.imaging_metadata.z_depth_ym;
    reported_z_depth = sessionData.daqdata.metadata.imaging_depth_lower - sessionData.daqdata.metadata.imaging_depth_upper;

    if ~(imagingdata_z_depth == reported_z_depth) % Reported and detected z_depth for piezo does not match
       quest = sprintf('OBS: The piezo volume imaging z step reported by the 2P microscope does not match the reported z step. 2P says: %i, you say: %i. What is correct? Type 0 if none is correct.',imagingdata_z_depth,reported_z_depth); 
        z_step_size = inputdlg(quest);
    else
        z_step_size = imagingdata_z_depth;
    end
   
    % ESTIMATE THE DEPTH BASED ON THE LOOKUP TABLE
    
%-- No piezo, just set z depth as the imaging_upper value
else 
    imaging_depth = sessionData.daqdata.metadata.imaging_depth_upper;
    for x = 1:length(sessionData.ROI_metadata)
        sessionData.ROI_metadata(x).estimated_location_z = imaging_depth;
    end
end


end
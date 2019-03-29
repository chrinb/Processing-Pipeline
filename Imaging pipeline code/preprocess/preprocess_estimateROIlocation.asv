function mousedata = preprocess_estimateROIlocation(mousedata,session_number,roidata_sorted_by_plane)
% PREPROCESS_ESTIMATEROILOCATION is applicable for volume imaging
% using the piezo. The function use a lookup table to estimate the true
% movement pattern of the piezo for a given seting and use this to further
% infere the depth of each ROI. The function requires imaging_depth_upper
% and imaging_depth_lower to be set in mouse.daqdata.metadata. If it is
% detected that the piezo is not used, the estimated_depth_z is set to be
% equal to the imaging_depth_upper value.
%
% Input
%   mousedata: struct for mousedata
%   session_number: session_number for the given session that is involved.
%   roidata_sorted_by_plane: a struct containing both the ROIs for each
%       plane and the related plane id number.
%
% Output
%   mousedata: struct for mousedata
%
% Written by AL.


%-- Convert ROI object into a struct
rois = struct();

for planes = 1:length(roidata_sorted_by_plane)
    roi_fields = fields(roidata_sorted_by_plane(planes).ROIdata);
    for num_rois = 1:length(roidata_sorted_by_plane(1).ROIdata)
        for x = 1:length(roi_fields)
           rois(num_rois).(roi_fields{x}) = roidata_sorted_by_plane(1).ROIdata(num_rois).(roi_fields{x});
        end
    end
end

%-- If piezo is active 
if mousedata(session_number).imaging_metadata.piezo_active
    %-- Check that the z step size for volume imaging is correctly reported by user and the 2P microscope.
    imagingdata_z_depth = mousedata(session_number).imaging_metadata.z_depth_ym;
    reported_z_depth = mousedata(session_number).daqdata.metadata.imaging_depth_lower - mousedata(session_number).daqdata.metadata.imaging_depth_upper;

    if ~(imagingdata_z_depth == reported_z_depth) % Reported and detected z_depth for piezo does not match
       quest = sprintf('OBS: The piezo volume imaging z step reported by the 2P microscope does not match the reported z step. 2P says: %i, you say: %i. What is correct? Type 0 if none is correct.',imagingdata_z_depth,reported_z_depth); 
        z_step_size = inputdlg(quest);
    else
        z_step_size = imagingdata_z_depth;
    end
   
    % ESTIMATE THE DEPTH BASED ON THE LOOKUP TABLE
    
 
%-- No piezo, just set z depth as the imaging_upper value
else 
    imaging_depth = mousedata(session_number).daqdata.metadata.imaging_depth_upper;
    mousedata(session_number).ROI_metadata = rois;
    for x = 1:length(mousedata(session_number).ROI_metadata)
        mousedata(session_number).ROI_metadata(x).estimated_location_z = imaging_depth;
    end
end


end
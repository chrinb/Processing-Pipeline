function mousedata = pipe_extractSignalsFromROIs(mousedata,channel,fileFolder)
% PIPE_EXTRACTSIGNALSFROMROIS allows the user to select the session-folder
% to which all ROIs will be extracted. This requires that the session has
% gone through image registration and that ROIs have been made using
% roimanager_lite. 
%
% Input
%   mousedata: structure containing all imaging data from a particular
%       mouse.
%   fileFolder: Other functions may call this function with a specific file
%       folder already selected. This input is not required.
% Output
%   mousedata: the same structure as input but with the added extracted
%       signals:
%       - mousedata().ROIsignals_raw: NxM matrix where N is the number of ROIs
%           and M is each sample point from the ROI signal trace
%       - mousedata().ROIsignals_dFoverF: same as .ROIsignals_raw but with
%           the signal being delta F over F.
%       - mousedata().daqdata: If loadSessionData == 1 give as input, the
%           session data will also be loaded. See function
%           pipe_loadSessionData().
%
% Written by AL

% if nargin<2 % in some cases the folder_name is used as input from another function
%     fileFolder = uigetdir;
% end

for ch = channel
%--- Initialize
%ch = 2; % Currently the script only extract from channel 2 in the image stack, this is the green fluroescens as captured by PMT2.

%--- Select session folder
fileFolder = uigetdir;
sessionID = getSessionIDfromString(fileFolder);
fileFolder = [fileFolder '\calcium_images_aligned'];
cd(fileFolder)
filesInFolder = dir(sprintf('*ch%d*',ch));
session_number = str2num(sessionID(end-2:end));
plane_num = 1;

%--- Locate the ROI files for all planes
for x = 1:length(filesInFolder)
    if ~isempty(findstr(filesInFolder(x).name,'roi_arr'))
        roiFile{plane_num} = [fileFolder '\' filesInFolder(x).name];
        if ~isempty(findstr(roiFile{plane_num},'_plane'))
            id_indx = findstr(roiFile{plane_num},'_plane');
            plane_name = roiFile{plane_num};
            plane_id{plane_num} = plane_name(id_indx+6:id_indx+8);
        end 
        plane_num = plane_num + 1;
    end
end
        
%--- Load imArray for each stack and extract signal for each ROI in each plane
signals = [];
all_signals = [];
roidata_sorted_by_plane = struct();
first_round = 1;
for plane_num = 1:length(plane_id)
    
    roiFileVar = load(roiFile{plane_num});
    rois = roiFileVar.roi_arr;
    roidata_sorted_by_plane(plane_num).ROIdata = rois;
    roidata_sorted_by_plane(plane_num).plane_id = plane_id;
    
    % Get ROI metadata from this plane
    signals  = [];
    current_plane = ['_plane',plane_id{plane_num}];
    fileCount = 1;
    for x = 1:length(filesInFolder)
       
        if ~isempty(findstr(filesInFolder(x).name,'tif'))
           if ~isempty(findstr(filesInFolder(x).name,current_plane))
               fprintf('Plane %s: Loading file nr. %d\n',plane_id{plane_num}, fileCount);
               fileCount = fileCount + 1;
               partNum = str2num(filesInFolder(x).name(end-6:end-4));
               imFilePath = [fileFolder '\' filesInFolder(x).name];
               tiffStack = stack2mat(imFilePath,true);
               extractedSignal = extractSignal(tiffStack,rois);
               temp_signal = extractedSignal.Signal;
               signals = [signals; temp_signal];

           end
        end
    end
    signals = signals';
    % Correct for missing frame at the end if the recording has stopped
    % before piezo has finished its cycle.
    if first_round == 0
        if size(signals,2) == size(all_signals,2)-1
            signals(:,end+1) = signals(:,end);
        else
        end
    else
        first_round = 0;
    end
    all_signals = [all_signals; signals];    
end

%%% UNDER DEVELOPMENT %-- Subtract the mean signal of each ROI from all neuropill ROIs, to remove noise
% neuropill_subtraction_mean = zeros(1,size(all_signals,2));
% divide_by = 0;
% for x = 1:length(rois)
%     if strcmp(rois(x).Group,'Neuropill')
%         neuropill_subtraction_mean = neuropill_subtraction_mean + all_signals(x,:);
%         divide_by = divide_by + 1;
%     end
% end
% 
% neuropill_subtraction_mean = neuropill_subtraction_mean/divide_by;
% 
% % Subtract neuropill mean from signals
% signals = [];
% for x = 1:372
%     signals(x,:) = all_signals(x,:) - neuropill_subtraction_mean;
% end
% 
% signals(signals<0) = 0;
% 
% 
% 


signals = all_signals;
    
%%% UNDER DEVELOPMENT This code works for files not containing _plane001 info..
% % % signals = [];
% % % 
% % % for x = 1:length(filesInFolder)
% % %    fprintf('Loading file %d of %d\n',x,length(filesInFolder));
% % %     if ~isempty(findstr(filesInFolder(x).name,'tif'))
% % %         
% % %        partNum = str2num(filesInFolder(x).name(end-6:end-4));
% % %        imFilePath = [filesInFolder(x).folder '\' filesInFolder(x).name];
% % %        
% % %        tiffStack = stack2mat(imFilePath,true);
% % %        extractedSignal = extractSignal(tiffStack,rois);
% % %        temp_signal = extractedSignal.Signal;
% % %        signals = [signals; temp_signal];
% % %          
% % %     end
% % %     
% % % end

if ch == 1
%--- Get imaging metadata
config_file_folder = [fileFolder(1:end-7),'raw_ss'];
config_file_folder_subdir = dir(config_file_folder);
config_file_folder = [config_file_folder,'\', config_file_folder_subdir(end).name]
raw_file = dir(fullfile(config_file_folder, '*.ini'));
inistring=fileread(fullfile(config_file_folder,raw_file.name));

mousedata(session_number).imaging_metadata.zoom = readVarIni(inistring,'ZOOM');
mousedata(session_number).imaging_metadata.frames_per_sec = readVarIni(inistring,'frames.p.sec');
mousedata(session_number).imaging_metadata.x_pixels = readVarIni(inistring,'x.pixels');
mousedata(session_number).imaging_metadata.y_pixels = readVarIni(inistring,'y.pixels');
mousedata(session_number).imaging_metadata.number_of_frames_acquired = readVarIni(inistring,'no.of.frames.acquired');
piezo_active = readVarIni(inistring,'piezo.active');

if sum(findstr(piezo_active,'FALSE')) % Is piezo active
    mousedata(session_number).imaging_metadata.piezo_active = false;
else
    mousedata(session_number).imaging_metadata.piezo_active = true;
    mousedata(session_number).imaging_metadata.piezo_imaging_rate_hz = readVarIni(inistring,'volume.rate.(in.Hz)');
    mousedata(session_number).imaging_metadata.number_of_planes = readVarIni(inistring,'frames.per.z.cycle');
    mousedata(session_number).imaging_metadata.z_depth_ym = (readVarIni(inistring,'z.spacing')*readVarIni(inistring,'no.of.planes'))-readVarIni(inistring,'z.spacing');
    
    if sum(findstr(readVarIni(inistring,'piezo.mode'),'FALSE')) % Piezo is active and it is zig mode
        mousedata(session_number).imaging_metadata.piezo_mode = 'zig';
    else
        mousedata(session_number).imaging_metadata.piezo_mode = 'saw';
    end 
end
mousedata(session_number).imaging_metadata.PMT1gain = readVarIni(inistring,'pmt1.gain');
mousedata(session_number).imaging_metadata.PMT2gain = readVarIni(inistring,'pmt2.gain');
end

if ch == 1
%--- Save signals to mousedata struct
mousedata(session_number).ROIsignals_raw_ch1 = signals;

%--- Calculate the delta f over f for the whole recording
mousedata(session_number).ROIsignals_dFoverF_ch1 = preprocess_deltaFoverF(signals);

%--- Calculate the z score normalized signal for the whole recording
mousedata(session_number).ROIsignals_dFoverF_zScored_ch1 = zScoreNormalize(mousedata(session_number).ROIsignals_dFoverF_ch1);

else
    mousedata(session_number).ROIsignals_raw_ch2 = signals;
    mousedata(session_number).ROIsignals_dFoverF_ch2 = preprocess_deltaFoverF(signals);
    mousedata(session_number).ROIsignals_dFoverF_zScored_ch2 = zScoreNormalize(mousedata(session_number).ROIsignals_dFoverF_ch2);
end
%--- Get ROI metadata ## UNDER DEVELOPMENT
% This shall include x,y,z location of ROI, as well as ROI type and radius
%mousedata(session_number).ROI_metadata.ROIobjects = rois;

%-- Estimate ROI depths if piezo active

%-- Get imaging depths
if ch == 1
if isfield(mousedata(session_number).daqdata.metadata,'imaging_depth_upper')
    if mousedata(session_number).daqdata.metadata.imaging_depth_upper == 0
       mousedata(session_number).daqdata.metadata.imaging_depth_upper = inputdlg('Imaging depth upper does not exist for this session. Enter the correct value'); 
    end
else
    mousedata(session_number).daqdata.metadata.imaging_depth_upper = inputdlg('Imaging depth upper does not exist for this session. Enter the correct value (If using the piezo, this value is the most superficial depth used in the recording):'); 
end

if mousedata(session_number).imaging_metadata.piezo_active
    if isfield(mousedata(session_number).daqdata.metadata,'imaging_depth_lower')
        if mousedata(session_number).daqdata.metadata.imaging_depth_lower == 0
            mousedata(session_number).daqdata.metadata.imaging_depth_lower = inputdlg('Imaging depth lower does not exist for this session. Enter the correct value'); 
        end
    else
        mousedata(session_number).daqdata.metadata.imaging_depth_lower = inputdlg('Imaging depth lower does not exist for this session. Enter the correct value (If this recording only used 1 plane (i.e. no piezo) put 0):'); 
    end
    
end

% Estimate ROI depth in brain based on either lookup tabel for piezo or from manually entered value imaging_depth_upper
mousedata = preprocess_estimateROIlocation(mousedata,session_number,roidata_sorted_by_plane);
end
clear signals all_signals
end

% Get the depth of top and bottom plane from daqdata.metadata or prompt
% user if daqdata has not yet been loaded. 

% mousedata(session_number).ROI_metadata = 


end
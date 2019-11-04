function sData = pipe_extractSignalsFromROIsS(sData,fileFolder)
% PIPE_EXTRACTSIGNALSFROMROISS allows the user to select the session-folder
% to which all ROIs will be extracted. This requires that the session has
% gone through image registration and that ROIs have been made using
% roimanager_lite. 
%
% INPUT
%   sData: A struct containing all session data.
%   fileFolder (optional): Other functions may call this function with a 
%       specific file folder already selected. This input is not required.
%
% OUTPUT
%   sData: the same structure as input but with the added extracted
%       signals:
%       - sData().ROIsignals_raw: NxM matrix where N is the number of ROIs
%           and M is each sample point from the ROI signal trace
%       - sData().ROIsignals_dFoverF: same as .ROIsignals_raw but with
%           the signal being delta F over F.
%
% Written by Andreas Lande and Eivind Hennestad
% Edited by Anna Chambers

% If inputs are not given, initiate the following
if nargin<1 
    sData = struct(); % Create empty sData struct
    fileFolder = uigetdir(getPathToDir('datadrive'));
elseif nargin<2
    fileFolder = uigetdir(getPathToDir('datadrive'));
end

%-- Select session folder
sessionID = getSessionIDfromString(fileFolder);
choosenFolder = fileFolder;
fileFolder = [fileFolder '\two_photon_images_reg'];
roiFolder = [choosenFolder '\roisignals'];
filesInFolder = dir(fileFolder);
plane_num = 1;
plane_id = {'001'};
new_plane_naming = 0; % This is used to determine if the .tif files contain "_plane00X" within the naming. This was not the case for older recordings.

%-- Locate the ROI files for all planes
% for x = 1:length(filesInFolder)
%     if ~isempty(findstr(filesInFolder(x).name,'_rois'))
%         roiFile{plane_num} = [filesInFolder(x).folder '\' filesInFolder(x).name];
%         if ~isempty(findstr(roiFile{plane_num},'_plane'))
%             new_plane_naming = 1;
%             id_indx = findstr(roiFile{plane_num},'_plane');
%             plane_name = roiFile{plane_num};
%             plane_id{plane_num} = plane_name(id_indx+6:id_indx+8);
%         end 
%         plane_num = plane_num + 1;
%     end
% end

cd(roiFolder);
filesInRoiFolder = dir('*rois.mat');
roiFile(plane_num).name = (fullfile(filesInRoiFolder.folder,filesInRoiFolder.name));

%-- Load imArray for each stack and extract signal for each ROI in each plane
signals = [];
all_signals = [];
all_neuropil_signals = [];
roidata_sorted_by_plane = struct();
first_round = 1;

% For each imaging plane
for plane_num = 1:length(plane_id)
    
    % Load ROI file
    name = roiFile(plane_num).name;
    roiFileVar = load(name);
    rois = roiFileVar.roi_arr;
    roidata_sorted_by_plane(plane_num).ROIdata = rois;
    roidata_sorted_by_plane(plane_num).plane_id = plane_id{plane_num};
    
    % Get ROI metadata from this plane
    signals  = [];
    neuropil_signals  = [];
    if new_plane_naming == 0
        current_plane = '';
    else
        current_plane = ['_plane',plane_id{plane_num}];
    end
    fileCount = 1;
    
    % For each file in folder, find the .TIF files
    for x = 1:length(filesInFolder)
       
        if ~isempty(findstr(filesInFolder(x).name,'tif')) % if the file is a .TIF
            if new_plane_naming == 1 % plane number is in image filename 
                if ~isempty(findstr(filesInFolder(x).name,current_plane))
                    fprintf('Plane %s: Loading file nr. %d\n',plane_id{plane_num}, fileCount);
                    fileCount = fileCount + 1;
                    partNum = str2num(filesInFolder(x).name(end-6:end-4));
                    imFilePath = [filesInFolder(x).folder '\' filesInFolder(x).name];
                    tiffStack = stack2mat(imFilePath,true);
                    extractedSignal = rmSignalExtraction.extractFluorescenceSignals(tiffStack, rois, 1, 1);
                    temp_signal = extractedSignal.meanRoiFluorescence;
                    temp_neuropil_signals = extractedSignal.meanNeuropilFluorescence;
                    neuropil_signals = [neuropil_signals, temp_neuropil_signals];
                    signals = [signals, temp_signal];
                    
                end
            else % plane number is not in image filename
                    fprintf('Plane %s: Loading file nr. %d\n',plane_id{plane_num}, fileCount);
                    fileCount = fileCount + 1;
                    partNum = str2num(filesInFolder(x).name(end-6:end-4));
                    imFilePath = [filesInFolder(x).folder '\' filesInFolder(x).name];
                    tiffStack = stack2mat(imFilePath,true);
                    extractedSignal = rmSignalExtraction.extractFluorescenceSignals(tiffStack, rois, 1, 1);
                    temp_signal = extractedSignal.meanRoiFluorescence;
                    temp_neuropil_signals = extractedSignal.meanNeuropilFluorescence;
                    neuropil_signals = [neuropil_signals, temp_neuropil_signals];
                    signals = [signals, temp_signal];
            end
        end
    end

    % Correct for missing frame at the end if the recording has stopped
    % before piezo has finished its cycle.
    if first_round == 0
        if size(signals,2) == size(all_signals,2)-1
            signals(:,end+1) = signals(:,end);
            neuropil_signals(:,end+1) = neuropil_signals(:,end);
        end
    else
        first_round = 0;
    end
    all_signals = [all_signals; signals];
    all_neuropil_signals = [all_neuropil_signals; neuropil_signals];
end

signals = all_signals;
neuropil_signals = all_neuropil_signals;
sData.imdata.roiSignals = struct();
sData.imdata.roiSignals(1).ch = 'red'; %for OS1
sData.imdata.roiSignals(2).ch = 'green'; %for OS1

%--- Get imaging metadata
try % This is only possible if the datafolders are organized correctly
    sData.imdata.meta = loadImagingMetadata(sessionID);

    %-- Convert ROI object into a struct and add ROI_metadata to sessionData
    rois = struct();
    curr_ROI = 1;
    for planes = 1:length(roidata_sorted_by_plane)
        roi_fields = fields(roidata_sorted_by_plane(planes).ROIdata);
        for num_rois = 1:length(roidata_sorted_by_plane(planes).ROIdata)
            for x = 1:length(roi_fields)
               rois(curr_ROI).(roi_fields{x}) = roidata_sorted_by_plane(planes).ROIdata(num_rois).(roi_fields{x});
            end
            curr_ROI = curr_ROI + 1;
        end
    end

    sData.imdata.roiArray = rois;
end
sData.imdata.roiArray = rois;

%figure out which channel was used for imaging for these rois
chIdx = strfind(filesInRoiFolder.name,'ch') + 2;
channel = str2double(filesInRoiFolder.name(chIdx));

%--- Save signals to sessionData struct
%sData.ROIsignals_raw = signals;
sData.imdata.roiSignals(channel).roif = signals;

%--- Save the neuropil_fluorescence signal to the struct
%sData.ROIsignals_neuropil = neuropil_signals;
sData.imdata.roiSignals(channel).npilf = neuropil_signals;

%--- Calculate the delta f over f for the whole recording
%sData.ROIsignals_dFoverF_npsubtracted = preprocess_dFoverF_subtractNeuropil(sData.ROIsignals_raw,sData.ROIsignals_neuropil,sData.ROI_metadata);

%sData.ROIsignals_dFoverF = preprocess_deltaFoverF(sData.ROIsignals_raw);
sData.imdata.roiSignals(channel).dff = preprocess_deltaFoverF(sData.imdata.roiSignals(channel).roif);
sData.imdata.roiSignals(channel).dffSubtractedNpil = preprocess_dFoverF_subtractNeuropil(sData.imdata.roiSignals(channel).roif,...
    sData.imdata.roiSignals(channel).npilf,sData.imdata.roiArray);

%deconvolve Ca signals (npil subtracted)
rawROI = sData.imdata.roiSignals(channel).dffSubtractedNpil;
for i = 1:size(rawROI,1)
    [~,deconROI(i,:)] = deconvolveCa(rawROI(i,:),'method','thresholded');
end
sData.imdata.roiSignals(channel).deconv = deconROI;

%--- Calculate the z score normalized signal for the whole recording
%sData.ROIsignals_dFoverF_zScored = zScoreNormalize(sData.ROIsignals_dFoverF);

%--- Get ROI metadata ## UNDER DEVELOPMENT
% This shall include x,y,z location of ROI, as well as ROI type and radius

%-- Estimate ROI depths if piezo active
% 
% %-- If DAQDATA is not loaded, attempt to load
% if (~(isfield(sessionData,'daqdata')) || isempty(sessionData.daqdata))  
%     disp('DAQDATA not detected. Attempting to load...');
%     sessionData = pipe_loadSessionDataS(choosenFolder);
% end
% 
% %-- Get imaging depths
% if (~(isfield(sessionData,'daqdata')) || isempty(sessionData.daqdata))
%     warning('DAQDATA has not been loaded for this session yet, imaging depth estimation is therefore skipped.');
% else
%     % Estimate ROI depth in brain based on either lookup tabel for piezo or from manually entered value imaging_depth_upper
%     % %%mousedata = preprocess_estimateROIlocation(mousedata,session_number,roidata_sorted_by_plane);
% end


end
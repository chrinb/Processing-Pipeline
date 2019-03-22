function [ ] = imregSessionPiezo( sessionID, options )
%imregSessionPiezo Register images from a session
%   imregSessionPiezo(sessionID, options) performs image registration to correct
%   for movement artifacts and rotation of images from a session after
%   spliting the individual frames obtained by using the piezo.
%
%   Options is a struct with following fields:
%       - rigid (default is true)       :   Rigid image registration
%       - nonrigid (default is true)   :   Non-rigid image registration (NoRMCorre)
%
%   Assumes that available imaging channels are red, green or both. If both
%   are present, it runs motion correction on red channel and applies
%   results to green channel.
 
% Written by EH. Modified for piezo by AL.
 
%-- Settings
if nargin < 2 || isempty(options)
    options.rigid = true;
    options.nonrigid = false;
end
 
% Turn of warnings
warning('off', 'MATLAB:mir_warning_maybe_uninitialized_temporary')
warning('off', 'MATLAB:maxNumCompThreads:Deprecated')
 
%-- Get number of blocks for this session + channels recorded
sessionFolder = getSessionFolder(sessionID);
imagingInfo = loadImagingMetadata(sessionID);
firstFrame = 1; % For OsloScope1/2 firstFrame is 1. 
 
% Sort channels so that red comes first. (Sort by color and flip : red, green)
ch_unsorted = cat(1, imagingInfo.channelColor(:)', num2cell(imagingInfo.channels));
ch_sorted = fliplr(sortrows(ch_unsorted.', 1)');
 
%-- Register images
for i = 1:imagingInfo.nCh % For each recording channel
     
    ch = ch_sorted{2, i};
 
    % Find number of overlapping pairs of images and angles
    if imagingInfo.piezoActive == 1
        nImages = (floor(imagingInfo.nFrames/imagingInfo.piezoNumberOfPlanes))*imagingInfo.piezoNumberOfPlanes; % This is done to remove frames taken halfway through a piezo stack because a SciScan recording is aborted.
    else
        nImages = imagingInfo.nFrames;
    end
     
    % Calcium recordings might be very long. Process recording in smaller chunks
    chunkSize = 2000; % If you change this, it has to be a multiple of 4,6,8 etc because of the piezo.
     
    % Define first index for each chunk
    lastFrame = nImages;
    initFrames = firstFrame:chunkSize:lastFrame;
     
    % Loop through each chunk
    chunk = 0;
    for c = initFrames
         
        chunk = chunk + 1;
         
        % Last chunk is not full size, calculate its size:
        if c == initFrames(end)
            chunkSize = lastFrame - initFrames(end);
        end
         
        % Set first and last frame number of current chunk
        idx_i = c; % first frame
        idx_e = (idx_i - 1) + chunkSize; % last frame
         
        % Load images from session into array
        sessionFolder = getSessionFolder(sessionID);
        if strncmp(sessionID,'ID',2) % If the folder is a raw recording from the scope
            imageFolder = sessionFolder;
        else % If the folder is a structured recording session
            imageFolder = dir(fullfile(sessionFolder, 'calcium_images_raw*'));
            imageFolder = imageFolder(1).name;
            subFolder = dir(fullfile(sessionFolder, imageFolder, '*201*' ));
            imageFolder = fullfile(sessionFolder, imageFolder, subFolder(1).name);
        end
        
        tmp_imArray = loadSciScanStack( imageFolder, ch, idx_i, idx_e);
         
        % Set plane info based on whether the piezo is used or not
        if imagingInfo.piezoActive == 0
            number_of_imaging_planes = 1;
            start_plane = 1;
        else
            number_of_imaging_planes = imagingInfo.piezoNumberOfPlanes;
             
            % If piezo mode is sawtooth, only save plane 2,3,4 etc ... because
            % the first plane is faulty because of the setling time of the
            % piezo. This is not a problem for zig-zag mode.
            if imagingInfo.piezoMode == 'saw'
                start_plane = 2;
            else
                start_plane = 1;
            end
             
        end
         
        step_num = number_of_imaging_planes;
 
        for plane_num = start_plane:number_of_imaging_planes
             
            %-- Rigid registration
            if options.rigid % Run rigid correction
                 
                % Create current image stack to use for correction
                Y = double(tmp_imArray(:,:,plane_num:step_num:end));
                                 
                % Set options
                options_rigid = NoRMCorreSetParms('d1', size(Y,1), 'd2', size(Y,2), ...
                    'bin_width', 50, 'max_shift', 20, ...
                    'us_fac', 50, 'correct_bidir', 0);
                 
                % Run NormCorre
                [~, nc_shifts, ~] = normcorre(Y, options_rigid); % Run NormCorre
                tmp_corrections = [];
                tmp_corrections(:, 1) = round(arrayfun(@(row) row.shifts(2), nc_shifts));
                tmp_corrections(:, 2) = round(arrayfun(@(row) row.shifts(1), nc_shifts));
                clearvars Y;
                 
                % Apply frame corrections to image array 
                prevstr = [];
                imArray = tmp_imArray(:,:,plane_num:step_num:end);
                nFrames = min([size(imArray, 3), max(size(tmp_corrections, 1))]);
                 
                for fr = 1:nFrames
                    % Display message in command window
                    if mod(fr, 50) == 0
                        str = ['applying displacements to frame ' num2str(fr) '/' num2str(nFrames)];
                        refreshdisp(str, prevstr, fr);
                        prevstr = str;
                    end
                     
                    % Translate images
                    if ~isempty(tmp_corrections)
                        imArray(:, :, fr) = shiftFrame(imArray(:, :, fr), tmp_corrections(fr, :));
                    end  
                end
                 
                tmp_imArray_corrected = imArray(:, :, 1:nFrames); % Corrected images
 
                % Save frame corrections
                saveData(tmp_corrections, 'FrameCorrections', sessionID, 1, ch, chunk, plane_num);
                clearvars imArray;
                 
            else % Skip rigid correction
                tmp_imArray_corrected = tmp_imArray(:,:,plane_num:step_num:end);
            end
             
            %-- Nonrigid registration
            if options.nonrigid % Run nonrigid registration
                 
                % Create image array
                Y1 = double(tmp_imArray_corrected);
                 
                % Set options
                options_nonrigid = NoRMCorreSetParms('d1',size(Y1,1),'d2',size(Y1,2),...
                    'grid_size',[128, 128],'mot_uf',4,'bin_width',43,...
                    'max_shift',10, 'max_dev',15,'us_fac',50);
                 
                % Run NoRMCorre
                if chunk == 1
                    [tmp_imArray_plane, ~, ref{plane_num}] = normcorre_batch(Y1, options_nonrigid);
                else
                    [tmp_imArray_plane, ~, ref{plane_num}] = normcorre_batch(Y1, options_nonrigid, ref{plane_num});
                end
            else % Skip nonrigid registration
                tmp_imArray_plane = tmp_imArray_corrected; % if nonrigid is skipped.
            end
             
            % Find image path to reference image
            refImPath = fullfile(sessionFolder, ['session_reference_img-plane' num2str(plane_num) '.tif']);
             
            % Align all stacks to the first stack of the session
            if chunk == 1
                imwrite(uint8(mean(tmp_imArray_plane, 3)), refImPath, 'TIFF')
                 
            else
                ref_im = double(imread(refImPath));
                src = mean(tmp_imArray_plane, 3);
                 
                % Get displacements using imreg_fft
                [~, dx, dy, ~] = imreg_fft(src, ref_im);
                 
                tmp_imArray_plane = shiftStack(tmp_imArray_plane, dx, dy);
            end
 
            saveData(tmp_imArray_plane, 'RegisteredImages', sessionID, 1, ch, chunk,plane_num);
             
        end
         
    end
 
    % Stack average and max projections
    alignedAvgStack = fullfile(sessionFolder, ['blocksAVG_', sessionID, '_ch', num2str(ch, '%d'), '.tif']);
    alignedMaxStack = fullfile(sessionFolder, ['blocksMAX_', sessionID, '_ch', num2str(ch, '%d'), '.tif']);
 
    stackImages(fullfile(sessionFolder, 'preprocessed_data'), alignedAvgStack, ['*AVG*ch', num2str(ch), '*'])
    stackImages(fullfile(sessionFolder, 'preprocessed_data'), alignedMaxStack, ['*MAX*ch', num2str(ch), '*'])
 
end
 
% Turn warnings back on
warning('on', 'MATLAB:mir_warning_maybe_uninitialized_temporary')
warning('on', 'MATLAB:maxNumCompThreads:Deprecated')
end
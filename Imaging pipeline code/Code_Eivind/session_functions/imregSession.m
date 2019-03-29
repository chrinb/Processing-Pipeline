function [ ] = imregSession( sessionID, options )
%imregSession Register images from a session
%   imregSession(sessionID, options) performs image registration to correct
%   for movement artifacts and rotation of images from a session
%
%   Options is a struct with following fields:
%       - rotate (default is true)      :   Rotate images
%       - rigid (default is true)       :   Rigid image registration
%       - nonrigid (default is false)   :   Non-rigid image registration (NoRMCorre)
%
%   Assumes that available imaging channels are red, green or both. If both
%   are present, it runs motion correction on red channel and applies
%   results to green channel.


% TODO: Handle multiple channels

% Settings
if nargin < 2 || isempty(options)
    options.rotate = true;
    options.rigid = true;
    options.nonrigid = false;
end

warning('off', 'MATLAB:mir_warning_maybe_uninitialized_temporary')

sessionFolder = getSessionFolder(sessionID);

% crashdumpFolder = fullfile(sessionFolder, 'crashdump');
% if ~exist(crashdumpFolder, 'dir'); mkdir(crashdumpFolder); end

% Get number of blocks for this session + channels recorded
%sessionInfo = loadSessionInfo(sessionID);
imagingInfo = loadImagingMetadata(sessionID);

acquisitionSoftware = imagingInfo.microscope;
switch acquisitionSoftware
    case 'Prairie'
        firstFrame = 60;
    case 'SciScan'
        firstFrame = 1;
end

%Angle delay...

% Sort channels so that red comes first. (Sort by color and flip : red, green)
ch_unsorted = cat(1, imagingInfo.channelColor(:)', num2cell(imagingInfo.channels));
ch_sorted = fliplr(sortrows(ch_unsorted.', 1)');

for i = 1:imagingInfo.nCh
    
    ch = ch_sorted{2, i};

    for block = 1:sessionInfo.nBlocks

        % Check if corrected stack already exists. If yes, continue
        try
            tmp_imArray = loadRegisteredImages(sessionID, block, ch);
            continue
        catch
            disp(['Aligning images from block ' num2str(block)])
        end
        
      % Check if frame corrections already exists
        try
            [corrections, stack_corrections, angles] = loadFrameCorrections(sessionID, block);
            options.rotate = false;
            options.rigid = false;
%            angles = loadLabviewData(sessionID, block, 'angles');
            if strcmp(acquisitionSoftware, 'Prairie'); angles = -angles(firstFrame:end); end
%            rotating = loadLabviewData(sessionID, block, 'rotating');
%            angles = correctAngleDelay(imArray, angles, rotating);
            tmp_imArray = applyFrameCorrections(tmp_imArray, angles, corrections, stack_corrections);
        catch
            disp('Starting image registration ...')
            angles = loadLabviewData(sessionID, block, 'angles');
            rotating = loadLabviewData(sessionID, block, 'rotating');
        end

        % Load delay of stage positions in relation to images.
        try
            load(fullfile(sessionFolder, 'imreg_variables', [sessionID, '_stagePositionDelay.mat']))
        catch
            stagePositionDelay = 0;
        end

        if stagePositionDelay < 0
            %angles = angles(abs(stagePositionDelay)+1:end);
            angles = angles(abs(stagePositionDelay):end);
            stagePositionDelay = 0;
        end
        
        % Find number of overlapping pairs of images and angles
        nAngles = length(angles);
        nImages = imagingInfo.nFrames - stagePositionDelay;
        nSamples = min([nAngles, nImages]);

        % Calcium recordings might be very long. Process recording in smaller chunks
        chunkSize = 5000;
        
        % overlap = 100; % Overlap in number of frames between chunk when registering images
        
        % Define first index for each chunk
        firstFrame = stagePositionDelay + 1;
        lastFrame = nSamples + stagePositionDelay;
        initFrames = firstFrame:chunkSize:lastFrame; 
        
        % Loop through each chunk
        chunk = 0;
        for c = initFrames;
            
            chunk = chunk + 1;
            
            % Last chunk is not full size, calculate its size:
            if c == initFrames(end)
                chunkSize = lastFrame - initFrames(end);
            end
            
            % Set first and last frame number of current chunk
            idx_i = c;
            idx_e = (idx_i - 1) + chunkSize;
            
            % Load images from session and block into array.
            tmp_imArray = loadRawImages(sessionID, block, ch, idx_i, idx_e);
            % TODO Does not work for prairie. Need to implement first and last idx

            % Rotate images based on stage positions
            if options.rotate
                tmp_angles = angles( (idx_i:idx_e) - stagePositionDelay );
                if strcmp(acquisitionSoftware, 'Prairie'); tmp_angles = -tmp_angles; end

                if block == 1 && chunk == 1   % Find whether image rotates off center
                    %[stack_dx, stack_dy] = findRotationAxis(tmp_imArray, tmp_angles);
                    try
                        load(fullfile(sessionFolder, 'imreg_variables', [sessionID, '_rotationCenterOffset.mat']))
                        stack_dx = rotationCenterOffset(1);
                        stack_dy = rotationCenterOffset(2);
                    catch
                        stack_dx = 0;
                        stack_dy = 0;
                    end
                end

%                 if ~exist('stack_dx', 'var')
%                     [~, stack_corrections] = loadFrameCorrections(sessionID, 1);
%                     stack_dx = stack_corrections(1);
%                     stack_dy = stack_corrections(2);
%                 end

                % Shift stack if images are not taken on rotation axis.
                tmp_imArray = shiftStack(tmp_imArray, stack_dx, stack_dy);

                % Rotate images
                tmp_imArray = rotateStack(tmp_imArray, tmp_angles);
                
                %filename = [rotated_chunk', num2str(chunk), '.tif']
                %mat2stack(tmp_imArray, fullfile('/Users/eivinhen/Desktop/', filename))
                %tmp_imArray = stack2mat(fullfile('/Users/eivinhen/Desktop/', filename));
            end

            % Use rigid registration methods to register images
            if options.rigid
                tmp_rotating = rotating( (idx_i:idx_e) - stagePositionDelay );
                cntr = round(size(tmp_imArray)/2);
                
                Y1 = tmp_imArray( (-150:150) + cntr(1), (-150:150) + cntr(2), :);
                for f = 1:size(Y1, 3)
                    Y1(:,:,f) = medfilt2(Y1(:,:,f));
                end

                [~, tmp_corrections] = stackregRigid(Y1, tmp_rotating, 'NormCorre');
                %tmp_imArray = applyFrameCorrections(tmp_imArray, [], tmp_corrections, []);
                
                %mat2stack(uint8(tmp_imArray), ['/Users/eivinhen/Desktop/rigid_chunk', num2str(chunk), '_v5_badref.tif'])

                % Concatenate corrections for each chunk and save to file on last chunk
                if chunk == 1
                    corrections = tmp_corrections;
                else
                    corrections = cat(1, corrections, tmp_corrections);
                end
                
                if c == initFrames(end)
                    saveFrameCorrections(sessionID, block, corrections, [stack_dx, stack_dy], angles);
                end
                    
            end

            

            if options.nonrigid
                %imArray = stackregNonRigid(imArray);

                Y1 = double(tmp_imArray);
                options_nonrigid = NoRMCorreSetParms('d1',size(Y1,1),'d2',size(Y1,2),...
                                       'grid_size',[128, 128],'mot_uf',4,'bin_width',43,...
                                       'max_shift',10, 'max_dev',15,'us_fac',50);

                [tmp_imArray, ~, ~] = normcorre_batch(Y1, options_nonrigid);

                % Remove 100 last frames of previous chunk from beginning of current chunk

            end
                

            
%             if chunk == 1
%                 imArray = tmp_imArray;
%             else
%                 imArray = cat(3, imArray, tmp_imArray);
%             end
            
            % Save to file.... save chunks and save as bigtiff in the end?

            refImPath = fullfile(sessionFolder, 'session_reference_img.tif');

            % Align all stacks to the first stack of the session
            if chunk == 1
                imwrite(uint8(mean(tmp_imArray, 3)), refImPath, 'TIFF')

            else
                ref = double(imread(refImPath));
                src = mean(tmp_imArray, 3);

                % Get displacements using imreg_fft
                [~, dx, dy, ~] = imreg_fft(src, ref);

                tmp_imArray = shiftStack(tmp_imArray, dx, dy);         
            end

            tmp_imArray =  circularCrop(tmp_imArray);
        
            %saveRegisteredImages(imArray, sessionID, block, ch);
            saveRegisteredImages(tmp_imArray, sessionID, chunk, ch);
        end


    end

    % Stack average and max projections
    alignedAvgStack = fullfile(sessionFolder, ['blocksAVG_', sessionID, '_ch', num2str(ch, '%d'), '.tif']);
    alignedMaxStack = fullfile(sessionFolder, ['blocksMAX_', sessionID, '_ch', num2str(ch, '%d'), '.tif']);

    stackImages(fullfile(sessionFolder, 'preprocessed_data'), alignedAvgStack, ['*AVG*ch', num2str(ch), '*'])
    stackImages(fullfile(sessionFolder, 'preprocessed_data'), alignedMaxStack, ['*MAX*ch', num2str(ch), '*'])

end

warning('on', 'MATLAB:mir_warning_maybe_uninitialized_temporary')

end
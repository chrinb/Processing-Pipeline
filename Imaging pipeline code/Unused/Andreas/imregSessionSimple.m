function [ ] = imregSessionSimple( sessionID, options )
%imregSession Register images from a session
%   imregSession(sessionID, options) performs image registration to correct
%   for movement artifacts and rotation of images from a session
%
%   Options is a struct with following fields:
%       - rigid (default is true)       :   Rigid image registration
%       - nonrigid (default is true)   :   Non-rigid image registration (NoRMCorre)
%
%   Assumes that available imaging channels are red, green or both. If both
%   are present, it runs motion correction on red channel and applies
%   results to green channel.

% Written by EH. Modified by AL.


% Settings
if nargin < 2 || isempty(options)
    options.rigid = true;
    options.nonrigid = true;
end

warning('off', 'MATLAB:mir_warning_maybe_uninitialized_temporary')
warning('off', 'MATLAB:maxNumCompThreads:Deprecated')

sessionFolder = getSessionFolder(sessionID);

% Get number of blocks for this session + channels recorded
sessionInfo = struct();%sessionInfo = loadSessionInfo(sessionID);
sessionInfo.nBlocks = 1;
imagingInfo = loadImagingMetadata(sessionID);

acquisitionSoftware = imagingInfo.microscope;
switch acquisitionSoftware
    case 'Prairie'
        firstFrame = 60;
    case 'SciScan'
        firstFrame = 1;
end

% Sort channels so that red comes first. (Sort by color and flip : red, green)
ch_unsorted = cat(1, imagingInfo.channelColor(:)', num2cell(imagingInfo.channels));
ch_sorted = fliplr(sortrows(ch_unsorted.', 1)');

for i = 1:imagingInfo.nCh
    
    ch = ch_sorted{2, i};

    for block = 1:sessionInfo.nBlocks
        
        % Find number of overlapping pairs of images and angles
        nImages = imagingInfo.nFrames;

        % Calcium recordings might be very long. Process recording in smaller chunks
        chunkSize = 3000;
        rotating = zeros(1,chunkSize);
        
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
            idx_i = c;
            idx_e = (idx_i - 1) + chunkSize;
            
            % Load images from session and block into array.
            tmp_imArray = loadRawImages(sessionID, block, ch, idx_i, idx_e);
            % TODO Does not work for prairie. Need to implement first and last idx


            % Use rigid registration methods to register images
            if options.rigid
                %---- in for example rotation experiments, the whole image is not needed. uncomment below to only register based on the inner parts of the image.    
                % cntr = round(size(tmp_imArray)/2);                 
                % Y1 = double(tmp_imArray( (-150:150) + cntr(1), (-150:150) + cntr(2), :));
                %-----------
                [~, tmp_corrections] = stackregRigid(tmp_imArray, rotating, 'NormCorre');
                %clearvars Y1
                tmp_imArray = applyFrameCorrections(tmp_imArray, [], tmp_corrections, []);
                
                saveData(tmp_corrections, 'FrameCorrections', sessionID, block, ch, chunk);
            end

            if options.nonrigid

                Y1 = double(tmp_imArray);
                options_nonrigid = NoRMCorreSetParms('d1',size(Y1,1),'d2',size(Y1,2),...
                                       'grid_size',[128, 128],'mot_uf',4,'bin_width',43,...
                                       'max_shift',10, 'max_dev',15,'us_fac',50);

                                   
                if chunk == 1
                    [tmp_imArray, ~, ref] = normcorre_batch(Y1, options_nonrigid);
                else 
                    [tmp_imArray, ~, ref] = normcorre_batch(Y1, options_nonrigid, ref);
                end

            end

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
        
            saveData(tmp_imArray, 'RegisteredImages', sessionID, block, ch, chunk);
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

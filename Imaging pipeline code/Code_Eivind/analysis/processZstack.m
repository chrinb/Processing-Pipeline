% Load and correct two channel z stack from SciScan.
function processZstack()
    % Browse to raw file
    [fileName, filePath, ~] =  uigetfile({'raw', 'Raw Files (*.raw)'; ...
                                                '*', 'All Files (*.*)'}, ...
                                                'Find SciScan Raw File', ...
                                                '');

    if fileName == 0 % User pressed cancel
        return
    end
    
    ch = 2;
    
    % Load imArray from channel 1
    %[ imArrayCh1 ] = loadSciScanStack( filePath, 1 );
    
    nFrames = 12033;
    
    % Calcium recordings might be very long. Process recording in smaller chunks
    chunkSize = 5000;

    % Define first index for each chunk
    firstFrame = 513;
    lastFrame = nFrames;
    initFrames = firstFrame:chunkSize:lastFrame; 
    
    % Loop through each chunk
    chunk = 0;
    for c = initFrames;

        chunk = chunk + 1;

        %Last chunk is not full size, calculate its size:
        if c == initFrames(end)
            chunkSize = lastFrame - initFrames(end);
        end
        
        % Set first and last frame number of current chunk
        idx_i = c;
        idx_e = (idx_i - 1) + chunkSize;

        % Load images from session and block into array.
        [ tmp_imArray ] = loadSciScanStack( filePath, 2, idx_i, idx_e);
        % TODO Does not work for prairie. Need to implement first and last idx


%         Y = double(tmp_imArray);
%         options_rigid = NoRMCorreSetParms('d1', size(Y,1), 'd2', size(Y,2), ...
%                                           'bin_width', 64, 'max_shift', 20, 'us_fac', 50);
%         [tmp_imArray, ~, ~] = normcorre(Y, options_rigid);
%         clearvars Y
        
        new_filename = strrep(fileName, '.raw', ['chunk', num2str(chunk, '%03d') '_ch', num2str(ch), '.tif']);
        new_filepath = fullfile(filePath, new_filename);
        mat2stack(uint8(tmp_imArray), new_filepath)
        
    end

end
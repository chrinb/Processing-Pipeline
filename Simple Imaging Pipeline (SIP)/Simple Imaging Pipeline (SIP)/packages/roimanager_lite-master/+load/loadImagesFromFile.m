function imArray = loadImagesFromFile(images, i, batchSize)
%loadImagesFromFile Loage images from file into array
    

    if iscell(images)
        imageFileType = 'tiff';
        
    elseif isa(images, 'memmapfile')
        imageFileType = 'memmap';
        
    elseif isa(images, 'virtualImageStack')
        imageFileType = 'virtualImageStack';
        
    else
        error('Load:ImageFromFile Unsupported image filetype: %s', ...
            class(images))
        
    end
    
%     fprintf('Loading images...'); t1 = tic;
    switch imageFileType
        case 'tiff'
            imArray = load.tiffs2mat(images{i});
            
        case 'memmap'
            % Determine number of frames of data.
            fieldName = fieldnames(images.Data);
            nFrames = size(images.Data.(fieldName{1}), 3);
            
            % Calculate framenumbers to load
            first = (i-1) * batchSize + 1;
            last = first + batchSize - 1;
            if last > nFrames; last = nFrames; end
            
            imArray = images.Data.(fieldName{1})(:,:,first:last);
            
        case 'virtualImageStack'
            nFrames = size(images, 3);
            
            % Calculate framenumbers to load
            first = (i-1) * batchSize + 1;
            last = first + batchSize - 1;
            if last > nFrames; last = nFrames; end
            
            imArray = images(:,:,first:last);
    end
    
%     fprintf(' Done. Elapsed Time: %s\n', timestr(toc(t1)));
end


function tString = timestr(nSeconds, format)
%timestr return seconds formatted in a timestring as HH:MM:SS
%
%   tString = timestr(nSeconds, format) returns nSeconds (number) as a
%   formatted string. Currently, format is not programmed, and the default
%   format of HH:MM:SS is used.

    tString = sprintf('%02d:%02d:%02d', ...
        floor(nSeconds/3600), ...
        floor(mod(nSeconds, 3600) / 60), ...
        floor(mod(nSeconds, 60)));


end
function [ signalData ] = extractSignals( sessionID, block, ch)
%extractSignals Extract signals from each roi for a block 
%   S = extractSignals(sessionID, BLOCK, CH) returns signal vectors for each
%   roi for the BLOCK no and CH no of specified session

    sessionFolder = getSessionFolder(sessionID);

    
    % Check if signalfile already exists
    signalFolder = fullfile(sessionFolder, 'extracted_calcium_signals');
    signalFile = dir(fullfile(signalFolder, ['*block', num2str(block, '%03d'), '_ch', num2str(ch), '*']));

    if ~isempty(signalFile) % load file if it exists

        s = load(fullfile(signalFolder, signalFile(1).name));
        signalData = s.signalData;

    else % extract signal based on rois if not.

        imageFolder = fullfile(sessionFolder, 'calcium_images_aligned');
        
        try

        % Load rois for current session
        %addpath(genpath(getPathToDir('roimanager')))
        roiArray = loadRoiArray( sessionID, ch );
        nRois = length(roiArray);

        % Find and load calcium images for current block
        filePattern = ['*block', num2str(block, '%03d'), '_ch', num2str(ch), '*.tif'];
        stacks = dir(fullfile(imageFolder, filePattern));
        imArray = stack2mat(fullfile(imageFolder, stacks(1).name));

        nFrames = size(imArray, 3);
        signal = NaN(nFrames, nRois);

        % Go through each roi and extract signals.
        for j = 1:nRois
            minX = min(roiArray(j).PixelsX);
            minY = min(roiArray(j).PixelsY);
            maxX = max(roiArray(j).PixelsX);
            maxY = max(roiArray(j).PixelsY);
            imChunk = imArray(minY:maxY, minX:maxX, :);
            roiMask = repmat(roiArray(j).Mask(minY:maxY, minX:maxX), 1, 1, nFrames);
            imChunk(~roiMask) = 0;
            signal(:, j) = squeeze(sum(sum(imChunk, 1), 2));
        end

        signalData.Signal = signal;
        signalData.roiArray = roiArray;

        % Save to folder.
        if ~exist(signalFolder, 'dir'); mkdir(signalFolder); end
        signalFilenm = ['extracted_signal_', sessionID, ...
                        '_block', num2str(block, '%03d'), ...
                        '_ch', num2str(ch), '.mat'];
        save(fullfile(signalFolder, signalFilenm), 'signalData')

    end

end


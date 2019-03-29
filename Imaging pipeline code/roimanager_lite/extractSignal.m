function [ signalData ] = extractSignal( imArray, roiArray )
%extractSignal Extract signals from rois in an image array
%   signalData = extractSignal( IMARRAY, ROIARRAY ) returns signals from each roi in 
%   an IMAGE ARRAY based on rois in ROI ARRAY
    
    nRois = length(roiArray);
    nFrames = size(imArray, 3);
    signal = NaN(nFrames, nRois);

    for j = 1:nRois

        minX = min(roiArray(j).PixelsX);
        minY = min(roiArray(j).PixelsY);
        maxX = max(roiArray(j).PixelsX);
        maxY = max(roiArray(j).PixelsY);
        imChunk = imArray(minY:maxY, minX:maxX, :);
        roiMask = repmat(roiArray(j).Mask(minY:maxY, minX:maxX), 1, 1, nFrames);
        imChunk(~roiMask) = 0;
        signal(:, j) = squeeze(sum(sum(imChunk, 1), 2)) / length(roiArray(j).PixelsX);
    
    end
    
    signalData.Signal = signal;
    signalData.roiArray = roiArray;
    
end


function signal = extractRoiFluorescence(roi, imArray, roiarraymask, npmask)
%extractRoiFluorescence Extract fluorescence of one roi

% todo: take care of total overlap.
% Is it possible to improve performance?r

% Determine if surrounding neuropil fluorescence will be extracted
if nargin == 4 && ~isempty(npmask)
    getNeuropil = true;
else
    getNeuropil = false;
end

[height, width, nFrames] = size(imArray);

% Find Roi Extent. Will use it to get a chunk of the imArray for signal 
% extraction. Nb, no rewriting of imArray, so no copies made.
% Find Roi Extent
[y, x] = find(roi.mask);
minX = min(x); maxX = max(x);
minY = min(y); maxY = max(y);

%tic
if getNeuropil
    % Find Neuropil Extent
    roiRadius = round( mean([maxX-minX, maxY-minY]) / 2 );
    pixelsX = minX-roiRadius:maxX+roiRadius;
    pixelsY = minY-roiRadius:maxY+roiRadius;

    % Check that neuropil extent does not exceed image dimensions.
    % (Assuming that no rois stretch from one side to the other, i.e 
    % I only I assume it does not touch both image borders.)
    if any(pixelsX > width)
        pixelsX = min(pixelsX):width;
    end
    if any(pixelsX < 1)
        pixelsX = 1:max(pixelsX);
    end

    if any(pixelsY > height)
        pixelsY = min(pixelsY):height;
    end
    if any(pixelsY < 1)
        pixelsY = 1:max(pixelsY);
    end
    
else
    pixelsX = minX:maxX;
    pixelsY = minY:maxY;
end
%toc

%tic
% Determine if imArray is in memory or a matfile object and load data.
if isa(imArray, 'matlab.io.MatFile')
    %nFrames = size(imArray.imArray, 3);
    imChunk = imArray.imArray(pixelsY, pixelsX, :);
else
    %nFrames = size(imArray, 3);
    imChunk = imArray(pixelsY, pixelsX, :);
    imChunkNp = imChunk;
end
%toc

%tic
% Remove surrounding rois from roi calculation
roiMask = roi.mask(pixelsY, pixelsX); % Get current roi
roiMask = roiMask & xor(roiMask, roiarraymask(pixelsY, pixelsX)); %Remove surrounding rois
roiMask = repmat(roiMask, 1, 1, nFrames);
%toc

%tic
% Extract roiSignal
imChunk(~roiMask) = 0;
fmeanRoi = squeeze(sum(sum(imChunk, 1), 2)) / length(x);
signal.fmeanRoi = fmeanRoi;
%toc

%tic
if getNeuropil
    % Extract surrounding neuropil signal 
    surroundMask = repmat(npmask(pixelsY, pixelsX), 1, 1, nFrames);
    % Use median of surrounding neuropil as signal value. Less biased by
    % bright elements if they are present in the neuropil mask.
    imChunkNp = double(imChunkNp);
    imChunkNp(~surroundMask) = nan;
    fmeanNeuropil = double(squeeze(nanmedian(nanmedian(imChunkNp, 1), 2))); 
    signal.fmeanNeuropil = fmeanNeuropil;
end
%toc



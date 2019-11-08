function [ signalData ] = extractFluorescenceSignals( imArray, roiArray, getNeuropil, wb_on )
%extractFluorescenceSignals Extract fluorescence signals from rois in an image array
%   signalData = extractSignal( IMARRAY, ROIARRAY ) returns signals from each roi in 
%   an IMAGE ARRAY based on rois in ROI ARRAY. Also, the surrounding neuropil signal 
%   for each roi and the bulk neuropil signal is extracted.
%
%   signalData = extractSignal( IMARRAY, ROIARRAY, false ) only extract roi signals.
%
%   signalData is a struct containing 3 fields (if getNeuroPil is false, 
%   the last two fields are just NaNs):
%   -   meanRoiFluorescence         : the mean fluorescence of all pixels in a roi.
%   -   meanNeuropilFluorescence    : the median fluorescence of pixels surrounding a roi.
%   -   meanNPilBulkFluorescence    : the mean fluorescence of all pixels outside rois.

%   Todo: 
%   -   Use imdilate to create the surrounding neuropil mask. Right not its just
%       extracting a rectangle/square around to roi.
%   -   Calculate the mean surrounding neuropil signal. Right now it is getting the
%       median.
%

% Determine if neuropil signals should be extracted.
if nargin < 3
    getNeuropil = true; % keep this as a choice to extract roi fluorescence faster.
end

if nargin < 4
    wb_on = false;
end

% Determine number of rois, image size and number of images.
nRois = length(roiArray);
nFrames = size(imArray, 3);

% Deterimine number of chunks for extracting bulk neuropil signal
if getNeuropil
    chunkSize = 5000;
    chunks = 1:chunkSize:nFrames;
else
    chunks = [];
end
nChunks = numel(chunks);

% Preallocate arrays for signals
fmeanRoi = NaN(nRois, nFrames);
fmeanNeuropil = NaN(nRois, nFrames);

% Create neuropil mask
npmask = rmSignalExtraction.createNeuropilMask(roiArray);

if wb_on; h = waitbar(0, 'Please Wait... Extracting signals'); end

% Loop through rois.
for j = 1:nRois
    surroundroimask = rmSignalExtraction.createSurroundingRoiMask(roiArray, j);
    roi = roiArray(j);
    % Extract signal from roi, w/ or w/o surrounding neuropil
    if getNeuropil
        signal = rmSignalExtraction.extractRoiFluorescence(roi, imArray, surroundroimask, npmask);
        fmeanNeuropil(j, :) = signal.fmeanNeuropil;
    else
        signal = rmSignalExtraction.extractRoiFluorescence(roi, imArray, surroundroimask, []);
    end
    
    fmeanRoi(j, :) = signal.fmeanRoi;

    if mod(j, 10) == 0 && wb_on
    	waitbar(j/(nRois+nChunks), h)
    end
    
end

if getNeuropil
    
    fmeanBulkNeuropil = zeros(1, nFrames);
    % Extract neuropil bulk fluorescence.
    
    npBulkMask = repmat(npmask, 1, 1, chunkSize);
    
    for i = 1:nChunks
        fi = chunks(i);
        if i == nChunks
            chunkSize = nFrames - (fi-1);
            li = nFrames;
            npBulkMask = repmat(npmask, 1, 1, chunkSize);
        else
            li = (fi-1) + chunkSize;
        end  
        
        imChunk = imArray(:, :, fi:li);
        imChunk(~npBulkMask) = 0;
        
        fmeanBulkNeuropil(fi:li) = squeeze(sum(sum(imChunk, 1), 2)) / sum(npmask(:));
        waitbar((j+i)/(nRois+nChunks), h)
    end
    
else
    fmeanBulkNeuropil = NaN(nFrames, 1);
end

if wb_on; close(h); end

% Add signals to signalData struct.
signalData.meanRoiFluorescence = fmeanRoi;
signalData.meanNeuropilFluorescence = fmeanNeuropil;
signalData.meanNPilBulkFluorescence = fmeanBulkNeuropil';
signalData.roiArray = roiArray;


end


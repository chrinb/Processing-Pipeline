function signalArray = extractRoiFluorescence(imArray, roiMask, npMask, npMethod)
%extractRoiFluorescence Extract fluorescence signal of one roi.
%
%   signalArray = extractRoiFluorescence(imArray, roiMask, npMask) extracts
%   the fluorescence signal of a roi in an imageArray based on the roiMask.
%   If a neuropil mask (npMask) is supplied, the signal in the neuropil
%   region will also be extracted. The signal is the mean spatial pixel 
%   intensity within the roi for each frame.
%
%   Inputs:
%       imArray: double (nPixY, nPixX, nFrames)
%       roiMask: logical (nPixY, nPixX)
%       npMask (optional): logical (nPixY, nPixX, nSubregions)
%       npMethod: 'mean' or 'median'. Default: 'mean'
%
%   Output:
%       signalArray : double (nFrames, 1+nSubregions). Note: The signal of 
%       the roi will be in the first column, and the the signal of neuropil
%       regions will be placed in the subsequent columns. 

% Determine if surrounding neuropil fluorescence will be extracted
if nargin >= 3 && ~isempty(npMask)
    roiMask = cat(3, roiMask, npMask);
end

if nargin < 4; npMethod = 'mean'; end % Default is mean

totalMask = sum(roiMask, 3) == 1;
[~, ~, nFrames] = size(imArray);

% Find the total roi extent. Will use it to crop the imArray for faster
% signal extraction. Nb, no rewriting of imArray, so no copies made.
[y, x] = find(totalMask);
minX = min(x); maxX = max(x);
minY = min(y); maxY = max(y);

% Crop image array and roi masks
imArrayCropped = imArray(minY:maxY, minX:maxX, :);
roiMaskCropped = roiMask(minY:maxY, minX:maxX, :);

% Preallocate signalArray
signalArray = zeros(nFrames, size(roiMask, 3) );

% Extract roiSignal
for i = 1:size(roiMask, 3)
    nPixels = sum(sum(roiMaskCropped(:,:,i)));
    tmpMask = repmat(roiMaskCropped(:,:,i), 1, 1, nFrames);
    if i > 1 && isequal(npMethod, 'median')
        signalArray(:, i) = median(reshape(imArrayCropped(tmpMask), nPixels, nFrames), 1);
    else
        signalArray(:, i) = mean(reshape(imArrayCropped(tmpMask), nPixels, nFrames), 1);
    end
end


% Tested, but not significantly different for 1  roi...
% % % signalArray2 = zeros(nFrames, size(roiMask, 3) );
% % % for i = 1:size(roiMask, 3)
% % % roiPixels = find(roiMask(:,:,i));
% % % nPixPerFrame = numel(roiMask(:,:,i));
% % % roiPixels = repmat(roiPixels, 1, nFrames) + (0:nFrames-1)*nPixPerFrame;
% % % signalArray2(:,i) = mean(imArray(roiPixels));
% % % end



    
end

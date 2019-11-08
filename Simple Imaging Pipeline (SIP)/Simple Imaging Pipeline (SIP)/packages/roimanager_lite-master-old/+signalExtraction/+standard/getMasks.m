function [roiMask, npMask] = getMasks(roiArray, roiIdx, expansionFactor, imageMask)
%getMasks Return modified roi mask and surrounding neuropil mask
%
%

if nargin < 3; expansionFactor = 4; end
if nargin < 4; imageMask = true(size(roiArray(1).mask)); end

[height, width] = size(roiArray(1).mask);
nRois = numel(roiArray);

% Create a mask with all rois except for the current one
roiMaskAll = reshape([roiArray.mask], [height, width, nRois]);
roiMaskAll(:, :, roiIdx) = [];
roiMaskAll = logical(sum(roiMaskAll, 3));

% Remove surrounding rois from the roi mask
roiMaskOrig = roiArray(roiIdx).mask;
roiMask = roiMaskOrig & xor(roiMaskOrig, roiMaskAll); % Remove parts with overlap.

% Create a mask where all rois are excluded. Erode avoid spillover.
npMask = ~(roiMaskAll | roiMask);

% Not sure if this is a good idea ...?
se = strel('square', 3);
erodedNpMask = imerode(npMask, se); 

% Make a mask for the neuropil surrounding the current RoI

% Inspired by fissa

npMask = roiMaskOrig;
origArea = sum(roiMaskOrig(:));     % original area
currentArea = 0;                    % current area
maxArea = numel(roiMaskOrig) - origArea;

count = 0;

while (currentArea < expansionFactor * origArea) && (currentArea < maxArea)
    
    % Check which case to use. In current version, we alternate
    % between case 0 (cardinals) and case 1 (diagonals).

    if mod(count, 2) == 0 
        % Imdilate 1 pixel in each direction: N, E, S, W.
        nhood = [0,1,0;1,1,1;0,1,0];
        npMask = imdilate(npMask, nhood);

    elseif mod(count, 2) == 1
        % Imdilate 1 pixel in each direction:  NE, SE, SW, NW
        nhood = [1,0,1;0,1,0;1,0,1];
        npMask = imdilate(npMask, nhood);
        
    end

    % Don't include pixels which are not in the original roi
    npMask(roiMaskOrig) = false;
    
    % Also, don't include pixels that are not in the eroded neuropil mask
    % when checking the area.
    npMaskTmp = npMask;
    
    npMaskTmp(~erodedNpMask) = false;
    npMaskTmp(~imageMask) = false;
    
    % update area
    currentArea = sum(npMaskTmp(:));

    % iterate counter
    count = count + 1;
    
end

% Refine the final neuropil mask
npMask(~erodedNpMask) = false;
npMask(~imageMask) = false;

end

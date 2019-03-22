function npMask = findNeuropilMask(roiMask, expansionFactor)
%getNeuropilMask  Given the mask for a ROI, find the surrounding neuropil.
% 
%     Parameters
%     ----------
%     roiMask : logical array
%         The reference ROI mask to expand the neuropil from. The array
%         should contain only boolean values.
%     expansionFactor : double, optional
%         How much larger to make the neuropil total area than mask area.
% 
%     Returns
%     -------
%     npMask
%         A boolean mask, where the region surrounding the input is now 
%         True and the region of the input mask is False.
% 
%     Implementation
%     --------------
%     Our implementation is as follows:
%         - On even iterations (where indexing begins at zero), expand
%           the mask in each of the 4 cardinal directions.
%         - On odd numbered iterations, expand the mask in each of the 4
%           diagonal directions.
%     This procedure generates a neuropil whose shape is similar to the
%     shape of the input ROI mask.

if nargin < 2; expansionFactor = 4; end


% Ensure roiMask is a logical array
roiMask = logical(roiMask);

% Make a copy of original mask which will be grown
npMask = roiMask;
origArea = sum(roiMask(:));    % original area
currentArea = 0;               % current area
maxArea = numel(roiMask) - origArea;

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

    % Don't expand based on the original mask; any expansion into
    % this region is marked as false once more.
    npMask(roiMask) = false;

    % update area
    currentArea = sum(npMask(:));

    % iterate counter
    count = count + 1;
    
end

end
function [erodedNpMask] = createNeuropilMask(roiArray)
%createNeuropilMask Create a neuropil mask
%   npmask = createNeuropilMask(roiArray) returns a mask where all the rois
%   are removed, like a cheese with holes.

% Initialize the mask   
npMask = true(size(roiArray(1).mask));

% Loop through rois
for j = 1:numel(roiArray)
    npMask(roiArray(j).mask) = false;
end

% Expand the holes to avoid roi spillover into neuropil (e.g if the roi is tight).
se = strel('square', 5);
erodedNpMask = imerode(npMask, se); 

end


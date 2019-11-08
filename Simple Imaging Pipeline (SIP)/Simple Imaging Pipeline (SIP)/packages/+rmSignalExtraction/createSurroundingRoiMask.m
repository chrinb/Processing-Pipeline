function [roiArrayMask] = createSurroundingRoiMask(roiArray, idx)
%createSurroundingRoiMask Create a mask of surrounding rois
%   roiMask = createSurroundingRoiMask(roiArray, i) returns a mask where 
%   all the rois except roi at position idx in roiArray is included

% Initialize the mask   
roiArrayMask = false(size(roiArray(1).mask));

% Loop through rois
for j = 1:numel(roiArray)
    if j == idx
        continue
    end
    roiArrayMask(roiArray(j).mask) = true;
end

end



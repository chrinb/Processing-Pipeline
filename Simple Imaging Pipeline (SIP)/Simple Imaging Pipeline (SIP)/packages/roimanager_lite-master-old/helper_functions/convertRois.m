function roiArray = convertRois(roiArray)
% Change RoI properties to the new RoI class definition.

if ~isempty(roiArray(1).ID)    
    
    % Do it for all rois
    nRois = numel(roiArray);
    for n = 1:nRois

        roi = roiArray(n);
        shape = roi.Shape;
        imdim = [roi.ImageDimX, roi.ImageDimY];
        num = roi.ID;

        % impoints was not a property a while back, so use the mask to
        % generate new roi
        if isempty(roi.imPointsX)
            shape = 'Mask';
        end
        
        switch shape
            case 'Polygon'
                % make impoint coordinates nx2 array
                if isrow(roi.imPointsX)
                    coordinates = [roi.imPointsX; roi.imPointsY]';
                else
                    coordinates = [roi.imPointsX, roi.imPointsY];
                end
            case 'Autothreshold'
                shape = 'Mask';
                coordinates = roi.Mask;
            case 'Mask'
                coordinates = roi.Mask;
        end
        
        % Get old group
        group = roi.Group;
        
        % Create new RoI
        roi = RoI(shape, coordinates, imdim);
        % Set new group properties
        roi = setGroup(roi, group);
        roi.num = num;
        roiArray(n) = roi;

    end
    
end

end
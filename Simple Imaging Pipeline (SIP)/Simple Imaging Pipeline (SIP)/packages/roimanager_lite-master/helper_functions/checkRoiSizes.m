function rois = checkRoiSizes(rois, imdim)

% Fuck this....
for i = 1:numel(rois)
    roi = rois(i);
    roiSize = size(roi.mask);
    
    if ~isequal(roiSize, imdim)
        
        sizeDiff = roiSize - imdim;
        crop = abs([sizeDiff(1)/2, sizeDiff(2)/2]);
        
        switch roi.shape
            case 'Mask'
                oldMask = roi.mask;
                newMask = false(imdim);

                if sizeDiff(1) > 1 % (roi mask is bigger than image)
                    oldMask = oldMask(1+floor(crop(1)):end-ceil(crop(1)), 1+floor(crop(2)):end-ceil(crop(2)), :);
                    newMask = oldMask;
                else % image is bigger than roi mask
                    newMask(1+floor(crop(1)):end-ceil(crop(1)), 1+floor(crop(2)):end-ceil(crop(2))) = oldMask;
                end

                rois(i).reshape('Mask', newMask);
                
            case 'Polygon'
                imPoints = roi.coordinates;
                if sizeDiff(1) > 1
                    imPoints(:, 1) = imPoints(:, 1) - round(crop(2));
                    imPoints(:, 2) = imPoints(:, 2) - round(crop(1));
                else
                    imPoints(:, 1) = imPoints(:, 1) + round(crop(2));
                    imPoints(:, 2) = imPoints(:, 2) + round(crop(1));
                end
                
                rois(i).reshape('Polygon', imPoints, imdim);
       end

    end

end
end
    
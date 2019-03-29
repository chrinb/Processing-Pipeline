function [im] = circularCrop(im)
% CircularMask - Make a "circular crop" around an image or imageArray.
    
    nDim = length(size(im));
    
    if nDim == 2
        [num_row, num_col] = size(im);
    elseif nDim == 3
        [num_row, num_col, num_frames] = size(im);
    end

    % Define center coordinates and radius
    x = num_row/2;
    y = num_col/2;
    radius = min(x, y);

    % Generate grid with binary mask representing the circle. Credit
    % StackOverflow??
    [xx, yy] = ndgrid((1:num_row) - y, (1:num_col) - x);
    mask = (xx.^2 + yy.^2) > radius^2;

    % Mask the original image
    if nDim == 2
        im(mask) = uint8(0);
    elseif nDim == 3
        mask = repmat(mask, [1, 1, num_frames]);
        im(mask) = uint8(0);
    end
    
end         
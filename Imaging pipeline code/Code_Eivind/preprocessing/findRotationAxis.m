function [x, y] = findRotationAxis(imArray, angles)
%findRotationAxis finds distance from center of image to rotation axis

angles = round(angles);

% When number of frames and number of angles does not correspond.
nFrames = min(length(angles), size(imArray, 3));
angles = angles(1:nFrames);
imArray = imArray(:, :, 1:nFrames);

% if numel(angles(angles == 180)) < 20
%     % Find mean images in 3 different directions.
%     avgIm_zero = mean(imArray(:,:,angles == 0), 3);
%     avgIm_120 = mean(imArray(:,:, angles == 120 | angles == -240 ), 3);
%     avgIm_240 = mean(imArray(:,:, angles == 240 | angles == -120 ), 3);
% 
%     avgIm_120 = imrotate(avgIm_120, 120, 'bilinear', 'crop');
%     avgIm_240 = imrotate(avgIm_240, 120, 'bilinear', 'crop');
%     
%     % Register frames using normcorre
%     Y = double(cat(3, avgIm_zero, avgIm_120, avgIm_240));
%     options_rigid = NoRMCorreSetParms('d1', size(Y,1), 'd2', size(Y,2), ...
%                                       'bin_width', 1, 'max_shift', 30, 'us_fac', 50);
% 
%     [~, nc_shifts, ~] = normcorre(Y, options_rigid);
% 
%     shifts_x = arrayfun(@(row) row.shifts(2), nc_shifts);
%     shifts_y = arrayfun(@(row) row.shifts(1), nc_shifts);
%     
%     % todo: figure out how to transform results to a shift.
%     % Convert to x, y shift in image coordinates.
%     
%     %x = -round(shifts_x(2)/2);
% %     x = -round(shifts_x(2));
% %     y = round(tan(30/360*2*pi) * -shifts_y(2));
%     
%     
%     
% else


    % Find mean images in 2 opposite directions.
    avgIm_zero = mean(imArray(:,:,angles == 0), 3);
    avgIm_180 = mean(imArray(:,:, angles == 180), 3);
    % Rotate back to zero position
    avgIm_180 = imrotate(avgIm_180, 180, 'bilinear', 'crop');

    % Register frames using normcorre
    Y = double(cat(3, avgIm_zero, avgIm_180));
    options_rigid = NoRMCorreSetParms('d1', size(Y,1), 'd2', size(Y,2), ...
                                      'bin_width', 1, 'max_shift', 30, 'us_fac', 50);

    [~, nc_shifts, ~] = normcorre(Y, options_rigid);

    shifts_x = arrayfun(@(row) row.shifts(2), nc_shifts);
    shifts_y = arrayfun(@(row) row.shifts(1), nc_shifts);

    % Divide by two and make negative. Have to move frames halfway in the opposite
    % direction from what the correction finds to correct the off center rotation.
    x = -round(shifts_x(2)/2);
    y = -round(shifts_y(2)/2);
%end

end


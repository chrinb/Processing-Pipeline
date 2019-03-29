function frame = shiftFrame(frame, shift)
% Shift frame based on shift ([dx, dy, dtheta]).
% dx left, dy down, dtheta ccw

    dx = shift(1);
    dy = shift(2);
    dtheta = shift(3);

    % Always translate first
    if dx ~= 0 || dy ~= 0
        % Create an empty expanded canvas to hold the image
        imdim = size(frame);
        canvas = zeros(imdim(1) + abs(dy)*2, ...
                       imdim(2) + abs(dx)*2, 'uint8');

        canvas(abs(dy) + (1 : imdim(1)), ...
               abs(dx) + (1 : imdim(2)), :) = frame; % put im in cntr...


        % Crop to original size off center to move frame.
        frame = canvas( abs(dy) - dy + (1:imdim(1)), ...
                        abs(dx) - dx + (1:imdim(2)), :);

    end

    % Always rotate second
    if dtheta ~= 0
        frame = imrotate(frame, dtheta, 'bicubic', 'crop');
    end

end

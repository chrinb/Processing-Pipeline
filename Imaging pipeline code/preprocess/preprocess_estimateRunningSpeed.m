function [run_speed,wheel_movement] = preprocess_estimateRunningSpeed(run_count,fs)
% Estimate instantaneous running speed based on the counter in a optical encoder wheel.

wheel_movement = abs(diff(run_count'));
wheel_movement(wheel_movement>0) = 1; 

% Since the wheel is told to give movement in radians, each value must be
% converted.

radius = 11; % radius of wheel in cm
circum_of_wheel_cm = 2*pi*radius;% in cm
radians_per_rotation = 2*pi;

distance_per_radians_step = circum_of_wheel_cm/radians_per_rotation;
run_count = abs(diff(run_count')).*distance_per_radians_step;

window_size = 0.5 * fs; % seconds * fs
% 
% run_speed = zeros(size(run_count));
% for x = 1:length(run_count)-100
%     run_speed(x) = mean(run_count(x:x+100))/100;
%     
% end

zeropadded_count = [zeros(1,window_size/2) [run_count] zeros(1,window_size/2)];
zeropadded_count = zeropadded_count * fs;
run_speed = zeros(size(run_count));
y = 1;
for x = (window_size/2):length(zeropadded_count)-(window_size/2)-1
    run_speed(y) = mean(zeropadded_count(x-(window_size/2)+1:x+(window_size/2)));
    y = y + 1;
end



end
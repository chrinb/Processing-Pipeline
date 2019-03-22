function [run_speed,wheel_movement] = preprocess_estimateRunningSpeed(run_count,fs,sessionID)
%% PREPROCESS_ESTIMATERUNNINGSPEED 
% Uses the wheel encoder count signal to estimate the instantaneous running
% speed. A moving window is applied to smooth the speed signal.
% 
% INPUT
%   run_count: An array containing the tick count from a rotary encoder.
%   fs: sampling frequency of the run_count signal.
%   sessionID (optional): A session ID as used in the pipeline of Eivind 
%       and Andreas.
%
% OUTPUT
%   run_speed: An array of the same length as run_count, containing the
%       estimated running speed at each sample.
%   wheel_movement: An array as samen length as run_speed, but ones where
%       the is any movement at all, or zero elsewhere.
%
% WB Andreas Lande | Vervaeke Lab 2018

% Estimate instantaneous running speed based on the counter in a optical encoder wheel.
fprintf('\nESTIMATING RUNNING SPEED\n');
wheel_movement = abs(diff(run_count'));
wheel_movement(wheel_movement>0) = 1; 

% If sessionID is not given as input, expect the recorded session to be of
% type SPACE
if nargin < 3
    sessionID = 'SPACE';
end

% Since the wheel is told to give movement in radians, each value must be
% converted.

if sum(strfind(sessionID,'SPACE')) > 0 % For the space setup is use ticks
    radius = 25; % radius of wheel in cm
    circum_of_wheel_cm = 2*pi*radius;% in cm
    
    number_of_ticks = 2000;
    
    distance_per_tick = circum_of_wheel_cm/number_of_ticks;
    run_count = abs(diff(run_count')).*distance_per_tick;
    
else % For the Visual Active Avoidance setup is use radians
    radius = 11;  % radius of wheel in cm
    circum_of_wheel_cm = 2*pi*radius; % in cm
    radians_per_rotation = 2*pi;
    
    distance_per_radians_step = circum_of_wheel_cm/radians_per_rotation;
    run_count = abs(diff(run_count')).*distance_per_radians_step;
end

% Smoothing window
window_size = 0.5 * fs; % seconds * fs

%%-- Using a moving window averaging before y
zeropadded_count = [zeros(1,window_size) [run_count]];

run_speed = zeros(size(run_count));
y = 1;
for x = window_size:length(zeropadded_count)
    run_speed(y) = sum(zeropadded_count(x-window_size+1:x))/0.5;
    y = y + 1;
end

fprintf('+ Running speed estimated. Used 0.5 seconds moving average for smoothing.\n');
end
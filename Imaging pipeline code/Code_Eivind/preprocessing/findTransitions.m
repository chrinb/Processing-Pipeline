function [ labviewData, transitions ] = findTransitions( labviewData )
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

rotating = labviewData(:, 4);

% if vector with rotating does not exist: create from stagepositions
if any(any(isnan(rotating)))
    angles = labviewData(:, 3);
    
    % Create rotation/ and transition "boolean" arrays.
    rotating = false(size(angles));
    
    angleDiff = diff(angles);
    rotating(abs(angleDiff) >= 0.2) = 1;
    % Get rid of glitches...
    rotating = medfilt1(rotating, 5, [], 2);
    labviewData(:, 4) = rotating;
end

% Make array with transitions between stationary and rotating
transitions = zeros(size(rotating));
transitions(2:end) = diff(rotating);

end


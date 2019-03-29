function [ newData ] = loadPupilData( sessionID, block )
%loadPupilData Load pupil data for specified block
%   PUPILDATA = loadPupilData(sessionID, BLOCK) returns an array of data
%   containing results from pupiltracking for BLOCK no of specified
%   session.

sessionFolder = getSessionFolder(sessionID);
blockFolders = dir(fullfile(sessionFolder, 'labview_data', '*block*'));

isBugged = bugcheckSession(sessionID, 'eyetrackingdata_longfile');

blockFolder = fullfile(sessionFolder, 'labview_data', blockFolders(block).name);

% Load data from pupil tracking
try
    if isBugged
        pupilData = correctEyetrackingFile(sessionID, block);
    else
        pupilFile = dir(fullfile(blockFolder, '*eyetracking*'));
        %pupilData = csvread(fullfile(blockPathRaw, pupilFile(1).name));
        pupilData = load(fullfile(blockFolder, pupilFile(1).name));
        %importdata gives error if some columns contain only nans. E.g if
        %tracking in dark.
    end
catch
    pupilData = nan(1, 5);
end


pupilDiameter = pupilData(:, 3);
pupilSamplingTimes = (pupilData(:, 2) - pupilData(1, 2)) / 1000; % in seconds

% Calculate frame to frame displacement of pupil
pupilDisplacement = nan(length(pupilDiameter), 1);
pupilDisplacement(1) = 0;

for j = 2:size(pupilData, 1)
    deltaXsq = (pupilData(j, 4) - pupilData(j-1, 4))^2;
    deltaYsq = (pupilData(j, 5) - pupilData(j-1, 5))^2;
    deltaS = sqrt(deltaXsq + deltaYsq);
    pupilDisplacement(j) = deltaS;
end

newData = zeros(size(pupilData, 1), 3);
newData(:, 1) = pupilSamplingTimes;
newData(:, 2) = pupilDiameter;
newData(:, 3) = pupilDisplacement;

end


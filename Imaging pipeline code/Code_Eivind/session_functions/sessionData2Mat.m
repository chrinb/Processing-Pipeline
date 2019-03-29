%sessionData2Mat places data in a struct and saves to a mat file.
%   Acquired metadata and data from a session is placed in a struct and
%   saved to disk.
%   
% INPUT:
%   sessionID (str): m%03d-yyyymmdd-hhmm where d is number of mouse
%   blocks (array): which blocks to retrieve. If empty; will retrieve all 
%
% EXAMPLE:
%   sessionData2Mat('m007-20161004-1837', [1, 2, 4, 5, 7, 8])
%
% FIELDS:
%   
%   metadata from session:
%
%   * sessionID (str) : m002-yyyymmdd-hhmm
%   * mouse (int) : number of mouse
%   * protocol (str) : name of protocol used
%   * date (str) : yyyymmdd
%   * startTime (str) : hhmm
%   * endTime (str) : hhmm
%   * rawDataPath (str) : drive/path where raw_data is stored
%   * backupPath (str) : drive/path where raw_data in backed up
%   * fovID (int) : have a reference image with a unique number for each fov
%   * fovCenterCoords (array) :  x, y coordinates of center of field of view in reference image
%   * imagingDepth (int) : imaging depth in micrometer
%   * nBlocks
%   * nBlocksLight
%   * nBlocksDark
%   * lights (bool) 
% 
%   session data:
% 
%   * roiArray
%   * nRois (int) : 
%   * nFrames (int) :
%   * timePoints (nFrames) : 
%   * signal (nBlocks, nRois, nFrames) : 
%   * stagePositions (nBlocks, nFrames) : 
%   * anglesRW (nBlocks, nFrames) : mouse orientation in real world 
%   * anglesIA (nBlocks, nFrames) : mouse orientation in arena (N/I)
%   * wallPositions : 
%   * stageRotating (bool) 
%   * stageTransition (bool)
%   * wallRotating (bool)
%   * stageSpeed : (N/I)
%   * stageAcceleration : (N/I)
%   * wallSpeed
%   * wallAcceleration
%   * stageRotationDirection
%   * wallRotationDirection
%   * nFramesToIgnore
%   * pupilTimes
%   * pupilDiameter (nBlocks, nSamples)
%   * pupilDisplacement (nBlocks, nSamples)
%
% NB: 
%   Baseline subtraction can be improved. Maybe put into a function..
%   Calculating strugglefactor is slow. Slower than before??


% TODO: add ptimes.
% Normalize raw signal and baseline subtract raw signal.

function [ ] = sessionData2Mat( sessionID, blocks )

sessionFolder = getSessionFolder(sessionID);

% Get session info which is recorded by the labview program running the
% experiments. Sessiondata initiated from this struct.
metadataLV = loadSessionInfo( sessionID );
sessionData = metadataLV;


% Make some divisions of experimental types.
switch sessionData.sessionProtocol
    case {'Rotations - Speed 45 deg/s', 'Free Water'}
        experimentType = 'activeRotationTask';
end

% Sessiondata will contain data from the specified blocks
if nargin < 2
    nBlocks = sessionData.nBlocks;
    blocks = 1:nBlocks;
else
    nBlocks = length(blocks);    
end
sessionData.loadedBlocks = blocks;

% Calculate duration of session. Why not do this in labview? /todo
start_time = datetime(sessionData.sessionStarted, 'ConvertFrom', 'HH:MM:SS');
end_time = datetime(sessionData.sessionEnded, 'ConvertFrom', 'HH:MM:SS');
sessionData.sessionDuration = datestr((end_time - start_time), 13);

% /todo
% Refer to a lookuptable with laser offset vs laserpower.

% Load roi array
sessionData.roiArray = loadRoiArray( sessionID, 2);
sessionData.nRois = length(sessionData.roiArray);

% Load imaging metadata.
metadata2P = loadImagingMetadata(sessionID);
fields = {'microscope', 'zPosition', 'umPerPx_x', 'umPerPx_y', 'nCh', 'channels', ...
          'channelNames', 'channelColor'};
for f = 1:length(fields)
    sessionData.(fields{f}) = metadata2P.(fields{f});
end

switch metadata2P.microscope;
    case 'Prairie'
        sessionData.firstFrame = 60;
    case 'SciScan'
        sessionData.firstFrame = 1;
end

% Make some assertions
if ~(metadata2P.nBlocks == metadataLV.nBlocks)
    disp('Number of session blocks and number of imaging series does not correspond')
end

% /todo: check frametimes

%sessionData.numFramesToIgnore = 60;  % If this is active: set start and stop idx.

% Calculate maximum number of common samples between blocks
imFrames = min(metadata2P.nFrames) - 1; % imFrames = min(metadata2P.nFrames(blocks));
lvSamples = min(metadataLV.nSamples) - 1; %lvSamples = min(metadataLV.nSamples(blocks))
sessionData.nFrames = min(imFrames, lvSamples) - (sessionData.firstFrame - 1);

% Prairie images are registered from frame 60 and onwards. Labview data needs to be
% aligned with that, and following variables are used to make sure all data is timealigned.
nFrames = sessionData.nFrames;
first = sessionData.firstFrame;
last = nFrames + (first - 1);


nPupilSamples = min(metadataLV.nPupilSamples);

% Assume same time vector for all blocks /todo: start from different index?
sessionData.timePoints = metadata2P.times{1}(first:last);

% Preallocate arrays for storing info
for ch = metadata2P.channels
    sessionData.(['signalCh', num2str(ch)]) = zeros(nBlocks, sessionData.nRois, nFrames);
end
    
sessionData.stagePositions = zeros(nBlocks, nFrames);
sessionData.anglesRW = zeros(nBlocks, nFrames);
sessionData.rotating = zeros(nBlocks, nFrames);
sessionData.transitions = zeros(nBlocks, nFrames);
sessionData.frameShifts = zeros(nBlocks, nFrames);
sessionData.frameMovement = zeros(nBlocks, nFrames);

sessionData.pupilDiameter = zeros(nBlocks, nPupilSamples);
sessionData.pupilDisplacement =  zeros(nBlocks, nPupilSamples);
sessionData.pupilTimes =  zeros(nBlocks, nPupilSamples);

switch experimentType
    case 'activeRotationTask'
        sessionData.lickResponses = zeros(nBlocks, nFrames);
        sessionData.waterRewards = zeros(nBlocks, nFrames);
end



% Go through block folders and save all block-relevant data to mat.file
for block = blocks
    
%     % Load brightness over time for ROIs
%     for ch = metadata2P.channels %/todo: get correct naming in signalData
%         signalData = extractSignals(sessionID, block, ch);
%         sessionData.(['signalCh', num2str(ch)])(block, :, :) = signalData.Signal(1:nFrames, :).'; %['signalCh', num2str(ch)]
%     end

    % Find tiffFiles in aligned folder
    tiffFiles = dir(fullfile(sessionFolder, 'calcium_images_aligned', '*.tif'));
    nChunks = length(tiffFiles);
    chunkLength = 5000; % Should be registered to sessionobject during registration.
    for chunk = 1:nChunks
        startFrame = 1 + (chunk-1)*chunkLength;
        for ch = metadata2P.channels %/todo: get correct naming in signalData
            signalData = extractSignals(sessionID, chunk, ch);
            nSig = size(signalData.Signal, 1);
            sessionData.(['signalCh', num2str(ch)])(1, :, startFrame:nSig+startFrame-1) = signalData.Signal(1:nSig, :).'; %['signalCh', num2str(ch)]
        end
    end
    
    % Load labview data, e.g. stage positions and pupil info
    labviewData = loadLabviewData(sessionID, block, 'all');
    sessionData.stagePositions(block, :) = labviewData(first:last, 3);
    sessionData.anglesRW(block, :) = absoluteAngle2relative(sessionData.stagePositions(block, :));
    sessionData.rotating(block, :) = labviewData(first:last, 4);
    sessionData.transitions(block, :) = labviewData(first:last, end);

    % Load pupildata and /todo resample to correspond with signal
    pupilData = loadPupilData(sessionID, block);
    %pupilData = resample(pupilData, sessionData.timePoints);
    sessionData.pupilTimes(block, :) = pupilData(1:nPupilSamples, 1);
    sessionData.pupilDiameter(block, :) = pupilData(1:nPupilSamples, 2);
    sessionData.pupilDisplacement(block, :) = pupilData(1:nPupilSamples, 3);

    % Get frame corrections and frame movement.
    frameCorrections = loadFrameCorrections(sessionID, block);
    frameCorrections = frameCorrections(1:nFrames, :);
    frameMovement = zeros(length(frameCorrections), 1);
    frameMovement(2:end) = sqrt( diff(frameCorrections(:, 1)).^2 + ...
                                      diff(frameCorrections(:, 2)).^2 ); %sqrt(dx^2+dy^2)
    
    sessionData.frameShifts(block, :) = frameCorrections(1:nFrames);
    sessionData.frameMovement(block, :) = frameMovement(1:nFrames);
    
    % Get licking data if this is an active task
    switch experimentType
        case 'activeRotationTask'
            licks = loadLabviewData(sessionID, block, 'licks');
            water = loadLabviewData(sessionID, block, 'water');
            sessionData.lickResponses(block, :) = licks(first:last);
            sessionData.waterRewards(block, :) = water(first:last);
    end
end

% Calculate delta F over F
if ~isempty(strfind(sessionData.sessionProtocol, 'continuous'))
    sessionData = deltaFoverFcontinuous( sessionData );
elseif ~isempty(strfind(sessionData.sessionProtocol, 'step'))
    sessionData = deltaFoverFstep( sessionData );
elseif strcmp(experimentType, 'activeRotationTask')
    sessionData = deltaFoverFsimple( sessionData );
    %error('No delta F over F method for protocol of this session')
end

% Normalize signals
for ch = metadata2P.channels
    minVal = min(sessionData.(['signalCh', num2str(ch)])(:));
    maxVal = max(sessionData.(['signalCh', num2str(ch)])(:));
    sessionData.(['signalCh', num2str(ch)]) = (sessionData.(['signalCh', num2str(ch)]) - minVal) / (maxVal-minVal);
end

% Add struggle Factor
[ sTimes, struggleFactor ] = getBodyMovement( sessionID, blocks );
sessionData.sTimes = sTimes;
sessionData.struggleFactor = struggleFactor;

% Crop array of pupil and strugglefactor to align with imaging and labview data.
start_time = sessionData.timePoints(1);

delta_t_pupil = abs(sessionData.pupilTimes(1, :) - start_time);
[~, idx] = min(delta_t_pupil);
sessionData.pupilTimes = sessionData.pupilTimes(:, idx:end);
sessionData.pupilDiameter = sessionData.pupilDiameter(:, idx:end);
sessionData.pupilDisplacement = sessionData.pupilDisplacement(:, idx:end);

delta_t_sFactor = abs(sessionData.sTimes - start_time);
[~, idx] = min(delta_t_sFactor);
sessionData.sTimes = sessionData.sTimes(idx:end);
sessionData.struggleFactor = sessionData.struggleFactor(:, idx:end);

save(fullfile(sessionFolder, ['session-', sessionID, ...
                              '-data.mat']), 'sessionData')
                  
% cd(getPathToDir('labbook_mat'))
save(fullfile(getPathToDir('labbook'), 'sessionData', ['session-', sessionID, ...
                              '-data.mat']), 'sessionData')
                          
% Add session to experiment inventory   
s = session(sessionID);
s.isAnalyzed = true;
s.imDepth = sessionData.zPosition;
savetoDB(s)

end

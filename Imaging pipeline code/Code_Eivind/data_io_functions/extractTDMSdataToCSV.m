% Create stage Position file

function extractTDMSdataToCSV(sessionID)

sessionFolder = getSessionFolder(sessionID);
labviewFolder = fullfile(sessionFolder, 'labview_data');

blockFolder = dir(fullfile(labviewFolder, '*block*'));
labviewFolder = fullfile(labviewFolder, blockFolder(1).name);

% Find tdms file with stage positions and convert to mat file
tdmsFile = dir(fullfile(labviewFolder, '*processed_setup_data.tdms'));
matFile = simpleConvertTDMS(fullfile(labviewFolder, tdmsFile(1).name));

load(matFile{1})

varPreFix = strrep(sessionID, '-', '');

% Identify frame ttl
frameSignal = eval([varPreFix, '2PFrames', '.Data']);
newFrameIdx = find(diff(vertcat(0, frameSignal)) == 128);

stagePos = eval([varPreFix, 'StagePosition', '.Data']);
stageMov = eval([varPreFix, 'StageMoving', '.Data']);
wallPos = eval([varPreFix, 'WallPosition', '.Data']);
wallMov = eval([varPreFix, 'WallMoving', '.Data']);
pupilSample = eval([varPreFix, 'PupilSampleNo', '.Data']);
lickSamples = eval([varPreFix, 'Licks', '.Data']);
water = eval([varPreFix, 'Water', '.Data']);



% Take stage pos and stage mov from same time point
csvData = zeros(length(newFrameIdx), 7);
csvData(:, 1) = 1:length(newFrameIdx);
csvData(:, 2) = nan;
csvData(:, 3) = stagePos(newFrameIdx);
csvData(:, 4) = stageMov(newFrameIdx);
csvData(:, 5) = wallPos(newFrameIdx);
csvData(:, 6) = wallMov(newFrameIdx);
csvData(:, 7) = pupilSample(newFrameIdx);

% Save as csv file. Check script (eyetracking bug correct)
newFileNm = fullfile(labviewFolder, [sessionID, '-arena_positions.txt']);
dlmwrite(newFileNm, csvData, 'delimiter', '\t', 'precision', '%.6f')

% Take licking data and water rewards from same time point
csvData = zeros(length(newFrameIdx), 2);
csvData(:,1) = lickSamples(newFrameIdx);
csvData(:,2) = water(newFrameIdx);

% Save as csv file.
newFileNm = fullfile(labviewFolder, [sessionID, '-lick_responses.txt']);
dlmwrite(newFileNm, csvData, 'delimiter', '\t', 'precision', '%.6f')

end





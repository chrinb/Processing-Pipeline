function blockPupilData = correctEyetrackingFile(sessionID, block)

% sessionID = 'm034-20170627-1555-004';

% For a while from 2017??? to 20170705?, there was a bug in Labview so that
% the text file with eyetracking results contained results from all
% previous blocks run from that labview session. Ideally, data would be
% cleared and only data from the current block would be saved to the text
% file
%
% This function uses the millisecond timer count from the textfile to find
% the last block that was recorded, and saves that to a new textfile in the
% blockfolder. new textfile gets the name extension _corrected.

sessionFolder = getSessionFolder(sessionID);
blockFolders = dir(fullfile(sessionFolder, 'labview_data', '*block*'));

blockFolder = fullfile(sessionFolder, 'labview_data', blockFolders(block).name);

pupilFile =  dir(fullfile(blockFolder, '*eyetracking*corrected*'));

% If file with corrected data is not there; create it.
if isempty(pupilFile)
    pupilFile = dir(fullfile(blockFolder, '*eyetracking*'));
    pupilData = load(fullfile(blockFolder, pupilFile(1).name));
    timeDiff = diff(pupilData(:,2));
    transitionIdx = vertcat(1, find(timeDiff>5000) + 1, size(pupilData, 1));

    blockPupilData = pupilData(transitionIdx(end-1):transitionIdx(end), :);
    newFileNm = fullfile(blockFolder, strrep(pupilFile(1).name, '.txt', '_corrected.txt'));
    dlmwrite(newFileNm, blockPupilData, 'delimiter', '\t', 'precision', '%.6f')
    
else 
    blockPupilData = load(fullfile(blockFolder, pupilFile(1).name));
end

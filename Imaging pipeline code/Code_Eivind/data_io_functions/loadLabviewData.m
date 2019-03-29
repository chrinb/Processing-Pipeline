function [ labviewData ] = loadLabviewData( sessionID, block, field )
%loadLabviewData Load labview data for specified block
%   LVDATA = loadLabviewData(sessionID, BLOCK, FIELD) returns an array of
%   data corresponding to each imaging frame for BLOCK No from specified
%   session. FIELD is optional and can be added to load specific column of
%   array.
%   
%   By default all fields are returned, but field can also be
%   specified as one of the following:
%       - rotating      -   logical vector, true if stage was rotating.
%       - angles        -   vector, stage position (0-360 deg) for each frame
%       - ms_count      -   vector, labview millisecond count for each frame
%       - licks
%       - water

if nargin < 3
    field = 'all';
end

sessionFolder = getSessionFolder(sessionID);
blockFolders = dir(fullfile(sessionFolder, 'labview_data', '*block*'));

blockFolder = fullfile(sessionFolder, 'labview_data', blockFolders(block).name);

% Load textfile with frame by frame info
textfile = dir(fullfile(blockFolder, '*arena_positions*'));
lickfile = dir(fullfile(blockFolder, '*lick_responses*'));
% File might not be there, then try to extract info from tdms file
if isempty(textfile)
    extractTDMSdataToCSV(sessionID)
    textfile = dir(fullfile(blockFolder, '*arena_positions*'));
    lickfile = dir(fullfile(blockFolder, '*lick_responses*'));
end
textfilePath = fullfile(blockFolder, textfile(1).name);
labviewData = importdata(textfilePath);

% Make test for length. Assertion... Handle if files are shorter as they
% were in the good old days. Add nans...

switch field
    case {'rotating', 'all'}
        
        nCols = size(labviewData, 2);
        if nCols < 6
            % Fill with empty nans
        end
        
    case {'licks', 'water'}
        lickfilePath = fullfile(blockFolder, lickfile(1).name);
        lickData = importdata(lickfilePath);
        

end

[labviewData, transitions] = findTransitions( labviewData );
labviewData(:, end+1) = transitions;

% make rotation and transition boolean arrays here...

switch field
    case 'angles'
        labviewData = labviewData(1:end, 3); % StagePosition (Angles)
    case 'rotating'
        labviewData = labviewData(1:end, 4); % StagePosition (rotating)
    case 'ms_count'
        labviewData = labviewData(1:end, 2); % StagePosition (millizecond count)
    case 'all'
        return
    case 'licks'
        labviewData = lickData(1:end, 1);
    case 'water'
        labviewData = lickData(1:end, 2);
        
end

end


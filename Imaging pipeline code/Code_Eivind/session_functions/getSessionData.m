function [ sessionData ] = getSessionData( sessionID )
%getSessionData Load session data from session with sessionID
%
%   INPUT:
%     sessionID (str): m%03d-yyyymmdd-hhmm-%03r where d is mouse number
%                      and r is the recording number.
%                      NOTE: sessionIDs prior to march-17 had no recording
%                      number.
%   OUTPUT:
%     sessionData (str): struct with all information from one session

sessionFolder = getSessionFolder(sessionID);
dataFile = dir(fullfile(sessionFolder, '*data.mat'));

% Search in Google Folder if nothing is found is sessionFolder
if isempty(dataFile)
    sessionFolder = fullfile(getPathToDir('labbook'), 'sessionData');
    dataFile = dir(fullfile(sessionFolder, ['*', sessionID, '*']));
end
    

try
    load(fullfile(sessionFolder, dataFile(1).name))
catch
    error (['File not found for session: ' sessionID])

end


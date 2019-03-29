function [ sessionPath ] = getSessionFolder( sessionID )
%getSessionFolder returns full path to session folder
%
%   INPUT:
%     sessionID (str): m%03d-yyyymmdd-hhmm-%03r where d is mouse number
%                      and r is the recording number.
%                      NOTE: sessionIDs prior to march-17 had no recording
%                      number.
%   OUTPUT:
%     sessionPath (str): full path to session folder for sessionID

assert(strncmp(sessionID, 'm', 1), 'Invalid Session ID')

sObj = session(sessionID);

if isempty(sObj.storageRootPath) % Use connected drive
    hddPath = getPathToDir('datadrive');
else
    hddPath = sObj.storageRootPath;
end

% Mouse folder and session folder
mouseFolder = ['mouse', sessionID(2:5)];
sessionFolder = ['session-', sessionID];


% Build pathname for session folder
sessionPath = fullfile(hddPath, mouseFolder, sessionFolder);

end
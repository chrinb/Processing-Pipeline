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
%
% Written by Eivind Hennestad

% Based on the sessionID begining, decide how to find folderpath
if strncmp(sessionID,'m',1) % If sessionID follows the regular structure
    
    sObj = session(sessionID);
    
    hddPath = getPathToDir('datadrive');
    
%     if isempty(sObj.storageRootPath) % Use connected drive
%         hddPath = getPathToDir('datadrive');
%     else
%         hddPath = sObj.storageRootPath;
%     end
    
    % Mouse folder and session folder
    mouseFolder = ['mouse', sessionID(2:5)];
    sessionFolder = ['session-', sessionID];
    
    % Build pathname for session folder
    sessionPath = fullfile(hddPath, mouseFolder, sessionFolder);
    
    
elseif strncmp(sessionID,'ID',2) % If sessionID indicates a raw recording folder
    sessionID = strrep(sessionID,'+','\');
    sessionPath = ['D:\',sessionID(4:end)];

    
else  % Something is wrong
    error('SessionID does not correspond to any options in getSessionFolder().'); 
    
end


end
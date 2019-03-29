function [] = updateExperimentInventory()
% Search for session IDs that are not in experiment database and add all new ones.

experimentInventory = loadExpInv();

%labview_data_path = fullfile(getPathToDir('google_drive_lab'), 'RotationExperiments', 'LabviewData');

labview_data_path = '/Volumes/Experiments';
mouseFolders = dir(fullfile(labview_data_path, 'mouse*'));
mouseFolders = fullfile(labview_data_path, {mouseFolders.name});

sessionFolders = {};

for m = 13:length(mouseFolders)
    m_sessionfolders = dir(fullfile(mouseFolders{m}, 'session*'));
    m_sessionfolders = fullfile(mouseFolders{m}, {m_sessionfolders.name});
    sessionFolders = vertcat(sessionFolders, m_sessionfolders.');
end

for s = 1:length(sessionFolders)
    sessionFolder = sessionFolders{s};
    sessionID = getSessionIDfromString(sessionFolder);
    LVxml = dir(fullfile(sessionFolder, 'labview_data', '*.xml')); %testing
    sessionXML = parseLabviewXML(fullfile(sessionFolder,  'labview_data', LVxml(1).name));
    %sessionID = sessionXML.sessionInfo.sessionID;
    
    % Search for sessionID in expInv and return session entry if it exists
    entry = find(strcmp(sessionID, experimentInventory(:,1)), 1);
    
    if isempty(entry)
        disp(sessionID)
        sObj = session(sessionID);
        %sObj.imLocation = sessionXML.sessionInfo.LocationID;
        sObj.protocol = sessionXML.sessionInfo.sessionProtocol;
        sObj.isTransferedImData = false;
        sObj.isTransferedLVData = false;
        
        experimentInventory(end+1, :) = {sObj.sessionID, sObj}; %/todo preallocate
    end
    
end

saveExpInv( experimentInventory )

    
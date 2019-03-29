function [ ] = transferSciScanFiles( sessionID )
%transferSciScanFiles Transfer imaging data from external drive to storage drive
%   transferSciScanFiles(sessionID) copies all SciScan imaging data for a specified 
%   session from an external drive to a storage drive. The path to these drives has to be 
%   set in pipeline_settings/getPathToDir for this function to work.

% Assumes that destination paths are already built..

% Path to session folder where data is copied to.
dst_session_folder = fullfile(getSessionFolder(sessionID), 'calcium_images_raw_ss');
if ~exist(dst_session_folder, 'dir'); mkdir(dst_session_folder); end

% Base paths for source files
src_drive = getPathToDir('images_transfer');

% Select SciScan Folder from correct date
dateFolderNm = [sessionID(6:9), '_', sessionID(10:11), '_', sessionID(12:13)];

src_path = fullfile(src_drive, dateFolderNm);

% List all sciscan folders with images
sciscanFolders = dir(fullfile(src_path));

% Get labview metadata
sessionInfo = loadSessionInfo(sessionID);
blockTimes = sessionInfo.blockStartTimes;

for block = 1:length(blockTimes)
    blockTime = blockTimes(block);
    blockTime = datetime(blockTime, 'ConvertFrom', 'HH:MM:SS');
    timestr = datestr(blockTime, 'yyyymmdd_HH_MM');
    
    idx = find(strncmp({sciscanFolders.name}, timestr, 14)); %/todo: debug..
    
    newFilenm = ['sciscan_data_', sessionID, '_block', num2str(block, '%03d')];
    
    copyfile(fullfile(src_path, sciscanFolders(idx).name), ...
             fullfile(dst_session_folder, newFilenm))
end


% % % Gather all destination folders from respective days.
% % 
% % for s = 1:length(sessionIDs)
% %     sessionPath = getSessionFolder(sessionID);
% %     nBlocks = findNBlocks(sessionID);
% %     
% %     for b = 1:nBlocks
% %         % Hvordan linker vi n? blokk med sciscan mappe. TimeStamp? Bruke
% %         % array fra labview fil med block start tid. Match block start time
% %         % og time stamp i sciscan mappe.
% %         
% %         % Deretter gi nytt navn til mappen og kopiere til session folder og
% %         % calcium_images_raw_ss/block nr
% %         
% %     end
% %     
% % end

end


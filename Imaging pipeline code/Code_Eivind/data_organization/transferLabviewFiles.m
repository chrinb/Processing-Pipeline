function [ ] = transferLabviewFiles( sessionID )
%transferLabviewFiles Transfer labview data from external drive to storage drive
%   transferLabviewFiles(sessionID) copies all Labview files for a specified session from 
%   an external drive to a storage drive. The path to these drives has to be set in
%   pipeline_settings/getPathToDir for this function to work.

% Path to session folder where data is copied to.
dst_session_folder = getSessionFolder(sessionID);
if ~exist(dst_session_folder, 'dir'); mkdir(dst_session_folder); end

% Find session folder where data is copied from
src_drive = getPathToDir('labview_transfer');

mouseNo = str2double(sessionID(2:4));
mouseFolderName = strcat('mouse', num2str(mouseNo, '%03d'), '*');

% Find mouse folder with data on labview transfer drive
srcMouseFolder = dir(fullfile(src_drive, mouseFolderName));
srcMouseFolder = fullfile(src_drive, srcMouseFolder(1).name);

src_session_folder = fullfile(srcMouseFolder, strcat('session-', sessionID));

disp('Copying labview data to storage drive...')

try
    tStart = tic;
    copyfile(src_session_folder, dst_session_folder);
    fprintf('Hurrah! Files copied succesfully. Elapsed time: %.2f s. \n', toc(tStart))
catch
    disp('Oh no! Something went wrong when copying labview data:( FUUUCK!##$%#!!')
end


end


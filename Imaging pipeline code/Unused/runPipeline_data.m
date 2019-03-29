%Run SIMA
% DYLD_INSERT_LIBRARIES=/opt/local/lib/libgcc/libgfortran.3.dylib:/opt/local/lib/libtiff.5.dylib
% /Applications/MATLAB_R2016a.app/bin/matlab from cmd

% Get access to Prairie disk through the server: 
% Check the mounted points using df or df -h
% It gives a list of mounted drives. If there are more than one D_L-122, 
% e.g. D_L-122-1, this might be the one that is accessible.


% USAGE
%   Add sessionIDs for experiments that were run today
%   Specify where to find labview data. Typically external drive
%   Change tSeriesPath if necessary
%   Change storageLocal if necessary


% sessionIDs = { 'm021-20170202-1400', ...
%             'm021-20170202-1408', 'm021-20170202-1415', 'm021-20170202-1429', 'm021-20170202-1435',...
%             'm021-20170202-1441', 'm021-20170202-1447', 'm021-20170202-1453'};
          
          
 sessionIDs = {'m030-20170219-2024', 'm030-20170219-2031', ...
               'm030-20170219-2037', 'm030-20170219-2041', 'm030-20170219-2047', 'm030-20170219-2050'};

overworked_underpaid_researcher = 'Eivind'; % Eivind or Anna

switch overworked_underpaid_researcher
    
    case 'Eivind'
        % Add local path for storing data.
        storageLocal = '/Volumes/Storage/Eivind/RotationExperiments';
        % Specify where Labview data is saved 
        labviewDataPath = '/Volumes/Labyrinth/labview_data';

    
    case 'Anna'
        % Add local path for storing data.
        %storageLocal = '/Volumes/Storage/Anna/Expts Dec 2016';
        storageLocal = '/Volumes/Anna/Data Backup';
        % Specify where Labview data is saved 
        labviewDataPath = '/Volumes/Anna/Expts Dec 2016';
        
end

% Find Prairie Mount Point. If other users on mac are logged on to the
% server, the disk is mounted with an extra number.
% prairieDisk = '/Volumes/D_L-122';
% for i = 1:5
%     try
%         addpath(prairieDisk)
%         break
%     catch
%         prairieDisk = strcat('/Volumes/D_L-122-', num2str(i));
%     end
% end
prairieDisk = '/Volumes/D_L-122-1';

switch overworked_underpaid_researcher
    case 'Eivind'
        % Add path where Imaging data is located.
        %tSeriesPath = fullfile(prairieDisk, 'Eivind', 'RotationExperiments');
        %tSeriesPath = fullfile(prairieDisk, 'Eivind');
        tSeriesPath = '/Volumes/2Photon_Backup_01/microscope_backup-2017-feb2';
    case 'Anna'
        % Add path where Imaging data is located.
        %tSeriesPath = fullfile(prairieDisk, 'Anna');
        tSeriesPath = '/Volumes/Anna/prism';
end
    

%Copy data for each session and run image alignment
for i = 1:length(sessionIDs)
    
    sessionID = sessionIDs{i};
    sessionFolder = strcat('session-', sessionID);

    start_time = clock;
    timestr = [num2str(start_time(4), '%02d'), ':' num2str(start_time(5), '%02d'), ...
               ':' num2str(round(start_time(6)), '%02d')];
    
    fprintf(['\n', ...
'                           - ' timestr,  ' -\n', ...
'--------------------------------------------------------------------- \n', ...
' Extracting session data for session: ', sessionID, '\n', ...
'--------------------------------------------------------------------- \n', ...
          '\n' ])
    
    
    mouseNo = str2double(sessionID(2:4));

    mouseFolderPrefix = strcat('mouse', num2str(mouseNo, '%03d'), '*');

    %% Get path to local mouse folder
    try
        localMouseFolder = dir(fullfile(storageLocal, mouseFolderPrefix));
        localMouseFolder = fullfile(storageLocal, localMouseFolder(1).name);
    catch
        localMouseFolder = fullfile(storageLocal, mouseFolderPrefix(1:end-1));
        mkdir(localMouseFolder)
    end

    
    %% Get path to labview mouse Folder
    labviewMouseFolder = dir(fullfile(labviewDataPath, mouseFolderPrefix));
    labviewMouseFolder = fullfile(labviewDataPath, labviewMouseFolder(1).name);

    
    %% Copy session folder with labview data to local drive
    disp('Copying labview data to local storage ...')
    
    try
        tStart = tic;
        copyfile(fullfile(labviewMouseFolder, sessionFolder), ...
                 fullfile(localMouseFolder, sessionFolder));
        fprintf('Hurrah! Files copied succesfully. Elapsed time: %.2f s. \n', toc(tStart))
    catch
        disp('Oh no! Something went wrong :( FUUUCK!##$%#!!')
        continue
    end
    

    % Find corresponding Tseries Data
    prairieMouseFolder = dir(fullfile(tSeriesPath, mouseFolderPrefix));
    prairieMouseFolder = fullfile(tSeriesPath, prairieMouseFolder(1).name);
    tSeriesParent = fullfile(prairieMouseFolder, sessionID(6:13));
    tSeriesFolder = strcat('TSeries-', sessionID(10:13), sessionID(6:9), ...
                           '-', sessionID(15:18), '-001');
    localTseriesFolder = fullfile(localMouseFolder, sessionFolder, ...
                                  'calcium_images');
    mkdir(localTseriesFolder)
    
    
%     %% Copy TSeries folder to local sessionFolder
%     disp('Copying calcium images to local storage ...')
%     try
%         tStart = tic;
% 
%         copyfile( fullfile(tSeriesParent, tSeriesFolder), ...
%                   fullfile(localTseriesFolder, tSeriesFolder) );
%         fprintf('YAAY! Files copied succesfully. Elapsed time: %.2f s. \n', toc(tStart))
%         
%     catch
%         disp('Oh no! This went south :( DOUBLE FUUUCK!!')
%         continue
%     end
%         

    %% Run image registration.
%    try
%         %Crop to 512x512 and check performance
%         cd('/Users/Eivind/Code/RotationExperiments')
%         SessionData2Mat(sessionID)
         addBodyMovementToSessionData( sessionID )
%         cd('/Users/Eivind/Code')
%    catch
%        disp('Oh no! This went south :( DOUBLE FUUUCK!!')
%        continue
%    end

    end_time = clock;
    elapsed_time = getElapsedTime(start_time, end_time);
    timestr = [num2str(end_time(4), '%02d'), ':' num2str(end_time(5), '%02d'), ...
               ':' num2str(round(end_time(6)), '%02d')];
    elapsed_timestr = [num2str(elapsed_time(4), '%02d'), ':' num2str(elapsed_time(5), '%02d'), ...
               ':' num2str(round(elapsed_time(6)), '%02d')];
    fprintf(['\n', ...
    'Fetching data for session: ', sessionID, ' was completed in ' elapsed_timestr '\n' ])

end


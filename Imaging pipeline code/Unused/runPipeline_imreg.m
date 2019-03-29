% Run SIMA
% DYLD_INSERT_LIBRARIES=/opt/local/lib/libgcc/libgfortran.3.dylib:/opt/local/lib/libtiff.5.dylib
% /Applications/MATLAB_R2016a.app/bin/matlab from cmd

% Get access to Prairie disk through the server: 
% Check the mounted points using df or df -h
% It gives a list of mounted drives. If there are more than one D_L-122, 
% e.g. D_L-122-1, this might be the one that is accessible. 
% This is now done automatically in addPrairieMount()


% USAGE
%   Add sessionIDs for experiments that were run today
%   Specify where to find labview data. Typically external drive
%   Change tSeriesPath if necessary
%   Change storageLocal if necessary
%   Change datadrive in config/getPathToDir if necessary


super_awesome_researcher = 'Eivind';
copy_labview_data = true; %Copy labview data to storageLocal
copy_tseries_data = false; %Copy tseries data to storageLocal

sessionIDs = {'m031-20170427-2115-004', 'm031-20170427-2115-005' };

prairieDisk = getPrairieMount();

switch super_awesome_researcher
    
    case 'Eivind'
        % Add local path for storing data.
        storageLocal = '/Volumes/Storage/Eivind/RotationExperiments';
        % Specify where Labview data is saved 
        %labviewDataPath = '/Volumes/Labyrinth/labview_data';
        labviewDataPath = '/Users/Eivind/Google Drive/PhD/Lab/Eivind Hennestad/RotationExperiments/LabviewData';
        % Specify relative path to calcium data on Prairie Data Drive
        tSeriesPath = fullfile(prairieDisk, 'Eivind', 'RotationExperiments');

    
    case 'Anna'
        % Add local path for storing data.
        %storageLocal = '/Volumes/Storage/Anna/Expts Dec 2016';
        storageLocal = '/Volumes/Anna/Data Backup';
        % Specify where Labview data is saved 
        labviewDataPath = '/Volumes/Anna/Expts Dec 2016';
        % Add path where Imaging data is located.
        %tSeriesPath = fullfile(prairieDisk, 'Anna');
        tSeriesPath = '/Volumes/Anna/prism';
        
end


%% Expand list of sessionIDs if there are multiple recordings per sessionID
extendedSessionIDs = {};
for i = 1:length(sessionIDs)
    sessionID = sessionIDs{i};
    mouseNo = str2double(sessionID(2:4));
    mouseFolderPrefix = strcat('mouse', num2str(mouseNo, '%03d'), '*');
    
    % Get path to labview mouse Folder
    labviewMouseFolder = dir(fullfile(labviewDataPath, mouseFolderPrefix));
    labviewMousePath = fullfile(labviewDataPath, labviewMouseFolder(1).name);
    
    % Session Folders
    sessionFolders = dir(fullfile(labviewMousePath, ['session-', sessionID, '*'] ));
    for j = 1:length(sessionFolders)
        extendedSessionIDs{end+1} = getSessionIDfromString(sessionFolders(j).name);
    end
    
end
sessionIDs = extendedSessionIDs;


%% Copy data for each session and run image alignment
for i = 1:length(sessionIDs)
    
    sessionID = sessionIDs{i};
    sessionFolder = strcat('session-', sessionID);
    
    start_time = clock;
    timestr = [num2str(start_time(4), '%02d'), ':' num2str(start_time(5), '%02d'), ...
               ':' num2str(round(start_time(6)), '%02d')];
    
    fprintf(['\n', ...
'                           - ' timestr,  ' -\n', ...
'--------------------------------------------------------------------- \n', ...
' Initialising registration of images for session: ', sessionID, '\n', ...
'--------------------------------------------------------------------- \n', ...
          '\n' ])
    
    
    mouseNo = str2double(sessionID(2:4));
    mouseFolderPrefix = strcat('mouse', num2str(mouseNo, '%03d'), '*');

    %% Get path to local mouse folder
    try % to use result from searching local storage
        localMouseFolder = dir(fullfile(storageLocal, mouseFolderPrefix));
        localMouseFolder = fullfile(storageLocal, localMouseFolder(1).name);
    catch % make new folder if folder was not found
        localMouseFolder = fullfile(storageLocal, mouseFolderPrefix(1:end-1));
        mkdir(localMouseFolder)
    end

    
    %% Copy session folder with labview data to local drive
    if copy_labview_data
        
        disp('Copying labview data to local storage ...')
        labviewMouseFolder = dir(fullfile(labviewDataPath, mouseFolderPrefix));
        labviewMouseFolder = fullfile(labviewDataPath, labviewMouseFolder(1).name);

        try
            tStart = tic;
            copyfile(fullfile(labviewMouseFolder, sessionFolder), ...
                     fullfile(localMouseFolder, sessionFolder));
            fprintf('Hurrah! Files copied succesfully. Elapsed time: %.2f s. \n', toc(tStart))
        catch
            disp('Oh no! Something went wrong when copying labview data:( FUUUCK!##$%#!!')
            continue
        end
    end
    
    
    %% Copy TSeries folder to local sessionFolder
    if copy_tseries_data
    
        localTseriesFolder = fullfile(localMouseFolder, sessionFolder, ...
                                      'calcium_images');
        if ~(exist(localTseriesFolder, 'dir') == 7); mkdir(localTseriesFolder); end
        
        % Find corresponding Tseries Data
        prairieMouseFolder = dir(fullfile(tSeriesPath, mouseFolderPrefix));
        prairieMouseFolder = fullfile(tSeriesPath, prairieMouseFolder(1).name);
        tSeriesParent = fullfile(prairieMouseFolder, sessionID(6:13));
        
        if length(sessionID) == 18      % E.g. m029-20170306-1457
            tSeriesFolder = strcat('TSeries-', sessionID(10:13), sessionID(6:9), ...
                                '-', sessionID(15:18), '-001');
        elseif length(sessionID) == 22  % E.g. m029-20170306-1457-001
            tSeriesFolder = strcat('TSeries-', sessionID(10:13), sessionID(6:9), ...
                                '-', sessionID(15:22));
        end
        
        disp('Copying calcium images to local storage ...')
        try
            tStart = tic;

            copyfile( fullfile(tSeriesParent, tSeriesFolder), ...
                      fullfile(localTseriesFolder, tSeriesFolder) );
            fprintf('YAAY! Files copied succesfully. Elapsed time: %.2f s. \n', toc(tStart))

        catch
            disp('Oh no! This went south :( DOUBLE FUUUCK!!')
            continue
        end
    end
    


        

    %% Run image registration.
   try
        %Crop to 512x512 and check performance
        cd('/Users/Eivind/Code/RotationExperiments')
        imregSession(sessionID)
        cd('/Users/Eivind/Code')
   catch
       disp('Oh no! This went south :( DOUBLE FUUUCK!!')
       continue
   end

    end_time = clock;
    elapsed_time = getElapsedTime(start_time, end_time);
    timestr = [num2str(end_time(4), '%02d'), ':' num2str(end_time(5), '%02d'), ...
               ':' num2str(round(end_time(6)), '%02d')];
    elapsed_timestr = [num2str(elapsed_time(4), '%02d'), ':' num2str(elapsed_time(5), '%02d'), ...
               ':' num2str(round(elapsed_time(6)), '%02d')];
    fprintf(['\n', ...
    'Processing of images for session: ', sessionID, ' was completed in ' elapsed_timestr '\n' ])

end


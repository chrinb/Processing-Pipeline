function [ ] = transferPrairieViewFiles( sessionID )
%transferPrairieViewFiles Transfer imaging data from external drive to storage drive
%   transferPrairieViewFiles(sessionID) copies all Prairie imaging data for a specified 
%   session from an external drive to a storage drive. The path to these drives has to be 
%   set in pipeline_settings/getPathToDir for this function to work.


% Create destination folder
sessionFolder = getSessionFolder(sessionID);

localTseriesFolder = fullfile(sessionFolder, 'calcium_images_raw_pv');
if ~(exist(localTseriesFolder, 'dir') == 7); mkdir(localTseriesFolder); end


% Find microscope data
%src_drive = getPathToDir('images_transfer');
tSeriesPath = '/Volumes/Experiments Storage/RotationStageExperiments/microscope_backup-2017-feb';
mouseFolderPrefix = strcat('mouse', sessionID(2:4), '*');

% Find Tseries Data
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
end


end


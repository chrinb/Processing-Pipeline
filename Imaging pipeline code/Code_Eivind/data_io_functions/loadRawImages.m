function [ imArray] = loadRawImages( sessionID, block, ch, first_frame, last_frame )
%loadRawImages Load raw images from specified ch, block and session
%   IMARRAY = loadRawImages(sessionID, BLOCK, CH) returns an array (uint8) of
%   raw images from specified CH, BLOCK and sessionID
%   IMARRAY = loadRawImages(sessionID, BLOCK, CH, FIRST_FRAME, LAST_FRAME) returns an 
%   array (uint8) of raw images between FIRST and LAST FRAME. NB Only implemented for SciScan

% Todo: make it work for prairie data.

% Default values of first and last idx.
if nargin < 4
    first_frame = 1;
    last_frame = -1;
end


sessionFolder = getSessionFolder(sessionID);

imageFolder = dir(fullfile(sessionFolder, 'calcium_images_raw*'));

imageFolder = imageFolder(1).name;
acquisitionSoftware = imageFolder(20:21);

switch acquisitionSoftware
    case 'ss' % SciScan
        % need to use a default name here... (currently: rotation) Set in
        % transfer files?
        blockFolders = dir(fullfile(sessionFolder, imageFolder, '*2019*' ));
        blockFolder = fullfile(sessionFolder, imageFolder, blockFolders(block).name);
        imArray = loadSciScanStack( blockFolder, ch, first_frame, last_frame );

        
    case 'pv' % PrairieView
        tSeriesFolders = dir(fullfile(sessionFolder, imageFolder, 'Tseries*' ));
        nFolders = length(tSeriesFolders);
        
        if nFolders > 1
            tSeriesPath = fullfile(sessionFolder, imageFolder, tSeriesFolders(block).name);
            cycle = 1;
        else 
            tSeriesPath = fullfile(sessionFolder, imageFolder, tSeriesFolders(1).name);
            cycle = block;
        end
        
        imArray = loadPrairieViewStack(tSeriesPath, cycle, ch);
        % To be developed
end


end


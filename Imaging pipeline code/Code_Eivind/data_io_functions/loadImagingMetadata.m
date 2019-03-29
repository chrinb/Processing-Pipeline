function meta2P = loadImagingMetadata(sessionID)
%loadImagingMetadata Load imaging metadata for specified session.
%   METADATA = loadImagingMetadata(sessionID) returns a struct with
%   imaging metadata from specified session.
%
%   METADATA contains following fields:
%       - dt            :   interframe interval
%       - xpixels       :   width of image in pixels
%       - ypixels       :   height of image in pixels
%       - objective     :   not necessary for now (not added)
%       - zoomFactor    :   zoomfactor during the recording
%       - pmtCh2        :   missing - can we implement??
%       - pmtCh3        :   missing - can we implement??
%       - zPosition     :   relative z position of microscope during data acquistion
%       - umPerPx_x     :   um per pixel conversion factor along x axis
%       - umPerPx_y     :   um per pixel conversion factor along y axis
%       - nCh           :   number of channels acquired
%       - channels      :   list of channels that are recorded (e.g. [2, 3])
%       - channelNames  :   list of corresponding channel names e.g. {Ch2, Ch3}
%       - channelColor  :   list of corresponding color for each channel e.g. {green, red}
%       - nBlocks       :   number of blocks
%       - nFrames       :   array of nFrames per block
%       - times         :   array of time vectors per recording/per block
%
%   see also getSciScanMetaData, getPrairieMetaData

sessionFolder = getSessionFolder(sessionID);

imageFolder = dir(fullfile(sessionFolder, 'calcium_images_raw*'));

imageFolder = imageFolder(1).name;
acquisitionSoftware = imageFolder(20:21);

switch acquisitionSoftware
    case 'ss' % SciScan                                 %/todo change to block..
        blockFolders = dir(fullfile(sessionFolder, imageFolder, '*2019*' ));
        
        %loop through blocks
        for b = 1:length(blockFolders)
            blockFolder = fullfile(sessionFolder, imageFolder, blockFolders(b).name);
            if b == 1
                meta2P = getSciScanMetaData( blockFolder );
            else 
                meta2P = getSciScanMetaData( blockFolder, meta2P );
            end
        end
        
        
    case 'pv' % PrairieView
        tSeriesFolders = dir(fullfile(sessionFolder, imageFolder, 'Tseries*' ));
        if length(tSeriesFolders) == 1
            tSeriesPath = fullfile(sessionFolder, imageFolder, tSeriesFolders(1).name);
            meta2P = getPrairieMetaData( tSeriesPath );
        else
            for b = 1:length(tSeriesFolders)
                blockFolder = fullfile(sessionFolder, imageFolder, tSeriesFolders(b).name);
                if b == 1
                    meta2P = getPrairieMetaData( blockFolder );
                else
                    meta2P = getPrairieMetaData( blockFolder, meta2P);
                end     
            end
  
        end        

end

end


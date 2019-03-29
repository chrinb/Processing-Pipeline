function [ savePath ] = getDataPath( datatype, sessionID, block, ch, part,plane_num )
%getDataPath Return a full path string for location of specified data
%   savePath = getDataPath( datatype, sessionID, BLOCK, CH, PART ) returns a pathstring
%   for data from a session. BLOCK refers to the block of the session, CH refers to
%   the imaging channel and PART refers to the part of the file (for imaging data where 
%   tiffstacks are divided into parts)
%
%   Specified datatypes:
%       RotatedImages : Array of images that can be save to an uint8 tiff stack.
%       RegisteredImages : Array of images that can be save to an uint8 tiff stack.
%       FrameCorrections : Array of corrected frame translations for a tiff stack
%       RotationCorrections : Array of rotation corrections for a tiff stack
%       AvgStackProjection : Average stack projection saved as uint8 tif image 
%       MaxStackProjection : Maximum stack projection saved as uint8 tif image 
%
%   See also saveData, loadData

% Get sessionFolder
sessionFolder = getSessionFolder(sessionID);

% Set folder names for the different datatypes
switch datatype
    case 'RotatedImages';           saveFolder = 'calcium_images_rotated';
    case 'RegisteredImages';        saveFolder = 'calcium_images_aligned';
    case 'FrameCorrections';        saveFolder = 'imreg_variables';
    case 'RotationCorrections';     saveFolder = 'imreg_variables';
    case 'AvgStackProjection';      saveFolder = 'stack_projections';
    case 'MaxStackProjection';      saveFolder = 'stack_projections';  
        
end

% Set filenames for the different data types
switch datatype
    case 'RotatedImages';           filename = 'calcium_images';        filetype = '.tif';
    case 'RegisteredImages';        filename = 'calcium_images';        filetype = '.tif';
    case 'FrameCorrections';        filename = 'frame_corrections';     filetype = '.mat';
    case 'RotationCorrections';     filename = 'rotation_corrections';  filetype = '.mat';
    case 'AvgStackProjection';      filename = 'stackAVG';              filetype = '.tif';
    case 'MaxStackProjection';      filename = 'stackMAX';              filetype = '.tif';
end

% Set folder to save data within session folder and create if it does not exist
saveFolder = fullfile(sessionFolder, saveFolder);
if ~ (exist(saveFolder, 'dir') == 7); mkdir(saveFolder); end

% Create an ID for filename with sessionId, block, channel (and part)
if part == 0
	filenameId = [ '_', sessionID, '_block', num2str(block, '%03d'), ...
                  '_plane',num2str(plane_num, '%03d'),'_ch', num2str(ch) ];
else
    filenameId = [ '_', sessionID, '_block', num2str(block, '%03d'), ...
                  '_plane',num2str(plane_num, '%03d'),'_ch', num2str(ch), '_part', num2str(part, '%03d') ];
end
          
% Assemble final pathname for where to save data
savePath = fullfile(saveFolder, [filename, filenameId, filetype]);

end


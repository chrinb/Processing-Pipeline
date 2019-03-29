function [ data ] = loadData(datatype, sessionID, block, ch, part )
%loadData Load piece of data from a session to speified place.
%   loadData( DATA, DATATYPE, sessionID, BLOCK, CH, PART ) loads DATA specified by
%   DATATYPE to the sessionfolder. BLOCK refers to the block of the session, CH refers to
%   the imaging channel and PART refers to the part of the file (for imaging data where 
%   tiffstacks are divided into parts)
%
%   Specified datatypes:
%       RotatedImages : Array of images (uint8) that are rotated.
%       RegisteredImages : Array of images (uint8) that are aligned.
%       FrameCorrections : Array of corrected frame translations for a tiff stack
%       RotationCorrections : Array of rotation corrections for a tiff stack

% See also getDataPath, saveData

% For non-imaging data, ch and part might not be specified
if nargin < 5; part = 0; end
if nargin < 4; ch = 0; end

% Get path where to save data
loadPath = getDataPath(datatype, sessionID, block, ch, part);

% Load data
switch datatype
    case {'RotatedImages', 'RegisteredImages'}
        data = stack2mat(loadPath);
    case 'FrameCorrections'
        loadedData = load(loadPath);
        data = loadedData.frame_corrections;
    case 'RotationCorrections'
        loadedData = load(loadPath);
        data = loadedData.rotation_corrections;
end

end

function [ ] = saveData( data, datatype, sessionID, block, ch, part,plane_num )
%saveData Save piece of data from a session to speified place.
%   saveData( DATA, DATATYPE, sessionID, BLOCK, CH, PART ) saves DATA specified by
%   DATATYPE to the sessionfolder. BLOCK refers to the block of the session, CH refers to
%   the imaging channel and PART refers to the part of the file (for imaging data where 
%   tiffstacks are divided into parts)
%
%   Specified datatypes:
%       RotatedImages : Array of images that can be save to an uint8 tiff stack.
%       RegisteredImages : Array of images that can be save to an uint8 tiff stack.
%       FrameCorrections : Array of corrected frame translations for a tiff stack
%       RotationCorrections : Array of rotation corrections for a tiff stack

% See also getDataPath, loadData

% For non-imaging data, ch and part might not be specified
if nargin < 5; part = 0; end
if nargin < 4; ch = 0; end

% Get path where to save data
savePath = getDataPath(datatype, sessionID, block, ch, part,plane_num);

% Save data
switch datatype
    case 'RotatedImages'
        mat2stack(uint8(data), savePath)
    case 'RegisteredImages'
        mat2stack(uint8(data), savePath)
        saveStackProjections( data, sessionID, block, ch, part, plane_num )
    case 'FrameCorrections'
        frame_corrections = data;
        save(savePath, 'frame_corrections')
    case 'RotationCorrections'
        rotation_corrections = data;
        save(savePath, 'rotation_corrections')
end

end


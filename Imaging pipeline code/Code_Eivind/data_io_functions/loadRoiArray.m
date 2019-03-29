function [ roiArray ] = loadRoiArray( sessionID, ch )
%loadRoiArray Load roi array for current session
%   ROIARRAY = loadRoiArray( sessionID, CH )

if nargin < 2
    ch = 1;
end

sessionFolder = getSessionFolder(sessionID);

try
    roiArrPath = fullfile(sessionFolder, ['roi_arr_ch' num2str(ch) '.mat']);
catch
    
    [fileName, pathName, ~] =  uigetfile({'mat', 'Mat Files (*.mat)'; ...
                                          '*', 'All Files (*.*)'}, ...
                                          ['Load rois for session ', sessionID], ...
                                          '/Volumes/Storage/Eivind/RotationExperiments');
    roiArrPath = fullfile(pathName, fileName);
                                      
    if filename == 0 % User pressed cancel
        return
    end
end

roiArray = load(roiArrPath);
roiArray = roiArray.roi_arr;

end


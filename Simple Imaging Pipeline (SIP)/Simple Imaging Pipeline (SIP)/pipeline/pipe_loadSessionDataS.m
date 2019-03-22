function [sessionData,fileFolder] = pipe_loadSessionDataS(fileFolder)
% PIPE_LOADSESSIONDATAS allow the user to select a session folder and
% automatically extract all related session data from the labview TDMS.
% This requires correct folder nomenclature, see Google Drive document.
% 
% Input:
%   fileFolder: Other functions may call this function with a specific file
%       folder already selected. This input is not required.
% Output:
%   sessionData: 
%
% Written by Andreas Lande

if nargin<1 % If fileFolder is not given as input, prompt user to select a folder
    fileFolder = uigetdir(getPathToDir('datadrive'));
end

sessionID = getSessionIDfromString(fileFolder);

%-- Get data
daqdata = loadLabViewTDMS(sessionID);

%-- Add data to mousedata struct
sessionData.daqdata = daqdata;

end

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
% Written by Andreas Lande, modified by Anna Chambers

if nargin<1 % If fileFolder is not given as input, prompt user to select a folder
    fileFolder = uigetdir(getPathToDir('datadrive'));
end

sessionID = getSessionIDfromString(fileFolder);

%-- Get data
daqdata = loadLabViewTDMS(sessionID);

%-- Add data to mousedata struct
sessionData.daqdata = daqdata;

%--Move LFP recording from daqdata section to its own "ephysdata" section
sessionData.ephysdata.lfp = sessionData.daqdata.lfp;

%--load mouse info
currentDir = fileFolder;
idcs   = strfind(currentDir,filesep);
mainMouseDir = currentDir(1:idcs(end)-1);
try
load(fullfile(mainMouseDir,'mouseInfo.mat'),'mouseInfo');
catch
    msg = 'Main mouse folder lacks mouseInfo data';
    error(msg)
end
sessionData.mouseInfo = mouseInfo;


%--add session info
sessionInfo.sessionID = sessionID;
sessionInfo.date = sessionID(7:14);
sessionInfo.sessionNumber = sessionData.daqdata.metadataFromLV.sessionNumber;
sessionInfo.sessionStartTime = sessionData.daqdata.metadataFromLV.Experiment_start_time;
sessionInfo.sessionStopTime = sessionData.daqdata.metadataFromLV.Experiment_stop_time__clock_;
cd(fileFolder)
checkIfImages = dir('*images*');
if ~isempty(sessionData.daqdata.lfp) && ~isempty(checkIfImages)
    sessionInfo.recordedData = {'2P','LFP'};
elseif ~isempty(sessionData.daqdata.lfp) && isempty(checkIfImages)
    sessionInfo.recordedData = {'LFP'};
elseif isempty(sessionData.daqdata.lfp) && ~isempty(checkIfImages)
    sessionInfo.recordedData = {'2P'};
end

sessionData.sessionInfo = sessionInfo;



end

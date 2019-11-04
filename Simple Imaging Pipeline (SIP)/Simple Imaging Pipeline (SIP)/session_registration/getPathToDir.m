% A collection of OS-specific or user-specific paths to directories
% or files that are used by the RotationExperiment pipeline.
%
% USAGE:
%
%   * Add paths to relevant directories/files under your username within
%     this function prior to calling it.
%
%   * Keep a backup of this file if you ever need to?pull the package
%   ??from github again.
%
% EXAMPLE
%   labbookPath = getPathToDir('labbook');
%
% INPUT:
%
%   whichDir (str): A string specifying what path to return
%       * 'datadrive'       :   drive containing experimental data
%       * 'backupdrive'     :   drive containing backup of experimental data
%       * 'labview_transfer :   drive containing experimental data from setup
%       * 'images_transfer' :   drive containing images from microscope
%       * 'google_drive_lab':
%       * 'localTMP'        :   local folder used temporarily for aligning
%       * 'roimanager'      :   path to roimanager in Matlab
%       * 'python'          :   path to python
%       * 'pipeline'        :   path to matlab folder.
%       * 'labbook'         :   path to save "databases" and labbook
%       * 'labbook_mat'     :   path to matlab folder with labbook files
%       * 'labbook_tex'     :   path to folder tex files for generating labbook
%       * 'xlwrite'         :   path to xlwrite package

% Written by Eivind Hennestad 

function [ path ] = getPathToDir( whichDir )
%getPathToDir returns path to folder specified in input
%   path = getPath(whichPath) is the absolute path to a folder or file
%   which is predefined for different users/os platforms.

path = 'empty';

% Find username of current user
if isunix
    [~, username] = system('whoami');
    username = username(1:end-1); % remove new-line char at end
elseif ispc
    username = getenv('USERNAME');
else
    username = 'unknown_user';
end

% Return paths for current user
switch username
    
    case 'Anna'
        switch whichDir
            
            case 'datadrive'
                path = 'E:\Data'; % Folder storing the original data for each mouse
                %path = 'F:\';
                return
            case 'experimentdata' % Folder storing the structs of data used in matlab
                %path = 'C:\Users\andlande\Dropbox\UiO\Data\Data';
                return
            case 'localTMP'
                %path = 'C:\Users\andlande\Google Drive\Andreas Lande\Active avoidance setup\MATLAB\ImagingPipelineDirectory\TMP';
                return
        end
        
    case 'Template'
        switch whichDir
            
            case 'datadrive'
                path = 'enter path to data drive here';
                return
                
            case 'experimentdata' 
                path = 'optional';
                return
                
            case 'localTMP'
                path = 'optional';
                return
                
            case 'fiji'
                path = 'optionale';
                return
                
            case 'roimanager'
                path = 'optional';
                return
            case 'python'
                path = 'optional';
                return
                
            case 'easylabbook'
                path = 'optional';
                return
        end
        
        
    otherwise
        switch whichDir
            case 'datadrive'
                path = 'C:\Users\Public'; % Folder storing the original data for each mouse
                return
            case 'experimentdata' % Folder storing the structs of data used in matlab
                path = 'C:\Users\Public';
                return
            otherwise
                error('Please add paths to local directories in getPathToDir.m')
        end
        
end

if strcmp(path, 'empty')
    error('Something went wrong')
    
end


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
    
case 'eivinhen'
    switch whichDir
        
    case 'datadrive'
        %path = '/Users/eivinhen/Google Drive/PhD/Lab/Eivind Hennestad/RotationExperiments/LabviewData';
        path = '/Volumes/Experiments';
        %path = '/Volumes/Labyrinth';
        %path = '/Users/eivinhen/Desktop'; 
        %path = '/Volumes/2Photon_Backup_01';
        
        if ~exist(path, 'dir')
            warning(['storage path is not available:', path])
        end

        return
    
    case 'images_transfer'
        path = '/Volumes/Labyrinth/Data_Microscope';
        if ~exist(path, 'dir')
            warning(['Drive with imaging data is not connected: ', path])
        end
        
    case 'labview_transfer'
        path = '/Volumes/Labyrinth/Data_Labview';
        if ~exist(path, 'dir')
            warning(['Drive with labview data is not connected: ', path])
        end
        
    case 'google_drive_lab'
        path = '/Users/eivinhen/Google Drive/PhD/Lab/Eivind Hennestad';

    case 'localTMP'
        path = '/Users/eivinhen/PhD/Projects/RotationExperiments/TMP';
        return
    case 'fiji'
        path = '/Applications/Fiji.app/scripts';
        return
    case 'roimanager'
        path = '/Users/eivinhen/PhD/Software/MATLAB/roimanager';
        return  
    case 'python'
        path = 'python';
        return  
    case 'pipeline'
        path = '/Users/eivinhen/PhD/Software/MATLAB/RotationExperiments';
        return 
    case 'labbook_mat'
        path = '/Users/eivinhen/PhD/Software/MATLAB/RotationExperiments/make_labbook';
        return
    case 'labbook_tex'
        path = [ '/Users/eivinhen/Google Drive/PhD/Lab/Eivind '...
                    'Hennestad/RotationExperiments/LabBook/labbook_tex' ];
        return
    case 'labbook'
        path = strcat( '/Users/eivinhen/Google Drive/PhD/Lab/', ...
                       'Eivind Hennestad/RotationExperiments/LabBook' );
        return
    case 'xlwrite'
        path = '/Users/eivinhen/PhD/Software/MATLAB/LabBook/io_functions/xlwrite';
        return
    otherwise
        error('Unknown input argument')
    end
           
case 'annacham'
    switch whichDir
    
    case 'datadrive'
        path = 'E:\Data'; %path = 'E:\Data';
        return
    case 'localTMP'
        path = 'C:\Users\andlande\Google Drive\Andreas Lande\Active avoidance setup\MATLAB\ImagingPipelineDirectory\TMP';
        return
    case 'fiji'
        path = 'C:\Program Files\Fiji.app\scripts';
        return
    case 'roimanager'
        path = 'C:\Users\andlande\Dropbox\UiO\Code\ImagingPipelineExample\roimanager-master\roimanager-master';
        return
    case 'python'
        path = 'python';
        return
    case 'labbook_mat'
        path = 'C:\Users\andlande\Dropbox\UiO\Code\ImagingPipelineExample\make_labbook';
        return
    case 'labbook_tex'
        path = 'C:\Users\andlande\Dropbox\UiO\Code\ImagingPipelineExample\make_labbook\labbook_tex';
        return
    case 'labbook'
        path = 'C:\Users\andlande\Google Drive\Andreas Lande\Active avoidance setup\MATLAB\ImagingPipelineDirectory\LabBook';
        return
    end
    
case 'Anna'
    switch whichDir
    
    case 'datadrive'
        path = 'F:\Rotation Expts + Eivind\RotationExperiments_v2';
        return
    case 'localTMP'
        path = 'C:\Users\Anna\Documents\RotationExperiments\TMP';
        return
    case 'fiji'
        path = 'C:\Program Files\Fiji.app\scripts';
        return
    case 'roimanager'
        path = 'C:\Users\Anna\Documents\MATLAB\roimanager';
        return
    case 'python'
        path = 'C:\Python34\python';
        return
    end
    
    
case 'Eivind' % Mac in L-104
    switch whichDir
        case  'datadrive'
            %path = '/Volumes/Experiments';
            path = '/Volumes/Storage/Eivind/RotationExperiments';
            %path = '/Volumes/Anna/Data Backup';
        
        case 'localTMP'
            path = '/Users/Eivind/Tmp_imreg';
        
        case 'fiji'
            error('Have not configured Fiji for Matlab on this MAC')
        
        case'roimanager'
            path = '/Users/Eivind/Code/roimanager';
        
        case 'python'
            path = '/opt/local/bin/python';
            
        case 'google_drive_lab'
            path = '/Users/Eivind/Google Drive/PhD/Lab/Eivind Hennestad';
        
        case 'pipeline'
            path = '/Users/Eivind/Code/RotationExperiments';
            
        case 'labbook_mat'
            path = '/Users/Eivind/Code/RotationExperiments/labbook';
    
        case 'labbook_tex'
            path = [ '/Users/Eivind/Google Drive/PhD/Lab/Eivind '...
                        'Hennestad/RotationExperiments/LabBook/labbook_tex' ];
            return
        case 'labbook'
            path = strcat( '/Users/Eivind/Google Drive/PhD/Lab/', ...
                           'Eivind Hennestad/RotationExperiments/LabBook' );

    end
    
    
    
case 'Template'
    switch whichDir
    
    case 'datadrive'
        path = 'enter path to data drive here';
        return
    case 'localTMP'
        path = 'enter path to directory for temporary storage here';
        return
    case 'fiji'
        path = 'enter path to FIJI here';
        return
    case 'roimanager'
        path = 'enter path to roimanager';
        return
    case 'python'
        path = 'enter path to python';
        return
    case 'easylabbook'
        path = 'enter path to matlab package easy labbook';
        return
    end
    

otherwise
    error('Please add paths to local directories in getPathToDir.m')
     
end

if strcmp(path, 'empty')
    error('Something went wrong')

end


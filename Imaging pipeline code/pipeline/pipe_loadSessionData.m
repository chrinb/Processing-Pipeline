function mousedata = pipe_loadSessionData(mousedata,fileFolder)
% PIPE_LOADSESSIONDATA allow the user to select a session folder and
% automatically extract all related session data from the labview TDMS.
% This requires correct folder nomenclature, see Google Drive document.
%
% Input:
%   mousedata: this is a struct containing all of the sessions for the mouse.
%       If no data exist for the mouse yet, create a struct as such: 
%       mouse1001 = struct() and use it as input.
%   fileFolder: Other functions may call this function with a specific file
%       folder already selected. This input is not required.
% Output:
%   mousedata: the same struct is given as output with the newly added
%       data.
%
% Written by AL

if nargin<2 % If fileFolder is not given as input, prompt user to select a folder
    fileFolder = uigetdir;
end

sessionID = getSessionIDfromString(fileFolder);

%-- Get data
daqdata = loadLabViewSession(sessionID);

%-- Save data
sessionNum = daqdata.metadata.sessionNumber;
mousedata(sessionNum).daqdata = daqdata;

%-- Based on the experiment type, do preprocessing on the data
exp_type = mousedata(sessionNum).daqdata.metadata.Experiment_type;

% ADAA or ADAAT
if (strcmp(exp_type, 'ADAA') || strcmp(exp_type, 'ADAAT'))
    [tone_onset_times, tone_onset_csplus, tone_onset_csminus] =  preprocess_findAllToneOnsetTimes(mousedata(sessionNum));
    mousedata(sessionNum).daqdata.experiment_data.tone_onset_times = tone_onset_times;
    mousedata(sessionNum).daqdata.experiment_data.tone_onset_csplus = tone_onset_csplus;
    mousedata(sessionNum).daqdata.experiment_data.tone_onset_csminus = tone_onset_csminus;

% PreADAA or PreADAAT
elseif (strcmp(exp_type, 'PreADAA') || strcmp(exp_type, 'PreADAAT'))
%     [tone_onset_times, tone_onset_csplus, tone_onset_csminus] =  preprocess_findAllToneOnsetTimes(mousedata(sessionNum));
%     mousedata(sessionNum).daqdata.experiment_data.tone_onset_times = tone_onset_times;
%     mousedata(sessionNum).daqdata.experiment_data.tone_onset_csplus = tone_onset_csplus;
%     mousedata(sessionNum).daqdata.experiment_data.tone_onset_csminus = tone_onset_csminus;
    
% CSD
elseif strcmp(exp_type,'CSD')
    
% VDAA or VDAAT
elseif strcmp(exp_type, 'VDAA')% NOT YET WORKING
%     [daqdata.dg_onsets,daqdata.dgOnsetForEachDirection] = preprocessing_setGratingDirectionAtPhotoDiodeMeasure(daqdata);
%     daqdata.gratingTypeOnsetTimes = findAllGratingDirectionWindows(daqdata); % Get a matrix containing the onset times (sample index) sorted for each grating direction:

% VAA
elseif strcmp(exp_type,'VAA')
    
% AAA
elseif strcmp(exp_type,'AAA')
    
% FREE
elseif strcmp(exp_type,'FREE')
    
    
% Unknown experiment type
else % Print a warning
    warning('Experiment type is not found in pipe_loadSessionData code');
end




end
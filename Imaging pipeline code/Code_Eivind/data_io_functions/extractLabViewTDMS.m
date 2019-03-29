function metadata = extractLabViewTDMS(sessionID)
% EXTRACTLABVIEWTDMS Converts the TDMS data produced by labview in the
% controller PC into .csv files and extract metadata related to properties
% set in the labview code.
%
% Input
%   sessionID: Classical sessionID used in the pipeline to identify the
%       session and mouse with the data.
% Output
%   metadata: structure containing all metadata obtained from the TDMS
%       file. This is iteratively find all properties set in the TDMS file
%       and assigns a subfield in the metadata struct containing the
%       property name and its corresponding value.
%
% Written by Eivind Hennestad. Rewritten to pipeline by AL.

sessionFolder = getSessionFolder(sessionID);
labviewFolder = fullfile(sessionFolder, 'labview_data');

blockFolder = dir(fullfile(labviewFolder, '*labview*'));
labviewFolder = fullfile(labviewFolder, blockFolder(1).name);

% Find tdms file with stage positions and convert to mat file
tdmsFile = dir(fullfile(labviewFolder, '*processed_setup_data.tdms'));
matFile = simpleConvertTDMS(fullfile(labviewFolder, tdmsFile(1).name));

load(matFile{1})

varPreFix = strrep(sessionID, '-', '');

% Extract property metadata from tdms file
indx = 1;
metadata = struct();
metadata.sessionNumber = str2num(varPreFix(end-2:end));

% Save all signals
while indx
    if isfield(ci.Object1,['Property' num2str(indx)])
        tmpName = ['Property' num2str(indx)];
        fieldName = ci.Object1.PropertyInfo(indx).Name;
        % Fix potential nameing errors
        fieldName = strrep(fieldName,' ','_');
        fieldName = strrep(fieldName,'CS+','CSpluss');
        fieldName = strrep(fieldName,'CS-','CSminus');
        fieldName = strrep(fieldName,'-','_');
        fieldName = strrep(fieldName,'(','_');
        fieldName = strrep(fieldName,')','_');
        fieldName = strrep(fieldName,'10','TEN');
        fieldName = strrep(fieldName,'20','TWENTY');
        
        property_value = ci.Object1.(tmpName).value;
        
        % Extract element from value if it is of type cell
        if iscell(property_value)
            property_value = property_value{1};
        end
        
        metadata.(fieldName) = property_value;
        indx = indx+1;
    
    else
       indx = 0; 
    end
end

% Detect all recorded channels in the TDMS file
all_vars = who;
allChannelVars = {};
channelNums = 1;

for x = 1:length(all_vars)
   if contains(all_vars(x), varPreFix)
       if strcmp(varPreFix,all_vars(x)) % Exclude empty channel
       else
           allChannelVars(channelNums) = all_vars(x);
           channelNums = channelNums+1;
          
       end
   end
end

% Identify frame ttl
frameSignal = eval([varPreFix, '2Pclock', '.Data']);
newFrameIdx = find(diff(vertcat(0, frameSignal)) == 32); % This is the new frame of reference for all recorded data. This is used because the control PC actually start to sample data from for instance the running wheel before the 2P microscope starts its recording.

% Get data from running speed and wheel, which are always present
runSpeed = eval([varPreFix, 'Instantspeed', '.Data']);
wheelCounter = eval([varPreFix, 'Wheelcounter', '.Data']);

% Detect the present channels for this specific recording
photodiode_channel_present = 0;
tone_onset_channel_present = 0;

for x = 1:length(allChannelVars)
   
    % Tone_onset
    if strcmp(allChannelVars(x),[varPreFix, 'Tone_onset'])
        tone_onset = eval([varPreFix, 'Tone_onset', '.Data']);
        speaker_signal = eval([varPreFix, 'Speaker_signal', '.Data']);
        tone_onset_channel_present = 1;
    end
    % Photodiode
    if strcmp(allChannelVars(x),[varPreFix, 'Photodiode'])
        photodiode_channel_present = 1;
        photoDiode = eval([varPreFix, 'Photodiode', '.Data']);
        % Filter photodiode signal
        filtered_pdSignal = filterPhotodiodeSignal(photoDiode,1000);
    end
        % Shock
    if strcmp(allChannelVars(x),[varPreFix, 'Shock'])
        shock_channel_present = 1;
        shock_signal = eval([varPreFix, 'Shock', '.Data']);
    else
        shock_channel_present = 0;
    end
end

%--- Save running speed data
csvData = zeros(length(newFrameIdx), 3);
csvData(:, 1) = 1:length(newFrameIdx);
csvData(:, 2) = runSpeed(newFrameIdx);
csvData(:, 3) = wheelCounter(newFrameIdx);

% Save as csv file. Check script (eyetracking bug correct)
newFileNm = fullfile(labviewFolder, [sessionID, '-run_speed_data.txt']);
dlmwrite(newFileNm, csvData, 'delimiter', '\t', 'precision', '%.9f')

%--- Save photodiode data if present
if photodiode_channel_present == 1
    csvData = zeros(length(newFrameIdx), 3);
    csvData(:, 1) = 1:length(newFrameIdx);
    csvData(:,2) = photoDiode(newFrameIdx);
    csvData(:,3) = filtered_pdSignal(newFrameIdx);
    
    if shock_channel_present == 1
        csvData(:,4) = shock_signal(newFrameIdx);
    end

    % Save as csv file.
    newFileNm = fullfile(labviewFolder, [sessionID, '-photo_diode.txt']);
    dlmwrite(newFileNm, csvData, 'delimiter', '\t', 'precision', '%.9f')
end

%--- Save tone_onset data if present
if tone_onset_channel_present == 1
    csvData = zeros(length(newFrameIdx), 3);
    csvData(:, 1) = 1:length(newFrameIdx);
    csvData(:,2) = tone_onset(newFrameIdx);
    csvData(:,3) = speaker_signal(newFrameIdx);
    
    if shock_channel_present == 1
        csvData(:,4) = shock_signal(newFrameIdx);
    end

    % Save as csv file.
    newFileNm = fullfile(labviewFolder, [sessionID, '-tone_onset.txt']);
    dlmwrite(newFileNm, csvData, 'delimiter', '\t', 'precision', '%.9f')
end

end
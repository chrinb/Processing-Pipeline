function output = extractLabViewTDMS_originalFs(sessionID)
% EXTRACTLABVIEWTDMS_originalFs Converts the TDMS data produced by labview in the
% controller PC into .csv files and extract metadata related to properties
% set in the labview code. In comparison to regular extractLabViewTDMS,
% this function stores the values at its original sampling rate, and not
% downsampled to fit with the onset of a new imaging frame.
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

matFile = dir(fullfile(labviewFolder, '*processed_setup_data.mat'));


if length(matFile)
    % If .mat file exists, load it
    matFilePath = [matFile(1).folder,'\',matFile(1).name];
    load(matFilePath)
else
    % Find tdms file and convert to .mat file
    tdmsFile = dir(fullfile(labviewFolder, '*processed_setup_data.tdms'));
    matFile = simpleConvertTDMS(fullfile(labviewFolder, tdmsFile(1).name));
    load(matFile{1})
end

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

%-- Identify frame ttl
frameIdx = [];
for x = 1:length(allChannelVars)
    
    if strcmp(allChannelVars(x),[varPreFix, '2Pclock'])
        frameSignal = eval([varPreFix, '2Pclock', '.Data']);
        frameIdx = find(diff(vertcat(0, frameSignal)) == 32); % This is the new frame of reference for all recorded data. This is used because the control PC actually start to sample data from for instance the running wheel before the 2P microscope starts its recording.
        frameOnset = zeros(1,length(frameSignal));
        for y = frameIdx
            frameOnset(y) = 1; 
        end
    end   
end

%-- Create output struct
output = struct();
output.metadata = metadata;

% -- Use 2P frame clock as reference if this is an imaging session
dontExportFrameOnset = 0;
if isempty(frameIdx) % Not an imaging session
    frameIdx(1) = 1;
    dontExportFrameOnset = 1;
end

if dontExportFrameOnset == 1
else
    output.frame_onset = frameOnset(frameIdx(1):end); % frame_onset
end

%-- Detect the present channels for this recording
for x = 1:length(allChannelVars)
   
    % Run speed channel
    if strcmp(allChannelVars(x),[varPreFix, 'Instantspeed'])
        runSpeed = eval([varPreFix, 'Instantspeed', '.Data']);
        output.run_speed = runSpeed(frameIdx(1):end); % run_speed
    end
    
    % Wheel counter channel
    if strcmp(allChannelVars(x),[varPreFix, 'Wheel_counter'])
        wheelCounter = eval([varPreFix, 'Wheel_counter', '.Data']);
        output.wheel_count = wheelCounter(frameIdx(1):end); % wheel_count
    elseif strcmp(allChannelVars(x),[varPreFix, 'Wheelcounter'])
        wheelCounter = eval([varPreFix, 'Wheelcounter', '.Data']);
        output.wheel_count = wheelCounter(frameIdx(1):end); % wheel_count
    end

    % Tone_onset signal
    if strcmp(allChannelVars(x),[varPreFix, 'Tone_onset'])
        tone_onset = eval([varPreFix, 'Tone_onset', '.Data']);
        output.tone_onset = tone_onset(frameIdx(1):end);
    end
    
    % Speaker_signal_raw signal
    if strcmp(allChannelVars(x),[varPreFix, 'Speaker_signal_raw'])
        speaker_signal = eval([varPreFix, 'Speaker_signal_raw', '.Data']);
        output.speaker_signal = speaker_signal(frameIdx(1):end);
        
    elseif strcmp(allChannelVars(x),[varPreFix, 'Speaker_signal'])
        speaker_signal = eval([varPreFix, 'Speaker_signal', '.Data']);
        output.speaker_signal = speaker_signal(frameIdx(1):end);
    end
    
    % Photodiode signal
    if strcmp(allChannelVars(x),[varPreFix, 'Photodiode'])
        photoDiode = eval([varPreFix, 'Photodiode', '.Data']);
        %if sum(lower(metadata.Experiment_type(1:2)) == 'sp') == 2 % Space projects ..
            %output.wheel_diode = photoDiode(frameIdx(1):end); 
            output.photodiode_filtered = photoDiode(frameIdx(1):end);
%         else % VAA projects..
%             % Filter photodiode signal
%             filtered_pdSignal = filterPhotodiodeSignal(photoDiode,1000);
%             output.photodiode_filtered = filtered_pdSignal(frameIdx(1):end);
        %end
    end
    
    % Wheel diode signal
    if strcmp(allChannelVars(x),[varPreFix, 'wheel_diode'])
        wheel_diode_signal = eval([varPreFix, 'wheel_diode', '.Data']);
        output.wheel_diode = wheel_diode_signal(frameIdx(1):end);
    end
    
    % LFP signal
    if strcmp(allChannelVars(x),[varPreFix, 'LFP'])
       LFP_signal_raw = eval([varPreFix, 'LFP', '.Data']);
       output.LFP_signal_raw = LFP_signal_raw(frameIdx(1):end);
    end
    
    % Optostimulation signal
    if strcmp(allChannelVars(x),[varPreFix, 'opto_signal'])
       opto_signal = eval([varPreFix, 'opto_signal', '.Data']);
       output.opto_signal = opto_signal(frameIdx(1):end);
    end
    
    % Shock signal
    if strcmp(allChannelVars(x),[varPreFix, 'Shock_on'])
        shock_signal = eval([varPreFix, 'Shock_on', '.Data']);
        output.shock_signal = shock_signal(frameIdx(1):end); 
    end
    
    % Water valve signal
    if strcmp(allChannelVars(x),[varPreFix, 'Water_valve'])
        water_valve_signal = eval([varPreFix, 'Water_valve', '.Data']);
        output.water_valve_signal = water_valve_signal(frameIdx(1):end);
    end

    % Lick signal
    if strcmp(allChannelVars(x),[varPreFix, 'Lick_signal'])
        lick_signal = eval([varPreFix, 'Lick_signal', '.Data']);
        output.lick_signal = lick_signal(frameIdx(1):end);
    end
end


%%% If you want to save the variables as text files, uncomment below. 
% PS: this takes both space and time. 
% %--- Save running speed data and frame clock signal
% csvData = zeros(length(frameSignal)-(frameIdx(1)-1), 4);
% csvData(:, 1) = 1:(length(frameSignal)-(frameIdx(1)-1));
% csvData(:, 2) = runSpeed(frameIdx(1):end);
% csvData(:, 3) = wheelCounter(frameIdx(1):end);
% csvData(:, 4) = frameOnset(frameIdx(1):end);
% 
% % Save as csv file
% newFileNm = fullfile(labviewFolder, [sessionID, '-run_speed_data.txt']);
% dlmwrite(newFileNm, csvData, 'delimiter', '\t', 'precision', '%.9f')
% 
% %--- Save photodiode data if present
% if photodiode_channel_present == 1
%     
%     csvData = zeros(length(frameSignal)-(frameIdx(1)-1), 2);
%     csvData(:,1) = photoDiode(frameIdx(1):end);
%     csvData(:,2) = filtered_pdSignal(frameIdx(1):end);
%     
%     % Save as csv file.
%     newFileNm = fullfile(labviewFolder, [sessionID, '-photo_diode.txt']);
%     dlmwrite(newFileNm, csvData, 'delimiter', '\t', 'precision', '%.9f')
% end
% 
% %--- Save tone_onset data if present
% if tone_onset_channel_present == 1
%     csvData = zeros(length(frameSignal)-(frameIdx(1)-1), 2);
%     csvData(:,1) = tone_onset(frameIdx(1):end);
%     csvData(:,2) = speaker_signal(frameIdx(1):end);
% 
%     % Save as csv file.
%     newFileNm = fullfile(labviewFolder, [sessionID, '-tone_onset.txt']);
%     dlmwrite(newFileNm, csvData, 'delimiter', '\t', 'precision', '%.9f')
% end
% 
% %--- Save shock_data if present
% if shock_channel_present == 1
%     csvData = zeros(length(frameSignal)-(frameIdx(1)-1), 1);
%     csvData(:,1) = shock_signal(frameIdx(1):end);
%     
%     % Save as csv file.
%     newFileNm = fullfile(labviewFolder, [sessionID, '-shock_signal.txt']);
%     dlmwrite(newFileNm, csvData, 'delimiter', '\t', 'precision', '%.9f')
% end
% 
% %--- Save LFP signal if present
% if LFP_channel_present == 1
%     csvData = zeros(length(frameSignal)-(frameIdx(1)-1), 1);
%     csvData(:,1) = LFP_signal_raw(frameIdx(1):end);
%     
%     % Save as csv file.
%     newFileNm = fullfile(labviewFolder, [sessionID, '-LFP_signal_raw.txt']);
%     dlmwrite(newFileNm, csvData, 'delimiter', '\t', 'precision', '%.9f')
% end

end
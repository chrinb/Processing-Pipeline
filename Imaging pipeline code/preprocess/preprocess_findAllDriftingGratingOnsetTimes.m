function [drifting_grating_onset,drifting_grating_onset_times] = preprocess_findAllDriftingGratingOnsetTimes(sessionData,photodiode_signal_downsampled)
% PREPROCESS_FINDALLDRIFTINGGRATINGONSETTIMES Detects the onset time, at what sample
% point, where are drifting grating is presented. The output vector drifting_grating_onset is zero
% everywhere but at the onset of a drifting grating it contains the direction used in degrees.
% This means that 0 degrees is named 360 degrees.
%
% Input
%   sessionData: A struct containing the specific session from the
%       mousedata struct.
% Output
%   tone_onset_times: A matrix with a row for each stimulus type, and a
%       column for each time onset. The first column contains the stimulus
%       type, i.e. the tone frequency used.
%
% Written by AL.

if nargin<2
   low = 0; 
else
    low = 1;
end
%--- Get the photodiode signal
if low == 0 % Find onset time on high sampling freq data from photodiode
    photodiode = sessionData.daqdata.photodiode_filtered;
else % Find onset times on a low sampling freq data
   photodiode = photodiode_signal_downsampled;
end

grating_directions = sessionData.daqdata.experiment_data.grating_direction;
grating_directions(grating_directions == 0) = 360;
drifting_grating_onset = zeros(length(photodiode),1);
tracker = 1;
current_grating = 1;

%--- For each tone onset set a 1 on the rising of the onset such that each stimulus onset has a marker where it starts
while tracker<length(photodiode)
    if photodiode(tracker) == 1
        drifting_grating_onset(tracker) = grating_directions(current_grating);
        current_grating = current_grating+1;
        % Continue until photodiode says stimulus is turned off
        on = 1;
        while on
            if sum(photodiode(tracker:tracker+5)) == 0 % at least 5 samples are 0. This is just to remove the possibilty of noise confounding
               on = 0; 
            end
            tracker = tracker+1;
        end
    else
        tracker = tracker + 1;
    end
end

%--- List all different grating directions used
gratings_used = unique(grating_directions);

%--- Make a matrix containing a row for each frequency used, and a coloumn for each trial giving the time onset. First column is the grating direction.
numTrials = length(grating_directions)/length(gratings_used);
drifting_grating_onset_times = zeros(length(gratings_used),numTrials+1);
drifting_grating_onset_times(:,1) = gratings_used;
indx = zeros(1,length(gratings_used));

for x = 1:length(drifting_grating_onset)
    if ~(drifting_grating_onset(x) == 0)
         row = find(drifting_grating_onset(x) == drifting_grating_onset_times(:,1));
         col = indx(row) + 2;
         drifting_grating_onset_times(row,col) = x;
         indx(row) = indx(row) + 1;
    end
end

end
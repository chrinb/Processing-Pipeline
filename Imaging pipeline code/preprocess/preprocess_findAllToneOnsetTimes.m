function [tone_onset_times,tone_onset_csplus,tone_onset_csminus] = preprocess_findAllToneOnsetTimes(sessionData)
% PREPROCESS_FINDALLTONEONSETTIMES Detects the onset time, at what sample
% point, where the CS+ or CS- stimuli are used. 
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

%--- Get the tone_onset signal obtained by the speaker signal.
tone_onset = sessionData.daqdata.tone_onset;
tone_onset_start = zeros(length(tone_onset),1);
tracker = 1;

%--- For each tone onset set a 1 on the rising of the onset such that each stimulus onset has a marker where it starts
while tracker<length(tone_onset)
    if tone_onset(tracker) == 1
        tone_onset_start(tracker) = 1;
        tracker = tracker + 150;
    else
        tracker = tracker + 1;
    end
end

%--- Similar to above, but now set the stimulus type (i.e. frequency value) at the stimulus start point.
nxt_stimulus_type = 1;

for x = 1:length(tone_onset_start)
    if tone_onset_start(x) == 1
       tone_to_set = sessionData.daqdata.experiment_data.stimulus_type(nxt_stimulus_type);
       tone_onset_start(x) = tone_to_set; 
       nxt_stimulus_type = nxt_stimulus_type + 1;
    end
end


%--- Make a onset vector for both CS+ and CS- stimulus 
tone_onset_csplus = zeros(size(tone_onset));
tone_onset_csminus = zeros(size(tone_onset));

CSplus = sessionData.daqdata.metadata.CSplus_hertz;
CSminus = sessionData.daqdata.metadata.CSminus_hertz;

for x = 1:length(tone_onset_start)
    if(tone_onset_start(x) == CSplus)
        for search = 0:150
           tone_onset_csplus(x+search) = CSplus; 
        end
    end
    if tone_onset_start(x) == CSminus
        for search = 0:150
           tone_onset_csminus(x+search) = CSminus; 
        end
    end
end


%-- Find all the tone frequencies used. 
tone_sequence = sessionData.daqdata.experiment_data.stimulus_type;
tone_frequencies = [];
for x = 1:length(tone_sequence)
    % If the frequency is not in the list, add it.
    if ~sum(tone_frequencies == tone_sequence(x))
        tone_frequencies = [tone_frequencies tone_sequence(x)];
    end
end


%--- Make a matrix containing a row for each frequency used, and a coloumn for each trial. First column is the frequnency.
numTrials = length(tone_sequence)/length(tone_frequencies);
tone_onset_times = zeros(length(tone_frequencies),numTrials+1);
tone_onset_times(:,1) = tone_frequencies;
indx = zeros(1,length(tone_frequencies));

for x = 1:length(tone_onset_start)
    if ~(tone_onset_start(x) == 0)
         row = find(tone_onset_start(x)==tone_onset_times(:,1));
         col = indx(row) + 2;
         tone_onset_times(row,col) = x;
         indx(row) = indx(row) + 1;
    end
end

end
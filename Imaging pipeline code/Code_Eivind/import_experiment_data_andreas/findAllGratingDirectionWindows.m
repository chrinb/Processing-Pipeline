function gratingOnsetTimes = findAllGratingDirectionWindows(sessionData)
% FINDALLGRATINGDIRECTIONWINDOWS detects all grating directions used in the experiment and finds all
% sample times for the onset of the grating for all trials.

grating_onsets = sessionData.daqdata.dg_onsets;
dg_sequence = sessionData.daqdata.dg_sequence;
for y = 1:length(dg_sequence) 
    if dg_sequence(y) == 0
        dg_sequence(y) = 360;
    end
end

grating_directions = [];
for x = 1:length(dg_sequence)
    % If the grating direction is not in the list, add it.
    if ~sum(grating_directions==dg_sequence(x))
        grating_directions = [grating_directions dg_sequence(x)];
    end
end
grating_directions = sort(grating_directions);
numTrials = length(dg_sequence)/length(grating_directions);
gratingOnsetTimes = zeros(length(grating_directions),numTrials+1);
gratingOnsetTimes(:,1) = grating_directions;
indx = zeros(1,length(grating_directions));

for x = 1:length(grating_onsets)
    if ~(grating_onsets(x) == 0)
         a = 1;
         row = find(grating_onsets(x)==gratingOnsetTimes(:,1));
         col = indx(row) + 2;
         gratingOnsetTimes(row,col) = x;
         indx(row) = indx(row) + 1;
    end
end


    
    
end
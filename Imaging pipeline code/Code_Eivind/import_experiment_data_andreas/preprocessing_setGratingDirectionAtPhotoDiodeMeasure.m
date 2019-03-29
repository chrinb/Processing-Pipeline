function [gratingDirectionTriggers, dgOnEachDirection] = preprocessing_setGratingDirectionAtPhotoDiodeMeasure(mousedata)
% PREPROCESSING_SETGRATINGDIRECTIONATPHOTODIODEMEASURE use the filtered photodiode signal
% to detect onset of a stimulus and assigns the corresponding drifting
% gratin direction to it.
%------------- REQUIRES CHECKING

pd_filtered = mousedata.daqdata.photodiode_filtered;
grating_onset = zeros(1,length(pd_filtered));
tracker = 1;

while tracker<length(pd_filtered)
    if pd_filtered(tracker) == 1
        grating_onset(tracker) = 1;
        tracker = tracker + 150;
    else
        tracker = tracker + 1;
    end
    
    
end
nxt_direction = 1;

for x = 1:length(grating_onset)
   
    if grating_onset(x) == 1
       gratingToSet = mousedata.daqdata.dg_sequence(nxt_direction);
       if gratingToSet == 0
          gratingToSet = 360; 
       end
       grating_onset(x) = gratingToSet; 
       nxt_direction = nxt_direction + 1;
    end
    
    
end

gratingDirectionTriggers = grating_onset;



% Create a struct with a subfield for each drifring gratinging direction in
% which the onset of that grating is represented as a 1 in a vector of
% length of the recording. This is similar to the dg_onset array but there
% is one array for each grating direction.

grating_directions = mousedata.daqdata.dg_sequence;

dgOnEachDirection = struct();
grating_directions(grating_directions == 0) = 360;

for b = 1:length(grating_directions)
    dgOnEachDirection.(['dg' num2str(grating_directions(b))]) = zeros(1,length(grating_onset));
end


for c = 1:length(grating_onset)  
    if ~(grating_onset(c) == 0)
        dgOnEachDirection.(['dg' num2str(grating_onset(c))])(c:c+123) = 1;
    end
    
end

end
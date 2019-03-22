function signal_downsampled = preprocess_downsampleSignalToClock(signal,frame_onset)

%-- Downsample runspeed to the frame clock for imaging
down_sampled_frame_ref = [];
indx = 1;
for y = 1:length(frame_onset)
    if frame_onset(y) > 0.9
        down_sampled_frame_ref(indx) = y;
        indx = indx+1;
    end
end

%signal(signal<0) = 0;
new_signal = [];
for t = 1:length(down_sampled_frame_ref)
   new_signal(t) = signal(down_sampled_frame_ref(t)); 
end

signal_downsampled = new_signal;

end
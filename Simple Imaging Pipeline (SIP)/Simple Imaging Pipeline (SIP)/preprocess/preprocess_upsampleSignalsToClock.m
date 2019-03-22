function upsampled_signal = preprocess_upsampleSignalsToClock(signal,scale)

%-- Upsample values for ROI signal to fit 2p clock
upsampled_signal = [];
number_of_imaging_planes = scale;
for x = 1:size(signal,1)
    count = 1;
    for y = 1:size(signal,2)
        upsampled_signal(x,count:count+number_of_imaging_planes-1) = signal(x,y);
        count = count+number_of_imaging_planes;
    end
end


end
function grating_on = filterPhotodiodeSignal(pdData,sampling_rate)
% Downsamples the photodiode signal and outputs a array with 1s where the screen is on and 0 elsewhere. 
% This is made based on a thresholding of the pdData signal.

% Input 
%   pdData: sampled signal frm the photo diode
%   sampling_rate: sampling rate of the pdData signal
% Output
%   grating_on: a binary array where there are 1's at the sample points the
%   photo diode detects the screen to be on.
%
% Written by Andreas Lande. 

down_samp_rate = sampling_rate/20;
filtered_pdSignal = [];
c = 1;
for x = 1:down_samp_rate:length(pdData)-50
    filtered_pdSignal(c:c+50) = mean(pdData(x:x+down_samp_rate));
    c = c+50;
end

up = 0;

grating_on = zeros(1,length(filtered_pdSignal));

for y = 1:length(filtered_pdSignal)
   
    if up == 0
       
        if filtered_pdSignal(y) > 3
           up = 1;
           grating_on(y) = 1;        
        end
        
    else

        if filtered_pdSignal(y) < 2.5
            up = 0;
        else
            grating_on(y) = 1;
        end
        
    end
    
    
end

% Zero padding at end
difference_size = length(pdData)-length(grating_on);
grating_on = [grating_on,zeros(1,difference_size)];


% ---  Uncomment to check number of samples where gratings is on:
% up = 0;
% ups = zeros(1,500);
% count = 1;
% for t = 2:length(grating_on)
% 
%     if grating_on(t) == 1
%         ups(count) = ups(count)+1;
%     end
%     if (grating_on(t-1) == 1) & (grating_on(t) == 0)
%        count = count + 1; 
%     end
% end



end
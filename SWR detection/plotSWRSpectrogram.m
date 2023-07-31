function [] = plotSWRSpectrogram(sData)


window  = 128;              % Window size for computing the spectrogram (FFT) [# samples]
overlap = 127;              % Overlap of the windows for computing the spectrogram [# samples]
nFFT    = 50:5:300;        % Vector defining the frequencies for computing the FFT
Fs      = 2500;             % Signal sampling frequency.

nRipples = length(sData.ephysdata.absRipIdx);
for i = 1:nRipples
    % discard ripple segments that are empty(e.g., [] ) or contains NaNs,
    if not( sum(size(sData.ephysdata.rippleSnips(i).lfp)) == 0) && ...
        ~isnan(sData.ephysdata.rippleSnips(i).lfp(1))
        allRipples(i,:) = sData.ephysdata.rippleSnips(i).lfp(501:2000);
    end
end

swr_segments = zeros(nRipples, 2501);

for i = 1:nRipples
    if isempty( sData.ephysdata.rippleSnips(i).lfp)
        swr_segments(i,:) = NaN;
    else
    swr_segments(i,:) = sData.ephysdata.rippleSnips(i).lfp;
    end
end
mean_swr_waveform = mean(swr_segments);

for z = 1:size(allRipples,1)
    fprintf('Calculating spectrogram...ripple %d of %d\n',z,size(allRipples,1));
    x = allRipples(z,:);
    [~,~,~,cP] = spectrogram(x,window,overlap,nFFT,Fs);
    P(:,:,z) = cP;
end
P = mean(P,3);
[~,F,T,~] = spectrogram(x,window,overlap,nFFT,Fs);

trim = round( (2500-length(T))/2);
mean_swr_waveform_trim = mean_swr_waveform(trim:(2500-trim));

% Plot spectrogram
figure
contourf(T,F,(abs(P)),200,'edgecolor','none');
hold on
plot(T, (mean_swr_waveform_trim*200)+60, 'color', 'w', 'linew',1)
% set(gca, 'clim',[-113, -7]);
colormap(jet)
colorbar
title('Avg spectrogram of all SWR events')
ylabel('Frequency (Hz)')
xlabel('Time (s)')
function [] = plotSWRSpectrogram(sData)


window  = 128;              % Window size for computing the spectrogram (FFT) [# samples]
overlap = 127;              % Overlap of the windows for computing the spectrogram [# samples]
nFFT    = 50:10:300;        % Vector defining the frequencies for computing the FFT
Fs      = 2500;             % Signal sampling frequency.

nRipples = length(sData.ephysdata.absRipIdx);
for i = 1:nRipples
    allRipples(i,:) = sData.ephysdata.rippleSnips(i).lfp(501:2000);
end

for z = 1:size(allRipples,1)
    fprintf('Calculating spectrogram...ripple %d of %d\n',z,size(allRipples,1));
    x = allRipples(z,:);
    [~,~,~,cP] = spectrogram(x,window,overlap,nFFT,Fs);
    P(:,:,z) = cP;
end
P = mean(P,3);
[~,F,T,~] = spectrogram(x,window,overlap,nFFT,Fs);
% Plot spectrogram
figure;surf(T,F,10*log10(abs(P)),'edgecolor','none');
colormap(jet)
view([0 90])

title('Avg spectrogram of all SWR events')
ylabel('Frequency (Hz)')
xlabel('Time (s)')
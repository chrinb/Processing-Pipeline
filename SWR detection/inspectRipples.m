function [final_rippleLFP,final_rippleLocs] = inspectRipples(rippleSnips,rippleIdx,lfp,makeSpectrogramPlot)

%use this code to manually go through each SWR in the LFP and approve or
%delete the ripple
nRipples_start = length(rippleSnips);
outOfAllRips = zeros(1,nRipples_start);
t = 1;
msecPerSample = 1000/2500;
extraRipples = [];
i = 1;
while i <= nRipples_start
    if length(rippleSnips(i).lfp) < 2000
       lfpSnip = rippleSnips(i).lfp;
       snipTime = length(rippleSnips(i).lfp)*msecPerSample;
       time = linspace(0,snipTime,length(rippleSnips(i).lfp));
       
    else 
        lfpSnip = rippleSnips(i).lfp(501:2000);
        time = linspace(0,600,1500);
  
    end
    
    if makeSpectrogramPlot
        figure, subplot(2,1,1),plot(time,lfpSnip);
%         drawnow
        box off
        set(gca,'TickDir','out')
        xlim([1 max(time)])

        window  = 128;              % Window size for computing the spectrogram (FFT) [# samples]
        overlap = 127;              % Overlap of the windows for computing the spectrogram [# samples]
        nFFT    = 50:5:300;          % Vector defining the frequencies for computing the FFT
        fs = 2500;
        x = lfpSnip;
        [~,F,T,P] = spectrogram(x,window,overlap,nFFT,fs);


        subplot(2,1,2);surf(T,F,(abs(P)),'edgecolor','none');
          colormap(jet)
          view([0 90])
    else
        figure; plot(time,lfpSnip);

        box off
        set(gca,'TickDir','out')
        xlim([1 max(time)])
    end
%display prompt and wait for response

    prompt = sprintf('Keep ripple? %d of %d',i,nRipples_start);
    x = input(prompt,'s');
    
    if strcmp(x,'y')
        keepRipples(t) = i;
        outOfAllRips(i) = 1;
        t = t + 1;
        
        clear lfpSnip
        close 
        i = i + 1;
    elseif strcmp(x,'b')
        close
        i = i - 1;
        
    elseif strcmp(x,'m')
        [manualLocs,~] = ginput;
        %calculate distance to center of plot, which is at x = 751 samples
        for k = 1:length(manualLocs)
            temp = find(round(time)==round(manualLocs(k)));
            manualLocs(k) = temp(1);
            clear temp
        end
        manualLocs = manualLocs - 751;
        manualLocs = rippleIdx(i) + manualLocs;
        extraRipples = [extraRipples; manualLocs];
        clear lfpSnip
        close
    else
        clear lfpSnip
        close
        i = i + 1;
    end
end

final_rippleLocs = rippleIdx(keepRipples);
final_rippleLocs = [final_rippleLocs extraRipples'];
final_rippleLocs = sort(final_rippleLocs);
for i = 1:length(final_rippleLocs)
    ripWindow = final_rippleLocs(i)-1250:final_rippleLocs(i)+1250;
    % check that ripple window don't begin before lfp recording or ends
    % after the end of lfp recording. Skip SWRs that do. 
    if ripWindow(1) > 1 && ripWindow(end) <= length(lfp)
        final_rippleLFP(i).lfp = lfp(ripWindow);
    end
end
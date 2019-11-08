function [final_rippleLFP,final_rippleLocs] = inspectRipples(rippleSnips,rippleIdx)

%use this code to manually go through each SWR in the LFP and approve or
%delete the ripple
nRipples_start = length(rippleSnips);
outOfAllRips = zeros(1,nRipples_start);
t = 1;
msecPerSample = 1000/2500;
for i = 1:nRipples_start
    if length(rippleSnips(i).lfp) < 2000
       lfpSnip = rippleSnips(i).lfp;
       snipTime = length(rippleSnips(i).lfp)*msecPerSample;
       time = linspace(0,snipTime,length(rippleSnips(i).lfp));
       
    else 
        lfpSnip = rippleSnips(i).lfp(501:2000);
        time = linspace(0,600,1500);
  
    end
    figure; plot(time,lfpSnip);
    
    box off
    set(gca,'TickDir','out')
    xlim([1 max(time)])
    
%display prompt and wait for response
    prompt = sprintf('Keep ripple? %d of %d',i,nRipples_start);
    x = input(prompt,'s');
    
    if strcmp(x,'y')
        keepRipples(t) = i;
        outOfAllRips(i) = 1;
        t = t + 1;
    end
    clear lfpSnip
    close
end

final_rippleLocs = rippleIdx(keepRipples);
final_rippleLFP = rippleSnips(keepRipples);
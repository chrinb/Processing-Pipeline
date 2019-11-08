function [tauRise, tauDecay] = getArConstantsInMs(g, fps)

    % Get exponential constants and scale by samplerate
    tauDr = ar2exp(g) / fps;
    
    % Get t1 and t2 as described here:
    % https://github.com/flatironinstitute/CaImAn-MATLAB/wiki/Interpretation-of-discrete-time-constants
    
    tau1 = tauDr(1); tau2 = tauDr(2);
    
    % Calculate the continuous time constants (see same link)
    tauDecay = tau1;
    tauRise = (tau1*tau2)/(tau1-tau2);
    
    % Convert to milliseconds
    tauDecay = tauDecay * 1000;
    tauRise = tauRise * 1000;
    
    if nargout == 1
        tauRise = [tauRise, tauDecay];
        clear tauDecay
    end

end
function [cia_dec, cia_den, cia_opt] = deconvolve(dff)
%getCaImAnDeconvolvedDff Use CaImAn to deconvolve dff signal.
%
%   cia_dec = getCaImAnDeconvolvedDff(dff, rois)

% Turn off warning that comes when adding cvx library
warning('off', 'MATLAB:dispatcher:nameConflict')
addpath(genpath('/Users/eivinhen/PhD/Programmering/MATLAB/dependencies'));
warning('on', 'MATLAB:dispatcher:nameConflict')

cia_dec = nan(size(dff));
cia_den = nan(size(dff));

nRois = size(dff, 1);
cia_opt = cell(nRois, 1);

prevstr = [];
if isempty(gcp('nocreate'))
    dispProgress = true;
else
    dispProgress = false;
end

starttime = tic;

for r = 1:nRois
    
    roiSignal = squeeze(dff(r, :));
        
    if any(isnan(roiSignal))
        continue
    end
    
    if dispProgress
        dt = toc(starttime);
        newstr = sprintf('Deconvolving signal for RoI %d/%d. Elapsed time: %02d:%02d', r, nRois, floor(dt/60), round(mod(dt, 60)));
        refreshdisp(newstr, prevstr, r)
        prevstr = newstr;
    end
    [den_df, dec_df, opt] = deconvolveCa(roiSignal, 'method', 'thresholded');
    cia_dec(r, :) = dec_df;
    cia_den(r, :) = den_df;
    cia_opt{r} = opt;
    

    
end

if dispProgress
refreshdisp('', prevstr, r)
fprintf('Signal deconvolution finished in %02d:%02d\n', floor(dt/60), round(mod(dt, 60)))
end

end
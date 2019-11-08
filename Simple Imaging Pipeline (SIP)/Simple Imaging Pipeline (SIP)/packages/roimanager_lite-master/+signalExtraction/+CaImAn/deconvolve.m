function [cia_dec, cia_den, cia_opt] = deconvolve(dff, opt)
%getCaImAnDeconvolvedDff Use CaImAn to deconvolve dff signal.
%
%   cia_dec = getCaImAnDeconvolvedDff(dff, rois)
%
%   dff is nRois x nTimePoints/nSamples

% Set default options...
if isfield(opt, 'caimanParameters')
    if isfield(opt.caimanParameters, 'spkSnr')
        opt.spk_SNR = opt.caimanParameters.spkSnr;
    end
    if isfield(opt.caimanParameters, 'lamPr')
        opt.lam_pr = opt.caimanParameters.lamPr;
    end
else
    if ~isfield(opt, 'spk_SNR');    opt.spk_SNR = 1;        end
    if ~isfield(opt, 'lam_pr');     opt.lam_pr = 0.5;       end
end


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

% %Set time constants
switch lower(opt.type)
    case 'ar1' 
%         g = nthroot(0.5, tau_dr(1));
        g = exp(-1/opt.tau_dr(1));
        opt.pars = g;
    case 'ar2'
        opt.pars = exp2ar(opt.tau_dr);
    case 'exp2'
        opt.pars = opt.tau_dr;
    otherwise
        if opt.fps > 15
            opt.type = 'ar2';
        else
            opt.type = 'ar1';
        end
        opt.pars = [];
end


for r = 1:nRois
    
    roiSignal = squeeze(dff(r, :));
        
    if any(isnan(roiSignal))
        cia_opt{r} = struct;
        cia_opt{r}.nSpikes = 0;
        continue
    end
    
    fr = opt.fps;
    decay_time = 0.5;  % default value in CNMF: 0.4; Maybe this is for f?
    
% %     a = GetSn(roiSignal, [.25, .5]);
% %     b = GetSn(roiSignal, [0, .25]);
% %     fprintf('Signal: %.3f    Noise: %.3f \n', b, a)
    
    spkmin = opt.spk_SNR * GetSn(roiSignal);   % GetSn = Noise Standard Deviation
%     spkmin = signalExtraction.spikeEstimation.getSpikeCutoffThreshold(dff);

    lam = choose_lambda(exp(-1/(fr*decay_time)), GetSn(roiSignal),opt.lam_pr);
    
    
    switch opt.type
        case 'ar1'
        	[cc,spk,opts_oasis] = deconvolveCa(roiSignal, 'ar1', 'method','thresholded', ...
                                 'lambda', lam, 'smin', spkmin, 'pars', opt.pars(1),...
                                 'optimize_b', true, 'optimize_pars', true);
        case 'ar2'
            [cc,spk,opts_oasis] = deconvolveCa(roiSignal, 'ar2', 'method','thresholded', ...
                                 'lambda', lam, 'smin', spkmin, 'pars', opt.pars, ...
                                 'optimize_b', true, 'optimize_pars', false);
        case 'exp2'
            [cc,spk,opts_oasis] = deconvolveCa(roiSignal, 'exp2', 'method','thresholded', ...
                                 'lambda', lam, 'smin',spkmin, 'pars', opt.pars, 'optimize_pars', false);
        case 'autoar'
            [cc,spk,opts_oasis] = deconvolveCa(roiSignal, 'ar2', 'method', 'thresholded', ...
                                 'lambda', lam, 'smin', spkmin,  ...
                                 'optimize_b', true, 'optimize_pars', true);

    end
                            
                            
    baseline = opts_oasis.b;
    den_df = cc(:) + baseline;
    dec_df = spk(:);
    
%     if dispProgress
%         dt = toc(starttime);
%         newstr = sprintf('Deconvolving signal for RoI %d/%d. Elapsed time: %02d:%02d', r, nRois, floor(dt/60), round(mod(dt, 60)));
%         refreshdisp(newstr, prevstr, r)
%         prevstr = newstr;
%     end
    
    
%     [den_df, dec_df, opt] = deconvolveCa(roiSignal, 'method', 'thresholded');
    cia_dec(r, :) = dec_df;
    cia_den(r, :) = den_df;
    cia_opt{r} = opt;
    cia_opt{r}.pars = opts_oasis.pars;
%     cia_opt{r}.nSpikes = 0.04 * round(sum(den_df>spkmin));
    
end

% cia_den = cia_den .* dffStd; 
% cia_dec = cia_dec .* dffStd; 

% if dispProgress
% refreshdisp('', prevstr, r)
% fprintf('Signal deconvolution finished in %02d:%02d\n', floor(dt/60), round(mod(dt, 60)))
% end

end


                                
                                
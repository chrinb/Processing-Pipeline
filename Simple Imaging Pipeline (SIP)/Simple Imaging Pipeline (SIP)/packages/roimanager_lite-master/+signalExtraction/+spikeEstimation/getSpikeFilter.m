function ignoreSpikes = getSpikeFilter(dff, den, method)
%getSpikeFilter Find frames with noise which does not "stand out"
%
%   ignoreSpikes = getSpikeFilter(dff, den, method)
%
%   Input: 
%       dff, den    : matrices (nSamples x nRois)
%       method      : string ('median', 'mode')

    if nargin < 3; method = 'median'; end
        
    % What is the 0.5th percentile of the dff distribution
    lowprctile = prctile(dff, 0.5);

    switch method
        case 'mode'
            dffMode = mode(dff);
            noisecutoff = dffMode + (dffMode-lowprctile);

        case 'median'
            dffMedian = median(dff);
            noisecutoff = dffMedian + (dffMedian-lowprctile);

    end
    
    ignoreSpikes = den<noisecutoff;

end
function spkSnr = getSpikeCutoffThreshold(dff, method)
%getSpikeCutoffThreshold Find "upper threshold" for noise
%
%   spkSnr = getSpikeCutoffThreshold(dff, method)
%
%   Input: 
%       dff         : matrices (nSamples x nRois)
%       method      : string ('median', 'mode')

    if nargin < 2; method = 'mode'; end
        
    % What is the 0.5th percentile of the dff distribution
    lowprctile = prctile(dff, 0.5);
    


    switch method
        case 'mode'
            % dffMode = mode(dff'); % Does not work for doubles...
            
            [n, binEdges] = histcounts(dff, 256);
            binCntr = binEdges(1:end-1) + diff(binEdges(1:2));
            [~, ind] = max(n);
            dffMode = binCntr(ind);
            spkSnr = dffMode + (dffMode-lowprctile);

        case 'median'
            dffMedian = median(dff);
            spkSnr = dffMedian + (dffMedian-lowprctile);

    end
    
    
end
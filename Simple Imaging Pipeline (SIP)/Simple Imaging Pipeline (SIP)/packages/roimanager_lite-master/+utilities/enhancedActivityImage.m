function imOut = enhancedActivityImage(IM)
%enhancedActivityImage Create image where contrast of active RoIs is
%improved
%
%   Work in progress...


IM = single(IM);
[imHeight, imWidth, nIm] = size(IM);

% Find a minimum image. Use this to mask out/ignre all dark (0) pixels
% minIm = nanmin(IM, [], 3);
% mask = minIm == 0;
% mask = repmat(mask, 1, 1, nIm);
% 
% IM(mask) = nan;
% clearvars mask

resizeFactor = 10;
IMtiny = imresize(IM, 1/resizeFactor);
[h, w, ~] = size(IMtiny);

maxNpeaks = 5;
peakIdxArray = zeros([h, w, maxNpeaks]);

warning('off', 'signal:findpeaks:largeMinPeakHeight')
for j = 1:h
    for i = 1:w
        pixelTseries = squeeze(IMtiny(j,i,:));
        peakThreshold = mean(pixelTseries) + 2*std(pixelTseries);
        
        if peakThreshold == 0
            continue
        end
        
        [~, idx] = findpeaks(pixelTseries, 'MinPeakHeight', peakThreshold, 'SortStr','descend');
        nPeaks = numel(idx);
        
        if nPeaks > maxNpeaks; nPeaks = maxNpeaks; end
        
        if nPeaks >= 1
            peakIdxArray(j, i, 1:nPeaks) = idx(1:nPeaks);
        end
    end
end
warning('on', 'signal:findpeaks:largeMinPeakHeight')

imOut = nan(imHeight, imWidth);

for j = 1:h
    for i = 1:w
        for n = 1:maxNpeaks
            peakIdx = peakIdxArray(j,i,n);
            
            if peakIdx == 0
                continue
            end
            
            % Extract imagechunk
            jOrig = j*resizeFactor;
            iOrig = i*resizeFactor;
            colIdx = max([1, iOrig-20]):min([iOrig+20, imWidth]);
            rowIdx = max([1, jOrig-20]):min([jOrig+20, imHeight]);
            frames = max([1, peakIdx-10]):min([peakIdx+10, nIm]);
            imChunk = nanmean(IM(rowIdx, colIdx, frames), 3);
            
            hkernel = fspecial('gaussian', size(imChunk), 20);
            imChunk = imChunk .* hkernel;
            
            minVal = prctile(imChunk(:), 5);
            maxVal = nanmax(imChunk(:));

            imChunk = (imChunk-minVal) / (maxVal-minVal);

            imOut(rowIdx, colIdx) = nanmax(cat(3, imOut(rowIdx, colIdx), imChunk), [], 3);
        end
    end
end


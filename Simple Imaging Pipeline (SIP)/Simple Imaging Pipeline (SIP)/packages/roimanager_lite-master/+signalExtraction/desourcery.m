function [sourceMask, sourceSignal] = desourcery(obj)
    
    % TODO: implement a minimum number of frames

    % Get roi and frames from obj
    if isempty(obj.selectedRois); return; end

    ch = obj.activeChannel;
    roiIdx = obj.selectedRois(end); % Dont want to do this for many rois.

    if isempty(obj.selectedFrames) || sum(obj.selectedFrames) == 0
        frames = 1:obj.nFrames(ch);
    else
        frames = find(obj.selectedFrames);
    end
    
    % Extract chunk of pixels centered around selected roi
    [y, x] = find(obj.roiArray{ch}(roiIdx).mask);
    minX = min(x); maxX = max(x);
    minY = min(y); maxY = max(y);
    minX = minX-5; minY=minY-5;maxX=maxX+5;maxY=maxY+5;
    pixelChunk = obj.imgTseries{ch}(minY:maxY, minX:maxX, frames);
    roiMask = obj.roiArray{ch}(roiIdx).mask;
    roiMask = roiMask(minY:maxY, minX:maxX);
    
    nPixRoi = sum(roiMask(:));

    % Apply a gaussian filtering
%     pixelChunk = filterImArray(pixelChunk, [], 'gauss');

    % Get size of pixelchunk.
    [imH, imW, nFrames] = size(pixelChunk);
    
    % Make a 2d representation of pixelChunk (nPix x nSamples)
    pixelSignal = double(reshape(pixelChunk, [], nFrames));

    % Find pixel correlations
    [rho, p] = corrcoef(pixelSignal');
    rho = rho - eye(size(rho));

% There was an idea to to motion correction, because motion artifacts
% create correlations...
%     [imArrayOut, ~, ~, ~] = nonrigid(pixelChunk);
    
    Z = linkage(rho,'complete','correlation');
    T = cluster(Z,'maxclust',10);
    T = reshape(T, imH, imW);
%     figure; imagesc(T)

    % Find significantly correlated pixel pairs at 1% significance level.
    isSignificant = p < 0.00001;
    
    % Remove pixel pairs that are correlating with without being part of a 
    % cluster (Correlations between single unconnected pixels) 
    isSignificant = imopen(isSignificant, ones(3,3));
    
    % Find number of other pixels each pixel correlate with
    numSignPerPix = sum(isSignificant);
    
    isSignificantPix = numSignPerPix > 5;
    BW = reshape(isSignificantPix, imH, imW);
    
    T(~BW) = 0;
    CC = struct;
    uniqueClusters = unique(T(:));
    uniqueClusters(uniqueClusters == 0) = [];
    CC.ImageSize = size(T);
    CC.NumObjects = numel(uniqueClusters);
    CC.PixelIdxList = arrayfun(@(i) find(T==i), uniqueClusters, 'uni', 0);

% %     % Make a BW mask of significant pixels and split into connected regions
% %     CC = bwconncomp(BW);

    % Only keep regions with more than 8 pixels.
    keep = cellfun(@(c) numel(c)>=5, CC.PixelIdxList);
    CC.NumObjects = sum(keep);
    CC.PixelIdxList = CC.PixelIdxList(keep);

    % Preallocate signal for each detected source
    sourceSignal = zeros(nFrames, CC.NumObjects);
    sourceMask = false(imH, imW, CC.NumObjects);
    baseline = prctile(pixelSignal, 30, 1); % Todo: make variable. Based on total roi area within chunk
    
    for j = 1:CC.NumObjects
        
        % Create a boolean mask for detected component
        pixInd = CC.PixelIdxList{j};
        mask = false(CC.ImageSize);
        mask(pixInd) = true;
        mask1d = reshape(mask, 1, []);
        mask1d = mask1d / sum(mask1d(:));

        sourceMask(:, :, j) = mask;
        sourceSignal(:, j) = sparse(mask1d) * pixelSignal - baseline;
        
        % Remove signal from each pixel%         
        mask = imdilate(mask, ones(3,3));
        pixInd = find(mask);
        roiOverlap = sum(roiMask(:) & mask(:)) / nPixRoi;
        roiNonOverlap = sum(mask(:) & ~roiMask(:)) / nPixRoi;
        
        if roiOverlap < 0.25 && roiNonOverlap > 0.05
            ccs = sgolayfilt(pixelSignal(pixInd, :), 3, 7, [], 2);
            ccs = ccs - baseline;
            roiMask = roiMask & ~mask;
%            pixelSignal(pixInd, :) = nan;
%             pixelSignal(pixInd, :) = pixelSignal(pixInd, :) - ccs;
        end
        
    end
    
    sourceSignal = sgolayfilt(sourceSignal, 3, 11);

    % Check if some sources are correlated
    [rho, p] = corrcoef(sourceSignal);
    toMerge = rho > 0.8 & p < (0.01 / CC.NumObjects);
    toMerge = triu(toMerge);
    
    [c1, c2] = ind2sub(size(toMerge), find(toMerge));
    
    for i = 1:numel(c1)
        sourceSignal(:, c1(i)) = mean(sourceSignal(:, [c1(i), c2(i)]), 2);
        sourceMask(:, :, c1(i)) = sourceMask(:, :, c1(i)) | sourceMask(:, :, c2(i));
    end
    
    sourceSignal(:, c2) = [];
    sourceMask(:, :, c2) = [];
    
    nSources = size(sourceSignal, 2);
    roiOverlap = arrayfun(@(i) sum(sum(roiMask & sourceMask(:, :, i)))/nPixRoi, 1:nSources);
    pixelChunk = reshape(pixelSignal, [CC.ImageSize, nFrames]);

    roimask1d = reshape(roiMask, 1, []);
    roisignal = sparse(roimask1d/sum(roimask1d(:))) * pixelSignal;
    npilmask = ~roiMask & sum(sourceMask, 3)==0;
    npilmask1d = reshape(npilmask, 1, []);
    npilsignal = sparse(npilmask1d/sum(npilmask1d(:))) * pixelSignal;
    
    dff_new = signalExtraction.dff.dffRoiMinusDffNpil(roisignal, npilsignal);
    obj.signalArray.dff(frames, roiIdx) = dff_new;
    
    if false
        figure('Position', [400, 400, 600, 400]); 
        ax1 = axes('Position', [0.05, 0.05, 0.9, 0.4]);
        ax2 = axes('Position', [0.05, 0.5, 0.9, 0.4]);
        plot(ax1, obj.signalArray.dff(frames, roiIdx), 'm' ); hold(ax1, 'on')
        plot(ax1, dff_new, 'g')

        plot(ax2, roisignal); hold(ax2, 'on'); plot(ax2, npilsignal)
        plot(ax2, obj.signalArray.roiMeanF(frames, roiIdx), 'm')
    end
    
%     extractSignal(obj, roiIdx, 'deconvolved');
%     extractSignal(obj, roiIdx, 'spikes');
    obj.updateSignalPlot(roiIdx, 'overwrite')

 end
    
%     Z = linkage(rho,'complete','correlation');
%     T = cluster(Z,'maxclust',20);
%     T = reshape(T, imH, imW);
%     figure; imagesc(T)
%     figure;T
%     dendrogram(Z)
    
    

    
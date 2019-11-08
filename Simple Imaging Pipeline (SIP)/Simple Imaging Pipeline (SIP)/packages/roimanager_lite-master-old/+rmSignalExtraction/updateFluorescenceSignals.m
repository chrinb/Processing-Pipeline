function [ signalDataNew ] = updateFluorescenceSignals( imArray, newRois, signalDataOld)
%updateFluorescenceSignals Update signalData by comparing old and new rois
%   signalDataNew = updateFluorescenceSignals( imArray, newRois, signalDataOld)
%
% Todo: If old roi array is longer, i.e some rois have been deleted, this
% function should match rois in new array to rois in old array before
% calculating new signals.

oldRois = signalDataOld.roiArray;

% Determine dimensions of new data

nNewRois = numel(newRois);
nOldRois = numel(oldRois);
nSamples = size(imArray, 3);

% Preallocate
signalDataNew.meanRoiFluorescence = zeros(nNewRois, nSamples);
signalDataNew.meanNeuropilFluorescence = NaN(nNewRois, nSamples);
signalDataNew.meanNPilBulkFluorescence = NaN(1, nSamples);

% Check if neuropil was extracted. If so, do it now as well
if isfield(signalDataOld, 'meanNeuropilFluorescence')
    getNeuropil = true;
    npmask = createNeuropilMask(newRois);
else
    getNeuropil = false;
end

% Loop through rois.
for r = 1:nNewRois
    
    if r <= nOldRois
        % Check if roi in new array is the same as roi in old array
        if isequal(oldRois(r), newRois(r))
            signalDataNew.meanRoiFluorescence(r, :) = signalDataOld.meanRoiFluorescence(r, :);
            if getNeuropil
                signalDataNew.meanNeuropilFluorescence(r, :) = signalDataOld.meanNeuropilFluorescence(r, :);
            end
            
            continue % no need to extract signal again
            
        end
    end
    
    % Update signal if old signal was not found..
    roi = newRois(r);
    surroundroimask = createSurroundingRoiMask(newRois, r);
    if getNeuropil
        signal = extractRoiFluorescence(roi, imArray, surroundroimask, npmask);
        signalDataNew.meanNeuropilFluorescence(r, :) = signal.fmeanNeuropil;
    else
        signal = extractRoiFluorescence(roi, imArray, surroundroimask, []);
    end
    signalDataNew.meanRoiFluorescence(r, :) = signal.fmeanRoi;

end

if getNeuropil % Copied from extractFluorescenceSignals
    % Extract neuropil bulk fluorescence.
    npBulkMask = repmat(npmask, 1, 1, nSamples);
    imArray(~npBulkMask) = 0;
    fmeanBulkNeuropil = squeeze(sum(sum(imArray, 1), 2)) / sum(npmask(:));
    signalDataNew.meanNPilBulkFluorescence = fmeanBulkNeuropil';  
end

% Add new rois to signal
signalDataNew.roiArray = newRois;
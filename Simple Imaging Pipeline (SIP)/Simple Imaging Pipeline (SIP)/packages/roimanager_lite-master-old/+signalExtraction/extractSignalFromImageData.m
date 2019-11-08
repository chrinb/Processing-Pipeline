function signalArray = extractSignalFromImageData(imArray, roiArray, method, roiIdx)

% Returns: 
%   signalArray : extracted roi signals  (nSamples x nSubregions x nRois)
%
% See also signalExtraction.extractRoiFluorescence

% Extract from all rois by default.
if nargin < 4; roiIdx = 1:numel(roiArray); end

% Determine number of subregions to extract from each roi.
switch lower(method)
    case 'raw'
        nSubregions = 1;
    case 'standard'
        nSubregions = 2;
    case 'fissa'
        nSubregions = 4+1;
end

nSamples = size(imArray, 3);
nRois = numel(roiIdx);

% Initialize signalArray
signalArray = zeros(nSamples, nSubregions, nRois);


% Loop through rois
for i = 1:numel(roiIdx)

    % Get the mask for the current RoI
    roiMask = roiArray(roiIdx(i)).mask;

    switch lower(method)

        case 'raw'
            signalArray(:, :, i) = signalExtraction.extractRoiFluorescence(imArray, roiMask);

        case 'standard' % Remove surrounding rois and extract neuropil too
            [roiMask, npMask] = signalExtraction.standard.getMasks(roiArray, roiIdx(i));
            signalArray(:, :, i) = signalExtraction.extractRoiFluorescence(imArray, roiMask, npMask, 'median');

        case 'fissa'
            % Get the mask for the current RoI and surrounding neuropils
            npMask = signalExtraction.fissa.getMasks(roiMask, nSubregions-1, nSubregions-1);
            signalArray(:, :, i) = signalExtraction.extractRoiFluorescence(imArray, roiMask, npMask);

        otherwise
            fprintf('unknown method for signal extraction, ''%s''\n', method)

    end

end


end

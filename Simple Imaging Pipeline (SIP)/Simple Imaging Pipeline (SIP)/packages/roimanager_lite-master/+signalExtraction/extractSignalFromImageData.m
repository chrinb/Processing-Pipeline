function signalArray = extractSignalFromImageData(imArray, roiArray, method, roiInd, imageMask)

% Returns: 
%   signalArray : extracted roi signals  (nSamples x nSubregions x nRois)
%
% See also signalExtraction.extractRoiFluorescence


% Extract from all rois by default.
if nargin < 4 || isempty(roiInd); roiInd = 1:numel(roiArray); end
if nargin < 5 || isempty(imageMask); imageMask = []; end

% Convert roiArray to struct array of masks for better performance
if isa(roiArray, 'RoI') || (isa(roiArray, 'struct') && isfield(roiArray, 'mask'))
    structArrayOfMasks = signalExtraction.prepareMasks(roiArray, method, roiInd, imageMask);
    roiInd = 1:numel(structArrayOfMasks); % Update indices because roi array might have been shortened
elseif isa(roiArray, 'struct') && isfield(roiArray, 'original')
    structArrayOfMasks = roiArray; clearvars roiArray
else
    error('Unsupported input format of roiArray')
end

% Determine number of subregions to extract from each roi.
switch lower(method)
    case 'raw'
        nSubregions = 1;
    case 'standard'
        nSubregions = 2;
    case 'donut_npil'
        nSubregions = 2;
    case 'fissa'
        nSubregions = 4+1;
end

% Initialize signalArray
nSamples = size(imArray, 3);
nRois = numel(roiInd);
signalArray = zeros(nSamples, nSubregions, nRois);

% Shorten name of fluorescence extraction function
extractF = @signalExtraction.extractRoiFluorescence;

% Loop through rois
for i = 1:nRois

    % Get mask of current roi
    roiOrigMask = structArrayOfMasks(roiInd(i)).original;

    switch lower(method)

        case 'raw'
            signalArray(:, :, i) = extractF(imArray, roiOrigMask);

        case 'standard' % Remove surrounding rois and extract neuropil too
            roiUniqMask = structArrayOfMasks(roiInd(i)).unique;
            roiNpilMask = structArrayOfMasks(roiInd(i)).neuropil;
            signalArray(:, :, i) = extractF(imArray, roiUniqMask, roiNpilMask, 'mean');
        case 'donut_npil' 
            roiNpilMask = structArrayOfMasks(roiInd(i)).neuropil;
            signalArray(:, :, i) = extractF(imArray, roiOrigMask, roiNpilMask, 'median');
        case 'fissa'
            roiNpilMask = structArrayOfMasks(roiInd(i)).neuropil;
            signalArray(:, :, i) = extractF(imArray, roiOrigMask, roiNpilMask);

        otherwise
            fprintf('unknown method for signal extraction, ''%s''\n', method)

    end

end


end

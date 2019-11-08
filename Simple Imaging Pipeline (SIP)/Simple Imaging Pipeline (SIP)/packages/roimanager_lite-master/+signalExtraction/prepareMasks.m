function roiMaskStruct = prepareMasks(roiArray, method, roiInd, imageMask)
%roiMaskStruct Create a structarray of roimasks for signal extraction
%
%   roiMaskStruct = prepareMasks(roiArray, method) returns a struct of roi
%   masks for all rois in the roi array. roiMaskStruct contains 3 fields:
%       original    : The original mask of the roi
%       unique      : The original mask excluding overlapping rois
%       neuropil    : A mask of surrounding neuropil.
%
%   The masks depend on the second argument, method. Method can be either
%   'raw', 'standard', 'donut_npil' or 'fissa'. Description of each method:
%       'raw'       : Only maskOrig. maskUniq and maskNpil are empty.
%       'standard'  : All fields have masks. neuropil is created by finding
%                     all pixels within an area 4x the size of the 
%                     unique mask. All surrounding rois are excluded.
%       'donut'     : All fields have masks. neuropil is created by finding
%                     all pixels within a donut area surrounding the roi.
%                     Surrounding rois are not excluded.
%       'fissa'     : No unique mask. neuropil is the same as 'donut',
%                     but it is split in 4 parts.
%
%   roiMaskStruct = prepareMasks(roiArray, method, roiInd) the optional
%   input roiInd specified the indices of rois to create masks for.
%
%   Eivind Hennestad | Vervaeke Lab | Sept 2018


% The default is to prepare masks for all rois
if nargin < 3 || isempty(roiInd)
    roiInd = 1:numel(roiArray);
end

if nargin < 4
    imageMask = [];
end

% Count number of rois
nRois = numel(roiInd);

% Determine number of subregions
switch lower(method)
    case 'raw'
        nSub = 1;
    case 'standard'
        nSub = 2;
    case 'donut'
        nSub = 2;
    case 'fissa'
        nSub = 4+1;
end

% Extract masks as cell array of mask and as a logical mask array
roiMasks = cat(3, {roiArray(:).mask});
roiMaskArray = cat(3, roiMasks{:});

roiMasks = roiMasks(roiInd);

% Preallocate neuropil masks and masks without overlap of other rois.
roiUniqueMask = cell(1, nRois); 
roiNpilMask = cell(1, nRois);

% NB; Use n for loop iterator and i for roiInd
for n = 1:nRois
    
    switch lower(method)
        case 'raw' 
            % Do nothing
        case 'standard'
            [roiUniqueMask{n}, roiNpilMask{n}] = ...
                signalExtraction.standard.getMasks(roiMaskArray, roiInd(n), [], imageMask);
        case 'donut'
            [roiUniqueMask{n}, ~] = ...
                signalExtraction.standard.getMasks(roiMaskArray, roiInd(n));
            roiNpilMask{n} = ...
                signalExtraction.fissa.getMasks(roiMasks{n}, nSub-1, 4);
        case 'fissa'
            roiNpilMask{n} = ...
                signalExtraction.fissa.getMasks(roiMasks{n}, nSub-1, nSub-1);
        otherwise
            error('The method, %s, is not implemented for roimask preparation', method)
    end
end

% Add all masks to a struct which can be used for signal extraction.
roiMaskStruct = struct('original', roiMasks, ...
                       'unique', roiUniqueMask, ...
                       'neuropil', roiNpilMask);

end
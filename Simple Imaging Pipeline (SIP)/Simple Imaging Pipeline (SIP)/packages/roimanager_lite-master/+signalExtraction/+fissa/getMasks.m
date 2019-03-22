function splitMask = getMasks(roiMask, nNpil, expansionFactor)
%Generate neuropil masks using the get_npil_mask function.
%
%     Parameters
%     ----------
%     roiMask : logical array
%         the cell mask (boolean 2d arrays)
%     nNpil : int
%         number of neuropil subregions
%     expansion : double
%         How much larger to make neuropil subregion area than roiMask's
% 
%     Returns
%     -------
%     Returns a list with neuropil masks (boolean 2d arrays)

if nargin < 3; expansionFactor = 4; end
if nargin < 2; nNpil = 4; end


% get the total neuropil for this cell
npMask = signalExtraction.fissa.findneuropilmask(roiMask, expansionFactor);

% split it up in nNpil neuropils
splitMask = signalExtraction.fissa.splitneuropilmask(npMask, roiMask, nNpil);

end
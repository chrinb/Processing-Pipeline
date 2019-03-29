function [tiffFiles] = listTseriesFiles(sessionID, blockNo, multicycle)
%listTseriesFiles returns full paths to all tiff-files of a block
%   Paths are ordered in a nested cell array, where the first layer has one
%   element for each imaging channel, and each channel element contains the
%   images for that channel.
%
%   INPUTs:
%       sessionID (str)     - sessionID for experiment 
%       blockNo (int)       - block number
%       multicycle (bool)   - are tseries acquired using multicycle?
%   
%   OUTPUT:
%       tiffFiles (cell)    - tiffFiles{c}{n} returns absolute path to
%                             image n from channel c


% Path to folders containing images for current session
sessionFolder = getSessionFolder(sessionID);
tSeriesParent = fullfile(sessionFolder, 'calcium_images');
tSeriesFolders = dir(fullfile(tSeriesParent, 'TSeries*'));


% Make multicycle true by default
if nargin < 3
    multicycle = true;
end


% Get folder path for TSeries folder containing raw tiff files
if multicycle
    tSeriesPath = fullfile(tSeriesParent, tSeriesFolders(1).name); 
else
    tSeriesPath = fullfile(tSeriesParent, tSeriesFolders(blockNo).name);
end


% Get a list of the raw tiff-files in the TSeries folder corresponding
% to current cycle/block.
if multicycle
    tiffFiles = dir(fullfile(tSeriesPath, ...
                    strcat('*Cycle', num2str(blockNo, '%05d*'))));
else
    tiffFiles = dir(fullfile(tSeriesPath, '*.tif'));
end

tiffFiles = fullfile(tSeriesPath, {tiffFiles.name});


% Find channels in list of files. Assumes Ch is always fixed in filename
[imChannels, ~, ic] = unique(cellfun(@(x) x(end-17:end-15), tiffFiles, ...
                             'uni', 0));
nChannels = length(imChannels);
nIms = histc(ic, 1:nChannels);
%assert( numel(unique(nIms)) == 1 )


% Sort tiff files into cell array according to channels
tiffFiles = arrayfun(@(x) tiffFiles(ic==x), 1:nChannels, 'uni', 0 );

end


function [ imArray ] = loadPrairieViewStack( tSeriesPath, cycle, ch)
%loadPrairieViewStack Load PrairieView tiff files into a matlab array
%   A = loadPrairieViewStack(tSeriesPATH) returns an array of images (uint8) from all 
%   channels of a PrairieView recording saved in a folder specified by tSeriesPATH.
%
%   A = loadPrairieViewStack(tSeriesPATH, CYCLE, CH) returns an array of images from 
%   the recording cycle specified by CYCLE and the channel specified by CH 
%   (CYCLE and CH are integers).
%
%   see also getPrairieMetaData

% Get a list of the raw tiff-files in the TSeries folder corresponding
% to current cycle/block.

tiffFiles = dir(fullfile(tSeriesPath, ...
    strcat('*Cycle', num2str(cycle, '%05d'), '_Ch', num2str(ch), '*' )));

tiffFiles = fullfile(tSeriesPath, {tiffFiles.name});

% Following code is adapted from the function 'stack2mat'

nFrames = length(tiffFiles);

imInfo = imfinfo(tiffFiles{1});
 
nRow = imInfo(1).Width;
nCol = imInfo(1).Height;

imArray = zeros(nRow, nCol, nFrames, 'uint8');

for i = 1:nFrames
    imArray(:, :, i) = imread(tiffFiles{i})./16;
end


end


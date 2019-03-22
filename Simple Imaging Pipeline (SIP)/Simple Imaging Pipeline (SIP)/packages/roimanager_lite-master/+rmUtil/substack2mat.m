function [ imArray ] = stack2mat( tiffStackPath, wb_on, first, last )
%STACK2MAT loads a tiff stack into an uint8 3dim array
%   Y = STACK2MAT(filepath) is an uint8 3 dim array of images from specified file
%
%   Y = STACK2MAT(filepath, true) loads the file and opens 
%   a waitbar to show progress while loading the file.

% Default: load all frames
if nargin < 4
    first = 1;
    last = -1;
end

% Default: waitbar is off
if nargin < 2
    wb_on = false;
end

tiffFile = Tiff(tiffStackPath, 'r');

initialFrame = tiffFile.currentDirectory();

% Get number of frames
n = 1;
tiffFile.setDirectory(1);
complete = tiffFile.lastDirectory();
while ~complete
    tiffFile.nextDirectory();
    n = n + 1;
    complete = tiffFile.lastDirectory();
end

if last == -1; last = n; end

% Get image dimensions and create empty array
nRow = tiffFile.getTag('ImageLength');
nCol = tiffFile.getTag('ImageWidth');
imArray = zeros(nRow, nCol, last-first+1, 'uint8');

if wb_on; h = waitbar(0, 'Please wait... Loading calcium images...'); end
    
% Load images to array
tiffFile.setDirectory(first);
imArray(:,:,first) = tiffFile.read();
for i = first+1:last
    tiffFile.nextDirectory();
    imArray(:,:,i) = tiffFile.read();
    
    if mod(i, 100) == 0 && wb_on
        waitbar(i/n, h)
    end
    
end

if wb_on; close(h); end

tiffFile.setDirectory(initialFrame);




% Old Version using imread

% % Load stack info
% if nargin < 2 || isempty(imInfo) 
%     imInfo = imfinfo(tiffStackPath);
% end
%     
% nRow = imInfo(1).Width;
% nCol = imInfo(1).Height;
% nFrames = length(imInfo);
% 
% % Create empty array
% stackArray = zeros(nCol, nRow, nFrames, 'uint8');
% 
% switch wb_on
%     
%     case {true, 'on'} % Load images while displaying a waitbar
%         h = waitbar(0, 'Please wait... Loading calcium images...');
%         for i = 1:nFrames
%             stackArray(:, :, i) = imread(tiffStackPath, 'Index', i, 'Info', imInfo);
%             if mod(i, 50) == 0
%                 waitbar(i/nFrames, h)
%             end
%         end
%         waitbar(1, h, 'Images loaded successfully')
%         close(h) 
%     
%     case {false, 'off'}  % Load images without displaying progress
%         for i = 1:nFrames
%             stackArray(:, :, i) = imread(tiffStackPath, 'Index', i, 'Info', imInfo);
%         end
% end


end



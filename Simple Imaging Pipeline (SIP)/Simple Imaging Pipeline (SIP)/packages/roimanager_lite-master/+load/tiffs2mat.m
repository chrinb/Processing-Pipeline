% function [ imArray ] = tiffs2mat( stackPath, wb_on, msg, first, last, wbfun)
function [ imArray ] = tiffs2mat( stackPath, wb_on, msg, first, last)

    %STACK2MAT loads a tiff stack into an uint8 3dim array
    %   Y = STACK2MAT(filepath) is an uint8 3 dim array of images from specified file
    %
    %   Y = STACK2MAT(filepath, true) loads the file and opens 
    %   a waitbar to show progress while loading the file.
    %
    %   Note: Assume that tiffs are saved in unsigned integer format.
       
    if nargin < 1; [filename, folder, ~] = uigetfile; 
        stackPath = fullfile(folder, filename); end

    % Default: waitbar is off, load all frames
    if nargin < 2; wb_on = false; end
    if nargin < 3; msg = 'Loading tiffstack, please wait...'; end
    if nargin < 4; first = 1; last = -1; end

    tiffFile = Tiff(stackPath, 'r');

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
    dataClass = sprintf('uint%d', tiffFile.getTag('BitsPerSample'));
    imArray = zeros(nRow, nCol, last-first+1, dataClass);

    if wb_on; h = waitbar(0, msg); end
%     if nargin == 6; wbfun{1}(h, wbfun{2}); end

    % Load images to array
    tiffFile.setDirectory(first);
    im = tiffFile.read();
    imArray(:,:,1) = im(:, :, 1);
    for i = first+1:last
        tiffFile.nextDirectory();
        im = tiffFile.read();
        imArray(:,:,i-first+1) = im(:, :, 1);
        if mod(i-first+1, 100) == 0 && wb_on
            waitbar((i-first+1)/(last-first+1), h)
        end

    end

%     handles = getappdata(h,'TMWWaitbar_handles');
%     set(handles.container, 'Parent', handles.figure)
    
    if wb_on; close(h); end

    tiffFile.setDirectory(initialFrame);
end

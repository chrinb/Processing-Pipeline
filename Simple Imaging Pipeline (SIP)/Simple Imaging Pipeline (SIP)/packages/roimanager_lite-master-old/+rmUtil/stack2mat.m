function [ imArray ] = stack2mat( stackPath, wb_on, msg)
    %STACK2MAT loads a tiff stack into an uint8 3dim array
    %   Y = STACK2MAT(filepath) is an uint8 3 dim array of images from specified file
    %
    %   Y = STACK2MAT(filepath, true) loads the file and opens 
    %   a waitbar to show progress while loading the file.


    % Default: waitbar is off
    if nargin < 2
        wb_on = false;
    end

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

    % Get image dimensions and create empty array
    nRow = tiffFile.getTag('ImageLength');
    nCol = tiffFile.getTag('ImageWidth');
    imArray = zeros(nRow, nCol, n, 'uint8');

    if wb_on; h = waitbar(0, msg); end

    % Load images to array
    tiffFile.setDirectory(1);
    imArray(:,:,1) = tiffFile.read();
    for i = 2:n
        tiffFile.nextDirectory();
        imArray(:,:,i) = tiffFile.read();

        if mod(i, 100) == 0 && wb_on
            waitbar(i/n, h)
        end

    end

    if wb_on; close(h); end

    tiffFile.setDirectory(initialFrame);
end

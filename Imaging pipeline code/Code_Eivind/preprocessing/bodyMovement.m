function [ timeVec, struggleFactor ] = bodyMovement(sessionID, block, crop)
%bodyMovement Looks at mouse video for body movement
%   [ timeVec, struggleFactor ] = bodyMovement(sessionID, block, crop)
%   returns the struggleFactor and corresponding times for specified
%   sessionID and block. 
%
%   The last input argument lets you crop the video, and it has two options:
%       - 'auto' : load mask from labview data for specified block and session (default)
%       - 'manual' : first make a rectangular crop around the mouse to reduce the amount 
%                    of image processing, and then draw a polygon around the body of the 
%                    mouse to filter out movements of background. The mask from the
%                    polygon selection overwrites the existing mousemask file in the 
%                    labview data.

if nargin < 3
    crop = 'auto';
end

% Find session and blockfolders, and the path to the videofile.
sessionFolder = getSessionFolder(sessionID);
labviewFolder = fullfile(sessionFolder, 'labview_data');

blockFolders = dir(fullfile(labviewFolder, '*Block*'));
blockFolder = blockFolders(block).name;

bodyviewVideo = dir(fullfile(labviewFolder, blockFolder, 'Body*'));
if isempty(bodyviewVideo)
    bodyviewVideo = dir(fullfile(labviewFolder, blockFolder, '*security*'));
end
 
% Read videofile

video = VideoReader(fullfile(labviewFolder, blockFolder, bodyviewVideo(1).name));
% frames = read(video);

k=0;

while hasFrame(video)
    frame = readFrame(video);
    if k == 0
        frames = zeros(size(frame, 1), size(frame, 2), 30000, 'uint8');
    end
    k=k+1;
    frames(:,:,k) = frame(:,:,1);
end

frames = frames(:,:,1:k);

% frames = squeeze(frames(:,:,1,:));
[imHeight, imWidth, nFrames] = size(frames);
%nFrames = size(frames, 3);


% Create a cropped version of the video around the mouse, and use a mask to
% remove all dynamic aspects in the video which is not due to mousemovement

switch crop                           % Should be loaded from labview data.
    case 'manual'

        disp('Select mouse region in image (double click to finish).')
        imshow(frames(:,:,1))
        h = impoly(gca);
        pcc = wait(h); % polygon crop coordinates
        rcc = uint16([ min(pcc)', max(pcc)' - min(pcc)' ]); % rectangle crop coordinates
        mask = poly2mask(pcc(:,1), pcc(:,2), imHeight, imWidth);
        close(gcf)

        %imwrite(uint8(mask), 'mouseMask.tif', 'Tiff')
        mask_filenm = [sessionID, '-block', num2str(block, '%03d'), '-mouse_roimask.bmp'];
        imwrite(uint8(mask*255), fullfile(labviewFolder, blockFolder, mask_filenm), 'TIFF')
                
    case 'auto'
        %rcc = [310.0000  240.0000  286.0000  189.0000];
        try
            maskFile = dir(fullfile(labviewFolder, blockFolder, '*mouse_roimask*'));
            mask = logical(imread(fullfile(labviewFolder, blockFolder, maskFile(1).name)));
            bcc = bwboundaries(mask); % bounding crop coordinates
            bcc = bcc{1};
            rcc = [ fliplr(min(bcc)), fliplr(max(bcc) - min(bcc)) ];
        catch
            error('Could not load mask for mouse position in image')
        end
end

for f = 1:nFrames
    frame = frames(:,:,f);
    frame(mask) = uint8(0);
    frames(:,:,f) = frame;
end
    
croppedFrames = frames(rcc(2)+(1:rcc(4)), rcc(1)+(1:rcc(3)) ,:);

% maskedFrames = frames;
% maskedFrames(~repmat(mask, 1, 1, nFrames)) = uint8(0);
% croppedFrames = maskedFrames(rcc(2)+(1:rcc(4)), rcc(1)+(1:rcc(3)) ,:);


% Apply median filter to get rid of noise
smoothedFrames = zeros(size(croppedFrames), 'uint8');

for f = 1:nFrames
    smoothedFrames(:, :, f) = uint8(medfilt2(croppedFrames(:, :, f)));
end

% Find the difference between successive frames
framesDiff = diff(smoothedFrames, 1, 3);
absoluteFrameDiff = squeeze(sum(sum(abs(framesDiff))));

% Normalize by change from median divided by median (delta S over S)
deltaSoverS = (absoluteFrameDiff - median(absoluteFrameDiff)) / median(absoluteFrameDiff);

struggleFactor = diff(deltaSoverS)';
struggleFactor = horzcat(0, struggleFactor, 0);

% Make timeVec
fps = 25;
timeVec = (0 : 1 : nFrames-1) / fps;


end


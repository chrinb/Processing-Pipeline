function [ imStack ] = rotateStack( imStack, angles, crop )
%RotateStack rotates images of a stack according to a vector of angles
%
% Length of angles must be the same as number of images in the image stack.
%     crop (bool): specify if images should be cropped after rotation

prevstr=[];

if nargin < 3
    crop = 1;
end

[nRows, nCols, nImages] = size(imStack);
nAngles = length(angles);

missing = (nImages - nAngles);
if missing < 0
    disp(['NB: ', num2str(abs(missing)), ' images are missing relative to labview data'])
elseif missing > 0
    disp(['NB: ', num2str(missing), ' stagepositions are missing relative to imaging data'])
end

nFrames = min(nAngles, nImages);


% Make empty array to hold rotated images if no crop is applied
if ~crop
    testIm = zeros(nRows, nCols);
    testIm = imrotate(testIm, 45);
    new_size = size(testIm);
    
    % Need this to work for boolean arrays as well
    switch class(imStack)
        case 'logical'
            newStack = zeros(new_size(1), new_size(2), nImages, 'uint8');
        otherwise
            newStack = zeros(new_size(1), new_size(2), nImages, 'like', imStack);
    end
end    


% Loop through images and rotate
for n = 1:nFrames
    
    angle = angles(n);
    
    if crop
        imStack(:, :, n) = imrotate(imStack(:, :, n), angle, 'bicubic', 'crop');
    else
        im = imrotate(imStack(:, :, n), angle, 'bicubic');
        tmp_size = size(im);
        shift = floor((new_size - tmp_size) ./ 2);
        
        newStack(shift(1) + (1 : tmp_size(1)), ...
           shift(2) + (1 : tmp_size(2)), n) = im; % put im in cntr...

    end
    
    if mod(n,100) == 0
        str=['rotating frame ' num2str(n) '/' num2str(nFrames)];
        refreshdisp(str, prevstr, n);
        prevstr=str;
    end
    
end

if ~crop
    imStack = newStack;
else
    imStack = imStack(:, :, 1:nFrames);
end
    
fprintf(char(8*ones(1,length(prevstr))));
fprintf('Rotated all images.');
fprintf('\n');


end


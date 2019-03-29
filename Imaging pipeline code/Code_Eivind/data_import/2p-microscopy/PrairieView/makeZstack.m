function [  ] = makeZstack( tSeriesPath, umStep, imPerCycle )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here



[parent, tseries, ~] = fileparts(tSeriesPath);
stackFolder = fullfile(parent, [tseries, '-stacked']);
if ~(exist(stackFolder, 'dir')==7)
   mkdir(stackFolder) 
end

if nargin < 2
    umStep = 4;
end

if nargin < 3
    imPerCycle = 30;
end

tiffFiles = dir(fullfile(tSeriesPath, '*.tif'));
nTiffs = length(tiffFiles);
cycle_cntr = 0;

% for i = 1:nTiffs
%     
%     im = imread(fullfile(tSeriesPath, tiffFiles(i).name));
%     im = uint8(im / 16);
%     
%     if mod(i-1, imPerCycle) == 0
%         cycle = tiffFiles(i).name(27:36);
%         stackname = strcat( cycle, '-stacked.tif' );
%         imwrite(im, fullfile(stackFolder, stackname), 'TIFF')
%         im_cntr = 0;
%         cycle_cntr = cycle_cntr + 1;
%     end
%     
%     im_cntr = im_cntr + 1;
%     
%     if cycle_cntr < 21 && im_cntr > 1 
%         imwrite(im, fullfile(stackFolder, stackname), 'TIFF', 'writemode', 'append');
%     elseif cycle_cntr >= 21
%         imwrite(im, fullfile(stackFolder, stackname), 'TIFF', 'writemode', 'append');
%     end
%     
%     if mod(i, imPerCycle) == 0
%         system(['python sima_wrappers/SIMALiteZstackPlane2D.py ' stackFolder ' ' stackname]);
%         alignedStack = strcat( cycle, '-pt2d.tif' );
%         stack = stack2mat(fullfile(stackFolder, alignedStack));
%         avg = mean(stack, 3);
%         imwrite(uint8(avg), fullfile(stackFolder, strcat(cycle, '-avg.tif')))
%     end
%     
% end

% Load average images:

avgIms = dir(fullfile(stackFolder, '*avg.tif'));
numAvgs = length(avgIms);

addpath('imreg_files')
imSizes = zeros(numAvgs, 2);

for i=1:numAvgs
    
    info = imfinfo(fullfile(stackFolder, avgIms(i).name));
    imSizes(i, :) = [info.Width, info.Height];
    
end

cropSize = min(min(imSizes));

for i = 1:numAvgs
    im = imread(fullfile(stackFolder, avgIms(i).name));
    im = CropImageCenter(im, cropSize);
    if i == 1
        imwrite(im, fullfile(stackFolder, 'zStack.tif'), 'TIFF', 'writemode', 'overwrite')
    else
        imwrite(im, fullfile(stackFolder, 'zStack.tif'), 'TIFF', 'writemode', 'append')
    end
end

Y = stack2mat(fullfile(stackFolder, 'zStack.tif'));
Y = double(Y);
options_rigid = NoRMCorreSetParms('d1',size(Y,1),'d2',size(Y,2), 'init_batch', 2, 'bin_width',2,'max_shift',30,'us_fac',50);
[M1, ~, ~] = normcorre(Y,options_rigid);
mat2stack(uint8(M1), fullfile(stackFolder, 'zStack_corr2.tif'));
options_rigid = NoRMCorreSetParms('d1',size(M1,1),'d2',size(M1,2), 'init_batch', 2, 'bin_width',2,'max_shift',30,'us_fac',50);
M1(isnan(M1)) = 0;
[M2, ~, ~] = normcorre(M1, options_rigid);
mat2stack(uint8(M2), fullfile(stackFolder, 'zStack_corr3.tif'));



% for i = 2:numAvgs
%     
%     ref = imread(fullfile(stackFolder, avgIms(i-1).name));
%     im = imread(fullfile(stackFolder, avgIms(i).name));
%         
%     ref = double(CropImageCenter(ref, cropSize));
%     im = double(CropImageCenter(im, cropSize));
%     
%     if i == 2
%         imwrite(uint8(ref), fullfile(stackFolder, 'zStack.tif'), 'TIFF')
%     end
% 
% 
%     [M1,shifts1,template1] = normcorre(Y,options_rigid)
%     % Get displacement
%     opt.s_thresh = 0.01;
%     [im, ~, ~, ~] = imreg_fft(ref, im, opt);
%     
%     imwrite(uint8(im),  fullfile(stackFolder, 'zStack.tif'), 'TIFF', ...
%             'writemode', 'append')
% end

end


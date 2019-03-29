% This script will load a raw file from SciScan, and then
%   1. stretch/compress images based on resonance mirror correction
%   2. rotate all the images based on a rotation speed
%   3. run movement correction

desktop = '/Users/eivinhen/Desktop/';
folder = '2017-05-23 SciScan Pollen Rotation Analysis/20170522_17_56_42_Rotating-Pollen';
filenm = '20170522_17_56_42_Rotating-Pollen_XYT.raw';

filepath = fullfile(desktop, folder, filenm);

imArray = loadRawFile( filepath, 1300 );
mat2stack(imArray, fullfile(desktop, 'test.tif'))

% Rotate images
imStack2 = imArray(:,:,29:1141);
degPerF = 9.6/30;

tiff_path = '/Users/eivinhen/Desktop/pollen_stack_rotated.tiff';
for i = 1:size(imStack2, 3)
    imStack2(:,:,i) = imrotate(imStack2(:,:,i), degPerF*i, 'bilinear', 'crop');
    if i == 1
        imwrite(imStack2(:,:,i), tiff_path, 'tiff', 'writemode', 'overwrite')
    else
        imwrite(imStack2(:,:,i), tiff_path, 'tiff', 'writemode', 'append')
    end
end

%Run rigid correction on images

reference = uint8(mean(imArray(:,:,1:28), 3));
[im_c, ~, ~, ~] = imreg_fft(double(imStack2), double(reference), opt);

mat2stack(uint8(im_c), '/Users/eivinhen/Desktop/pollen_stack_corr.tiff')



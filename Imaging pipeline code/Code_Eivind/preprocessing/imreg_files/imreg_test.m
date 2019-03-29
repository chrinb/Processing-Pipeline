%% Testing imreg

path = '/Users/eivinhen/Desktop/';
tiffstack = 'imreg_test.tif';

tiffPath = fullfile(path, 'imreg_test.tif');
tiffPathreg = fullfile(path, 'imreg_test_reg.tif');

imInfo = imfinfo(tiffPath);
nIms = numel(imInfo);


imSum = zeros(725);
%imStack = zeros(725, 725, numIms(1), 'uint8');

opt.pct_pad = (725^2-512^2) / 725^2;
opt.debug=1;
wrap_opt.debug=0;

tic
for nIm = 1:nIms

    % Open tiff file
    im = imread(tiffPath, 'Index', nIm, 'Info', imInfo);

    % Use imreg to register images.

    if nIm ~= 1
        if rotating(nIm) == 1
            %[im, dx, dy, E ] = imreg_fft(double(im), ref, opt);
            [im, dx, dy, dtheta, E ] = imreg_rigid(double(im), ref, opt);
            disp(['N: ' num2str(nIm), ', Error: ' num2str(E)])
            %corrections(nIm, :) = [dx, dy, dtheta];
        else
            [im, dx, dy, E ] = imreg_fft(double(im), ref, opt);
            disp(['N: ' num2str(nIm), ', Error: ' num2str(E)])
            %corrections(nIm, :) = [dx, dy, 0];
        end
    end


    imSum = imSum + double(im);
    ref = imSum / ( nIm );
    
    % Write image to stack
    if nIm==1
        imwrite(uint8(im), tiffPathreg, 'TIFF', 'writemode', 'overwrite')
    else
        imwrite(uint8(im), tiffPathreg, 'TIFF', 'writemode', 'append')
    end
    
end
toc

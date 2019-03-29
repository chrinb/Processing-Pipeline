function [ ] = mat2stack( mat, stackPath )
%mat2stack writes an uint8 array to a tiff-stack
%   mat2stack(A, filepath) saves 3D array as a tiff stack in specified path

[height, width, nFrames] = size(mat);

tiffFile = Tiff(stackPath,'w');

for f = 1:nFrames
    tiffFile.setTag('ImageLength', height);
    tiffFile.setTag('ImageWidth', width');
    tiffFile.setTag('Photometric',Tiff.Photometric.MinIsBlack);
    tiffFile.setTag('PlanarConfiguration',Tiff.PlanarConfiguration.Chunky);
    tiffFile.setTag('BitsPerSample', 8);
    tiffFile.setTag('SamplesPerPixel', 1);
    tiffFile.setTag('Compression',Tiff.Compression.None);
    tiffFile.write(mat(:, :, f));
    tiffFile.writeDirectory();
end

tiffFile.close();

% Old Version
% for i = 1:size(mat, 3)
%     if i == 1
%         imwrite(mat(:, :, i), stackPath, 'TIFF')
%     else
%         imwrite(mat(:, :, i), stackPath, 'TIFF', 'writemode', 'append')
%     end
% end

end


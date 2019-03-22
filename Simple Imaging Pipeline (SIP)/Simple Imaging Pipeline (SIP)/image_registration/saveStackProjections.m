function [ ] = saveStackProjections( imArray, sessionID, block, ch, part,plane_num )
%saveStackProjections Save average and maximum projection of a tiff stack
%   saveStackProjections(IMARRAY, sessionID, BLOCK, CH, PART) saves an average and a 
%   maximum projection of a stack as uint8 tif images
%
%   See also getDataPath

% Get paths where to save images
avgSavePath = getDataPath( 'AvgStackProjection', sessionID, block, ch, part,plane_num );
maxSavePath = getDataPath( 'MaxStackProjection', sessionID, block, ch, part,plane_num );

imwrite(uint8(mean(imArray, 3)), avgSavePath, 'TIFF')

% Despeckle before taking the max
for f = 1:size(imArray, 3)
         imArray(:, :, f) = medfilt2(imArray(:, :, f));
end

imwrite(uint8(max(imArray, [], 3)), maxSavePath, 'TIFF')

end
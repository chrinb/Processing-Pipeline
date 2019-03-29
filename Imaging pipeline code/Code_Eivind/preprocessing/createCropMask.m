function stackMask = createCropMask(arraySize, angles, translations_cor, rotations_cor)

% Create a boolean mask of ones with size of original image
nRows = arraySize(1); nCols = arraySize(2); nFrames = arraySize(3);
stackMask = zeros(nRows, nCols);
innerMask = ones(nRows - 6, nCols - 6);
stackMask(4:nRows-3, 4:nRows-3, :) = innerMask;
stackMask = repmat(stackMask, 1, 1, nFrames);

stackMask = rotateStack(stackMask, angles, 0);

stackMask = applyFrameCorrections(stackMask, rotations_cor, translations_cor, []);

stackMask = logical(stackMask);

end
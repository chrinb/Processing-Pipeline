function new_ref = createReferenceFromStationaryImages(imArray, rotating, old_ref)
% createRefImageFromStationaryFrames creates reference image without rotation artifacts.
%   NEW_REF = createReferenceFromStationaryImages(imArray, rotating, OLD_REF) creates a
%   new reference image based on non-rotating frames of a stack. OLD_REF is an optional
%   input which can be used as template for aligning the new reference image.
%
% old reference image is optional input
if nargin < 3
    old_ref = [];
end

[nRows, nCols, nFrames] = size(imArray);

% Make a reference stack with maximum 100 frames
nRigidFrames = sum(~rotating);
nRigidFrames = min([nRigidFrames, 100]);
newImArray = zeros(nRows, nCols, nRigidFrames);

% Add images to reference stack
c = 0;
for f = 1:nFrames
    if ~rotating(f)
        c = c+1;
        newImArray(:,:,c) = imArray(:,:,f);
        if c == nRigidFrames
            break
        end
    end
end

[newImArray, ~] = stackregRigid(newImArray, [], 'NormCorre', old_ref);
new_ref = mean(newImArray, 3);

end
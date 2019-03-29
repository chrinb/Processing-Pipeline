function new_ref = createUncroppedReferenceImage(imArray, stackMask, old_ref)
% createUncroppedReferenceImage creates reference image without rotation artifacts.
%   NEW_REF = createUncroppedReferenceImage(imArray, orig_size, angles, shifts, rot_offsets, OLD_REF) creates a
%   new reference image based on non-rotating frames of a stack. OLD_REF is an optional
%   input which can be used as template for aligning the new reference image.

% Old reference image is optional input
if nargin < 3
    old_ref = [];
end

% Convert imArray to double to be able to set values to nan.
b = double(imArray);
b(~stackMask) = nan;

% Find the nanmean of the stack
if isempty(old_ref) 
    new_ref = nanmean(b, 3);
else
    new_ref = nanmean(cat(3, b, old_ref), 3);
end

clearvars b

end
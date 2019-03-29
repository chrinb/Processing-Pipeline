function angles = correctAngleDelay(imArray, angles, rotating)
%autodetect angle delay

%Slice array to get one reference and one test stack

% Find transitions:
transitions = diff(rotating);
transition_idc = find(abs(transitions)==1) + 1;

ref_stack = imArray(:,:,1:transition_idc(1));
rot_stack = imArray(:,:,transition_idc(1):transition_idc(2));
tmp_angles = angles(transition_idc(1):transition_idc(2));

% Despeckle
for f = 1:size(ref_stack, 3)
    ref_stack(:,:,f) = medfilt2(ref_stack(:,:,f));
end

ref_im = double(max(ref_stack, [], 3));

% Despeckle
for f = 1:size(rot_stack, 3)
    rot_stack(:,:,f) = medfilt2(rot_stack(:,:,f));
end

nFrames = size(rot_stack, 3);
correlations = zeros(6,1);

for i = 0:5
    angle_delay = i;
    tmp_rot_stack = rot_stack;

    % Loop through images and rotate
    for n = 1:nFrames
        if n > nFrames - angle_delay
            angle = tmp_angles(n);
        else
            angle = tmp_angles(n + angle_delay);
        end
        
        tmp_rot_stack(:, :, n) = imrotate(tmp_rot_stack(:, :, n), angle, 'bicubic', 'crop');
    end
    
    rot_im = double(max(tmp_rot_stack, [], 3));
    correlations(i+1) = corr_err(ref_im, rot_im);
    
end

[~, best_idx] = max(correlations);
disp(best_idx - 1)

% Shifting angles. NB: Moving angles from beginning to end. Does not work
% if session starts or stops during rotation.
angles = vertcat(angles(best_idx:end), angles(1:best_idx));

% This is the error function based on normalized cross-correlation for 2 images

function e = corr_err(im1,im2)
	im1l = reshape(im1,1,[]);
	im2l = reshape(im2,1,[]);
	im1l = im1l/max(im1l);
	im2l = im2l/max(im2l);
	inval = unique([find(im2l==0) find(im1l == 0)]); % imrotate'd images have 0 in unassigned squares; ignore these
	val = setdiff(1:length(im1l), inval);
	R = corrcoef(im1l(val),im2l(val));
	e = R(1,2);



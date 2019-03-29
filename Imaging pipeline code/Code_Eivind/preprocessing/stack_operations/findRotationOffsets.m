function [dtheta_r] = findRotationOffsets(im_s, im_t)
%findRotationOffsets Correlation based search for optimal rotation correction

% Simplified version of imreg_rigid, only looking for correction of rotation.

sim = size(im_s);
if (length(sim) == 3) 
  nframes = sim(3);
else 
  nframes = 1;
end

% Normalize target image to median value. Omit padded zeros
im_t_vec = sort(reshape(im_t, 1, []));
nim_t = im_t / median(im_t_vec);
%nim_t = im_t/median(reshape(im_t,1,[])); % normalize to median

% Initialize vectors for storing results
dtheta_r = zeros(1, nframes);

for f = 1:nframes
    % 0) prenormalize to median
    % Normalize target image to median value. Omit padded zeros
    im_s_vec = sort(reshape(im_s(:,:,f), 1, []));
    nim_s = im_s(:,:,f) / median(im_s_vec); 
    %nim_s = im_s(:,:,f)/median(reshape(im_s(:,:,f),1,[])); % normalize to median
    
    % iterate through angles
    drtheta = 10; % initial angular range - no more than 45!
    n_pts = 11; % how many points to test per iteration? odd keeps 0 (angular stepsize)
    n_iter = 2;
    rot_theta = 0;

    for n = 1:n_iter
        % seeding
        dtheta = (rot_theta-(drtheta/2)):(drtheta/(n_pts-1)):(rot_theta+(drtheta/2));
        err = zeros(n_pts, 1);
        
        % rotation loop
        for t = 1:length(dtheta)
            imr = imrotate(nim_s, dtheta(t), 'bilinear', 'crop');
            if dtheta(t) == 0
                imr = imrotate(nim_s, 1, 'bilinear', 'crop');
                imr = imrotate(imr, -1, 'bilinear', 'crop');
            end
            
            err(t) = corr_err(nim_t, imr); 
        end
        [best_corr, best_idx] = max(err);
        %plot(dtheta, err)

        % new rot_theta
        rot_theta = dtheta(best_idx);
        drtheta = 2*(drtheta/(n_pts-1));
        
    end

    % assign final variables
    dtheta_r(f) = dtheta(best_idx);
	
end
end

%
% This is the error function based on normalized cross-correlation for 2 images
%   NO normalization -- you should do this beforehand
%
function e = corr_err(im1,im2)
	im1l = reshape(im1,1,[]);
	im2l = reshape(im2,1,[]);
%	im1l = im1l/max(im1l);
%	im2l = im2l/max(im2l);
	inval = unique([find(im2l==0) find(im1l == 0)]); % imrotate'd images have 0 in unassigned squares; ignore these
	val = setdiff(1:length(im1l), inval);
	R = corrcoef(im1l(val),im2l(val));
	e = R(1,2);
end



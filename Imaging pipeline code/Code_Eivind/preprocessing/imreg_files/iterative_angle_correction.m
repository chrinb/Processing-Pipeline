% Used for rigid registration of images - EH 
%
% [im_c dx_r dy_r E] = imreg_rigid(im_s, im_t, options)
%
% Given two images, finds optimal x/y offset by computing the dx/dy via
% fft, then a simple iterative convergence to otpimal dx/dy/dtheta.
%
% Returns the corrected image -- im_s is source image, im_t is target image
% (i.e., shifts source so it fits with target). Also returns displacement 
% in x (dx_r) and y (dy_r) that needs to be applied to source image to 
% match target.  dx_r > 0 and dy_r > 0 imply right and down movement, resp.
% E is the error for each frame.  Also returns rotated angle.
%
% Note that im_s can be a stack; in this case, so will im_c.
%
% options - structure containing parameters ; use structure to allow you to
%    vary the options without many function variables.
%       debug: set to 1 to get messages out the wazoo (default = 0)
%       wb_on: set to 1 to have a waitbar (default = 0)
%       pct_pad: percent of padding if the source/target images are padded.


function [im_s, dtheta_r] = iterative_angle_correction(im_s, im_t, rotating, pass, opt)


% Default options
defopt.debug = 0;
defopt.wb_on = 0;
defopt.pct_pad = 0;


% Set options to default values if they are not given.
if nargin < 5 || isempty(opt); opt = defopt; end

if ~isfield(opt, 'debug'); opt.debug = defopt.debug; end
if ~isfield(opt, 'wb_on'); opt.wb_on = defopt.wb_on; end
if ~isfield(opt, 'pct_pad'); opt.pct_pad = defopt.pct_pad; end

% options to variable
wb_on = opt.wb_on;
pct_pad = opt.pct_pad;

sim = size(im_s);
if (length(sim) == 3) 
  nframes = sim(3);
else 
  nframes = 1;
end

% Normalize target image to median value. Omit padded zeros
im_t_vec = sort(reshape(im_t, 1, []));
n_pixels = length(im_t_vec);
nim_t = im_t / median(im_t_vec(round(n_pixels*pct_pad)+1:end)); 
%nim_t = im_t/median(reshape(im_t,1,[])); % normalize to median

nim_t = double(nim_t);
im_s = double(im_s);

% --- main loop -- do this frame-by-frame
fft_opt.wb_on = 0;
if (wb_on) ; wb = waitbar(0, 'Processing rigid registration...'); end


dtheta_r = zeros(nframes, 1);

for f = 1:nframes
    
    if rotating(f) == 1
    
        % 0) prenormalize to median
        % Normalize target image to median value. Omit padded zeros
        im_s_vec = sort(reshape(im_s(:,:, f), 1, []));
        n_pixels = length(im_s_vec);
        nim_s = im_s(:,:,f) / median(im_s_vec(round(n_pixels*pct_pad)+1:end)); 
        %nim_s = im_s(:,:,f)/median(reshape(im_s(:,:,f),1,[])); % normalize to median

        % iterate through
        drtheta = 6; % initial angular range - no more than 45!
        n_pts = 7; % how many points to test per iteration? odd keeps 0 (angular stepsize)
        rot_theta = 0;

        for it = 1:2
            % seeding
            dtheta = (rot_theta-(drtheta/2)):(drtheta/(n_pts-1)):(rot_theta+(drtheta/2));
            err = zeros(n_pts, 1);

            if (opt.debug == 1) ; 
                disp(['Iterating with theta change of ' ...
                      num2str(drtheta/(n_pts-1)) ' center ' ...
                      num2str(rot_theta)]); 
            end

            % rotation loop
            for t = 1:length(dtheta)
                imr = imrotate(nim_s, dtheta(t), 'bilinear', 'crop');
                if dtheta(t) == 0
                    imr = imrotate(nim_s, 1, 'bilinear', 'crop');
                    imr = imrotate(imr, -1, 'bilinear', 'crop');
                end
                err(t) = corr_err(nim_t, imr); 
            end
            [~, best_idx] = max(err); 

            dtheta_r(f) = dtheta_r(f) + dtheta(best_idx);
            im_s(:,:,f) = imrotate(im_s(:,:,f), dtheta(best_idx), 'bicubic','crop');
            if (opt.debug == 1) ; disp(['Optimal dtheta: ' num2str(dtheta_r(f)) ]); end
            
            %update drtheta
            drtheta = 2*(drtheta/(n_pts-1));

        end
            
            
%         if mod(f, 100) == 0
%             im_t = mean(im_s(:,:,1:f), 3);
%             im_t_vec = sort(reshape(im_t, 1, []));
%             n_pixels = length(im_t_vec);
%             nim_t = im_t / median(im_t_vec(round(n_pixels*pct_pad)+1:end));
%             nim_t = imrotate(nim_t, 1, 'bilinear', 'crop');
%             nim_t = imrotate(nim_t, -1, 'bilinear', 'crop');
%         end

        
    end
    
    
    if (wb_on) ; waitbar(f/nframes,wb); end
	
end

if (wb_on) ; delete(wb); end

	

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


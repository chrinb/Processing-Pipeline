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


function [im_c, dx_r, dy_r, dtheta_r, E] = imreg_rigid(im_s, im_t, opt)


% Default options
defopt.debug = 0;
defopt.wb_on = 0;
defopt.pct_pad = 0;


% Set options to default values if they are not given.
if nargin < 3 || isempty(opt); opt = defopt; end

if ~isfield(opt, 'debug'); opt.debug = defopt.debug; end
if ~isfield(opt, 'wb_on'); opt.wb_on = defopt.wb_on; end
if ~isfield(opt, 'pct_pad'); opt.pct_pad = defopt.pct_pad; end


% options to variable
wb_on = opt.wb_on;
pct_pad = opt.pct_pad;
  

E = [];

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

% Initialize vectors for storing results
dx_r = zeros(1, nframes);
dy_r = zeros(1, nframes);
dtheta_r = zeros(1, nframes);

% --- main loop -- do this frame-by-frame
fft_opt.wb_on = 0;
if (wb_on) ; wb = waitbar(0, 'Processing rigid registration...'); end

for f = 1:nframes
    % 0) prenormalize to median
    % Normalize target image to median value. Omit padded zeros
    im_s_vec = sort(reshape(im_s(:,:,f), 1, []));
    n_pixels = length(im_s_vec);
    nim_s = im_s(:,:,f) / median(im_s_vec(round(n_pixels*pct_pad)+1:end)); 
    %nim_s = im_s(:,:,f)/median(reshape(im_s(:,:,f),1,[])); % normalize to median
    
    % determine, apply (initial) translation
    [nim_c, dx_f, dy_f, E] = imreg_fft(nim_s, nim_t, fft_opt);

    % iterate through - always imreg_fft, then rotate
    drtheta = 10; % initial angular range - no more than 45!
    n_pts = 11; % how many points to test per iteration? odd keeps 0 (angular stepsize)
    n_iter = 2;
    rot_theta = 0;

    for n=1:n_iter
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
            imr = imrotate(nim_c, dtheta(t), 'bilinear', 'crop');
            if dtheta(t) == 0
                imr = imrotate(nim_c, 1, 'bilinear', 'crop');
                imr = imrotate(imr, -1, 'bilinear', 'crop');
            end
            
            err(t) = corr_err(nim_t, imr); 
        end
        [best_corr, best_idx] = max(err); 
        %plot(dtheta, err)

        % new rot_theta
        rot_theta = dtheta(best_idx);
        drtheta = 2*(drtheta/(n_pts-1));

        % determine, apply (secondary) translation
        [tim_s, irr] = imreg_wrapup(nim_s, nim_t, dx_f, dy_f, rot_theta, [], [], []);
        [im_irr, dx_f2, dy_f2, E2] = imreg_fft(tim_s, nim_t, fft_opt);
        
        % convert the new [dx dy] translation vector from rotated 
        % coordinates to normal coordinates and add to dx, dy
        th = rot_theta*pi/180;
        R = [cos(th) -sin(th) ; sin(th) cos(th)];
        D = R*[dx_f2 ; dy_f2];
        dx_f = dx_f + round(D(1));
        dy_f = dy_f + round(D(2));
        
        % apply to produce novel nim_c
        [nim_c irr] = imreg_wrapup(nim_s, nim_t, dx_f, dy_f, 0, [], [], []);
    end

    % assign final variables
    dx_r(f) = dx_f;
    dy_r(f) = dy_f;
    dtheta_r(f) = dtheta(best_idx);
    
    if (opt.debug == 1) ; disp(['Optimal dtheta: ' num2str(dtheta_r(f)) ' dx: ' num2str(dx_f) ' dy: ' num2str(dy_f)]); end
    
    if (wb_on) ; waitbar(f/nframes,wb); end
	
end

if (wb_on) ; delete(wb); end

	
% --- send to imreg_wrapup
	
wrap_opt.err_meth = 3; % correlation based
if (opt.debug == 1); 	wrap_opt.debug = 1; end
  
[im_c, E] = imreg_wrapup(im_s, im_t, dx_r', dy_r', dtheta_r', [], [], wrap_opt);


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
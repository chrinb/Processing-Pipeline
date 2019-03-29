% Used for rigid registration of images - EH 
%
% [im_c dx_r dy_r E] = imreg_fft(im_s, im_t, opt)
%
% Given two images, finds optimal x/y offset by computing the FFT;
%  returns the corrected image -- im_s is source image, im_t is 
%  target image (i.e., shifts source so it fits with target). Also returns
%  displacement in x (dx_r) and y (dy_r) that needs to be applied to source image
%  to match target.  dx_r > 0 and dy_r > 0 imply right and down movement, resp.
%  E is the error for each frame.
%
% Note that im_s can be a stack; in this case, so will im_c.
%
% opt - structure containing parameters ; use structure to allow you to
%       vary the options without many function variables.
%       opt.g_r - radius of gaussian for initial convolution -- MUST BE ODD
%       opt.t_thresh - [0,1] ; threshold of target image at which you cutoff;
%                      thresholding is done because when you do fft, you do it
%                      on a zero-padded version of the input image, and if
%                      you don't remove points below threshold by zeroing them,
%                      you simply align the image areas and not features, giving
%                      dx_r/dy_r of 0
%       opt.s_thresh - as with t_thresh, but for source image
%       opt.wb_on - if set to 0, no wb


function [im_c, dx_r, dy_r, E] = imreg_fft(im_s, im_t, opt)
	

    % Turn off warning from imreg
    wId = 'MATLAB:colon:nonIntegerIndex';
    warning('off', wId) 
    
    
    E = [];
  

	% Default options
	defopt.g_r = 5;         % MUST BE ODD % gauss radius for smoothing of image?
	defopt.s_thresh = 0.01; % threshold for prefilter src img, 0<v<1 ; see below
	defopt.t_thresh = 0.01; % threshold for prefilter target img, 0<v<1 ; see below
    defopt.wb_on = 0;       % waitbar
    
    % Set options and use default values if no values are provided.
    if nargin < 3 || isempty(opt); opt = defopt; end
    
	if ~isfield(opt, 'g_r'); opt.g_r = defopt.g_r; end; g_r = opt.g_r;
    if ~isfield(opt,'s_thresh'); opt.s_thresh = defopt.s_thresh; end; s_thresh = opt.s_thresh;
    if ~isfield(opt,'t_thresh'); opt.t_thresh = defopt.t_thresh; end; t_thresh = opt.t_thresh;
    if ~isfield(opt,'wb_on');  opt.wb_on =  defopt.wb_on; end; wb_on = opt.wb_on;
	
    if (mod(g_r,2) ~= 0) ; g_r = g_r+1; end

    
    % 0) setup
	im_c = zeros(size(im_s)); % corrected image
	S = size(im_s);
	if (length(S) == 3) ; F = S(3) ; else F = 1; end

	% 1) pre-smooth input image with gaussian
	gauss = customgauss([(2*g_r)+1 (2*g_r)+1], 1.5 , 1.5, 0, 0, 1, [1 1]*(g_r+1));

  % 2) select a threshold - and set other pix to 0 ; otherwise, you will simply register the
	%    image-on-black-background (due to padding - below) to itself, yielding ~0,0 deltas
	Mt = max(max(im_t));
	Ms = max(max(max(im_s)));
	im_t (find(im_t < t_thresh*Mt)) = 0;

	% 3) run algo
	if (wb_on) ; wb = waitbar(0, 'FFT Processing ...'); end
	for f=1:F
		% gaussian convolve, resize
		im_sc = conv2(im_s(:,:,f),gauss); % Why not use inbuilt?
		im_sc = im_sc(g_r+1:S(1)+g_r, g_r+1:S(2)+g_r); 
		im_sc(find(im_sc < s_thresh*Ms)) = 0;

		% compute fft 2d - use padded matrices
        fim_s = zeros(S(1)*2,S(2)*2);
        fim_s((1/4)*2*S(1):(3/4)*2*S(1)-1,(1/4)*2*S(2):(3/4)*2*S(2)-1) = im_sc;
        fim_t = zeros(S(1)*2,S(2)*2);
        fim_t((1/4)*2*S(1):(3/4)*2*S(1)-1,(1/4)*2*S(2):(3/4)*2*S(2)-1) = im_t;
		R = real(ifft2(fft2(rot90(rot90(fim_s))).*fft2(fim_t)));

		[irr idx] = max(reshape(R,4*S(1)*S(2),1)); %Make a long col vector

		% derive the x, y displacements
		dx = floor(idx/(2*S(1)));
		dy = round(((idx/(2*S(1)))-dx) * 2*S(1));
    if (dx > S(2)) ; dx = -1*(2*S(2) - dx); end
    if (dy > S(1)) ; dy = -1*(2*S(1) - dy); end
	   
		dx_r(f) = dx;
		dy_r(f) = dy;

	  if (wb_on) ; if mod(f, 50) == 0; waitbar(f/F,wb); end; end
      
	end
	if (wb_on) ; delete(wb); end
  
	% send to imreg_wrapup
	wrap_opt.err_meth = 3; % correlation based
	wrap_opt.debug = 0;
	dx_r = dx_r'; % transpose to make right (size(dx,1) should be nframes)
	dy_r = dy_r';
  [im_c E] = imreg_wrapup (im_s, im_t, dx_r, dy_r, [], [], [], wrap_opt);


%
% This function computes the error for all frames specified
%  err_meth: 1: raw difference (L1) ; 2: diff only where > 0 
%            3: median-normalized correlation
%  im_c, im_t: corrected and target images, respectively
%  frames: frames to compute for (indices)
%
function	E = imreg_wrapup_calculate_error(err_meth, im_c, im_t, frames);
  E = zeros(length(frames),1);
	for f=frames
    if (err_meth == 1) % raw diff
			E(f) = sum(sum(im_t - im_c(:,:,f)));
    elseif (err_meth == 2) % diff where > 0
			imsl = double(reshape(im_t,1,[]));
			imcl = double(reshape(im_c(:,:,f),1,[]));
			val = find(imcl ~= -1);
			E(f) = sum(abs(imcl(val)-imtl(val)));
    elseif (err_meth == 3) % correlation normalized to MEDIAN
			imsl = double(reshape(im_t,1,[]));
			imcl = double(reshape(im_c(:,:,f),1,[]));
			val = find(imcl ~= -1);
			imsl = imsl(val)/median(imsl(val));
            imsl(val)
			imcl = imcl(val)/median(imcl(val));
      R = corrcoef(imsl,imcl);
			E(f) = R(1,2);
	  end
	end



function [imArrayOut, ref, shifts, options_nonrigid] = nonrigid(imArrayIn, ref)

[sz1, sz2, ~] = size(imArrayIn);
options_nonrigid = NoRMCorreSetParms('d1', sz1, 'd2', sz2,...
                   'grid_size', [64, 64], 'mot_uf', 4, 'bin_width', 50,...
                   'max_shift', 40, 'max_dev', 15, 'us_fac', 50, ...
                   'correct_bidir', 0, 'upd_template', true, ...
                   'boundary', 'NaN', 'print_msg', 0, 'iter', 1, ...
                   'shifts_method', 'fft');

if nargin < 2; ref = []; end
               
if size(imArrayIn, 3) == 1
    [imArrayOut, shifts, ref] = normcorre(single(imArrayIn), options_nonrigid, single(ref));
else
    try
        [imArrayOut, shifts, ref] = normcorre_batch_even(single(imArrayIn), options_nonrigid, single(ref));
    catch
        [imArrayOut, shifts, ref] = normcorre_batch(single(imArrayIn), options_nonrigid, single(ref));
    end
end

imArrayOut = cast(imArrayOut, 'like', imArrayIn);

if nargout == 2
    clear shifts options_nonrigid
elseif nargout == 1
    clear ref shifts options_nonrigid
end

end
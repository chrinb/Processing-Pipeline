function [imArray, shifts] = stackregRigid(imArray, rotating, method, ref)
%stackregRigid runs rigid image registration on a stack.
%   Use imregFFT.
%   Todo, add possibility of using normcorre, with rotation correction.
%   Add SIMA?

% Return corrected stack and shifts used to correct stack.

% Reference image is optional input.

% Written by EH.

if nargin < 4
    ref = [];
end


% Used for printing status to commandline
prevstr=[];

% Set imregFFT to default 
if nargin < 3
    method = 'imregFFT';
end

nFrames = size(imArray, 3);
shifts = zeros(nFrames, 3);

switch method
    
    case 'imregFFT'

        % Create reference image without rotation artifacts
        opt.wb_on = 0;
        
        ref_stack = zeros(size(imArray, 1), size(imArray, 2), 100);
        counter = 0;
        for i = 1:size(imArray, 3)
            if rotating(i) == 1
                continue
            else
                counter = counter + 1;
                ref_stack(:,:,counter) = imArray(:,:,i);
                if counter == 100
                    break
                end
            end
        end
        %mat2stack(uint8(ref_stack), '/Users/eivinhen/Desktop/ref_stack.tif')
        ref = mean(ref_stack, 3);
        [ref_stack, ~, ~, ~] = imreg_fft(double(ref_stack), ref, opt);
        
        ref = mean(ref_stack, 3);

        % Reminder of what happens when things are not thought through
        % ref = mean(imArray(:,:,1:100), 3);
        

        % Loop through and correct frames
        for n = 1:nFrames
            rot = rotating(n);
            im = imArray(:,:,n);

            if rot == 1
                [im, dx, dy, dtheta, ~ ] = imreg_rigid(double(im), ref, opt);
                shifts(n, :) = [dx, dy, dtheta];
            else
                [im, dx, dy, ~] = imreg_fft(double(im), ref, opt);
                shifts(n, :) = [dx, dy, 0];
            end
            imArray(:,:,n) = im;

            if mod(n, 50) == 0
                str=['registering frame ' num2str(n) '/' num2str(nFrames)];
                refreshdisp(str, prevstr, n);
                prevstr=str;
            end

        end

        fprintf(char(8*ones(1,length(prevstr))));
        fprintf('Registered all images.');
        fprintf('\n');
        imArray = uint8(imArray);
        
    case 'NormCorre'
        
        Y = double(imArray);
        options_rigid = NoRMCorreSetParms('d1', size(Y,1), 'd2', size(Y,2), ...
                                          'bin_width', 50, 'max_shift', 20, ...
                                          'us_fac', 50, 'correct_bidir', 0);
        if isempty(ref)
            [imArray, nc_shifts, ~] = normcorre(Y, options_rigid);
        else
            [imArray, nc_shifts, ~] = normcorre(Y, options_rigid, ref);
        end
        
        shifts(:, 1) = round(arrayfun(@(row) row.shifts(2), nc_shifts));
        shifts(:, 2) = round(arrayfun(@(row) row.shifts(1), nc_shifts));
        
        
    case 'Custom'
%         im_t = mean(imArray(:,:,1:100), 3);
%         
%         opt.wb_on = 0;
%         [imArray, dtheta_r] = iterative_angle_correction(imArray, im_t, rotating, 1, opt);
%         
%         shifts(:, 3) =  dtheta_r;
%         mat2stack(uint8(imArray), '/Users/eivinhen/Desktop/angle_corr.tiff')
        
        Y = double(imArray);
        options_rigid = NoRMCorreSetParms('d1', size(Y,1), 'd2', size(Y,2), ...
                                          'bin_width', 50, 'max_shift', 15, 'us_fac', 50);
        [imArray, nc_shifts, ~] = normcorre(Y, options_rigid);
        
        imArray(isnan(imArray)) = 0;
        
        shifts(:, 1) = round(arrayfun(@(row) row.shifts(2), nc_shifts));
        shifts(:, 2) = round(arrayfun(@(row) row.shifts(1), nc_shifts));
        
        %mat2stack(uint8(imArray), '/Users/eivinhen/Desktop/normcorre.tiff')
        

end

end


function [tmp_imArray, corrections] = stackregPiecewise(tmp_imArray, tmp_rotating)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%todo: ref image for nonrigid should cover outside edges.


% Pre-assign array for storing corrections
[height, width, nFrames] = size(tmp_imArray);
corrections = zeros(nFrames, 1);

% Create stack for reference image without rotation artifacts
ref_stack = zeros(height, width, 100);
counter = 0;
for i = 1:nFrames
    if tmp_rotating(i) == 1
        continue
    else
        counter = counter + 1;
        ref_stack(:, :, counter) = tmp_imArray(:,:,i);
        if counter == 100
            break
        end
    end
end

%mat2stack(uint8(ref_stack), '/Users/eivinhen/Desktop/ref_stack.tif')

% Align reference stack and create reference image.
opt.wb_on = 0;
ref = mean(ref_stack, 3);
[ref_stack, ~, ~, ~] = imreg_fft(double(ref_stack), ref, opt);
ref = mean(ref_stack, 3); % Already double

% Find Transitions between rotation and stationary periods.
transitions = zeros(size(tmp_rotating));
transitions(2:end) = diff(tmp_rotating);

% Find indices where trial starts and stop (a.k.a transitions)
if tmp_rotating(1) == 1
    stationaryStartIdx = find(transitions == -1);
    rotationStartIdx = vertcat(1, find(transitions == 1));
else 
    stationaryStartIdx = vertcat(1, find(transitions == -1));
    rotationStartIdx = find(transitions == 1);
end

startIdc = sort(vertcat(stationaryStartIdx, rotationStartIdx));

% Used for printing status to commandline
prevstr=[];

% Loop through different pieces of array.
for i = 1:numel(startIdc)
        
    % Find start and stop indices for current "piece"
    start = startIdc(i);
    if i == numel(startIdc)
        stop = length(tmp_rotating);
    else 
        stop = startIdc(i+1) - 1;
    end
    
    % Display message
    str = ['registering frame ' num2str(start) '-' num2str(stop)];
    refreshdisp(str, prevstr, i);
    prevstr=str;
    %fprintf('\n');

    % Determine if current piece is rotating or not
    if i == 1
        rot = tmp_rotating(1);
    else
        rot = ~rot;
    end
    
    % Extract the images of the current "piece"
    imArray_piece = tmp_imArray(:, :, start:stop);
    
    if rot
        % Do rigid rotation correction before nonrigid correction.
        
        % Create small versions of stack and reference. 150x150
        imArray_small_piece = double(imArray_piece((-150:150)+round(height/2), (-150:150)+round(width/2), :));
        small_ref = ref((-150:150)+round(height/2), (-150:150)+round(width/2));
        rotation_offsets = findRotationOffsets(imArray_small_piece, small_ref);
        
        %[imArray_piece, dx, dy, dtheta, ~ ] = imreg_rigid(double(imArray_piece), ref, opt);

        corrections(start:stop, 1) = rotation_offsets;
        imArray_piece = applyFrameCorrections(imArray_piece, rotation_offsets, [], []);
        
%         % Run nonrigid correction
%         Y1 = double(imArray_piece);
%         options_nonrigid = NoRMCorreSetParms('d1',size(Y1,1),'d2',size(Y1,2),...
%                            'grid_size',[128, 128],'mot_uf',4,'bin_width',size(Y1,3),...
%                            'max_shift', 5, 'max_dev',10, 'us_fac',10, ...
%                            'correct_bidir', 0, 'upd_template', false);
%         [imArray_piece, ~, ~] = normcorre_batch(Y1, options_nonrigid, ref);
%         clearvars Y1
        
    else
%         % Run nonrigid correction
%         Y1 = double(imArray_piece);
%         options_nonrigid = NoRMCorreSetParms('d1', size(Y1,1), 'd2', size(Y1,2),...
%                            'grid_size', [128, 128], 'mot_uf', 4, 'bin_width', size(Y1,3),...
%                            'max_shift', 20, 'max_dev', 20, 'us_fac', 50, ...
%                            'correct_bidir', 0, 'upd_template', false);
%         [imArray_piece, ~, ~] = normcorre_batch(Y1, options_nonrigid, ref);
%         % Add shifts to corrections
%         clearvars Y1
    end
    
    tmp_imArray(:,:, start:stop) = imArray_piece;
    
    % Create new reference image.
    if ~rot
       nFrames_piece = size(imArray_piece, 3);
       if nFrames_piece > 100
           ref_stack(:, :, :) = imArray_piece(:, :, end-99:end);
       else
           nFrames_keep = 100 - nFrames_piece;
           ref_stack(:, :, 1:nFrames_keep) = ref_stack(:, :, end-(nFrames_keep-1):end);
           ref_stack(:, :, nFrames_keep+1:end) = imArray_piece;
       end
       ref = mean(ref_stack, 3);
    end


end

fprintf(char(8*ones(1,length(prevstr))));
fprintf('Registered all images.');
fprintf('\n');

end


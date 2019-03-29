function [imArray, ref] = normcorreRotation(imArray, maskArray, angles, rotating, ref)
% normcorreRotation(imArray, maskArray, angles, rotating, ref)
%
% Perform nonrigid registration on a stack that is rotating. Because images that are
% rotated gets cropped lines, this function implements a "workaround" by rotating images 
% back to their original position before aligning them

if isempty(ref)
	ref = createUncroppedReferenceImage(imArray, maskArray, ref);
end

% Find indices where trial starts and stop (e.g transitions)
if rotating(1) == 1
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
        
    if rot
        
        for f = start:stop
            
            % Extract angle as f th element after start of substack
            angle = angles(f);
            
            im = imArray(:, :, f);
            mask = maskArray(:, :, f);
            
            im = imrotate(im, -angle, 'bicubic', 'crop');
            mask = imrotate(mask, -angle, 'bicubic', 'crop');
            ref = imrotate(ref, -angle, 'bicubic', 'crop');
            
            % Find indices for where to crop image.
            col_transitions = diff(mask, 1, 1);
            row_transitions = diff(mask, 1, 2);

            colStart = find(col_transitions == 1);
            colStart = max(colStart);
            colEnd = find(col_transitions == -1);
            colEnd = min(colEnd);
            rowStart = find(row_transitions == 1);
            rowStart = max(rowStart);
            rowEnd = find(row_transitions == -1);
            rowEnd = min(rowEnd);

            cropped_im = im(rowStart:rowEnd, colStart:colEnd);
            cropped_ref = ref(rowStart:rowEnd, colStart:colEnd);

            cropped_im = double(cropped_im);
            
            options_nonrigid = NoRMCorreSetParms('d1',size(cropped_im,1), ...
                                                 'd2',size(cropped_im,2), ...
                                                 'grid_size',[128, 128], ...
                                                 'mot_uf',4,'bin_width',43,...
                                                 'max_shift', 5, 'max_dev',10, 'us_fac',10, ...
                                                 'correct_bidir', 0, 'upd_template', false);
            [reg_im, ~, ~] = normcorre_batch(cropped_im, options_nonrigid, cropped_ref);

            im(rowStart:rowEnd, colStart:colEnd) = reg_im;
            im = imrotate(im, angle, 'bicubic', 'crop');
            
            imArray(:,:,f) = im;
        end
        
        
    else                    % extract chunk and run rigid. 

        % Extract the images of the current "piece"
        imArray_piece = imArray(:, :, start:stop);
        
        % Run nonrigid correction
        Y1 = double(imArray_piece);
        options_nonrigid = NoRMCorreSetParms('d1', size(Y1,1), 'd2', size(Y1,2),...
                           'grid_size', [128, 128], 'mot_uf', 4, 'bin_width', size(Y1,3),...
                           'max_shift', 20, 'max_dev', 20, 'us_fac', 50, ...
                           'correct_bidir', 0, 'upd_template', false);
        [imArray_piece, ~, ~] = normcorre_batch(Y1, options_nonrigid, ref);
        clearvars Y1
        imArray(:, :, start:stop) = imArray_piece;
    end
    
    % Update reference. Do a nanmean with ref and newly registered images...
    nFramesRef = min([100, (stop-start+1)]);
    tmp_refArray = imArray(end-nFramesRef+1:end);
    tmp_maskArray = maskArray(end-nFramesRef+1:end);
    ref = createUncroppedReferenceImage(tmp_refArray, tmp_maskArray, ref);
    
end
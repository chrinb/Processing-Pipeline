function imArray = applyFrameCorrections(imArray, angles, corrections, stack_corrections)
% applyFrameCorrections applies vector of frame corrections to imArray
%   imArray = applyFrameCorrections(imArray, angles, corrections, stack_corrections)
% 
%   Inputs:
%       imArray - array of images
%       angles - angles 
%       corrections - (dx, dy, dtheta) per image (nIm, 3).
%       stack_corrections

    prevstr=[];

    nFrames = min([size(imArray, 3), max(size(corrections, 1), numel(angles))]);
    
    if ~isempty(stack_corrections)
        imArray = shiftStack(imArray, stack_corrections(1), stack_corrections(2));
    end
    
    for fr = 1:nFrames
        % Display message in command window
        if mod(fr, 50) == 0
            str = ['applying displacements to frame ' num2str(fr) '/' num2str(nFrames)];
            refreshdisp(str, prevstr, fr);
            prevstr = str;
        end
        
        % translate first
        if ~isempty(corrections)
            imArray(:, :, fr) = shiftFrame(imArray(:, :, fr), corrections(fr, :));
        end
        
        % rotate second
        if ~isempty(angles)
            imArray(:, :, fr) = imrotate(imArray(:, :, fr), angles(fr), 'bicubic', 'crop');
        end
        
    end

    imArray = imArray(:, :, 1:nFrames);
%     
%     fprintf(char(8*ones(1,length(prevstr))));
%     fprintf('Shifted all images.');
%     fprintf('\n');
    
end
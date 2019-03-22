function [] = stackImages(folder, destination, wildcard, del)

% Function that stacks images in a folder into TIFF-stack.
%
% Inputs: folder, destination, wildcards in filename and 
% del (bool stating if original images should be deleted)

if nargin < 4
    del = false;
end

    % Get list of files in the folder
    files_to_stack = dir( fullfile(folder, wildcard) );
    files_to_stack = fullfile( folder, {files_to_stack.name} );
    n_files  = length(files_to_stack);

    % Loop through tiff-files
    for i = 1:n_files
        imFile = files_to_stack{i};
        im = imread(imFile);

        if i == 1 %Create a new stack
            imwrite(im, destination, 'TIFF')
        else 
            imwrite(im, destination, 'TIFF', 'writemode', 'append');

        end

    end

if del
    delete(files_to_stack{:})
end
    
end





function [] = saveFrameCorrections( sessionID, block, corrections, stack_corrections, angles )
%saveFrameCorrections Save frame by frame and stack corrections to file.
%   saveFrameCorrections(sessionID, BLOCK, CORR, STACK_CORR) saves frame
%   by frame corrections and stack corrections for block no for specified
%   sessionID. CORR is a vector containing x and y displacements for each 
%   frame of a stack, and STACK_CORR contains one x and one y displacement 
%   for the whole stack.

if nargin < 4
    stack_corrections = [0, 0];
    angles = [];
end

sessionFolder = getSessionFolder(sessionID);

saveFolder = fullfile(sessionFolder, 'preprocessed_data');
if ~ (exist(saveFolder, 'dir') == 7)
    mkdir(saveFolder)
end

filenm = ['framecorrections_', sessionID, '_block', num2str(block, '%03d'), '.mat'];

%save(fullfile(saveFolder, filenm), 'corrections', 'stack_corrections', 'angles')
save(fullfile(saveFolder, filenm), 'corrections')

end



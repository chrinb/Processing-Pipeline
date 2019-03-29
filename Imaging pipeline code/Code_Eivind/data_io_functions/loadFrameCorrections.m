function [ corrections, stack_corrections ] = loadFrameCorrections( sessionID, block )
%loadFrameCorrections Load frame by frame and stack corrections from file.
%   CORR, STACK_CORR = loadFrameCorrections(sessionID, BLOCK) returns frame
%   by frame corrections and stack corrections for block no for specified
%   sessionID. CORR is a vector containing x and y displacements for each 
%   frame of a stack, and STACK_CORR contains one x and one y displacement 
%   for the whole stack.

sessionFolder = getSessionFolder(sessionID);

saveFolder = fullfile(sessionFolder, 'preprocessed_data');

filenm = ['framecorrections_', sessionID, '_block', num2str(block, '%03d'), '.mat'];

s = load(fullfile(saveFolder, filenm));

corrections = s.corrections;
%stack_corrections = s.stack_corrections;

end


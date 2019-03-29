function [ output_args ] = TranslateStackWrapper( filename, imsize, disp )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

extra_padding = abs(disp);
canvas_size = imsize + extra_padding*2;

% This is needed for finding FIJI
addpath('/Applications/Fiji.app/scripts')

% start FIJI without GUI.
Miji(false);

% open stack
MIJ.run('Open...', ['path=[' filename ']']);

% Path to macro for creating a rectangle
macropath = fullfile(pwd, 'MakeRectangle.ijm');
MIJ.run(macropath)

% get Average of stack
MIJ.run('Canvas Size...', ['width=' canvas_size(2) ...
        ' height=' canvas_size(1) ' position=Center zero']);

% transfer image from FIJI to Matlab
avgImage = MIJ.getCurrentImage;

% close image window in FIJI
MIJ.run('Close');
MIJ.run('Close');

% exit FIJI
MIJ.exit

end


end


function pipe_makeVolumeStack
% PIPE_MAKEVOLUMESTACK will make a 3D model of zstack acquired. This 3D
% model can be used to visualize the location of responsive cells in a 3D
% visualization.



%-- Choose stack folder
folderpath = uigetdir();

%-- Get number of frames acquired
raw_file = dir(fullfile(folderpath, '*.ini'));
inistring = fileread(fullfile(raw_file.folder,raw_file.name));
nframes = readVarIni(inistring,'no.of.frames.acquired');
zspacing = readVarIni(inistring,'z.spacing');
frames_per_plane = readVarIni(inistring,'frames.per.plane');
first_frame = 1;
if nframes > 6000
    last_frame = 1;
    warning('The stack is too big. Fix code');
else
    last_frame = nframes;
end

im_Array = loadSciScanStack(folderpath, 2, first_frame, last_frame);
averaged_imArray = [];
num_iterations = size(im_Array,3)/frames_per_plane;
for x = 0:num_iterations-1
a(:,:,x+1) = mean(im_Array(:,:,(x*frames_per_plane)+1:frames_per_plane*(x+1)),3);
end

% diff = a;
% diff(diff<40) = nan;
% diff = double(squeeze(diff));
% h = slice(diff, [], [], 1:size(diff,3),'method','nearest');
% colormap('gray');
% set(h, 'EdgeColor','none', 'FaceColor','interp')
% alpha(.2)
% 
%     
% a = 1;


%-- Load stack

%-- Make new stack with a mean of the images in previous stack within one
%depth.




end

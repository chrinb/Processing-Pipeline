function pipe_makeVolumeStack
% PIPE_MAKEVOLUMESTACK will make a 3D model of z-stack acquired. This 3D
% model can be used to visualize the location of responsive cells in a 3D
% visualization. This is most interesting when using a piezo or Bessel beam 
% module for volume imaging.
% ##### UNDER DEVELOPMENT

%-- Choose stack folder
folderpath = 'E:\Data\M1205\2018_08_01\20180801_14_06_09_m1205_exp-test_gaussian_140ym_2x_007_zstaclk';%uigetdir();

%-- Get number of frames acquired
raw_file = dir(fullfile(folderpath, '*.ini'));
inistring = fileread(fullfile(raw_file.folder,raw_file.name));
nframes = readVarIni(inistring,'no.of.frames.acquired');
zspacing = readVarIni(inistring,'z.spacing');
frames_per_plane = readVarIni(inistring,'frames.per.plane');

first_frame = 1;
ch = 1;

% Define first index for each chunk
last_frame = nframes;
chunk_frames = 2000;
chunkSize = floor(chunk_frames/frames_per_plane)*frames_per_plane;
initFrames = first_frame:chunkSize:last_frame;

% Loop through each chunk
chunk = 0;
averaged_array = [];

for c = initFrames
    
    chunk = chunk + 1;
    
    % Last chunk is not full size, calculate its size:
    if c == initFrames(end)
        chunkSize = last_frame - initFrames(end);
    end
    
    % Set first and last frame number of current chunk
    idx_i = c; % first frame
    idx_e = (idx_i - 1) + chunkSize; % last frame
    
    im_Array = loadSciScanStack(folderpath, ch, idx_i, idx_e);
    averaged_imArray = [];
    
    num_iterations = size(im_Array,3)/frames_per_plane;
    % Create averaged stack of loaded the loaded stack
    for x = 0:num_iterations-1
        a(:,:,x+1) = mean(im_Array(:,:,(x*frames_per_plane)+1:frames_per_plane*(x+1)),3);
    end
    
    % Add this to averaged images already in memory
    averaged_array = cat(3,averaged_array, a);

end



% Save stack
sep_line = strfind(folderpath,'\');
sep_line = sep_line(end);
savePath = [folderpath,'\',folderpath(sep_line+1:end),'_averaged.tif'];
mat2stack(uint8(averaged_array), savePath);






end

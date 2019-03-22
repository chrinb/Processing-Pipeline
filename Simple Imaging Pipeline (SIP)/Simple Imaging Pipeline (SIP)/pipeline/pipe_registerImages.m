function pipe_registerImages
% PIPE_REGISTERIMAGES allows the user to select a session folder and
% automatically register all the images using the parameters specified in
% the options struct below. The aligned images are stored in the same
% session folder as selected in a new subfolder named
% "calcium_images_aligned".
%
% Written by Andreas Lande and Eivind Hennestad.

%-- Select registration methods
options = struct();
options.rigid = true; % Run rigid motion correction?
options.nonrigid = false; % Run nonrigid motion correction?

%-- Select session folder
folder_name = uigetdir(getPathToDir('datadrive'));
sessionID = getSessionIDfromString(folder_name);

%-- Run image registration on session
time_start = clock;
imregSessionPiezo(sessionID,options);
time_end = clock;
fprintf('\n------- Registration finished. Time elapsed: %2.f minutes\n',etime(time_end,time_start)/60)

end
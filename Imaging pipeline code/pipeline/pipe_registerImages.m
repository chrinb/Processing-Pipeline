function pipe_registerImages
% PIPE_REGISTERIMAGES allows the user to select a session folder and
% automatically register all the images using the parameters specified in
% the options struct below. The aligned images are stored in the same
% session folder as selected in a new subfolder named
% "calcium_images_aligned".
%
% Written by AL.

%--- Select registration methods
options = struct();
options.rigid = true;
options.nonrigid = true;

%--- Select session folder
folder_name = uigetdir;
sessionID = getSessionIDfromString(folder_name);

%--- Run image registration on session
imregSessionPiezo(sessionID,options);

end
function pipe_registerImages_multi
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

%--- Loop through folders
%folders = {'D:\Data\mouse1009\session-m1009-20171202_1639_FREE-006','D:\Data\mouse1009\session-m1009-20171202_1653_FREE-007','D:\Data\mouse1009\session-m1009-20171203_1406_FREE-010'};

for x = 1:length(folders)
    folder_name = folders{x};
    sessionID = getSessionIDfromString(folder_name);

    %--- Run image registration on session
    imregSessionPiezo(sessionID,options);
end

end
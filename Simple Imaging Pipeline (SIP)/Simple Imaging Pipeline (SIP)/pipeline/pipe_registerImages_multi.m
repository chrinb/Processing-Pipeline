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

%--- Set options for each recording
rigid = [true true true true true];
nonrigid = [true true true true false];

%--- Loop through folders
folders = {'E:\Data\mouse1205\session-m1205-20180803_1218_SPACE-003-05', ...
    'E:\Data\mouse1205\session-m1205-20180803_1058_SPACE-003-01' ...
    'E:\Data\mouse1205\session-m1205-20180803_1127_SPACE-003-03' ...
    'E:\Data\mouse1205\session-m1205-20180803_1117_SPACE-003-02' ...
    'E:\Data\mouse9876\session-m9876-20180729_1837-SPACE-001'};

for x = 1:length(folders)
    options.rigid = rigid(x);
    options.nonrigid = nonrigid(x);
    folder_name = folders{x};
    sessionID = getSessionIDfromString(folder_name);

    %--- Run image registration on session
    time_start = clock;
    imregSessionPiezo(sessionID,options);
    time_end = clock;
    fprintf('\n------- Registration finished. Time elapsed: %2.f minutes\n',etime(time_end,time_start)/60)

end

end
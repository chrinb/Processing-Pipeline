%% Overview --- DO NOT RUN ANY OF THIS CODE. THE PIPE_OVERVIEW FILE IS JUST FOR DEMONSTRATION OF THE PROCEDURE.
%--- Select the mousedata structure to be used. 
% If this is the first session in the mouse, make a structure with its name:
    mouse1000 = struct();
    save mouse1000.mat mouse1000;
% else if this is already done
    load mouse1000.mat
    mousedata = mouse1000;

%% Pipeline: For each session, do the following
%--- Register images from session
pipe_registerImages;

%--- Select ROIs
roimanager_lite;

%% --- NB! You have to finish using roimanager_lite before continuing here..
%--- Load sessiondata obtained in LabView
mousedata = pipe_loadSessionData(mousedata);

%--- Extract signal from each ROI
mousedata = pipe_extractSignalsFromROIs(mousedata,channel);


%% Save the mousedata
save mouse1000.mat mousedata;

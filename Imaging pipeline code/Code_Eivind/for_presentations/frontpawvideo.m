% Video showing neural responses and front paw movement.

%roim = roimanager_lite;
% In roimanager, open relevant session and also open it in sessionbrowser
sBrowser = roim.sessionBrowser;

% Made video from session  m042-20170902_2059-001

% Make a new figure window to save to video:
videoFig = figure('Position', [1128, 1374, 850, 540]); % Open on big screen
colormap gray
set(videoFig, 'color', 'white')

% Move relevant axes to videoFig
set(roim.axStackDisplay, 'Parent', videoFig, 'units', 'pixels', 'Position', [50, 230, 300, 300])
set(sBrowser.axOverviewVideo, 'Parent', videoFig, 'units', 'pixels', 'Position', [300, 230, 600, 300])
set(sBrowser.axPopulationResponse, 'Parent', videoFig, 'units', 'pixels', 'Position', [50, 100, 745, 100])
set(sBrowser.axCellResponse, 'Parent', videoFig, 'units', 'pixels', 'Position', [50, 30, 745, 50])

colormap(sBbrowser.axPopulationResponse, 'default')

sessionFolder = getSessionFolder(sBrowser.sessionID);
videoName = ['FrontPawVideo_short-' sBrowser.sessionID '-Block' ...
             num2str(sBrowser.currentBlock, '%03d') '.avi'];
%Todo: Hide Buttons and sliders
%Todo: Show Title

% Filepath to save the movie
video = VideoWriter(fullfile(sessionFolder, videoName));

video.FrameRate = 30;
video.open();
roim.currentFrameNo = 4700;
for i = 1 : 1200
%     sBrowser = updateFrames(sBrowser);
%     sBrowser = updateFrameMarkers(sBrowser);
    roim.changeFrame([], [], 'playvideo');
    F = getframe(videoFig);
    frame = frame2im(F);
    writeVideo(video, frame)
end
video.close()
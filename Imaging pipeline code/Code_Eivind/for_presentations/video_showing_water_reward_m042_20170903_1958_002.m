% Open sessionBrowser.

%sBrowser = sessionBrowser;
sBrowser = sbrowser;
% In sessionBrowser, open a session.
% Load body video

% Make a new figure window to save to video:
videoFig = figure('Position', [0,0,950,400]);

% Move relevant axes to videoFig
set(sBrowser.axArenaAnimation, 'Parent', videoFig, 'units', 'pixels', 'Position', [50, 50, 300, 300])
set(sBrowser.axOverviewVideo, 'Parent', videoFig, 'units', 'pixels', 'Position', [450, 25, 600, 350])


set(videoFig, 'color', 'white')
colormap gray

%sBrowser.exportVideo([],[])


sessionFolder = getSessionFolder(sBrowser.sessionID);
videoName = ['SummaryVideo-' sBrowser.sessionID '-Block' ...
             num2str(sBrowser.currentBlock, '%03d') '.avi'];
%Todo: Hide Buttons and sliders
%Todo: Show Title

% Filepath to save the movie
video = VideoWriter(fullfile(sessionFolder, videoName));

video.FrameRate = 30;
video.open();
ctr = 0;
sBrowser.currentFrame = 1;
for i = 1 : 700%browser.sessionData.nFrames
    sBrowser = updateFrames(sBrowser);
    sBrowser = updateFrameMarkers(sBrowser);
    if i > 270 && i < 315
        ctr = ctr+1;
        if ctr == 4
            ctr = 0;
        else 
            sBrowser.currentFrame = sBrowser.currentFrame - 1;
        end
    end
        
    F = getframe(gcf);
    frame = frame2im(F);
    writeVideo(video, frame)
    sBrowser.currentFrame = sBrowser.currentFrame + 1;
end
set(sBrowser.frameslider, 'Value', sBrowser.currentFrame )
video.close()
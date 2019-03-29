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

sBrowser.exportVideo([],[])


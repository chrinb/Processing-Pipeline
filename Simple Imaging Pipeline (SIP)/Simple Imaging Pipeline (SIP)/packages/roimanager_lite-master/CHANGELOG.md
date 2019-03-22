% Changes 27/11/2017 - Added support for multiple channels
%{
    - Added properties: currentChannel, loadedChannels, nLoadedChannels, channelDisplayMode
    - Added button: btnShowSingleChannel
    - Added method: changeChannelDisplayMode, changeCurrentChannel
    - Changed properties: imgTseries, imgTseriesMedfilt, tiffClass, ... 
                    imgAvg, imgMax, roiArray, roiCount, ...
                    RoiPlotHandles, RoiTextHandles from arrays to cell array of arrays
    Todo: Take care of several channels if using sessionID and databases.
    Todo: Export signals
%}

% Changes 28/11/2017 - Added cortical layer popup menu
%{
    - Added popupmenu for setting cortical layer of ROI
        Layer is now a property of the ROI class
    - Fixed display of average and max picture for multiple channels.
    - Fixed playback speeds, making them more reliable (only showing 
        every nth frame if speed is increased).
    - Added function for setting colors of multichannel image based on
      channel color settings (property channelColors)
    - 0 on keybord switches between showing single channels or all channels 
%}

% Changes 28/11/2017 - Started working on background tasks
%{ 
    - Added functions :
        quitRoimanager, startBackgroundJob, pollBackgroundJob
    - Added timer object, and objects for storing jobObjects, jobNames
        and current task number.
%}

% Changes december 2017

% Bug: show signal mode: If two rois are selected and show signal is
% changed, suddenly there are three lines.

% Changes 14/05/2018 - Removed background tasks
%{
    - Removed functions for running background tasks
%}

% Changes 07/06/2018 - Added undo/redo functionality for rois.

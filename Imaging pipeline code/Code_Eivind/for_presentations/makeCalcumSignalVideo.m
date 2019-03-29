% Make video


% Made video from session  m042-20170903_1958-006

% Make a new figure window to save to video:
%videoFig = figure('Position', [1128, 1374, 850, 540]); % Open on big screen
videoFig = figure('Position', [0,0,950,400]);
colormap gray
set(videoFig, 'color', 'white')

set(roim.axStackDisplay, 'Parent', videoFig, 'units', 'pixels', 'Position', [25, 40, 350, 350])

signal_ax = axes('Parent', videoFig, 'units', 'pixel', 'Position', [450, 40, 450, 350], 'fontsize', 12);
set(signal_ax, 'box', 'off')

%signals = load(fullfile('/Volumes/Experiments/mouse042/session-m042-20170903_1958-006/extracted_calcium_signals', 'extracted_signal_m042-20170903_1958-006_block001_ch2.mat'));
signals = load(fullfile('/Volumes/Labyrinth/mouse042/session-m042-20170903_1958-006/extracted_calcium_signals', 'extracted_signal_m042-20170903_1958-006_block001_ch2.mat'));

% Normalize signals
signals = signals.signalData.Signal;
signals = signals/max(signals(:));

nRois = size(signals, 2);

smoothedSignals = zeros(size(signals));
for roi = 1:nRois
    smoothedSignals(:, roi) = smooth(signals(:, roi), 9);
end

lines = gobjects(nRois, 1);

sessionFolder = getSessionFolder(roim.sessionID);
movieFolder = fullfile(sessionFolder, 'movie_part1_1');
mkdir(movieFolder)

videoName = ['CaSignalExample-' roim.sessionID 'part1_.avi'];
imName = 'CaSignalExample';

set(roim.RoiPlotHandles, 'Visible', 'off');

% Filepath to save the movie
% video = VideoWriter(fullfile(sessionFolder, videoName));
% 
% video.FrameRate = 30;
% video.open();
roim.currentFrameNo = 1;

timepoints = (0:roim.nFrames-1)/31;
plottedSignals = nan(size(signals));

roiCount = 1;

for f = 1:15
    if f == 1
        for p = 1:nRois
            lines(p) = plot(signal_ax, timepoints, plottedSignals(:, p) + (p-1), 'Visible', 'on', 'LineWidth', 1.2);
            color = lines(p).Color;
            roim.RoiPlotHandles(p).Color = color;
            roim.RoiPlotHandles(p).LineWidth = 1.2;
            if p == 1
                hold(signal_ax, 'on')
                ylim([0,14])
                xlim([0, timepoints(end)])
                set(signal_ax, 'YTick', [1:13]);
                xlabel(signal_ax, 'Time (s)')
            end
        end
    end
    
%     F = getframe(videoFig);
%     frame = frame2im(F);
%     writeVideo(video, frame)
    fig2png(videoFig, fullfile(movieFolder, [imName, num2str(f, '%05d'), '.png']))

    if mod(f, 1) == 0 && roiCount < 14
        set(roim.RoiPlotHandles(roiCount), 'Visible', 'on')
        roiCount = roiCount+1;
    end
end
%video.close()

%videoName = ['CaSignalExample-' roim.sessionID 'part2_.avi'];
% Filepath to save the movie
% video = VideoWriter(fullfile(sessionFolder, videoName));
% video.FrameRate = 30;
% video.open();

movieFolder = fullfile(sessionFolder, 'movie_part2');
mkdir(movieFolder)

for f = 1:5:roim.nFrames-1
    roim.changeFrame([], [], 'playvideo');
    fig2png(videoFig, fullfile(movieFolder, [imName, num2str(f, '%05d'), '.png']))

%     F = getframe(videoFig);
%     frame = frame2im(F);
%     writeVideo(video, frame)
    
    plottedSignals(1:f, :) = smoothedSignals(1:f, :);
    for p = 1:nRois
        lines(p).YData = plottedSignals(:, p) + (p-0.2);
    end

    
end
    
%video.close()
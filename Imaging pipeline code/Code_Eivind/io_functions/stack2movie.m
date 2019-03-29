function [ ] = stack2movie( filepath, frames, framerate )
%stack2movie Saves a stack (array) as a movie on disk

% Filepath to save the movie
video = VideoWriter(filepath);

video.FrameRate = framerate;
video.open();

% Write frames
for i = 1:size(frames, 4)
    frame = frames(:, :, :, i);
    writeVideo(video, frame)  
end

video.close()

end


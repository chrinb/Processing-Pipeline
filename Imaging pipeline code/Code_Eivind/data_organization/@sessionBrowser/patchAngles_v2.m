function [patches] = patchAngles_v2(ax, polar, rotating)
% Patch areas in an axes according to angles. CCw = yellow, CW = magenta???

% Get info from plot
axLine = findobj(ax, 'Type', 'Line'); % If patch angles is called from sessionbrowser.

% Find length of data that is plotted. Used for patching of all samples
lineLengths = arrayfun(@(x) length(axLine(x).XData), 1:length(axLine), 'un', 0 );
[~, idx] = max(cell2mat(lineLengths)); % Then there is the frame marker line which is shorter than the rest.
xCoords = axLine(idx).XData;

% Get ax limits, to fill all the plot
ylim = get(ax, 'Ylim');
xlim = get(ax, 'Xlim');

% Create a colormap ranging from 0 to 360. Can we find a circular one?
cmap = hsv(365);  % (cmap = cool(8));

% Set y coordinates for patch
%yPatch = [ylim(1), ylim(1), ylim(2), ylim(2)];

polar = polar(1, 1:end-1);

% Find Transitions.
transitions = zeros(size(rotating));
transitions(2:end) = rotating(2:end) - rotating(1:end-1);

% Find indices where trial starts and stop (e.g transitions)
stationaryStartIdx = horzcat(1, find(transitions == -1));
stationaryStopIdx = horzcat(find(transitions == 1), length(xCoords));

% Find orientations of each stationary period:
orientations = zeros(1, numel(stationaryStartIdx));
rotation_dir = zeros(1, numel(stationaryStopIdx)-1);

for i = 1:length(stationaryStartIdx);
    % Find an index in middle of a stationary period and retrieve position
    sampleIdx1 = stationaryStopIdx(i) - round(diff([stationaryStartIdx(i), stationaryStopIdx(i)])/2);
    orientations(i) = polar(sampleIdx1);
    
    % Find an index in middle of a rotation period (one less rotation) and retrieve
    % direction
    if ~ (i==length(stationaryStartIdx))
        sampleIdx2 = stationaryStartIdx(i+1) - round(diff([stationaryStopIdx(i), stationaryStartIdx(i+1)])/2);
        rotation_dir(i) = sign(diff([polar(sampleIdx2-5), polar(sampleIdx2)]));
    end
        

    
end


% Find number of stationary positions
orientations(orientations==360) = 0;
uniqueOrientations = unique(orientations);
nOrientations = length(uniqueOrientations);

% Make the patches. n categories, x directions and 2 (cw or ccw) rotations.
patches = gobjects(nOrientations+2, 1);

% First make stationary patches.

for i = 1:nOrientations
    orientation = uniqueOrientations(i);
    orientation_idc = find(orientations == orientation);
    
    xData = zeros(length(orientation_idc), 4);
    yData = zeros(length(orientation_idc), 4);

    xData(:,1) = xCoords(stationaryStartIdx(orientation_idc));
    xData(:,2) = xCoords(stationaryStopIdx(orientation_idc));
    xData(:,3) = xCoords(stationaryStopIdx(orientation_idc));
    xData(:,4) = xCoords(stationaryStartIdx(orientation_idc));

    yData(:,1:2) = ylim(1);
    yData(:,3:4) = ylim(2);
    
    color = cmap(round(orientation)+1, :);
    patches(i) = patch(xData', yData', color ,'Parent', ax);
    
end

unique_dir = [-1, 1];

for i = 1:2
    
    direction_idc = find(rotation_dir == unique_dir(i));
    
    xData = zeros(length(direction_idc), 4);
    yData = zeros(length(direction_idc), 4);
    
    xData(:,1) = xCoords(stationaryStopIdx(direction_idc));
    xData(:,2) = xCoords(stationaryStartIdx(direction_idc+1));
    xData(:,3) = xCoords(stationaryStartIdx(direction_idc+1));
    xData(:,4) = xCoords(stationaryStopIdx(direction_idc));

    yData(:,1:2) = ylim(2)-(ylim(2)*0.1);
    yData(:,3:4) = ylim(2);
    
    if i == 1
        color = 'red';
    else 
        color = 'green';
    end
    
    patches(nOrientations+i) = patch(xData', yData', color ,'Parent', ax);
    
end


set(patches(1:nOrientations), 'facealpha', 0.2, 'edgecolor', 'none', 'HitTest', 'off')
set(patches(end-1:end), 'facealpha', 1, 'edgecolor', 'none', 'HitTest', 'off')
function [ax] = patchAngles(ax, polar, rotating, makeArrow, ax2)
% Patch areas in an axes according to angles.

if nargin < 4
    makeArrow = false;
end

if nargin < 5
    ax2 = ax;
end

% Get info from plot
%data = get(ax, 'children');
axLine = findobj(ax, 'Type', 'Line'); % If patch angles is called from sessionbrowser.
lineLengths = arrayfun(@(x) length(axLine(x).XData), 1:length(axLine), 'un', 0 );
[~, idx] = max(cell2mat(lineLengths)); % Then there is the frame marker line which is shorter than the rest.
xData = axLine(idx).XData;
ylim = get(ax2, 'Ylim');  % Does this work ok?
xlim = get(ax, 'Xlim');

% Create a colormap ranging from 0 to 360. Can we find a circular one?
cmap = hsv(365);  % (cmap = cool(8));

% Set y coordinates for patch
yPatch = [ylim(1), ylim(1), ylim(2), ylim(2)];

polar = polar(1, 1:end-1);

rot = true;

transitions = zeros(size(rotating));
transitions(2:end) = rotating(2:end) - rotating(1:end-1);

% Find indices where trial starts and stop (e.g transitions)
stationaryStartIdx = horzcat(1, find(transitions == -1));
stationaryStopIdx = horzcat(find(transitions == 1), length(xData));

% first_idx = 1;
% last_idx = findEndOfTrial(polar, first_idx);

first_idx = stationaryStartIdx(1);
last_idx = stationaryStopIdx(1);
counter = 1;

for i = 1 : length(xData) - 1
    if (i == first_idx)
        rot = ~rot;
        xPatch = [ xData(i), xData(i+1), xData(i+1), xData(i) ];
        patch(xPatch, yPatch, [0,0,0], 'Parent', ax2, 'edgecolor','none');
    end
    
    if rot
        xPatch = [ xData(i), xData(i+1), xData(i+1), xData(i) ];
        patch(xPatch, yPatch, cmap(round(polar(i))+1,:), 'Parent', ax2, ...
              'facealpha', 0.2,'edgecolor','none');
          
    else
        if i == first_idx
            xPatch = [ xData(i), xData(last_idx), xData(last_idx), xData(i) ];
            patch(xPatch, yPatch, cmap(round(polar(i))+1,:), 'Parent', ax2, ...
                  'facealpha', 0.2,'edgecolor','none');
        end
    end
    
    if (i == last_idx)
        if i == length(xData) - 1
            break
        end
        rot = ~rot;
        
        counter = counter + 1;
        first_idx = stationaryStartIdx(counter);
        last_idx = stationaryStopIdx(counter);

        
        xPatch = [ xData(i), xData(i+1), xData(i+1), xData(i) ];
        patch(xPatch, yPatch, [0,0,0], 'Parent', ax2, 'edgecolor','none');
        %last_idx = findEndOfTrial(polar, first_idx);
    end
    
end

if makeArrow

    % Create rotation/ and transition "boolean" arrays. Todo: Make real bools 
%     angleDiff = diff(polar);
%     rotating = zeros(size(polar));
%     rotating(abs(angleDiff) >= 0.2) = 1;
%     rotating = medfilt1(rotating, 5);
    transitions = zeros(size(rotating));
    transitions(2:end) = rotating(2:end) - rotating(1:end-1);

    % Find indices where trial starts and stop (e.g transitions)
    stationaryStartIdx = horzcat(1, find(transitions == -1));
    stationaryStopIdx = horzcat(find(transitions == 1), length(xData));

    cntrY = 0.85 * ylim(2);
    arrowLengthFactor = 0.15;

    figPosition = get(gcf, 'Position');
    figHeight = figPosition(4);
    figWidth = figPosition(3);
    lengthFactor = max(figHeight, figWidth)*0.2;
    xScaling = 1/figWidth*lengthFactor;
    yScaling = 1/figHeight*lengthFactor;

    axPosition = get(ax, 'Position');
    axHeight = axPosition(4);
    axWidth = axPosition(3);
    axAspectRatio = (figWidth/figHeight)*(axWidth/axHeight);
    circleY = arrowLengthFactor * ylim(2);
    circleX = arrowLengthFactor * (xlim(2)-xlim(1))/axAspectRatio;
    
    rotationDir = [1,2,2,2,2,3,3,3,3,2,2,2,2,3,3,3,3];
    rotationColor = [[0.4,0.4,0.4]; [0.176,0.533,0.176]; [0.667, 0.224, 0.224]];
    

    for i = 1:size(stationaryStartIdx, 2)

        cntrX = floor((stationaryStopIdx(i) - stationaryStartIdx(i)) / 2 + stationaryStartIdx(i));
        angle = polar(cntrX);
        cntrX = xData(cntrX);

        deltaY = cos(angle/180*pi)*arrowLengthFactor * ylim(2);
        deltaX = sin(angle/180*pi)*arrowLengthFactor * (xlim(2)-xlim(1))/axAspectRatio;

        %x = [cntrX-deltaX, cntrX+deltaX];
        %y = [cntrY+deltaY, cntrY-deltaY];

        x_fig = [0.5, 0.5 - (sin(angle/180*pi)*xScaling) ];
        y_fig = [0.5, 0.5 + (cos(angle/180*pi)*yScaling) ];

        arrow = annotation('textarrow', x_fig, y_fig);
        circle = annotation('ellipse', [0.5,0.5,0.2,0.2]);
        arrow.Color = rotationColor(rotationDir(i),:);
        circle.Color = rotationColor(rotationDir(i),:);
        set(arrow, 'parent', ax);
        set(circle, 'parent', ax);
        set(arrow, 'position', [cntrX+(deltaX/2), cntrY-(deltaY/2), -deltaX, deltaY])
        set(circle, 'position', [cntrX-circleX/2, cntrY-circleY/2, circleX, circleY])
    end
    
    

%     % Complete mess to make arrow legends
%     cntrXCW = floor((stationaryStopIdx(1) - stationaryStartIdx(1)) / 2 + stationaryStartIdx(1));
%     cntrXCW = (xData(cntrXCW) / xlim(2) * axWidth + axPosition(1)) ;
%     cntrXCCW = floor((stationaryStopIdx(4) - stationaryStartIdx(4)) / 2 + stationaryStartIdx(4));
%     cntrXCCW = (xData(cntrXCCW) / xlim(2) * axWidth + axPosition(1)) ;
%     
%     cntrY = axPosition(2) + axPosition(4) + 0.03;
%     
%     deltaY = arrowLengthFactor * axHeight;
%     deltaX = arrowLengthFactor * axWidth / axAspectRatio;
%     
%     arrowCW = annotation('textarrow', [cntrXCW-deltaX, cntrXCW], [cntrY, cntrY]);
%     arrowCCW = annotation('textarrow', [cntrXCCW-deltaX, cntrXCCW], [cntrY, cntrY]);
%     circleCW = annotation('ellipse', [cntrXCW-deltaX, cntrY-deltaY/2,deltaX,deltaY]);
%     circleCCW = annotation('ellipse', [cntrXCCW-deltaX,cntrY-deltaY/2,deltaX,deltaY]);
%     arrowCW.Color = [0.176,0.533,0.176];
%     arrowCCW.Color = [0.667, 0.224, 0.224];
%     circleCW.Color = [0.176,0.533,0.176];
%     circleCCW.Color = [0.667, 0.224, 0.224];
%     cwText = annotation('textbox', [cntrXCW+deltaX/2, cntrY-deltaY/1.5, deltaX, deltaY], ...
%                'String', 'CW rotation', 'FitBoxToText', 'on');
%     cwText.Color=[0.176,0.533,0.176];
%     cwText.FontSize = 14;
%     cwText.LineStyle = 'none';
%     ccwText = annotation('textbox', [cntrXCCW+deltaX/2, cntrY-deltaY/1.5, deltaX, deltaY], ...
%                'String', 'CCW rotation', 'FitBoxToText', 'on');
%     ccwText.Color = [0.667, 0.224, 0.224];
%     ccwText.FontSize = 14;
%     ccwText.LineStyle = 'none';
end

% 
% colormap(cmap)
% h = colorbar;
% caxis([0 360])
% 
% annotation('textbox',...
%     h.Position,...
%     'FitBoxToText','off',...
%     'FaceAlpha',0.3,...
%     'EdgeColor',[1 1 1],...
%     'BackgroundColor',[1 1 1]);

end
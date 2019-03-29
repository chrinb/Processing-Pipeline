% Detect all licks.


% 1 second before lick and 4 seconds after.
function analyseRotationDirection(sessionID)


sessionData = getSessionData(sessionID);
sessionFolder = getSessionFolder(sessionID);

figureFolder = fullfile(sessionFolder, 'figures', 'rotation');
if ~exist(figureFolder, 'dir'); mkdir(figureFolder); end
figureNamePrefix = [sessionID, '_rotationresponse_roi_'];

% Find go Trials.
transitions = sessionData.transitions(1,:);
rotating = sessionData.rotating(1, :);
angles = sessionData.anglesRW(1, :);
angles = round(sessionData.stagePositions(1, :));

rotStart = find(transitions == 1);
rotStop = find(transitions == -1);
startPositions = angles(rotStart-5);
stopPositions = angles(rotStop+5);



fps = 31;
preSamples = 1*fps;
postSamples = 1*fps;

timePoints = (-preSamples:postSamples) / fps;

df_f0_max = max(max(sessionData.deltaFoverFch2(1, :, :)));

for roi = 1:sessionData.nRois
    fig = figure('Visible', 'off', 'Position', [0, 0, 960, 387]);
    
    s1 = subplot(231); % Positive Rotation Short
    s2 = subplot(232); % Positive Rotation Medium
    s3 = subplot(233); % Positive Rotation Long
    s4 = subplot(234); % Negative Rotation Short
    s5 = subplot(235); % Negative Rotation Medium
    s6 = subplot(236); % Negative Rotation Long
    
    subs = {s1, s2, s3, s4, s5, s6};
    
    
%     
%     meanTrace_hit = zeros(length(timePoints), 1);
%     meanTrace_miss = zeros(length(timePoints), 1);
%     medianTrace_hit = zeros(length(timePoints), length(waterStart));
%     medianTrace_miss = zeros(length(timePoints), length(gotrials) - length(waterStart));
    
    for i = 2:length(rotStart)-1
        
        % Initiate plot
        if i == 2
            for j = 1:6
                plot(subs{j}, [0, 0], [-1, df_f0_max], '--k')
                hold(subs{j}, 'on')
                
            end
                
%             legendObjects_hits(1) = plot(s1, [0,0], [0,1], '--k');
%             legendObjects_misses(1) = plot(s2, [0,0], [0,1], '--k');
            
        end
        
        % find length of rotation
        startPosition = startPositions(i);
        stopPosition = stopPositions(i);
        
        rot_diff = abs(stopPosition - startPosition);
        if rot_diff == 360; rot_diff=0; end
        
        if rot_diff == 0
            rot_length = 3;
        elseif rot_diff == 120
            rot_length = 1;
        elseif rot_diff == 240
            rot_length = 2;
        else
            error('unknown rotation interval')
        end
        
        % Find rotation direction
        sampleIdx2 = rotStop(i) - round(diff([rotStart(i), rotStop(i)])/2);
        rotation_dir = sign(diff([angles(sampleIdx2-5), angles(sampleIdx2)]));
        
        % Extract signal around rotation.
        roiTrace = sessionData.deltaFoverFch2(1, roi, rotStart(i)-preSamples:rotStop(i)+postSamples);
        roiTrace = squeeze(roiTrace);
        
        % Plot in correct plot
        
        if rotation_dir == 1
            if rot_length == 1
                s = subs{1};
            elseif rot_length == 2
                s = subs{2};
            elseif rot_length == 3
                s = subs{3};
            end
                
        elseif rotation_dir == -1
            if rot_length == 1
                s = subs{4};
            elseif rot_length == 2
                s = subs{5};
            elseif rot_length == 3
                s = subs{6};
            end
            
        else
            error('unknown rotation direction')
        end
        
        roiLine = plot(s, roiTrace, 'Color', [0.6, 0.6, 0.6]);
            % Add trace to median and mean arrays.
%             meanTrace_hit = meanTrace_hit + roiTrace;
%             medianTrace_hit(:, hits) = roiTrace;

    end
    
    for j = 1:6
        s = subs{j};
        lines = findobj(s, 'Type', 'Line');
        for l = 1:length(lines)
            if length(lines(l).XData) == 2
                continue
            else
                lines(l).XData = (lines(l).XData - preSamples) / fps;
            end
        end
            
        lineLength = arrayfun(@(x) length(lines(x).XData), 1:length(lines), 'un', 0 );
        maxLineLength = max(cell2mat(lineLength));
        
        xlim(s, [-preSamples / fps, (maxLineLength-preSamples)/fps]);
        
        if j == 5
            xlabel(s, 'Time (s)')
        end
        
        if j < 4
            color = 'red';
        else
            color = 'green';
        end
        
        yPatch = [-1,-1, -0.5, -0.5];
        xPatch = [0, (maxLineLength-preSamples)/fps, (maxLineLength-preSamples)/fps, 0];
        p = patch(xPatch, yPatch, color, 'facealpha', 1,'edgecolor','none', 'Parent', s);
        box(s, 'off')
        if j==3
            leg = legend(s, p, {'Positive Rotation'});
            leg.Position = [0.7802, 0.94, 0.1146, 0.0362];
        elseif j == 6
            leg = legend(s, p, {'Negative Rotation'});
            leg.Position = [0.7802, 0.47, 0.1146, 0.0362];
        end
        
    end
                
    
%     legendObjects_hits(2) = roiLine_hit;
%     legendObjects_misses(2) = roiLine_miss;
%     meanTrace_hit = meanTrace_hit / hits;
%     medianTrace_hit = median(medianTrace_hit, 2); % Double Check This!!!!
%     
%     meanTrace_miss = meanTrace_miss / misses;
%     medianTrace_miss = median(medianTrace_miss, 2); % Double Check This!!!!
%     
%     legendObjects_hits(3) = plot(s1, timePoints, meanTrace_hit, 'k'); % Plot in Bold
%     legendObjects_hits(4) = plot(s1, timePoints, medianTrace_hit, 'r');
%     
%     legendObjects_misses(3) = plot(s2, timePoints, meanTrace_miss, 'k'); % Plot in Bold
%     legendObjects_misses(4) = plot(s2, timePoints, medianTrace_miss, 'r');
%     
%     
%     leg_hit = legend(s1, legendObjects_hits, {'Go Trial Start', 'Single Responses', 'Mean Trace', 'Median Trace'});
%     leg_miss = legend(s2, legendObjects_misses, {'Go Trial Start', 'Single Responses', 'Mean Trace', 'Median Trace'});
%     xlabel(s1, 'Time (s)')
%     xlabel(s2, 'Time (s)')
%     ylabel(s1, 'Delta F over F')
%     ylim(s1, [0,df_f0_max])
%     ylim(s2, [0,df_f0_max])
%     
%     title(s1, ['Neuronal Responses to hit trials - Roi # ', num2str(roi, '%03d')])
%     title(s2, ['Neuronal Responses to miss trials - Roi # ', num2str(roi, '%03d')])
    
    
    fig2png(fig, fullfile(figureFolder, [figureNamePrefix, num2str(roi, '%03d'), '.png']))
    close(fig)
end
    
end
% Detect all licks.


% 1 second before lick and 4 seconds after.
function analyseGoTrials(sessionID)


sessionData = getSessionData(sessionID);
sessionFolder = getSessionFolder(sessionID);

figureFolder = fullfile(sessionFolder, 'figures', 'goTrial');
if ~exist(figureFolder, 'dir'); mkdir(figureFolder); end
figureNamePrefix = [sessionID, '_gotrialResponse_roi_'];

water = sessionData.waterRewards(1, :);
licks = sessionData.lickResponses(1, :);
waterGiven = diff(water);

waterStart = find(waterGiven == 1);
waterStop = find(waterGiven == -1);

waterDuration = waterStop(1) - waterStart(1);

waterInterval = diff(waterStart);

% Find go Trials.
transitions = sessionData.transitions(1,:);
angles = sessionData.anglesRW(1, :);

% Set up colormap
cmap = hsv(365);

rotStop = find(transitions == -1);
positions = angles(rotStop+5);

gotrials = find(positions == 0);

gotrialStartIdx = rotStop(gotrials);

fps = 31;
preSamples = 1*fps;
postSamples = 4*fps;

timePoints = (-preSamples:postSamples) / fps;

df_f0_max = max(max(sessionData.deltaFoverFch2(1, :, :)));

for roi = 1:sessionData.nRois
    fig = figure('Visible', 'off', 'Position', [0, 0, 960, 387]);
    
    s1 = subplot(121); % Hit trials
    set(s1, 'Position', [0.07, 0.11, 0.4, 0.8150])
    s2 = subplot(122); % Miss trials
    set(s2, 'Position', [0.57, 0.11, 0.4, 0.8150])
    
    roiSignalMax = max(sessionData.deltaFoverFch2(1, roi, :));
    meanTrace_hit = zeros(length(timePoints), 1);
    meanTrace_miss = zeros(length(timePoints), 1);
    medianTrace_hit = zeros(length(timePoints), length(waterStart));
    medianTrace_miss = zeros(length(timePoints), length(gotrials) - length(waterStart));
    
    legendObjects_hits = gobjects(4,1);
    legendObjects_misses = gobjects(4,1);
    
    hits = 0;
    misses = 0; 
    
    for i = 1:length(gotrials)
        
        % Initiate plot
        if i == 1
            plot(s1, [0,0], [0,df_f0_max], '--k')
            plot(s2, [0,0], [0,df_f0_max], '--k')
            %plot(timePoints, waterTrace, 'g');
            hold(s1, 'on')
            hold(s2, 'on')
            legendObjects_hits(1) = plot(s1, [0,0], [0,1], '--k');
            legendObjects_misses(1) = plot(s2, [0,0], [0,1], '--k');
            
            xPatch = [-1, 4, 4, -1];
            yPatch = [0, 0, df_f0_max, df_f0_max];
            patch(xPatch, yPatch, cmap(0+1,:), 'facealpha', 0.1,'edgecolor','none', 'Parent', s1)
            patch(xPatch, yPatch, cmap(0+1,:), 'facealpha', 0.1,'edgecolor','none', 'Parent', s2)
            
        end
        
        % Extract signal around water reward.
        roiTrace = sessionData.deltaFoverFch2(1, roi, gotrialStartIdx(i) + (-preSamples:postSamples));
        % Normalize
        roiTrace = squeeze(roiTrace);
        
        % Split hit and miss trials
        responseTime = abs(gotrialStartIdx(i) - waterStart);
        if any(responseTime < 75)
            % Treat as hit trial
            hits = hits+1;
            % Plot the line
            roiLine_hit = plot(s1, timePoints, roiTrace, 'Color', [0.6, 0.6, 0.6]);
            % Add trace to median and mean arrays.
            meanTrace_hit = meanTrace_hit + roiTrace;
            medianTrace_hit(:, hits) = roiTrace;
        else
            % Treat as miss trial
            misses = misses+1;
            roiLine_miss = plot(s2, timePoints, roiTrace, 'Color', [0.6, 0.6, 0.6]);
            % Add trace to median and mean arrays.
            meanTrace_miss = meanTrace_miss + roiTrace;
            medianTrace_miss(:, misses) = roiTrace;
        end

    end
    
    legendObjects_hits(2) = roiLine_hit;
    legendObjects_misses(2) = roiLine_miss;
    meanTrace_hit = meanTrace_hit / hits;
    medianTrace_hit = median(medianTrace_hit, 2); % Double Check This!!!!
    
    meanTrace_miss = meanTrace_miss / misses;
    medianTrace_miss = median(medianTrace_miss, 2); % Double Check This!!!!
    
    legendObjects_hits(3) = plot(s1, timePoints, meanTrace_hit, 'k'); % Plot in Bold
    legendObjects_hits(4) = plot(s1, timePoints, medianTrace_hit, 'r');
    
    legendObjects_misses(3) = plot(s2, timePoints, meanTrace_miss, 'k'); % Plot in Bold
    legendObjects_misses(4) = plot(s2, timePoints, medianTrace_miss, 'r');
    
    
    leg_hit = legend(s1, legendObjects_hits, {'Go Trial Start', 'Single Responses', 'Mean Trace', 'Median Trace'});
    leg_miss = legend(s2, legendObjects_misses, {'Go Trial Start', 'Single Responses', 'Mean Trace', 'Median Trace'});
    xlabel(s1, 'Time (s)')
    xlabel(s2, 'Time (s)')
    ylabel(s1, 'Delta F over F')
    ylim(s1, [0,df_f0_max])
    ylim(s2, [0,df_f0_max])
    
    title(s1, ['Neuronal Responses to hit trials - Roi # ', num2str(roi, '%03d')])
    title(s2, ['Neuronal Responses to miss trials - Roi # ', num2str(roi, '%03d')])
    
    
    fig2png(fig, fullfile(figureFolder, [figureNamePrefix, num2str(roi, '%03d'), '.png']))
    close(fig)
end
    
end
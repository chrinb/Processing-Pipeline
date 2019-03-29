% Detect all licks.


% 1 second before lick and 4 seconds after.
function analyseNoGoTrials(sessionID)


sessionData = getSessionData(sessionID);
sessionFolder = getSessionFolder(sessionID);

figureFolder = fullfile(sessionFolder, 'figures', 'noGoTrial');
if ~exist(figureFolder, 'dir'); mkdir(figureFolder); end
figureNamePrefix = [sessionID, '_nogoResponse_roi_'];

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

rotStop = find(transitions == -1);
positions = angles(rotStop+5);

gotrials = find(positions == 0);
nogotrials_v1 = find(positions == 120);
nogotrials_v2 = find(positions == 240);

gotrialStartIdx = rotStop(gotrials);
nogotrials_v1_StartIdx = rotStop(nogotrials_v1);
nogotrials_v2_StartIdx = rotStop(nogotrials_v2);

% Set up colormap
cmap = hsv(365);


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
    meanTrace_nogo1 = zeros(length(timePoints), 1);
    meanTrace_nogo2 = zeros(length(timePoints), 1);
    medianTrace_nogo1 = zeros(length(timePoints), length(nogotrials_v1));
    medianTrace_nogo2 = zeros(length(timePoints), length(nogotrials_v2));
    
    legendObjects_nogo1 = gobjects(4,1);
    legendObjects_nogo2 = gobjects(4,1);
    
    for i = 1:length(nogotrials_v1)
        
        % Initiate plot
        if i == 1
            legendObjects_nogo1(1) = plot(s1, [0,0], [0,df_f0_max], '--k');
            legendObjects_nogo2(1) = plot(s2, [0,0], [0,df_f0_max], '--k');
            %plot(timePoints, waterTrace, 'g');
            hold(s1, 'on')
            hold(s2, 'on')
            xPatch = [-1, 4, 4, -1];
            yPatch = [0, 0, df_f0_max, df_f0_max];
            patch(xPatch, yPatch, cmap(120+1,:), 'facealpha', 0.1,'edgecolor','none', 'Parent', s1)
            patch(xPatch, yPatch, cmap(240+1,:), 'facealpha', 0.1,'edgecolor','none', 'Parent', s2)
        end
        
        % Extract signal around water reward.
        roiTrace = sessionData.deltaFoverFch2(1, roi, nogotrials_v1_StartIdx(i) + (-preSamples:postSamples));
        % Normalize
        roiTrace = squeeze(roiTrace);
        
        % Plot the line
        roiLine_nogo1 = plot(s1, timePoints, roiTrace, 'Color', [0.6, 0.6, 0.6]);
        % Add trace to median and mean arrays.
        meanTrace_nogo1 = meanTrace_nogo1 + roiTrace;
        medianTrace_nogo1(:, i) = roiTrace;
        
    end
    
    for i = 1:length(nogotrials_v2)
        
        % Extract signal around water reward.
        roiTrace = sessionData.deltaFoverFch2(1, roi, nogotrials_v2_StartIdx(i) + (-preSamples:postSamples));
        % Normalize
        roiTrace = squeeze(roiTrace);

        roiLine_nogo2 = plot(s2, timePoints, roiTrace, 'Color', [0.6, 0.6, 0.6]);
        % Add trace to median and mean arrays.
        meanTrace_nogo2 = meanTrace_nogo2 + roiTrace;
        medianTrace_nogo2(:, i) = roiTrace;
    end

    
    legendObjects_nogo1(2) = roiLine_nogo1;
    legendObjects_nogo2(2) = roiLine_nogo2;
    meanTrace_nogo1 = meanTrace_nogo1 /length(nogotrials_v1);
    medianTrace_nogo1 = median(medianTrace_nogo1, 2); % Double Check This!!!!
    
    meanTrace_nogo2 = meanTrace_nogo2 / length(nogotrials_v2);
    medianTrace_nogo2 = median(medianTrace_nogo2, 2); % Double Check This!!!!
    
    legendObjects_nogo1(3) = plot(s1, timePoints, meanTrace_nogo1, 'k'); % Plot in Bold
    legendObjects_nogo1(4) = plot(s1, timePoints, medianTrace_nogo1, 'r');
    
    legendObjects_nogo2(3) = plot(s2, timePoints, meanTrace_nogo2, 'k'); % Plot in Bold
    legendObjects_nogo2(4) = plot(s2, timePoints, medianTrace_nogo2, 'r');
    
    
    leg_hit = legend(s1, legendObjects_nogo1, {'NoGo Trial Start', 'Single Responses', 'Mean Trace', 'Median Trace'});
    leg_miss = legend(s2, legendObjects_nogo2, {'NoGo Trial Start', 'Single Responses', 'Mean Trace', 'Median Trace'});
    xlabel(s1, 'Time (s)')
    xlabel(s2, 'Time (s)')
    ylabel(s1, 'Delta F over F')
    ylim(s1, [0,df_f0_max])
    ylim(s2, [0,df_f0_max])
    
    title(s1, ['Neuronal Responses to nogo trials (120deg) - Roi # ', num2str(roi, '%03d')])
    title(s2, ['Neuronal Responses to nogo trials (240deg) - Roi # ', num2str(roi, '%03d')])
    
    
    fig2png(fig, fullfile(figureFolder, [figureNamePrefix, num2str(roi, '%03d'), '.png']))
    close(fig)
end
    
end
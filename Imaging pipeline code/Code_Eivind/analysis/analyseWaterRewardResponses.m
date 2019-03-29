% Detect all licks.


% 1 second before lick and 4 seconds after.
function analyseWaterRewardResponses(sessionID)


sessionData = getSessionData(sessionID);
sessionFolder = getSessionFolder(sessionID);

figureFolder = fullfile(sessionFolder, 'figures', 'waterRewardResponsesDF_f0');
if ~exist(figureFolder, 'dir'); mkdir(figureFolder); end
figureNamePrefix = [sessionID, '_waterResponse_roi_'];

water = sessionData.waterRewards(1, :);
waterGiven = diff(water);

waterStart = find(waterGiven == 1);
waterStop = find(waterGiven == -1);

waterDuration = waterStop(1) - waterStart(1);

waterInterval = diff(waterStart);

fps = 31;
preSamples = 1*fps;
postSamples = 4*fps;

timePoints = (-preSamples:postSamples) / fps;

df_f0_max = max(max(sessionData.deltaFoverFch2(1, :, :)));

for roi = 1:sessionData.nRois
    fig = figure('Visible', 'off');
    
    roiSignalMax = max(sessionData.deltaFoverFch2(1, roi, :));
    meanTrace = zeros(length(timePoints), 1);
    medianTrace = zeros(length(timePoints), length(waterStart));
    
    legendObjects = gobjects(4,1);
    
    for i = 1:length(waterStart)
        
        if i == 1
            waterTrace = water(waterStart(i) + (-preSamples:postSamples));
            %plot(timePoints, waterTrace, 'g');
            hold on
            
            xPatch = [0, waterDuration/fps, waterDuration/fps, 0];
            yPatch = [0,0,df_f0_max,df_f0_max];
            legendObjects(1) = patch(xPatch, yPatch, 'g', 'facealpha', 0.2,'edgecolor','none');
            
        end
        
        % Extract signal around water reward.
        roiTrace = sessionData.deltaFoverFch2(1, roi, waterStart(i) + (-preSamples:postSamples));
        % Normalize
        roiTrace = squeeze(roiTrace);
        
        % Plot the line
        roiLine = plot(timePoints, roiTrace, 'Color', [0.6, 0.6, 0.6]);
        
        % Add trace to median and mean arrays.
        meanTrace = meanTrace + roiTrace;
        medianTrace(:, i) = roiTrace;

    end
    
    legendObjects(2) = roiLine;
    meanTrace = meanTrace / length(waterStart);
    medianTrace = median(medianTrace, 2); % Double Check This!!!!
    
    legendObjects(3) = plot(timePoints, meanTrace, 'k'); % Plot in Bold
    legendObjects(4) = plot(timePoints, medianTrace, 'r');
    leg = legend(legendObjects, {'Water Reward', 'Single Responses', 'Mean Trace', 'Median Trace'});
    xlabel('Time (s)')
    ylabel('Delta F over F')
    ylim([0,df_f0_max])
    
    title(['Neuronal Responses to water Reward - Roi # ', num2str(roi, '%03d')])
    
    fig2png(fig, fullfile(figureFolder, [figureNamePrefix, num2str(roi, '%03d'), '.png']))
    close(fig)
end
    
end
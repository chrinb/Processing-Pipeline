function [xData, yData] = getEventPatchCoordinates(eventVector, yLim)

    if any(eventVector)

        [start, stop] = rmUtil.findTransitions(eventVector);
        
        xData = zeros(length(start), 4);
        yData = zeros(length(start), 4);

        xData(:,1) = start;
        xData(:,2) = stop;
        xData(:,3) = stop;
        xData(:,4) = start;

        yData(:,1:2) = yLim(1);
        yData(:,3:4) = yLim(2);
    else 
        xData = [];
        yData = [];
    end

end
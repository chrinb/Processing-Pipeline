roiArray = RoI.empty;

%count rois that are cells
isCell = cell2mat(arrayfun(@(x) x.iscell, stat, 'uni', 0));
nCells = length(isCell);

for i = 1:nCells
    
    roimask = zeros(341, 341);
    
    if stat(i).iscell
    
        xpix = stat(i).xpix;
        ypix = stat(i).ypix;

        for p = 1:numel(xpix)
            roimask(ypix(p), xpix(p)) = 1;
        end


        %loop through all rois pass roi mask to RoI
        newRoI = RoI(roimask);    
        newRoI.Group = 'AutoDetected';
        newRoI.Shape = 'Outline';
        newRoI.ID = i;
        newRoI.Tag = [newRoI.Group(1:4), num2str(i,'%03d')];
        roiArray(end+1) = newRoI;
    else
        continue
    end

end
    
saveToFile(roiArray, '/Users/eivinhen/desktop/autoroi_v3.mat')
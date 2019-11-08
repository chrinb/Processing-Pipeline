function roiArrays = synchRoiArrays(roiArrays)

    roiUIDs = cell(numel(roiArrays), 1);
    for i = 1:numel(roiArrays)
        if ~isempty(roiArrays{i})
            roiUIDs(i) = {{roiArrays{i}(:).uid}};
        end
    end
    
    uniqueIds = unique(cat(2, roiUIDs{:}));
    
    % Find which rois are missing in each array.
    missingRoiIds = cell(numel(roiArrays), 1);
    for i = 1:numel(roiArrays)
        if ~isempty(roiArrays{i})
            missingRoiIds(i) = {setdiff(uniqueIds, roiUIDs{i})};
        end
    end
    
    uniqueMissing = unique(cat(2, missingRoiIds{:}));
    
    % Find missing rois
    missingRois = {};
    for i = 1:numel(roiArrays)
        if ~isempty(roiArrays{i})
            
            roiMatch = contains({roiArrays{i}(:).uid}, uniqueMissing);
            
            if isempty(roiMatch)
                continue
            end
            
            foundRois = roiArrays{i}(roiMatch);
            
            if ~isa(foundRois, 'struct')
                foundRois = utilities.roiarray2struct(foundRois);
            end
            
            if isempty(missingRois)
                missingRois = foundRois;
            else
                missingRois = cat(2, missingRois, foundRois);
            end
            
            uniqueMissing = setdiff(uniqueMissing, {foundRois(:).uid});
            
            if isempty(uniqueMissing)
                break
            end
        end
    end
    
    
    for i = 1:numel(roiArrays)
        if ~isempty(missingRoiIds{i})
            rois2add = contains({missingRois(:).uid}, missingRoiIds{i});
            
            if isa(roiArrays{i}, 'RoI')
                roiArrays{i} = cat(2, roiArrays{i}, utilities.struct2roiarray(missingRois(rois2add)));
            else
                roiArrays{i} = cat(2, roiArrays{i}, missingRois(rois2add));
            end
            
        end
    end
        
        
end       
    
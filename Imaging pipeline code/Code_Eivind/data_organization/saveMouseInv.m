function [ ] = saveMouseInv( mouseInventory )
%saveMouseInv Sort and save mouse inventory
%   saveMouseInv( mouseInventory ) saves a database with mouse metadata
%   objects to mat file in a path specified in pipeline_settings/getPathToDir
%
%   NB: Will overwrite existing file
    
    mouseInventoryPath = fullfile(getPathToDir('labbook'), 'mouseInventory.mat' );

    % Sort mouse inventory
    [~, Idx] = sort(mouseInventory(:,1));
    mouseInventory = mouseInventory(Idx, :);

    % Save mouse inventory
    save(mouseInventoryPath, 'mouseInventory')

end


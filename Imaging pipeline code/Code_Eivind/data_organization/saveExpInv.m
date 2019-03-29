function [ ] = saveExpInv( experimentInventory )
%saveExpInv Sort and save experiment inventory
%
% NB: Will overwrite existing file
    
    expInventoryPath = fullfile(getPathToDir('labbook'), 'experimentInventory.mat' );

    % Sort experiment inventory
    [~, Idx] = sort(experimentInventory(:,1));
    experimentInventory = experimentInventory(Idx, :);

    % Save experiment inventory
    save(expInventoryPath, 'experimentInventory')

end


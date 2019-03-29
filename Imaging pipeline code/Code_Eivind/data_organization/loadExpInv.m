function [ experimentInventory ] = loadExpInv( )
%loadExpInv Load experiment inventory if it exists.

    % Path to experiment inventory
    expInventoryPath = fullfile(getPathToDir('labbook'), 'experimentInventory.mat');

    % Load or create new experiment inventory 
    if (exist(expInventoryPath, 'file') == 2)
        load(expInventoryPath);
    else
        experimentInventory = cell(0, 2);
        experimentInventory(1,:) = {'SessionId', 'Session Object'};
    end

end


function [ mouseInventory ] = loadMouseInv( )
%loadMouseInv Load mouse inventory if it exists.

    % Path to mouse inventory
    mouseInventoryPath = fullfile(getPathToDir('labbook'), 'mouseInventory.mat');

    % Load or create new mouse inventory 
    if (exist(mouseInventoryPath, 'file') == 2)
        load(mouseInventoryPath);
    else
        mouseInventory = cell(0, 2);
        mouseInventory(1,:) = {'MouseId', 'Mouse Object'};
    end

end

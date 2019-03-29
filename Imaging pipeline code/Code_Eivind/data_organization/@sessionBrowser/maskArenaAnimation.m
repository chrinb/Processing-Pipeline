function maskArenaAnimation(ax)

im = findobj(ax, 'Type', 'Image');

[num_row, num_col] = size(im.CData(:,:,1));

% Define center coordinates and radius
x = num_row/2;
y = num_col/2;
radius = 105;

% Generate grid with binary mask representing the circle. Credit
%StackOverflow??
[xx, yy] = ndgrid((1:num_row) - y, (1:num_col) - x);
mask = (xx.^2 + yy.^2) > radius^2;

mask = ~mask;

set(im, 'alphadata', mask)

%set(browser.axArenaAnimation,'color','none');
%set(browser.axArenaAnimation, 'visible', 'off') ;
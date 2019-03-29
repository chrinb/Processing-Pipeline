function fig2png(fig, filename)
%fig2png Generate a png file of the current figure with
%   dimensions consistent with the figure's screen dimensions.
%
%   fig2png(fig, 'filename') saves the figure (fig) to the
%   png file "filename".
%
%    Sean P. McCarthy
%    Copyright (c) 1984-98 by MathWorks, Inc. All Rights Reserved

if nargin < 1
     error('Not enough input arguments!')
end

oldscreenunits = get(fig,'Units');
oldpaperunits = get(fig,'PaperUnits');
oldpaperpos = get(fig,'PaperPosition');
set(fig,'Units','pixels');
scrpos = get(fig, 'Position');
newpos = scrpos/100;
set(fig,'PaperUnits','inches',...
     'PaperPosition',newpos)
print(fig, '-dpng', filename, '-r100');
drawnow
set(fig,'Units',oldscreenunits,...
     'PaperUnits',oldpaperunits,...
     'PaperPosition',oldpaperpos)

end


function [ new_im ] = correctResonanceStretch( im, zoom, binSize)
%correctResonanceStretch Corrects the resonance mirror "stretch effect".
%   IM = correctResonanceStretch( IM, ZOOM, BINSIZE) splits image (IM) into strips of 
%   width BINSIZE and compresses each bin according to a predetermined lookuptable, which 
%   for each ZOOM Factor, contains the relationship between the image stretch and the 
%   distance from the center of the image. Available ZOOM Factors : 1, 2.
%
%   Check out find_resonance_profile.m and polyfit_lookup.m for hints on how to 
%   add lookup tables for different zoom factors.

if nargin < 3
    binSize = 16;
end
 useZoomTwo = 0;
if zoom ~= 1 && zoom ~= 2
    warning('Resonance stretch lookup does not exist for the zoom factor used. Zoom factor 2 used as alternative')
    useZoomTwo = 1;
    %     new_im = im;
%     return
end

% Get size of images
if length(size(im)) == 2
    [height, width] = size(im);
    nFrames = 1;
elseif length(size(im)) == 3
    [height, width, nFrames] = size(im);
end 

prevstr=[];

% BinSize should be factor of image width
assert( mod(width, binSize) == 0, 'BinSize should be a factor of image width' )


% % Make half a cosine and mirror it around y-axis.
% x = linspace(0, pi*lineDutyCycle/2, 256);
% y = -scaleFactor*cos(x) + scaleFactor;
% y = [fliplr(y), y];

% use a poly from a lookuptable
% lookup_table = load('polyfit_lookup.mat');
% y = polyval(lookup_table.(['p_zoom', num2str(zoom)]), 1:width);

lookup_table = load('spline_interp_stretch.mat');
%----FORCE LOOKUP AT x1 ZOOM

if useZoomTwo == 1
    y = lookup_table.(['stretch_zoom', '2']); %y = lookup_table.(['stretch_zoom', num2str(zoom)]);
else
    y = lookup_table.(['stretch_zoom', num2str(zoom)]);
end

% Find the incremental changes in speed of mirror
%diffY = abs(diff(y));
diffY = diff(y);
diffY(1:255) = diffY(1:255)* -1;
diffY = horzcat(diffY(1), diffY);

% Calculate new binsizes for all the bins. NB: It works very well to use floor
% here. This might not be a general thing... (floor for the sinusoid. might
% be because the sinusoid doesnt fit very well
newBinSizes = binSize - round(sum(reshape(diffY,  [], 512/binSize), 1));

% Create empty image stack (preallocate)
imInfo = whos('im');
newWidth = sum(newBinSizes);
new_im = zeros(height, newWidth, nFrames, imInfo.class);

% Create indices for putting image stripes into new image stack
newBinStartIdx = horzcat(1, cumsum(newBinSizes) + 1);
newBinStopIdx = horzcat(cumsum(newBinSizes));

for n = 1:nFrames
    % Loop through image. Split into stripes and compress each stripe based on sinusoid.
    c = 0;
    for bin = 1:binSize:width
        imStrip = im(:, bin:bin+binSize-1, n);
        c = c+1;
        imStrip = imresize(imStrip, [height, newBinSizes(c)]);
        new_im(:, newBinStartIdx(c):newBinStopIdx(c), n) = imStrip; 
    end
    
    % Print progress in command window
    if mod(n, 50) == 0
        str=['squeezing frame ' num2str(n) '/' num2str(nFrames)];
        refreshdisp(str, prevstr, n);
        prevstr=str;
    end
    
end

% Print finish message in command window
fprintf(char(8*ones(1,length(prevstr))));
fprintf('Squeezed all images.');
fprintf('\n');

% Make image square
if height == width
    new_im = new_im((1:newWidth) + floor((width-newWidth)/2), :, :);
end

% Remove singleton dimension...
new_im = squeeze(new_im);

end


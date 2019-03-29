function [ imArray ] = loadSciScanStack( folderpath, ch, first_frame, last_frame )
%loadSciScanStack Load a SciScan raw file into a matlab array
%   A = loadSciScanStack(FOLDERPATH) returns an array of images (uint8) from all 
%   channels of a SciScan recording saved in a folder specified by FOLDERPATH.
%
%   A = loadSciScanStack(PATH, CH) returns an array of images from the channel
%   specified by CH (CH is an integer).
%
%   A = loadSciScanStack(PATH, CH, FIRST_FRAME, LAST_FRAME) returns an array of images 
%   from the channel specified by CH (CH is an integer), starting at FIRST_FRAME and 
%   ending at LAST_FRAME.
%
%   This function takes some time because, in addition to loading images,
%   it also corrects for a stretching effect that occurs during
%   acquisition. The resonance mirror has a sinusoidal movement profile,
%   moving slower around the edges of the image, making the images edges appear
%   stretched out.
%
%   see also getSciScanMetaData, correctResonanceStretch
 

if nargin < 2
    ch = 'all';
end

if nargin < 3
    first_frame = 1;
    last_frame = -1;
end

% find raw file:
raw_file = dir(fullfile(folderpath, '*.raw'));
raw_file_path = fullfile(folderpath, raw_file(1).name);

% if images are lineshifted, rename file to "default name"
if ~isempty(strfind(raw_file_path, '.lineshifted'))
    renamed_raw_file = strrep(raw_file_path, '.lineshifted', '');
    movefile(raw_file_path, renamed_raw_file)
    raw_file_path = renamed_raw_file;
end
raw_file_path = strrep(raw_file_path, '.lineshifted', '');

% switch channel number to string
if ch == 1; ch = 'first'; elseif ch == 2; ch = 'second'; end

% obtain number of frames from ini file
[pathstr, filenameWOext] = fileparts(raw_file_path);
inifilename=[filenameWOext '.ini'];
inistring=fileread(fullfile(pathstr,inifilename));
zoom = readVarIni(inistring,'ZOOM');

% read images into array
%imArray = readrawfile(raw_file_path, 0, 'all', 400);
if last_frame == -1
    imArray = readrawfile(raw_file_path, first_frame-1, ch);
else 
    imArray = readrawfile(raw_file_path, first_frame-1, ch, last_frame - (first_frame-1));
end

% Permute because loading of images mixes x and y dimension. This only
% works when loading single channel stacks?
imArray = permute(imArray, [2,1,3]);

Y = double(imArray);
% Correct for bidirectional scanning. Requires NormCorre.
[~, M] = correct_bidirectional_offset(Y, size(Y, 3),1);

imArray = M;

%----------------- THIS CAN BE TURNED ON TO REMOVE THE STRETCHING EFFECT IN THE CORNERS
% Correct stretching of images due to the sinusoidal movement profile 
% of the resonance mirror
maxImArray = max(imArray(:));
minImArray = min(imArray(:));

imArray = correctResonanceStretch(imArray, zoom); 
imArray(imArray<minImArray) = minImArray;
imArray(imArray>maxImArray) = maxImArray;
%---------------------------------------------

% "Normalize" and convert to uint8
if first_frame == 1
    sortedValues = sort(imArray(:));
    subtractValue = median(sortedValues(1:100));
    imArray = imArray - subtractValue;
    normalizingFactor = (65536/2)/256;
    imArray = double(imArray) / normalizingFactor;
    save imCorrVariables.mat subtractValue normalizingFactor

else
    load('imCorrVariables.mat');
    imArray = imArray - subtractValue;
    imArray = double(imArray) / normalizingFactor;
end
% if first_frame == 1
%     darkestValue = min(imArray(:));
%     imArray = imArray - darkestValue;
%     save darkestValue.mat darkestValue
% else
%     load('darkestValue.mat');
%     imArray = imArray - darkestValue;
% end
% 
% imArray = double(imArray);
% imArray = (imArray/(65536/2))*255;
imArray = uint8(imArray);
end


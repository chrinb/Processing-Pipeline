function [ metadata ] = getSciScanMetaData( path, metadata )
%getSciScanMetaData Return metadata from a SciScan recording.
%   M = getSciScanMetaData(PATH) returns a struct with metadata (M) from a recording specified 
%   by PATH, where PATH is the path to a folder containing data from a SciScan recording.
%
%   M = getSciScanMetaData(PATH, M) updates a metadata (M) file by concatenating info 
%   to some of the output fields (nBlocks, nFrames, times).
%
%   The idea of this function is to get metadata either from one recording
%   or from multiple blocks of recordings. By looping through a set of
%   "blockfolders" and passing the metadata from the previous iteration to
%   this function, the following fields are updated with data from the most
%   recent block: nBlocks, nFrames, times.
%   All other fields are assumed constant throughout a block recording and
%   is only retrieved from the first of multiple blocks of recordings
%
%   Returned Fields:
%       - microscope    :   SciScan
%       - dt            :   interframe interval
%       - xpixels       :   width of image in pixels
%       - ypixels       :   height of image in pixels
%       - objective     :   not necessary for now (not added)
%       - zoomFactor    :   zoomfactor during the recording
%       - pmtCh2        :   missing - can we implement??
%       - pmtCh3        :   missing - can we implement??
%       - zPosition     :   relative z position of microscope during data acquistion
%       - umPerPx_x     :   um per pixel conversion factor along x axis
%       - umPerPx_y     :   um per pixel conversion factor along y axis
%       - nCh           :   number of channels acquired
%       - channels      :   list of channels that are recorded (e.g. [2, 3])
%       - channelNames  :   list of corresponding channel names e.g. {Ch2, Ch3}
%       - channelColor  :   list of corresponding color for each channel e.g. {green, red}
%       - nBlocks       :   number of blocks (incremented every time metadata is updated)
%       - nFrames       :   array of nFrames per block
%       - times         :   array of time vectors per recording per block
%
%       see also loadSciScanStack
%
% Written by EH. Modified for piezo by AL.

if nargin < 2
    metadata = struct();
end

ini_file = dir(fullfile(path, '*.ini'));
imj_file = dir(fullfile(path, '*IJmacro.txt'));
inifilepath = fullfile(path, ini_file(1).name);
imjfilepath = fullfile(path, imj_file(1).name);
inistring = fileread(inifilepath);
imjstring = fileread(imjfilepath);

if isempty(fieldnames(metadata))
    
    metadata.microscope = 'SciScan';
    metadata.xpixels=readVarIni(inistring,'x.pixels');
    metadata.ypixels=readVarIni(inistring,'y.pixels');
    aqu_freq=readVarIni(inistring,'frames.p.sec'); 
    metadata.dt = 1/aqu_freq;
    
    % Detect settings for when the piezo is used.
    metadata.piezoNumberOfPlanes = readVarIni(inistring,'frames.per.z.cycle');
    piz = readVarIni(inistring,'piezo.active');
    if (piz(2:5) == 'TRUE')
        metadata.piezoActive = true;
    else
        metadata.piezoActive = false;
    end
    % Detect if zig-zag or sawtooth mode for piezo
    piz_mode = readVarIni(inistring,'piezo.mode');
    if (piz_mode(2:5) == 'TRUE')
        metadata.piezoMode = 'saw';
    else
        metadata.piezoMode = 'zig';
    end
% Add metadata.times. Should be a cell array of array with timevec.
    metadata.zoomFactor = readVarIni(inistring,'ZOOM');
    metadata.zPosition = abs(readVarIni(inistring,'setZ'));
    xfov = abs(readVarIni(inistring,'x.fov'));
    yfov = abs(readVarIni(inistring,'y.fov'));

    metadata.umPerPx_x = xfov / metadata.xpixels;
    metadata.umPerPx_y = yfov / metadata.ypixels;
    
    colors = {'Red', 'Green', 'N/A', 'N/A'};
    metadata.channels = [];
    metadata.channelNames = {};
    metadata.channelColor = {};
    for ch = 1:4
        if strcmp(strtrim(readVarIni(inistring, ['save.ch.', num2str(ch)])), 'TRUE')
            metadata.channelNames{end+1} = ['Ch', num2str(ch)];
            metadata.channelColor{end+1} = colors{ch};
            metadata.channels(end+1) = ch;
        end
    end
    
    metadata.nCh = length(metadata.channels);

    metadata.nBlocks = 0;
    metadata.nFrames = [];
    metadata.times = {};
end

metadata.nBlocks = metadata.nBlocks + 1;
%metadata.nFrames(end+1) = readVarIni(inistring, 'no.of.frames.acquired');
metadata.nFrames(end+1) = 18672;

%Get number of images from imageJ macro file for now. Should be added to
%inifile
% ind1 = strfind(imjstring, 'number=');
% ind2 = strfind(imjstring, ' ');
% varstring = imjstring(ind1+7:ind2(ind2>ind1(1)));
% metadata.nFrames(end+1) = str2double(varstring);

metadata.times{end+1} = linspace(0, metadata.nFrames(end)*metadata.dt, metadata.nFrames(end));
end
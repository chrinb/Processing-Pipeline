function [ ] = addSessionToLabbook( sessionID )
%addSessionToLabbook Summary of this function goes here
%   Detailed explanation goes here


% Load session data 
try
    load(fullfile(getPathToDir('labbook'), 'sessionData', ...
                  strcat('session-', sessionID, '-data.mat')))
catch
    disp('Could not find session data on disk')
end


% Create tex file for session in labbook tex folder
tex_file = fullfile(getPathToDir('labbook_tex'), [sessionID, '.tex']);
        
fid = fopen(tex_file, 'w');

writeTex(fid, '\newpage')
writeTex(fid, ['\subsection{' sessionID '}']) % Call by session Id or by session No.
writeTex(fid, '\begin{table}[ht]')
writeTex(fid, '\noindent\begin{tabular*}{\linewidth}{@{\extracolsep{\fill} } llll}')
writeTex(fid, '\multicolumn{4}{l}{\bfseries Session Info} \\')
writeTex(fid, '\hline')
writeTex(fid, ['Date: & ' sessionData.dateOfExperiment  ...
               ' & Session Protocol: & ' sessionData.sessionProtocol ' \\'] )
writeTex(fid, ['Nblocks: & ' num2str(sessionData.nBlocks) ...
               ' & Duration: & ' num2str(sessionData.sessionDuration) ' min \\'])
writeTex(fid, ['Ntrials per block: & ' num2str(size(sessionData.trialSpecifications, 1)) ...
               ' & Intertrial interval: & ' num2str(sessionData.intertrialInterval) ' sec \\'])
writeTex(fid, '\\')
writeTex(fid, '\end{tabular*}')
writeTex(fid, '\noindent\begin{tabular*}{\linewidth}{@{\extracolsep{\fill} } llllll}')
writeTex(fid, '\multicolumn{6}{l}{\bfseries Microscope Info} \\')
writeTex(fid, '\hline')
%TODO add laser power
writeTex(fid, ['PMT ch2: & ' num2str(sessionData.pmtCh2, 3) ' & ' ... 
               'PMT ch3: & ' num2str(sessionData.pmtCh3, 3) ' & ' ...
               'Laser Power: & ' 'N/E' ' \\'])
writeTex(fid, '\\')
writeTex(fid, '\multicolumn{6}{l}{\bfseries Population Info} \\')
writeTex(fid, '\hline')
writeTex(fid, '\end{tabular*}')
writeTex(fid, '\begin{minipage}[t]{0.55\linewidth}')
writeTex(fid, '\vspace{1mm}')


%Todo: 
% 1. Find mean image from alignment. Open stack used for rois and take e.g.
% 1st image
sessionFolder = getSessionFolder(sessionID);
im = imread(fullfile(sessionFolder, 'alignedAvgAllBlocksCh2.tif'), 1);
roiArr = load(fullfile(sessionFolder, 'roi_arr_ch1.mat'));
roiArr = roiArr.roi_arr;
% 2. Loop through rois and draw rois into image and mark with number.
for r = 1:length(roiArr)
    coords = roiArr(1,r).Boundary{1, 1};
    for i = 1:length(coords)
        im(coords(i,1), coords(i,2)) = 255;
    end
    textCoords = [max(coords(:,2)), min(coords(:,1))];
    im = insertText(im, textCoords, num2str(r), 'TextColor', 'white', 'BoxOpacity', 0);
end
% end

% 3. Save to file and load here.
im_path = fullfile(getPathToDir('labbook'), 'imaged_populations', [sessionID, '.png']);
imwrite(im, im_path);

im_path = strrep(im_path, ' ', '" "');

writeTex(fid, ['\includegraphics[width=\textwidth]{' im_path '}'])
writeTex(fid, '\end{minipage}')
writeTex(fid, '\begin{minipage}[t]{0.45\linewidth}')
writeTex(fid, '\hfill \begin{tabular}[t]{ll}')
writeTex(fid, '\\')
% Todo: Add population ID to session Data.
writeTex(fid, 'Population: & N/E \\')
writeTex(fid, ['Location N: & ' num2str(sessionData.LocationID) ' \\'])
writeTex(fid, ['$\Delta$ S to bregma: & ' '2 mm' ' \\'])
writeTex(fid, ['$\Delta$ S to midline: & ' '-0.3 mm' ' \\'])
% if deltaS < 0, hemisphere = 'left'; else, hemisphere = right; end
writeTex(fid, ['Hemisphere: & ' 'Left' ' \\'])
writeTex(fid, ['Depth: & ' num2str(sessionData.imDepth, 3) ' um \\'])
writeTex(fid, ['Number of cells: & ' num2str(sessionData.nRois) ' \\'])

% Calculate and add FOV size to session Data
fovSize = sessionData.umPerPx * fliplr(size(im));
writeTex(fid, ['FOV Size: & ' num2str(fovSize(2), 3) ' x ' ... 
               num2str(fovSize(3), 3) ' um \\'])
% Todo make a compound variable for frame movement
writeTex(fid, 'Frame movement: & Compound?\\')
writeTex(fid, '\end{tabular}')
writeTex(fid, '\end{minipage}')
writeTex(fid, '\end{table}')

writeTex(fid, '\noindent\begin{tabular*}{\linewidth}{@{\extracolsep{\fill} } l}')
writeTex(fid, '{\bfseries Activity Summary} \\')
writeTex(fid, '\hline')
writeTex(fid, '\end{tabular*}')

summaryPath = fullfile(getPathToDir('labbook'), 'sessionData', 'summary_plots', ...
                       ['session-', sessionID, '.png']);
if ~(exist(summaryPath, 'file')==2)
    try
        makeSummaryPlot(sessionID)
    catch
        summaryPath = '';
    end        
end

if ~isempty(summaryPath)
    summaryPath = strrep(summaryPath, ' ', '" "');
                   
    writeTex(fid, ['\includegraphics[width=\linewidth]{' summaryPath '}'])
end
%Todo: Make a summary figure with events for all blocks.

% Show figure of identified event for all cells and all blocks, like a PSTH?


% Close tex-file
fclose(fid);

end


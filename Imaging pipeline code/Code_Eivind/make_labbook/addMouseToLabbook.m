function [ ] = addMouseToLabbook( mouseID )
%addMouseToLabbook Writes info from mouse object to a page in the labbook

mouseNo = str2double(mouseID(end-2:end));
mInf = mouse(mouseNo);

mInf = formatPropsForTex(mInf);

% make mouse page
tex_file = fullfile(getPathToDir('labbook_tex'), [mouseID, '.tex']);
        
fid = fopen(tex_file, 'w');
writeTex(fid, '\newpage')
writeTex(fid, ['{\section{' mInf.mouseID '}']);

% Set up table with two boxes, one for image, one for info table.
writeTex(fid, '\begin{table}[ht]')
writeTex(fid, '\begin{minipage}[t]{0.6\linewidth}')

% Write table with to left-aligned columns ({ll})
% [t] to align top of table to vspace over image.
writeTex(fid, '\begin{tabular}[t]{ll}  ')            % use hFill to push it to the right. use use [b] to vertically align bottom of table to baseline of surrounding text, in this case the image which has baseline at bottom
writeTex(fid, '\\')
writeTex(fid, '\multicolumn{2}{l}{\bfseries Mouse info} \\')
writeTex(fid, '\hline')
writeTex(fid, ['mouseId: & ' mInf.mouseID '\\']) % &-new col, \\-new row 
writeTex(fid, ['headbar: & \' mInf.headbarID '\\'])

writeTex(fid, ['date of birth: & ' mInf.dateofBirth '\\'])

try
    mouseAge = num2str(age_weeks(mInf.surgeryDay, mInf.dateofBirth));
catch
    mouseAge = 'N/A';
end

writeTex(fid, ['surgery date: & ' mInf.surgeryDay ' (' mouseAge ' w.o.)\\'])
writeTex(fid, ['habituation period: & ' mInf.startDateHabit '-' mInf.endDateHabit '\\'])
writeTex(fid, ['imaging period: & ' mInf.startDateImaging '-' mInf.endDateImaging '\\'])
writeTex(fid, ['euthanised: & ' mInf.dateSacrificed '\\'])
writeTex(fid, '\\')
writeTex(fid, '\end{tabular}')
writeTex(fid, '\end{minipage}')
writeTex(fid, '\begin{minipage}[t]{0.4\linewidth}')
writeTex(fid, '\vspace{1mm}')

im_path = fullfile(getPathToDir('labbook'), 'mouseInfo', ...
                   'mouse_pictures', [mouseID, '.jpg']);
if ~isempty(mInf.mousePortrait)
    imwrite(mInf.mousePortrait, im_path);
    im_path = regexprep(im_path, ' ', '" "');
    writeTex(fid, ['\includegraphics[width=0.8\textwidth]{' im_path '}'])
end

writeTex(fid, '\end{minipage}')
writeTex(fid, '\end{table}')

% Animal facility info to table
writeTex(fid, '\noindent\begin{tabular*}{\linewidth}{@{\extracolsep{\fill} } lllllll}')
writeTex(fid, '\\')
writeTex(fid, '\multicolumn{2}{l}{\bfseries Animal Facility info} \\')
writeTex(fid, '\hline')
writeTex(fid, ['mouseId: & ' mInf.mouseNumber ' & Location: & ' ...
                mInf.cageRoom ' & ' mInf.cageLocation ' &  Cage No: & ' ...
                mInf.cageNumber '\\'])
writeTex(fid, '\\')
writeTex(fid, '\end{tabular*}')

% Surgery info to table
writeTex(fid, '\begin{table}[ht]')
writeTex(fid, '\noindent\begin{tabular*}{\linewidth}{ll}')
writeTex(fid, '\multicolumn{2}{l}{\bfseries Surgery info} \\')
writeTex(fid, '\hline')
writeTex(fid, ['Surgery was performed according to the protocol: & ' mInf.surgeryProtocol '\\'])
writeTex(fid, '\end{tabular*}')
writeTex(fid, '\noindent\begin{tabular*}{\linewidth}{ll}')
writeTex(fid, ['Virus type: & ' mInf.injectedVirus '\\'])
writeTex(fid, '\\')
writeTex(fid, '\end{tabular*}')

writeTex(fid, '\begin{minipage}[t]{0.55\linewidth}')
writeTex(fid, '\vspace{1mm}')

% Add markers for injection spots to an image
injections_im = mInf.brainSurface;
if ischar(mInf.nInjections); mInf.nInjections = str2double(mInf.nInjections); end

for h = 1:mInf.nInjections
    x = mInf.injectionCoordsIM(h, 1);
    y = mInf.injectionCoordsIM(h, 2);
    
    injections_im = insertMarker(injections_im, [x, y], 'x', 'size', 3, ...
                                 'color', 'white');
    injections_im = insertText(injections_im, [x+15, y-14], ...
                               [' Inj. ' num2str(h)], 'FontSize', 18,  ...
                               'TextColor', 'white', 'BoxOpacity', 0);
end

im_path = fullfile(getPathToDir('labbook'), 'brain_surface', [mouseID, '-injections.png']);
imwrite(injections_im, im_path);

im_path = regexprep(im_path, ' ', '" "');
writeTex(fid, ['\includegraphics[width=0.8\textwidth]{' im_path '}'])

writeTex(fid, '\end{minipage}')
writeTex(fid, '\begin{minipage}[t]{0.45\linewidth}')
writeTex(fid, '\hfill \begin{tabular}[t]{lll}')              % use hFill to push it to the right. use use [b] to vertically align bottom of table to baseline of surrounding text, in this case the image which has baseline at bottom
writeTex(fid, '\\')
writeTex(fid, '\multicolumn{3}{l}{\underline {Virus Injections relative to bregma}} \\')
writeTex(fid, '\\')
writeTex(fid, '\multicolumn{3}{l}{Locations:} \\')
writeTex(fid, 'No & X & Y \\')

for i = 1:mInf.nInjections
    writeTex(fid, [num2str(i) ': & ' num2str(mInf.injectionCoordsRW(i, 1), '%.1f') ...
        ' mm & ' num2str(mInf.injectionCoordsRW(i, 2), '%.1f') ' mm \\'])
    
end

writeTex(fid, '\\')
writeTex(fid, ['\multicolumn{2}{l}{Injection Depth(s):} & ' mInf.injectionDepth ' um \\'])
writeTex(fid, '\\')
writeTex(fid, ['\multicolumn{2}{l}{Injection Volume:} & ' mInf.injectionVolumes ' nl \\'])
writeTex(fid, '\\')
writeTex(fid, ['\multicolumn{2}{l}{Injection Angle:} & ' mInf.injectionAngle ' deg\\'])
writeTex(fid, '\end{tabular}')
writeTex(fid, '\end{minipage}')
writeTex(fid, '\end{table}')

writeTex(fid, '\\')
writeTex(fid, '\noindent\begin{tabular}{p{\linewidth}}')
writeTex(fid, 'Comments: \\');
writeTex(fid, mInf.commentsSurgery)
writeTex(fid, '\end{tabular}');
writeTex(fid, '\\')

writeTex(fid, '\noindent\begin{tabular*}{\linewidth}{@{\extracolsep{\fill} } l}')
writeTex(fid, '\\')
writeTex(fid, '{\bfseries Habituation} \\')
writeTex(fid, '\hline')
writeTex(fid, '\end{tabular*}')
writeTex(fid, '\noindent\begin{tabular}{ll}')
writeTex(fid, ['Animals were habituated according to protocol: & ' mInf.habituationProtocol '\\'])
writeTex(fid, '\\')
writeTex(fid, '\end{tabular}')

writeTex(fid, '\\')
writeTex(fid, '\noindent\begin{tabular}{p{\linewidth}}')
writeTex(fid, 'Comments: \\');
writeTex(fid, mInf.commentsHabituation)
writeTex(fid, '\end{tabular}');
writeTex(fid, '\\')

% Write imaging summary
writeTex(fid, '\begin{table}')

writeTex(fid, '\noindent\begin{tabular*}{\linewidth}{ll}')
writeTex(fid, '\multicolumn{2}{l}{\bfseries Imaging Summary} \\')
writeTex(fid, '\hline')
writeTex(fid, '\end{tabular*}')

writeTex(fid, '\begin{minipage}[t]{0.60\linewidth}')
writeTex(fid, '\vspace{1mm}')

% Add image with rectangles illustrating imaging locations on brainsurface
imlocations_im = mInf.drawImagingLocations();
im_path = fullfile(getPathToDir('labbook'), 'brain_surface', [mouseID, '-imlocations.png']);
imwrite(imlocations_im, im_path);

im_path = strrep(im_path, ' ', '" "');
writeTex(fid, ['\includegraphics[width=0.9\textwidth]{' im_path '}'])
writeTex(fid, '\end{minipage}')
writeTex(fid, '\begin{minipage}[t]{0.40\linewidth}')
writeTex(fid, '\hfill \begin{tabular}[t]{lll}')
writeTex(fid, '\\')
writeTex(fid, '\multicolumn{3}{l}{\underline {Imaged Locations}} \\')
writeTex(fid, '\\')
writeTex(fid, '\multicolumn{3}{l}{Position relative to bregma:} \\')

% Display distance from bregma: 
writeTex(fid, 'No & X & Y \\')
for n = 1:mInf.nImagedLocations  
    writeTex(fid, [num2str(n) ': & ' num2str(mInf.imagingLocRWmm(n, 1), '%.1f') ' mm & ' ...
                   num2str(mInf.imagingLocRWmm(n, 2), '%.1f') ' mm \\'])
end
writeTex(fid, '\\')
writeTex(fid, '\end{tabular}')
writeTex(fid, '\end{minipage}')
writeTex(fid, '\end{table}')


% Load experimentInventory and find all sessions for current mouse
try
    expInv = load(fullfile(getPathToDir('labbook'), 'experimentInventory.mat'));
    expInv = expInv.experimentInventory;
    mId = strrep(mouseID, 'ouse', ''); % shorten mouse001 to m001
    mouseSessions = find(strncmp( expInv(:,1), mId, 4 ));
    if isempty(mouseSessions); mouseSessions = []; end
catch
    disp('Could not find experimentInventory on disk')
    mouseSessions = [];
end


% Loop through sessions and print out info into table:
% Date | Population | Protocol | SessionId

writeTex(fid, '\noindent\begin{tabular*}{\linewidth}{@{\extracolsep{\fill} } llllllll}')
writeTex(fid, '\\')
writeTex(fid, 'No & Date & Time & Loc & Depth & \multicolumn{3}{l}{Session Protocol} \\')
writeTex(fid, '\hline')

%TODO rewrite this to find properties of sessionObject.
cnt = 1;
for i = mouseSessions'
    session = expInv{i, 2};
    writeTex(fid, [ num2str(cnt) '. & ' session.date ' & ' session.time ' & '...
                    num2str(session.imLocation) ' & ' num2str(session.imDepth, 3) ... 
                    ' um & \multicolumn{3}{l}{' session.protocol '} \\'] )
    cnt = cnt+1;
end

writeTex(fid, '\\') % empty line before ending table
writeTex(fid, '\end{tabular*}')


% Close tex-file
fclose(fid);


end


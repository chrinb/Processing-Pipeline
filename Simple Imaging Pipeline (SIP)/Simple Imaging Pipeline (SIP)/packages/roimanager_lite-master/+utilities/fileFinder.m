% Open a figure window with a listbox and a button for adding files.
% Also, a button to cancel and one to ok..

function imfilePathCellarray = fileFinder(msg, filetype, initpath)

if nargin < 3; initpath = ''; end
if nargin < 2; filetype = ''; end
if nargin < 1; msg = 'Open and add files'; end

screenSize = get(0, 'ScreenSize');
figSize = [400, 300];
fontSize = 13;

figPos = screenSize(3:4) ./2 - figSize ./ 2;

% Create figure window
fig = figure('Position', [figPos, figSize]);
fig.MenuBar = 'none';
fig.NumberTitle = 'off';
fig.Name = 'Find Files';
fig.CloseRequestFcn = @cancel;

fig.UserData.initPath = initpath;
fig.UserData.ImFilePathArray = {};

% Create textbox on the top with a message
textbox = uicontrol('style', 'text');
textbox.Parent = fig;
textbox.Units = 'normalized';
textbox.Position = [0.05, 0.68, 0.9, 0.27];
textbox.BackgroundColor = fig.Color;
textbox.String = msg;
textbox.FontSize = 12;
textbox.HorizontalAlignment = 'left';

% Create listbox
listbox = uicontrol('style', 'listbox');
listbox.Parent = fig;
listbox.Units = 'normalized';
listbox.Position = [0.05, 0.15, 0.9, 0.5];
listbox.String = {};
listbox.Tag = 'Filename List';
listbox.FontSize = fontSize;

% Create buttons
buttonSize = [0.25, 0.08];
buttonPos = [ [0.2, 0.5, 0.8] - 0.125; [0.03, 0.03, 0.03] ];


buttonFinish = uicontrol('style', 'pushbutton');
buttonFinish.Parent = fig;
buttonFinish.Units = 'normalized';
buttonFinish.Position = [buttonPos(:,1)', buttonSize];
buttonFinish.String = 'Continue';
buttonFinish.Callback = @finish;
buttonFinish.FontSize = fontSize;

buttonAdd = uicontrol('style', 'pushbutton');
buttonAdd.Parent = fig;
buttonAdd.Units = 'normalized';
buttonAdd.Position = [buttonPos(:,2)', buttonSize];
buttonAdd.String = 'Add Files';
buttonAdd.Callback = {@addFiles, filetype};
buttonAdd.FontSize = fontSize;


buttonCancel = uicontrol('style', 'pushbutton');
buttonCancel.Parent = fig;
buttonCancel.Units = 'normalized';
buttonCancel.Position = [buttonPos(:,3)', buttonSize];
buttonCancel.String = 'Cancel';
buttonCancel.Callback = @cancel;
buttonCancel.FontSize = fontSize;

% addFiles(fig, [], filetype)
uiwait(fig)

imfilePathCellarray = fig.UserData.ImFilePathArray;
delete(fig)

end


function addFiles(src, ~, filetype)

%todo: create a cell of file type filters.
switch filetype
    case 'image'
        filefilter = {  '*tif;*.png;*.jpg;*.tiff', 'Image Files(*tif;*.png;*.jpg;*.tiff)'; ...
                        '*.*', 'All files(*.*)'};
    case 'mat'
        filefilter = {  '*.mat', 'Matlab Files (*.mat)';  ...
                        '*.*', 'All files(*.*)'};
    case 'binary'
        filefilter = {  '*.raw;*.bin', 'Binary Files (*.raw;*.bin)';  ...
                        '*.*', 'All files(*.*)'};
    otherwise
        filefilter = {'*.*', 'All files(*.*)'};

end

if isa(src, 'matlab.ui.control.UIControl')
    src = src.Parent;
end


if strcmp(filetype, 'folder')
%     fullPath = uigetdir2(src.UserData.initPath, 'Select Folders');
    fullPath = uigetdir(src.UserData.initPath, 'Select Folders');
    if isequal(fullPath, 0); return; end
    [~, filename] = fileparts(fullPath);
    fullPath = {fullPath}; filename = {filename};
else
    
    [filename, folder] = uigetfile(filefilter, 'Find Files', src.UserData.initPath, 'MultiSelect', 'on');

    if isequal(filename, 0); return; end

    if ~isa(filename, 'cell'); filename = {filename}; end

    fullPath = fullfile(folder, filename);
end

src.UserData.ImFilePathArray = cat(1, src.UserData.ImFilePathArray, fullPath');
listbox = findobj(src, 'Tag', 'Filename List');
listbox.String = cat(1, listbox.String, filename');

end


function finish(src, ~)
    uiresume(src.Parent)
end

function cancel(src, ~)
    if isa(src, 'matlab.ui.control.UIControl')
        src = src.Parent;
    end
    src.UserData.ImFilePathArray = {};
    uiresume(src)
end


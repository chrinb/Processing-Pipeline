classdef rotationAlignmentGUI < handle
    
    % Todos
    % - only load e.g. 1000 first frames
    % - load angles and images automatically
    % - load 1000 first images of raw file. load stage positions. if they dont exist, make
    % them    
    %
    % method for seeing how mean/max image changes by changing the center offset (on the fly) 
    % method for seeing how mean/max image changes by changing the angle (on the fly)
    % 
    % Input for delta x and y. Also, keypress for shifting 1 in each direction
    % Show/hide crosshair with circles on centre. Draggable circles??
    % plot(rgui.axStackDisplay, [rgui.imWidth/2, rgui.imWidth/2], rgui.axStackDisplay.YLim)
    % plot(rgui.axStackDisplay, rgui.axStackDisplay.XLim,  [rgui.imHeight/2, rgui.imHeight/2] )
    
properties
    
    fig                             % GUI Figure Window
    margins                         % Side margins within the GUI window
    padding                         % Padding between objects in the GUI window

    % UI panels

    sidePanelL                      % Left sidepanel
    imPanel                         % Image Panel for displaying tiffstack (center)
    sidePanelR                      % Right sidepanel
    
    % Ax and image for displaying the imagestack

    axStackDisplay                  % Axes to display images from the tiffstack
    imageObj                        % Image object for the displayed image
    
           
    mouseInv                        % A database of experimental mice
    expInv                          % A database of experimental sessions
    sessionID
    
    % Plot for showing stage pos
    
    axStagePosPlot
    stagePosPlotHandle = gobjects(0)
    plotFrameMarker
    
    % Image dimensions

    imWidth                         % Width (pixels) of images in tiff stack
    imHeight                        % Height (pixels) of images in tiff stack
    nFrames                         % Number of frames in tiff stack
    
    tiffStack                       % 
    shiftedStack
    rotatedStack
    stackAvg                        % An average projection image of the tiff stack
    stackMax                        % An maximum projection image of the tiff stack

    stagePos
    tmpStagePos
    rotating
    tmpRotating
    
    % GUI state properties
    currentFrameNo                  % Number of the current frame which is displayed
    currentStack = 'orig';
    first_frame
    last_frame
    centerpoint
    bullseyePlotHandle = gobjects(0)
    bullseyeInnerDiameter = 30;
    bullseyeOuterDiameter = 100;
    
    angleSelectionHandle = gobjects(0)
    selectionLineAngles
    centerCross = gobjects(0)
    
    centerShift = [0, 0]
    
    activeLine % active line for angle determination, only active if mouse is down.
    
    % Filepaths
    
    initPath = '';                  % Path to start browsing from
    filePath                        % Filepath to folder where tiff file is loaded from (NB, not if file is loaded using block popup menu)
    fileName                        % Filename of tiff-file
    imFilePath                      % Complete filepath (folder and filename) of tiffile

    % Buttons

    btnLoadStack                    % Open file dialog to find and load a tiff-stack
    btnMarkCenter
    btnShowStagePos                 % Button used for showing stagepos
    btnShowStack
    btnShowAvg                      % Show average projection of tiff stack in image display
    btnShowMax                      % Show maximum projection of tiff stack in image display
    btnShowShifted
    btnShowRotated
    btnSaveParameters
    btnShowAngularRangeSelection
    btnRegisterStack
    btnShowCross
    
    % Other UIcontrols
    angleDelay
    angleDeviation
    currentFrameIndicator           % Textstring that shows which frame is displayed
    frameslider                     % A sliderbar for scrolling through frames
    mousepopup                      % Popupmenu for selecting mouse if mouse database is loaded
    sessionpopup                    % Popupmenu for selecting session if experiment database is loaded

    
end

methods
    
    function obj = rotationAlignmentGUI()
        
        % Create figure window
        screenSize = get(0, 'Screensize');
        
        obj.fig = figure(...
                      'Name', 'Rotation Alignment', ...
                      'NumberTitle', 'off', ...
                      'Visible','off', ...
                      'Position', screenSize, ...
                      'WindowScrollWheelFcn', {@obj.changeFrame, 'mousescroll'},...
                      'WindowKeyPressFcn', @obj.keyPress, ...
                      'WindowButtonUpFcn', @obj.mouseRelease );
                  
        % Make figure visible to get the right figure size when setting up.
        obj.fig.Visible = 'On';
        set(obj.fig, 'menubar', 'none');
        pause(0.5)
        
        % Find aspectratio of figure 
        figsize = get(obj.fig, 'Position');
        aspectRatio = figsize(3)/figsize(4);
        
        % Specify obj.margins (for figure window) and obj.padding (space between objects)
        obj.margins = 0.05 ./ [aspectRatio, 1];  %sides, top/bottom
        obj.padding = 0.07 ./ [aspectRatio, 1];  %sides, top/bottom
        
        % Load mouse and experiment databases
        obj.mouseInv = loadMouseInv();
        obj.expInv = loadExpInv();

        % Set up UI panel positions
        imPanelSize = [0.9/aspectRatio, 0.9]; % This panel determines the rest.
        freeSpaceX = 1 - imPanelSize(1) - obj.margins(1)*2 - obj.padding(1)*2;
        lSidePanelSize = [freeSpaceX/3*1, 0.9];
        rSidePanelSize = [freeSpaceX/3*1, 0.9];
        
        
        lSidePanelPos = [obj.margins(1), obj.margins(2), lSidePanelSize];
        imPanelPos = [obj.margins(1) + lSidePanelSize(1) + obj.padding(1), obj.margins(2), imPanelSize];
        rSidePanelPos = [imPanelPos(1) + imPanelSize(1) + obj.padding(1), obj.margins(2), rSidePanelSize];

        % Create left side UI panel for image controls
        obj.sidePanelL = uipanel('Title','Controls', 'Parent', obj.fig, ...
                          'FontSize', 11, 'FontUnits', 'normalized', ...
                          'units', 'normalized', 'Position', lSidePanelPos);
                      
        % Create center UI panel for image display             
        obj.imPanel = uipanel('Title','Image Stack', 'Parent', obj.fig, ...
                          'FontSize', 11, 'FontUnits', 'normalized', ...
                          'units', 'normalized', 'Position', imPanelPos);
                      
        set(obj.imPanel, 'units', 'pixel')
        panelAR = (obj.imPanel.Position(3) / obj.imPanel.Position(4));
        set(obj.imPanel, 'units', 'normalized')
        
        % Create right side UI panel for roimanager controls
        obj.sidePanelR = uipanel('Title','Alignment tools', 'Parent', obj.fig, ...
                          'FontSize', 12, ...
                          'units', 'normalized', 'Position', rSidePanelPos);  

        % Add the ax for image display to the image panel. (Use 0.03 units as margins)
        obj.axStackDisplay = axes('Parent', obj.imPanel, 'xtick',[], 'ytick',[], ...
                                  'Position', [0.03/panelAR, 0.03, 0.94/panelAR, 0.94] );
        
        obj.axStagePosPlot = axes('Parent', obj.imPanel, 'xtick',[], 'ytick',[], ...
                                'Position', [0.03, 0.01, 0.96, 0.15], 'Visible', 'off', ...
                                'box', 'on', ...
                                'ButtonDownFcn', @obj.mousePressPlot);
        hold(obj.axStagePosPlot, 'on')
        set(obj.stagePosPlotHandle, 'Visible', 'off')
        
        % Activate callback function for resizing panels when figure changes size
        set(obj.fig, 'SizeChangedFcn', @obj.figsizeChanged );
               
        % Create ui controls of left side panel
        popupPos = [0.1, 0.85, 0.8, 0.1];
        btnPosL = [0.1, 0.91, 0.8, 0.04];
        btnSep = 0.07;
        
        obj.mousepopup = uicontrol('Style', 'popupmenu', 'Parent', obj.sidePanelL, ...
                                    'String', vertcat({'Select mouse'}, obj.mouseInv(2:end, 1)), ...
                                    'Value', 1, ...
                                    'units', 'normalized', 'Position', popupPos, ...
                                    'Callback', @obj.changeMouse);
                               
        popupPos(2) = popupPos(2) - 0.05;       
        obj.sessionpopup = uicontrol('Style', 'popupmenu', 'Parent', obj.sidePanelL, ...
                                    'String', 'Select a mouse...', ...
                                    'units', 'normalized', 'Position', popupPos, ...
                                    'Callback', @obj.changeSession);
                                 
        btnPosL(2) = popupPos(2) - 0.02;        
        obj.btnLoadStack = uicontrol('Style', 'pushbutton', 'Parent', obj.sidePanelL, ...
                                    'String', 'Load Calcium Images', ...
                                    'Units', 'normalized', 'Position', btnPosL, ...
                                    'Callback', @obj.loadStack);
                                
        btnPosL(2) = btnPosL(2) - btnSep;                        
        obj.btnShowStack = uicontrol('Style', 'pushbutton', 'Parent', obj.sidePanelL, ...
                                    'String', 'Show Stack', ...
                                    'Units', 'normalized', 'Position', btnPosL, ...
                                    'Callback', @obj.showStack);                         
                                 
        btnPosL(2) = btnPosL(2) - btnSep;                        
        obj.btnShowAvg = uicontrol('Style', 'pushbutton', 'Parent', obj.sidePanelL, ...
                                    'String', 'Show Avg', ...
                                    'Units', 'normalized', 'Position', btnPosL, ...
                                    'Callback', @obj.showAvg);
        
        btnPosL(2) = btnPosL(2) - btnSep;                           
        obj.btnShowMax = uicontrol('Style', 'pushbutton', 'Parent', obj.sidePanelL, ...
                                    'String', 'Show Max', ...
                                    'Units', 'normalized', 'Position', btnPosL, ...
                                    'Callback', @obj.showMax);
                                
        btnPosL(2) = btnPosL(2) - btnSep;                           
        obj.btnShowShifted = uicontrol('Style', 'togglebutton', 'Parent', obj.sidePanelL, ...
                                    'String', 'Show Shifted', ...
                                    'Units', 'normalized', 'Position', btnPosL, ...
                                    'Callback', @obj.changeCurrentStack);
        btnPosL(2) = btnPosL(2) - btnSep;                           
        obj.btnShowRotated = uicontrol('Style', 'togglebutton', 'Parent', obj.sidePanelL, ...
                                    'String', 'Show Rotated', ...
                                    'Units', 'normalized', 'Position', btnPosL, ...
                                    'Callback', @obj.changeCurrentStack);                                
                                
        btnPosL(2) = btnPosL(2) - btnSep;
        obj.btnShowStagePos = uicontrol('Style', 'togglebutton', 'Parent', obj.sidePanelL, ...
                                    'String', 'Show StagePos', ...
                                    'Units', 'normalized', 'Position', btnPosL, ...
                                    'Callback', @obj.showStagePosPlot);
                                
        btnPosL(2) = btnPosL(2) - btnSep;                                
        obj.btnSaveParameters = uicontrol('Style', 'pushbutton', 'Parent', obj.sidePanelL, ...
                                    'String', 'Save parameters', ...
                                    'Units', 'normalized', 'Position', btnPosL, ...
                                    'Callback', @obj.saveParameters);

                                
        uiTextPos = [0.1, btnPosL(2) - btnSep, 0.45, 0.025];                         
        uiTextPos(2) = btnPosL(2) - btnSep;
        uicontrol('Style', 'text', 'Parent', obj.sidePanelL, ...
                  'String', 'Angle Delay', ...
                  'HorizontalAlignment', 'left', ...
                  'Units', 'normalized', 'Position', uiTextPos)
        uiEditPos = [uiTextPos(1) + uiTextPos(3) + 0.05, uiTextPos(2) + 0.005, 0.25, 0.025];
        uiEditPos(2) = uiTextPos(2) + 0.005;
        obj.angleDelay = uicontrol('Style', 'edit', 'Parent', obj.sidePanelL, ...
                                    'String', '0', ...
                                    'Units', 'normalized', ...
                                    'Position', uiEditPos, ...
                                    'Callback', @obj.changeAngleDelay);  
                            
        % Create buttons on right sidepanel
        btnPosR = [0.1, 0.91, 0.8, 0.04];
        btnSep = 0.07;
        
        obj.btnMarkCenter = uicontrol('Style', 'pushbutton', 'Parent', obj.sidePanelR, ...
                                    'String', 'Mark Rotation Center', ...
                                    'Units', 'normalized', 'Position', btnPosR, ...
                                    'Callback', @obj.markCenter);
        
        btnPosR(2) = btnPosR(2) - btnSep;   
        obj.btnShowCross = uicontrol('Style', 'togglebutton', 'Parent', obj.sidePanelR, ...
                                    'String', 'Show cross on center', ...
                                    'Units', 'normalized', 'Position', btnPosR, ...
                                    'Callback', @obj.showCross);
                                
        btnPosR(2) = btnPosR(2) - btnSep;                        
        obj.btnShowAngularRangeSelection = uicontrol('Style', 'togglebutton', 'Parent', obj.sidePanelR, ...
                                    'String', 'Angular Range Selection', ...
                                    'Units', 'normalized', 'Position', btnPosR, ...
                                    'Callback', @obj.showAngularRangeSelection);   
        uiTextPos = [0.1, btnPosR(2) - btnSep, 0.45, 0.025];                         
        uiTextPos(2) = btnPosR(2) - btnSep;
        uicontrol('Style', 'text', 'Parent', obj.sidePanelR, ...
                  'String', 'Angle Deviation', ...
                  'HorizontalAlignment', 'left', ...
                  'Units', 'normalized', 'Position', uiTextPos)
        uiEditPos = [uiTextPos(1) + uiTextPos(3) + 0.05, uiTextPos(2) + 0.005, 0.25, 0.025];
        uiEditPos(2) = uiTextPos(2) + 0.005;
        obj.angleDeviation = uicontrol('Style', 'edit', 'Parent', obj.sidePanelR, ...
                                        'String', '0', ...
                                        'Units', 'normalized', ...
                                        'Position', uiEditPos);  
                                    
        btnPosR(2) = uiTextPos(2) - btnSep;                            
        obj.btnRegisterStack = uicontrol('Style', 'pushbutton', 'Parent', obj.sidePanelR, ...
                                    'String', 'Register Stack (Rigid)', ...
                                    'Units', 'normalized', 'Position', btnPosR, ...
                                    'Callback', @obj.registerStack);                            

        obj.frameslider = uicontrol('Style', 'slider', 'Visible', 'off', ...
                                    'Min', 1, 'Max', 1, 'Value', 1,...
                                    'units', 'normalized', ...
                                    'Position', [imPanelPos(1), 0.02, imPanelSize(1), 0.02],...
                                    'Callback',  {@obj.changeFrame, 'slider'});
                                
        obj.currentFrameIndicator = uicontrol('Style', 'text', 'Parent', obj.imPanel, ...
                                    'String', 'Current frame: N/A', ...
                                    'units', 'normalized', ...
                                    'HorizontalAlignment', 'right', ...
                                    'Position', [0.7, 0.97, 0.265, 0.03]);                            
                                
        % Activate callback functions
        set(obj.fig, 'WindowButtonMotionFcn', {@obj.mouseOver})
                                
        % Set some initial gui state varibles
        obj.nFrames = 0;
        obj.currentFrameNo = 0;  
                        
    end
    
    
    function obj = figsizeChanged(obj, ~, ~)
        % Callback function to resize/move ui panels if figure size is changed

        figsize = get(obj.fig, 'Position');
        aspectRatio = figsize(3)/figsize(4);

        obj.margins(1) = obj.margins(2) / aspectRatio; 
        obj.padding(1) = obj.padding(2) / aspectRatio;

        % Calculate new panel positions
        imPanelSize = [0.9/aspectRatio, 0.9]; % This panel determines the rest.
        freeSpaceX = 1 - imPanelSize(1) - obj.margins(1)*2 - obj.padding(1)*2;
        lSidePanelSize = [freeSpaceX/3*1, 0.9];
        rSidePanelSize = [freeSpaceX/3*2, 0.9];

        lSidePanelPos = [obj.margins(1), obj.margins(2), lSidePanelSize];
        imPanelPos = [obj.margins(1) + lSidePanelSize(1) + obj.padding(1), obj.margins(2), imPanelSize];
        rSidePanelPos = [imPanelPos(1) + imPanelSize(1) + obj.padding(1), obj.margins(2), rSidePanelSize];

        % Reset panel positions
        set(obj.sidePanelL, 'Position', lSidePanelPos);
        set(obj.imPanel, 'Position', imPanelPos)
        set(obj.sidePanelR, 'Position', rSidePanelPos);

        % Scale frameslider to keep same width as impanel
        fslidePos = get(obj.frameslider, 'Position');
        fslidePos(1) = imPanelPos(1);
        fslidePos(3) = imPanelPos(3);
        set(obj.frameslider, 'Position', fslidePos)

        if obj.btnShowStagePos.Value
            set(obj.axStackDisplay, 'Position', [0.12, 0.12, 0.76, 0.94])
        end
            
    end

    
    function obj = keyPress(obj, ~, event)
    % Function to handle keyboard shortcuts. 

    % Pan and zoom functions are modified from axdrag (https://github.com/gulley/Ax-Drag)

        switch event.Key

            % Use these for changing impoint
            case 'leftarrow'
                source.Value = 1;
                obj.changeFrame(source, [], 'keyPress')

            case 'rightarrow'
                source.Value = -1;
                obj.changeFrame(source, [], 'keyPress')
                
            case 'uparrow'
                
            case 'downarrow'
                
        end

    end
    
    
    function obj = mousePressPlot(obj, ~, event)
    % Callback function for mousepress within signal plot ax
        x = event.IntersectionPoint(1);

        source.String = num2str(round(x));
        obj.changeFrame(source, [], 'jumptoframe');


    end
    
    
    function obj = mouseRelease(obj, ~, ~)
    % Callback function when mouse button is released over figure.

        obj.activeLine = 0;
        
    end
    
    
    function obj = mouseOver(obj, ~, ~)
    % Callback funtion to handle mouse movement over figure
            
        if obj.activeLine
            mousePointAx = get(obj.axStackDisplay, 'CurrentPoint');
            mousePointAx = mousePointAx(1, 1:2);
            set(obj.angleSelectionHandle(obj.activeLine), ...
                'XData', [obj.imWidth/2, mousePointAx(1)], ...
                'YData', [obj.imHeight/2, mousePointAx(2)])
            obj.calculateAngle();
            
        end
    end
    

    function obj = changeMouse(obj, source, ~)
    % Change current mouse in popupmenu. Load sessions for this mouse
    % into session popupmenu

        if source.Value == 1 % No mouse is selected
            set(obj.sessionpopup, 'Value', 1);
            set(obj.sessionpopup, 'String', 'Select mouse...');  
            return
        end

        mouseId = source.String{source.Value}; % Selected string from menu

        % Find sessions which are present for selected mouse
        mId = strrep(mouseId, 'ouse', ''); % shorten mouse001 to m001
        mouseSessions = find(strncmp( obj.expInv(2:end, 1), mId, 4 ));
        mouseSessions = arrayfun(@(x) obj.expInv(x+1, :), mouseSessions, 'un', 0);
        if isempty(mouseSessions); mouseSessions = {'No Sessions Available'}; end

        % Add sessions to session popupmenu
        mouseSessions = cellfun(@(x) x{1,1}, mouseSessions, 'uni', 0);            
        set(obj.sessionpopup, 'Value', 1);
        set(obj.sessionpopup, 'String', horzcat({'Select a session...'}, mouseSessions(:, 1)'));

    end


    function obj = changeSession(obj, source, ~)
    % Get sessionID

        if source.Value ~= 1
            obj.sessionID = source.String{source.Value};
        else
            obj.sessionID = [];
        end

    end
        
    
    function obj = loadStack(obj, ~, ~)
    % Load an image stack into the GUI

        if ~isempty(obj.sessionID)
            initpath = getSessionFolder(obj.sessionID);
        else
            initpath = obj.initPath;
        end

        [obj.fileName, obj.filePath, filterIdx] =  uigetfile({'tif', 'Tiff Files (*.tif)'; ...
                                    'tiff', 'Tiff Files (*.tiff)'; ...
                                    'raw', 'Raw Files (*.raw)'; ...
                                    '*', 'All Files (*.*)'}, ...
                                    'Find Stack', ...
                                    initpath);

        if obj.fileName == 0 % User pressed cancel
            return
        else
            obj.initPath = obj.filePath;
        end

        obj.imFilePath = fullfile(obj.filePath, obj.fileName);
        
        switch filterIdx
            case {1, 2}
                obj.tiffStack = stack2mat(obj.imFilePath, true);
            case 3
                frames = inputdlg({'Enter first frame', 'Enter last frame'});
                obj.first_frame = str2double(frames{1});
                obj.last_frame = str2double(frames{2});
                obj.tiffStack = loadSciScanStack(obj.filePath, 2, obj.first_frame, obj.last_frame );
        end
        
        obj.shiftedStack = obj.tiffStack;
        obj.rotatedStack = obj.tiffStack;

        % Get image dimensions
        [obj.imWidth, obj.imHeight, obj.nFrames] = size(obj.tiffStack);

        % Load average and max stack projections
        %obj = loadStackProjections(obj);

        % (Re)set current frame to first frame
        obj.currentFrameNo = 1;

        % Set up frame indicators and frameslider
        if obj.nFrames < 11
            sliderStep = [1/(obj.nFrames-1), 1/(obj.nFrames-1)];
        else
            sliderStep = [1/(obj.nFrames-1), 10/(obj.nFrames-10)];
        end

        set(obj.currentFrameIndicator, 'String', ['Current Frame: 1/' num2str(obj.nFrames)] )
        set(obj.frameslider, 'Max', obj.nFrames, ...
                             'Value', obj.currentFrameNo, ...
                             'SliderStep', sliderStep, ...
                             'Visible', 'on');

        % Set limits of StagePos Plot
        set(obj.axStagePosPlot, 'Xlim', [1, obj.nFrames])
        
        for i = 1:length(obj.stagePosPlotHandle)
                delete(obj.stagePosPlotHandle(i))
        end
        obj.stagePosPlotHandle=gobjects(0);

        
        % Load Stage Positions
        obj.loadStagePos();
        
        % Display image
        obj = updateImageDisplay(obj);

    end
    
    
    function obj = loadStagePos(obj)
    % Open filebrowser in same location as tiffstack was loaded from
    
        if ~isempty(obj.sessionID)
            sessionFolder = getSessionFolder(obj.sessionID);
            initpath = fullfile(sessionFolder, 'labview_data');
            blockFolder = ['labview_data-', obj.sessionID, '-block001'];
            stagePosFile = dir(fullfile(initpath, blockFolder, '*arena_positions*'));
            stageposFile = fullfile(initpath, blockFolder, stagePosFile(1).name);
        else
            initpath = obj.initPath;
            [stageposFileName, pathName, ~] =  uigetfile({'txt', 'Txt Files (*.txt)'; ...
                                      '*', 'All Files (*.*)'}, ...
                                      'Find Arena Positions File', ...
                                      initpath);

            if stageposFileName == 0 % User pressed cancel
                return
            end
            stageposFile = fullfile(pathName, stageposFileName);
        end

        labviewData = importdata(stageposFile);
        obj.stagePos = labviewData(1:end, 3); % StagePosition (Angles)
        obj.rotating = labviewData(1:end, 4); % Rotating (boolean)
        obj.tmpStagePos = obj.stagePos(obj.first_frame:obj.last_frame);
        obj.tmpRotating = obj.rotating(obj.first_frame:obj.last_frame);
        obj.stagePosPlotHandle = plot(obj.axStagePosPlot, obj.tmpStagePos, 'HitTest', 'off');
        set(obj.stagePosPlotHandle, 'Visible', 'off')
        set(obj.plotFrameMarker, 'YData', get(obj.axStagePosPlot, 'ylim'));

    end
               
    
    function obj = updateImageDisplay(obj)
        % Updates the image in the image display

        frameNo = obj.currentFrameNo;

        if obj.nFrames > 1 
            set( obj.currentFrameIndicator, 'String', ...
                  ['Current Frame: ' num2str(obj.currentFrameNo) '/' num2str(obj.nFrames)] )
        end


        switch obj.currentStack
            case 'orig'
                caframe = obj.tiffStack(:, :, frameNo);
            case 'shifted'
                caframe = obj.shiftedStack(:, :, frameNo);
            case 'rotated'
                caframe = obj.rotatedStack(:, :, frameNo);
        end
%         
%         if ~isempty(obj.tmpStagePos)
%             angle = obj.tmpStagePos(frameNo);
%             %caframe = imrotate(caframe, angle, 'bilinear', 'crop');
%         end

        if isempty(obj.imageObj) % First time initialization. Create image object
           obj.imageObj = imshow(caframe, [0, 255], 'Parent', obj.axStackDisplay, 'InitialMagnification', 'fit');
        else
           set(obj.imageObj, 'cdata', caframe);
        end

        obj.updateFrameMarker();

    end

    
    function obj = changeFrame(obj, source, event, action)
    % Callback from different sources to change the current frame.

        switch action
            case 'mousescroll'
                i = event.VerticalScrollCount;
            case {'slider', 'buttonclick'}
                newValue = source.Value;
                i = newValue -  obj.currentFrameNo;
                i = round(i);
            case 'keypress'
                i = source.Value;
            case {'jumptoframe'}
                i = str2double(source.String) -  obj.currentFrameNo;
                i = round(i);
            otherwise
                i = 0;   
        end

        % Check that new value is within range and update current frame/slider info
        if (obj.currentFrameNo + i) >= 1  && (obj.currentFrameNo + i) <= obj.nFrames
            obj.currentFrameNo = round(obj.currentFrameNo + i);
            set(obj.frameslider, 'Value', obj.currentFrameNo );
            if strcmp(obj.frameslider.Visible, 'off')
                obj.frameslider.Visible = 'on';
            end
        else
            i = 0;
        end

        if ~isempty(obj.tiffStack) && i~=0
            obj = updateImageDisplay(obj);
        end
    end    
    
    
    function obj = updateFrameMarker(obj)
        % Update line indicating current frame in plot. 
            frameNo = obj.currentFrameNo;
            if isempty(obj.plotFrameMarker)
                obj.plotFrameMarker = plot(obj.axStagePosPlot, [1, 1], get(obj.axStagePosPlot, 'ylim'), 'r', 'Visible', 'off', 'HitTest', 'off');
            else
                set(obj.plotFrameMarker, 'XData', [frameNo, frameNo]);
            end
    end

    
    function obj = showStack(obj, ~, ~)
    % Shows current frame in image display
        obj.unFocusButton(obj.btnShowStack)
        set(obj.frameslider, 'Visible', 'on');
        obj.updateImageDisplay();
    end
    
    
    function obj = showAvg(obj, ~, ~)
    % Shows stack average projection in image display
        obj.unFocusButton(obj.btnShowAvg)

        set(obj.frameslider, 'Visible', 'off');
        set( obj.currentFrameIndicator, 'String', ...
                      'Current Frame: Avg Image' )
                  
        switch obj.currentStack
            case 'orig'
                caframe = mean(obj.tiffStack, 3);
            case 'shifted'
                caframe = mean(obj.shiftedStack, 3);
            case 'rotated'
                caframe = mean(obj.rotatedStack, 3);
        end
        
        set(obj.imageObj,'cdata',caframe);
    end


    function obj = showMax(obj, ~, ~)
    % Shows stack average projection in image display
        obj.unFocusButton(obj.btnShowMax)
        set(obj.frameslider, 'Visible', 'off');
        set( obj.currentFrameIndicator, 'String', ...
                      'Current Frame: Max Image' )

        switch obj.currentStack
            case 'orig'
                caframe = max(obj.tiffStack, [], 3);
            case 'shifted'
                caframe = max(obj.shiftedStack, [], 3);
            case 'rotated'
                caframe = max(obj.rotatedStack, [], 3);
        end
        
        set(obj.imageObj,'cdata',caframe);
    end           


    function obj = showStagePosPlot(obj, source, ~)
        if source.Value
            set(obj.axStagePosPlot, 'Visible', 'on')  
            set(obj.stagePosPlotHandle, 'Visible', 'on')
            set(obj.plotFrameMarker, 'Visible', 'on')
            set(obj.axStackDisplay, 'Position', [0.12, 0.2, 0.76, 0.76])
            drawnow
        else
            %obj.resetSignalPlot();
            set(obj.axStagePosPlot, 'Visible', 'off')
            set(obj.stagePosPlotHandle, 'Visible', 'off')
            set(obj.plotFrameMarker, 'Visible', 'off')
            set(obj.axStackDisplay, 'Position', [0.03, 0.03, 0.94, 0.94])
        end

    end
    
    
    function obj = changeAngleDelay(obj, source, ~)
        
        delay = str2double(source.String);
        
        % If end of stack is loaded, this does not work
        if delay < 0 && obj.first_frame <= abs(delay)
            obj.tmpStagePos = cat(1, zeros(abs(delay), 1), obj.stagePos(obj.first_frame:(obj.last_frame-abs(delay))));
            obj.tmpRotating = cat(1, zeros(abs(delay), 1), obj.rotating(obj.first_frame:(obj.last_frame-abs(delay))));
        else
        	obj.tmpStagePos = obj.stagePos( (obj.first_frame:obj.last_frame) + delay);
        	obj.tmpRotating = obj.rotating( (obj.first_frame:obj.last_frame) + delay);
        end
        
        obj.rotatedStack = rotateStack( obj.shiftedStack, obj.tmpStagePos);
        
        % Save to folder
        
        set(obj.stagePosPlotHandle, 'YData', obj.tmpStagePos)
      
    end
    
    
    function obj = markCenter(obj, source, ~)
        switch source.String
            case 'Mark Rotation Center'
                %[x, y] = getpts(obj.axStackDisplay);
                obj.centerpoint = impoint(obj.axStackDisplay);
                obj.centerpoint.addNewPositionCallback(@(pos)centerPointMoved(obj, pos));
                set(obj.btnMarkCenter, 'String', 'Finish')
            case 'Finish'
                rotCenter = obj.centerpoint.getPosition;
                imCenter = [obj.imWidth/2, obj.imHeight/2];
                
                deltaCenter = round((imCenter - rotCenter));
                switch obj.currentStack
                    case 'orig'
                        obj.centerShift = deltaCenter;
                    case 'shifted'
                        obj.centerShift = obj.centerShift + deltaCenter;
                end

                % Save to folder
                
                %obj.tiffStack = shiftStack(obj.tiffStack, deltaCenter(1), deltaCenter(2));
                obj.shiftedStack = shiftStack(obj.tiffStack, obj.centerShift(1), obj.centerShift(2));
                delay.String = obj.angleDelay.String;
                obj.changeAngleDelay(delay, []);
                obj.updateImageDisplay();
                
                set(obj.btnMarkCenter, 'String', 'Mark Rotation Center')
                delete(obj.centerpoint)
                obj.centerpoint = [];
                delete(obj.bullseyePlotHandle)
                obj.bullseyePlotHandle = gobjects(0);
                
        end
 
    end
    
    
    function obj = centerPointMoved(obj, pos)
        x = pos(1);
        y = pos(2);
        
        % Plot a circle with diameter r.

        r1 = obj.bullseyeInnerDiameter/2;
        r2 = obj.bullseyeOuterDiameter/2;

        th = 0:pi/50:2*pi;
        xdata1 = r1 * cos(th) + x;
        ydata1 = r1 * sin(th) + y;
        xdata2 = r2 * cos(th) + x;
        ydata2 = r2 * sin(th) + y;

        xData = horzcat(xdata1, nan, xdata2);
        yData = horzcat(ydata1, nan, ydata2);

        hold(obj.axStackDisplay, 'on')
        if isempty(obj.bullseyePlotHandle)
            obj.bullseyePlotHandle = plot(xData, yData, 'white');
        else
            set(obj.bullseyePlotHandle, 'XData', xData, 'YData', yData)
        end
        hold(obj.axStackDisplay, 'off')
        
    end
    
    
    function obj = changeCurrentStack(obj, source, ~)
        switch source.String
            case 'Show Shifted'
                if source.Value
                    set(obj.btnShowRotated, 'Value', 0)
                    obj.currentStack = 'shifted';
                else
                    obj.currentStack = 'orig';
                end
                
            case 'Show Rotated'                
                if source.Value
                    set(obj.btnShowShifted, 'Value', 0)
                    obj.currentStack = 'rotated';
                else
                    obj.currentStack = 'orig';
                end
                
        end
    end
   
    
    function obj = saveParameters(obj, ~, ~)
        if ~isempty(obj.sessionID)
            savepath = getSessionFolder(obj.sessionID);
        else
            msgbox('No session is selected');
            return
        end
        
        savepath = fullfile(savepath, 'imreg_variables');
        if ~exist(savepath, 'dir'); mkdir(savepath); end
        
        rotationCenterOffset = obj.centerShift;
        stagePositionDelay = str2double(get(obj.angleDelay, 'String'));
        
        save(fullfile(savepath, [obj.sessionID,'_rotationCenterOffset.mat']), 'rotationCenterOffset')
        save(fullfile(savepath, [obj.sessionID,'_stagePositionDelay.mat']), 'stagePositionDelay')

        
    end
    
    
    function obj = showAngularRangeSelection(obj, source, ~)
        if source.Value
            if isempty(obj.angleSelectionHandle)
                hold(obj.axStackDisplay, 'on')
                obj.angleSelectionHandle(1) = plot(obj.axStackDisplay, [obj.imWidth/2, 1], [obj.imHeight/2, 1], 'ButtonDownFcn', {@obj.clickedLine, 1});
                obj.angleSelectionHandle(2) = plot(obj.axStackDisplay, [obj.imWidth/2, 1], [obj.imHeight/2, obj.imHeight], 'ButtonDownFcn', {@obj.clickedLine, 2});
                
                obj.calculateAngle();
               
            else 
                set(obj.angleSelectionHandle, 'Visible', 'on')
            end
        else
            set(obj.angleSelectionHandle, 'Visible', 'off')
        end
    end
    
    
    function obj = calculateAngle(obj)
        % Calculates the angle between the lines. diff y is negated compared to normal
        % coordinate system because of reversed yaxis in images.

        x1 = obj.angleSelectionHandle(1).XData;
        y1 = obj.angleSelectionHandle(1).YData;
        x2 = obj.angleSelectionHandle(2).XData;
        y2 = obj.angleSelectionHandle(2).YData;
        
        angle1 = atan( -(diff(y1)) / diff(x1) ) / pi * 180;
        angle2 = atan( -(diff(y2)) / diff(x2) ) / pi * 180;
        if diff(y1) > 0 && diff(x1) < 0; angle1 = angle1+180;
        elseif diff(y1) < 0 && diff(x1) < 0; angle1 = angle1+180; 
        elseif diff(y1) > 0 && diff(x1) > 0; angle1 = angle1+360; 
        end
        if diff(y2) > 0 &&  diff(x2) < 0; angle2 = angle2+180;
        elseif diff(y2) < 0 &&  diff(x2) < 0; angle2 = angle2+180;
        elseif diff(y2) > 0 && diff(x2) > 0; angle2 = angle2+360; 
        end
%         angle1

        angleDiff = ceil(abs(diff([angle1, angle2])));
        if angleDiff > 180; angleDiff = 360 - angleDiff; end 
        
        set(obj.angleDeviation, 'String', num2str(angleDiff))
    end
        
    
    function obj = clickedLine(obj, ~, ~, lineNo)
        obj.activeLine = lineNo;
    end
        
     
    function obj = registerStack(obj, ~, ~)
        tmp_stack = obj.rotatedStack( (-150:150) + obj.imHeight/2, (-150:150) + obj.imWidth/2, :);
        shifts = zeros(size(tmp_stack, 3), 3);
        nStationaryFrames = min([sum(~obj.tmpRotating), 100]);
        % Create stack for reference image without rotation artifacts
        ref_stack = zeros(size(tmp_stack, 1), size(tmp_stack, 2), nStationaryFrames);
        counter = 0;
        for i = 1:size(tmp_stack, 3)
            if obj.tmpRotating(i) == 1
                continue
            else
                counter = counter + 1;
                ref_stack(:, :, counter) = tmp_stack(:,:,i);
                if counter == nStationaryFrames
                    break
                end
            end
        end
        
        % Align reference stack and create reference image.
        opt.wb_on = 1;
        ref = mean(ref_stack, 3);
        [ref_stack, ~, ~, ~] = imreg_fft(double(ref_stack), ref, opt);
        ref = mean(ref_stack, 3); % Already double
        imwrite(uint8(ref), '/Users/eivinhen/Desktop/ref.tif')
        mat2stack(uint8(ref_stack), '/Users/eivinhen/Desktop/ref_stack.tif')
        
        %[~, dx_r, dy_r, E] = imreg_fft(double(tmp_stack), ref, opt);
%         shifts(:, 1) = dx_r;
%         shifts(:, 2) = dy_r;
        
        Y = double(tmp_stack);
        options_rigid = NoRMCorreSetParms('d1', size(Y,1), 'd2', size(Y,2), ...
                                          'bin_width', 50, 'max_shift', 20, 'us_fac', 50);
        [~, nc_shifts, ~] = normcorre(Y, options_rigid);
        
        shifts(:, 1) = round(arrayfun(@(row) row.shifts(2), nc_shifts));
        shifts(:, 2) = round(arrayfun(@(row) row.shifts(1), nc_shifts));
        obj.rotatedStack = applyFrameCorrections(obj.rotatedStack, [], shifts, []);
        
    end
    
    
    function obj = showCross(obj, source, ~)
        if source.Value
            set(obj.btnShowCross, 'String', 'Hide Cross')
            if isempty(obj.centerCross)
                hold(obj.axStackDisplay, 'on')
                obj.centerCross(1) = plot(obj.axStackDisplay, [obj.imWidth/2, obj.imWidth/2], [1, obj.imHeight] );
                obj.centerCross(2) = plot(obj.axStackDisplay, [1, obj.imWidth], [obj.imHeight/2, obj.imHeight/2] );
                hold(obj.axStackDisplay, 'off')
            else
                set(obj.centerCross, 'Visible', 'on')
            end
        else
            set(obj.btnShowCross, 'String', 'Show Cross')
            if isempty(obj.centerCross)
                return
            else
                set(obj.centerCross, 'Visible', 'off')
            end
            
        end
    end
    
    
end

methods (Static)


    function unFocusButton(btnHandle)
        set(btnHandle, 'Enable', 'off');
        drawnow;
        set(btnHandle, 'Enable', 'on');
    end


end


end
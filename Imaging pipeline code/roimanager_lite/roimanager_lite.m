classdef roimanager_lite < handle
    %A lite version of the roimanager GUI.
    %   ROIMANAGER_LITE opens a GUI for drawing rois
    %
    %   ROIMANAGER_LITE(sessionID) opens the GUI and loads a session
    %
    %   Usage:
    %       - Load a tiff stack
    %       - Use draw button (or press 'd' on the keyboard) 
    %         to activate a polygon selection tool for drawing rois in the
    %         image. Press the finish button (or 'f' on the keyboard) to complete the roi.
    %       - Or: Use Autodetect rois ('a') to point and click to select rois.
    %
    %   Extra features:
    %       - Autodetect rois by point and click.
    %       - RoIs can be moved around by dragging them in the image using
    %         the mouse
    %       - Keyboard zoom shortcuts ('z' - zoom in, 'Z' - zoom out)
    %       - Keyboard pan shortcuts (use arrow keys)
    %       - Other keyboard shortcuts:
    %           'e' - toggle edit mode
    %           'q' - toggle zoom in mouse tool
    %           'w' - toggle zoom out mouse tool
    %           'r' - reset zoom (zoom out to show entire image)
    %           's' - go to select mode
    %           'escape' - cancel drawing or editing of roi
    %           'backspace' - remove selected rois
    %       - Play video (speed is not very precise)
    %
    %
    %   Optional additions:
    %       For automatic roi segmentation: 
    %           - ca_source_extraction:   https://github.com/epnev/ca_source_extraction
    %           - cvx:                    http://cvxr.com/cvx/download/
    %                                     currently commented out (see line 409-418)
    %       For quicker loading of tiffstacks:
    %           - tiffStack (optional):   https://github.com/DylanMuir/TIFFStack
    %                                     currently commented out (see line 1310-1316)
    
    
    % TODO
    
    % Import directory.
    % Different channels. Different blocks/chunks/parts.
    % Dropdown with files or load all in beginning?
    % 
    % Load chunks...
    % Roi file will be a file linked with a stack.
    % There will be a property of roi object with a boolean array, same length as 
    % number of frames. This boolen will say whether we should take the signal from 
    % that frame, or ignore it.
    % when loading a new stack, the rois remain, but the boolean array is reset...
    % 
    % Channels. Channels are resolved based on "chxxx". Could also be used for planes.
    % For each channel: All these properties should be cell arrays: cell(nch*nplane)
    % currentFileName
    % tiffstack
    % tiffstack medfilt
    % RoiPlotHandles                  % A list of plot handles for all finished rois
    % RoiTextHandles 
    % tiffstack object. 
    % roiarray.
    % roicount
    %
    % Change channel/plane method. Shortcuts(1,2,3,4) (shift+1, shift+2, etc)
    % Reset all shared properties.
    % Replot and reshow other channel info.
    % Export signal and rois. One file for each tiff file. E.g. per channel, per block
    % Copy roi to channel/plane. Select channel/plane from dropdown menu.

    
    
    properties
        
        % User settings
        
        initPath = '';                  % Path to start browsing from
        
        % Different roi classes, their abbreviations, and color for plots.
        roiClasses = {'Neuronal Soma', 'Neuronal Dendrite', 'Neuronal Axon', 'Neuropill','Astrocyte Soma','Astrocyte Endfoot','Astrocyte Process','Gliopill', 'Artery', 'Vein', 'Capillary'};
        roiTags = {'NS', 'ND', 'NA','Np','AS', 'AE', 'AP','Gp','Ar','Ve','Ca'}
        roiColors = {'Red', [.96 .45 .027], [.96 .65 .027], [.75 .5 0], 'Green', [0.016 .61 .51], [.63 .90 .02], [.067 .48 0], [.24 .09 .66], [.43 .051 .64], [.76, .02 .47]}
        
        
        % Figure and figure settings
        
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
        panFactor = 0.1;                % Determines image shift when using arrow keys
        zoomFactor = 0.25;              % Determines zoom when using zoom keys (z and Z)
        binningSize = 9;                % Bin size used for moving averages or maximums.
        
        axSignalPlot
        signalPlotHandle
        plotFrameMarker
        
        % Image dimensions
        
        imWidth                         % Width (pixels) of images in tiff stack
        imHeight                        % Height (pixels) of images in tiff stack
        nFrames                         % Number of frames in tiff stack
        
        % Roi handles for creating and displaying rois
        
        RoiTmpPlotHandle                % A plot handle for temporary lines of roi polygon
        RoiTmpEdges                     % A list of impoints for the temporary roi polygon
        RoiTmpPosX                      % X coordinate values of the temporary roi
        RoiTmpPosY                      % Y coordinate values of the temporary roi
        RoiPlotHandles                  % A list of plot handles for all finished rois
        RoiTextHandles                  % A list of text handles for all finished rois
        roiOuterDiameter = 10;          % Roi diameter in pixels used for autodetection
        roiInnerDiameter = 5;           % Roi inner diameter in pixels used for autodetection
        roiTemplatePlotHandle           % Plot handle of roitemplate for autodetection
        roiDisplacement = 0;            % Temporary "keeper" of roi displacement if rois are moved
        
        % Data which is loaded into gui
        
        mouseInv                        % A database of experimental mice
        expInv                          % A database of experimental sessions
        tiffStack                       % A tiffstack of images on which to draw rois
        tiffStackMedfilt                % A tiffstack of images which are median filtered
        tiffClass                       % The class of tiffStack ('TIFFStack' or 'double')
        stackAvg                        % An average projection image of the tiff stack
        stackMax                        % An maximum projection image of the tiff stack
        roiArray = RoI.empty            % An array of RoI objects
        selectedRois                    % Numbers of the selected/active rois                   
        
        % GUI state properties
        
        sessionID                       % Session ID of an experiment loaded into roimanager
        channel                         % Recording channel for current tiff stack
        currentFrameNo                  % Number of the current frame which is displayed
        roiCount                        % A counter for the number of rois that have been drawn
        playbackspeed = 1
        
        % Mouse state and recorded cursor positions
        
        mouseMode = 'Select'            % MouseMode ('Draw' or 'Select')
        prevMouseMode                   % Previous active mousemode
        mouseDown = 0                   % Indicates if mouse button is pressed
        prevMouseClick                  % Axes coordinates when mouse was last clicked.
        prevMousePointAx                % Needed for moving RoIs
        prevMousePointFig               % Needed for panning image display in select mode
        roiTemplateCenter               % Needed when setting the roi diameter
        zoomRectPlotHandle              % Handle for rectangle plot when drag-zooming
        
        % Filepaths
        
        filePath                        % Filepath to folder where tiff file is loaded from (NB, not if file is loaded using block popup menu)
        fileName                        % Filename of tiff-file
        imFilePath                      % Complete filepath (folder and filename) of tiffile
        
        % Buttons
        
        btnLoadStack                    % Open file dialog to find and load a tiff-stack
        btnRunAutoSegmentation          % Run automatic roi detection (Paninski code)
        btnShowStack                    % Show current frame of tiff stack in image display
        btnShowAvg                      % Show average projection of tiff stack in image display
        btnShowMovingAvg                % Togglebutton for showing moving average projection
        btnShowMovingStd                % Togglebutton for showing moving average projection
        btnShowMovingMax                % Togglebutton for showing moving maximum projection
        btnShowMax                      % Show maximum projection of tiff stack in image display
        btnDrawRoi                      % Button used for drawing a new RoI
        btnAutoDetect                   % Button used to activate "autodetection clicktool"
        btnEditRoi                      % Button used for editing an existing RoI
        btnShowSignal                   % Button used for extracting signal from a roi
        btnRemoveRoi                    % Button used for removing selected rois
        btnLoadRois                     % Button used for loading rois from file
        btnExportRois                   % Button used for exporting rois to file
        btnExportSignal                 % Button used for exporting signal to file
        btnClearAllRois                 % Button used for removing all rois
        btnShowTags                     % Button used for showing or hiding text/tags of rois
        btnSetRoiSize                   % Button to quickly set the size of roi to autodetect
        btnPlayVideo                    % Button to start/stop video.
        btn2x
        btn4x
        btn8x
        
        % Other UIcontrols
        
        mousepopup                      % Popupmenu for selecting mouse if mouse database is loaded
        sessionpopup                    % Popupmenu for selecting session if experiment database is loaded
        blockpopup                      % Popupmenu for selecting block is a session is selected
        roiclasspopup                   % Popupmenu for selecting roi type/Groupname
        inputJumptoFrame                % Input field to display specified frame in image display
        setBinningSize                  % Input field to set binning size for moving averages
        currentFrameIndicator           % Textstring that shows which frame is displayed
        currentFileName                 % Textstring with current filename
        roiListBox                      % A listbox containing the name of all rois
        frameslider                     % A sliderbar for scrolling through frames
        roiSizeSlider                   % A sliderbar to set the roisize for autodetection
        roiSizeSliderContainer          % A container for the roi size sliderbar
        brightnessSlider
        brightnessSliderContainer
    end
    
    
    
    methods
        
        
        function obj = roimanager_lite(sessionID)
        %Constructs the GUI window and places all objects within it.
        
        % Start roimanager without opening a specified session.
        if nargin < 1
            sessionID = [];
        end
        
        % Set up figure. Default is to cover the whole screen
        screenSize = get(0, 'Screensize');
        
        obj.fig = figure(...
                      'Name', 'Roimanager Lite', ...
                      'NumberTitle', 'off', ...
                      'Visible','off', ...
                      'Position', screenSize, ...
                      'WindowScrollWheelFcn', {@obj.changeFrame, 'mousescroll'}, ...
                      'WindowKeyPressFcn', @obj.keyPress, ...
                      'WindowButtonUpFcn', @obj.mouseRelease);
                  
        % Make figure visible to get the right figure size when setting up.
        obj.fig.Visible = 'On';
        set(obj.fig, 'menubar', 'none');
        pause(0.5)
        
        try
            % Load mouse and experiment databases
            obj.mouseInv = loadMouseInv();
            obj.expInv = loadExpInv();
            dbLoaded = true;
        catch
            dbLoaded = false;
        end

        % Find aspectratio of figure 
        figsize = get(obj.fig, 'Position');
        aspectRatio = figsize(3)/figsize(4);
        
        % Specify obj.margins (for figure window) and obj.padding (space between objects)
        obj.margins = 0.05 ./ [aspectRatio, 1];  %sides, top/bottom
        obj.padding = 0.07 ./ [aspectRatio, 1];  %sides, top/bottom
               
        % Set up UI panel positions
        imPanelSize = [0.9/aspectRatio, 0.9]; % This panel determines the rest.
        freeSpaceX = 1 - imPanelSize(1) - obj.margins(1)*2 - obj.padding(1)*2;
        lSidePanelSize = [freeSpaceX/3*1, 0.9];
        rSidePanelSize = [freeSpaceX/3*2, 0.9];
                
        lSidePanelPos = [obj.margins(1), obj.margins(2), lSidePanelSize];
        imPanelPos = [obj.margins(1) + lSidePanelSize(1) + obj.padding(1), obj.margins(2), imPanelSize];
        rSidePanelPos = [imPanelPos(1) + imPanelSize(1) + obj.padding(1), obj.margins(2), rSidePanelSize];

        % Create left side UI panel for image controls
        obj.sidePanelL = uipanel('Title','Image Controls', 'Parent', obj.fig, ...
                          'FontSize', 12, ...
                          'units', 'normalized', 'Position', lSidePanelPos);
                      
        % Create center UI panel for image display             
        obj.imPanel = uipanel('Title','Image Stack', 'Parent', obj.fig, ...
                          'FontSize', 12, ...
                          'units', 'normalized', 'Position', imPanelPos);
                      
        set(obj.imPanel, 'units', 'pixel')
        panelAR = (obj.imPanel.Position(3) / obj.imPanel.Position(4));
        set(obj.imPanel, 'units', 'normalized')

        % Add the ax for image display to the image panel. (Use 0.03 units as margins)
        obj.axStackDisplay = axes('Parent', obj.imPanel, 'xtick',[], 'ytick',[], ...
                                  'Position', [0.03/panelAR, 0.03, 0.94/panelAR, 0.94] );
        
        obj.axSignalPlot = axes('Parent', obj.imPanel, 'xtick',[], 'ytick',[], ...
                                'Position', [0.03, 0.01, 0.96, 0.15], 'Visible', 'off', ...
                                'box', 'on', ...
                                'ButtonDownFcn', @obj.mousePressPlot);
        hold(obj.axSignalPlot, 'on')                    
            
        % Create right side UI panel for roimanager controls
        obj.sidePanelR = uipanel('Title','RoiManager', 'Parent', obj.fig, ...
                          'FontSize', 12, ...
                          'units', 'normalized', 'Position', rSidePanelPos);   
        
        % Activate callback function for resizing panels when figure changes size
        set(obj.fig, 'SizeChangedFcn', @obj.figsizeChanged );
        
        % Create ui controls of left side panel
        popupPos = [0.1, 0.85, 0.8, 0.1];
        btnPosL = [0.1, 0.91, 0.8, 0.04];
        
        if dbLoaded
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
                                 
        popupPos(2) = popupPos(2) - 0.05;  
        obj.blockpopup = uicontrol('Style', 'popupmenu', 'Parent', obj.sidePanelL, ...
                                    'String', 'Select a session...', ...
                                    'units', 'normalized', 'Position', popupPos );
        btnPosL(2) = popupPos(2) - 0.02;
        end
                
        obj.btnLoadStack = uicontrol('Style', 'pushbutton', 'Parent', obj.sidePanelL, ...
                                    'String', 'Load Calcium Images', ...
                                    'Units', 'normalized', 'Position', btnPosL, ...
                                    'Callback', @obj.loadStack);
                                
%         obj.btnLoadNextStack = uicontrol('Style', 'pushbutton', 'Parent', obj.sidePanelL, ...
%                                     'String', 'Next stack', ...
%                                     'Units', 'normalized', 'Position', btnPosL, ...
%                                     'Callback', @obj.loadNextStack);
                                
        uiTextPos = [0.1, btnPosL(2) - 0.08, 0.45, 0.025];
        uicontrol('Style', 'text', 'Parent', obj.sidePanelL, ...
                  'String', 'Enter channel', ...
                  'HorizontalAlignment', 'left', ...
                  'Units', 'normalized', 'Position', uiTextPos)
        
        uiEditPos = [uiTextPos(1) + uiTextPos(3) + 0.05, uiTextPos(2) + 0.005, 0.25, 0.025];
        obj.channel = uicontrol('Style', 'edit', 'Parent', obj.sidePanelL, ...
                                    'String', '1', ...
                                    'Units', 'normalized', ...
                                    'Position', uiEditPos);
        
        btnPosL(2) = uiTextPos(2) - 0.08;   
        obj.btnShowStack = uicontrol('Style', 'pushbutton', 'Parent', obj.sidePanelL, ...
                                    'String', 'Show Stack', ...
                                    'Units', 'normalized', 'Position', btnPosL, ...
                                    'Callback', @obj.showStack);                         
                                 
        btnPosL(2) = btnPosL(2) - 0.05;                        
        obj.btnShowAvg = uicontrol('Style', 'pushbutton', 'Parent', obj.sidePanelL, ...
                                    'String', 'Show Avg', ...
                                    'Units', 'normalized', 'Position', btnPosL, ...
                                    'Callback', @obj.showAvg);
        
        btnPosL(2) = btnPosL(2) - 0.05;                           
        obj.btnShowMax = uicontrol('Style', 'pushbutton', 'Parent', obj.sidePanelL, ...
                                    'String', 'Show Max', ...
                                    'Units', 'normalized', 'Position', btnPosL, ...
                                    'Callback', @obj.showMax);
                                
        sliderPos = [0.1, btnPosL(2) - 0.04, 0.8, 0.03];                     
        jSlider = com.jidesoft.swing.RangeSlider(0, 255, 0, 255);
        [obj.brightnessSlider, obj.brightnessSliderContainer] = javacomponent(jSlider);
        obj.brightnessSlider = handle(obj.brightnessSlider, 'CallbackProperties');
        set(obj.brightnessSlider, 'StateChangedCallback', @obj.brightnessValueChange);
        set(obj.brightnessSliderContainer, 'Parent', obj.sidePanelL, 'units', 'normalized', 'Position', sliderPos)
        
        uiTextPos(2) = sliderPos(2) - 0.08;
        uicontrol('Style', 'text', 'Parent', obj.sidePanelL, ...
                  'String', 'Go to frame', ...
                  'HorizontalAlignment', 'left', ...
                  'Units', 'normalized', 'Position', uiTextPos)
        
              
        uiEditPos(2) = uiTextPos(2) + 0.005;
        obj.inputJumptoFrame = uicontrol('Style', 'edit', 'Parent', obj.sidePanelL, ...
                                    'String', 'N/A', ...
                                    'Units', 'normalized', ...
                                    'Position', uiEditPos, ...
                                    'Callback', {@obj.changeFrame, 'jumptoframe'});
                                
        btnPosL(2) = uiTextPos(2) - 0.08;                        
        obj.btnShowMovingAvg = uicontrol('Style', 'togglebutton', 'Parent', obj.sidePanelL, ...
                                    'String', 'Show Moving Average', 'Value', 0, ...
                                    'Units', 'normalized', 'Position', btnPosL, ...
                                    'Callback', @obj.showMovingAvg);     
                                
        btnPosL(2) = btnPosL(2) - 0.08;                        
        obj.btnShowMovingStd = uicontrol('Style', 'togglebutton', 'Parent', obj.sidePanelL, ...
                                    'String', 'Show Moving Std', 'Value', 0, ...
                                    'Units', 'normalized', 'Position', btnPosL, ...
                                    'Callback', @obj.showMovingStd); 
        
        btnPosL(2) = btnPosL(2) - 0.08;                        
        obj.btnShowMovingMax = uicontrol('Style', 'togglebutton', 'Parent', obj.sidePanelL, ...
                                    'String', 'Show Moving Maximum', 'Value', 0, ...
                                    'Units', 'normalized', 'Position', btnPosL, ...
                                    'Callback', @obj.showMovingMax); 
                                
        uiTextPos(2) = btnPosL(2) - 0.08;
        uicontrol('Style', 'text', 'Parent', obj.sidePanelL, ...
                  'String', 'Set Bin Size', ...
                  'HorizontalAlignment', 'left', ...
                  'Units', 'normalized', 'Position', uiTextPos)
        uiEditPos(2) = uiTextPos(2) + 0.005;
        obj.setBinningSize = uicontrol('Style', 'edit', 'Parent', obj.sidePanelL, ...
                                    'String', num2str(obj.binningSize), ...
                                    'Units', 'normalized', ...
                                    'Position', uiEditPos, ...
                                    'Callback', @obj.updateBinningSize);
                                
        obj.frameslider = uicontrol('Style', 'slider', 'Visible', 'off', ...
                                    'Min', 1, 'Max', 1, 'Value', 1,...
                                    'units', 'normalized', ...
                                    'Position', [imPanelPos(1), 0.02, imPanelSize(1), 0.02],...
                                    'Callback',  {@obj.changeFrame, 'slider'});
                      
        obj.currentFrameIndicator = uicontrol('Style', 'text', 'Parent', obj.imPanel, ...
                                    'String', 'Current frame: N/A', ...
                                    'units', 'normalized', ...
                                    'HorizontalAlignment', 'right', ...
                                    'Position', [0.78, 0.9725, 0.185, 0.025]);
                                
        obj.currentFileName = uicontrol('Style', 'text', 'Parent', obj.imPanel, ...
                                    'String', 'Current file: N/A', ...
                                    'units', 'normalized', ...
                                    'HorizontalAlignment', 'right', ...
                                    'Position', [0.4, 0.9725, 0.36, 0.025]);
                                
        obj.btnPlayVideo = uicontrol('Style', 'togglebutton', 'Parent', obj.imPanel, ...
                                    'String', 'Play', ...
                                    'units', 'normalized', ...
                                    'HorizontalAlignment', 'right', ...
                                    'Position', [0.1, 0.975, 0.05, 0.02], ...
                                    'Callback', @obj.playVideo );
        obj.btn2x = uicontrol('Style', 'togglebutton', 'Parent', obj.imPanel, ...
                                    'String', '2x', ...
                                    'units', 'normalized', ...
                                    'HorizontalAlignment', 'right', ...
                                    'Position', [0.17, 0.975, 0.05, 0.02], ...
                                    'Callback', @obj.btnPlaybackSpeed );
                                
        obj.btn4x = uicontrol('Style', 'togglebutton', 'Parent', obj.imPanel, ...
                                    'String', '4x', ...
                                    'units', 'normalized', ...
                                    'HorizontalAlignment', 'right', ...
                                    'Position', [0.24, 0.975, 0.05, 0.02], ...
                                    'Callback', @obj.btnPlaybackSpeed );
                                
        obj.btn8x = uicontrol('Style', 'togglebutton', 'Parent', obj.imPanel, ...
                                    'String', '8x', ...
                                    'units', 'normalized', ...
                                    'HorizontalAlignment', 'right', ...
                                    'Position', [0.31, 0.975, 0.05, 0.02], ...
                                    'Callback', @obj.btnPlaybackSpeed );

         
        obj.roiListBox = uicontrol('Style', 'listbox', 'Parent', obj.sidePanelR, ...
                                    'Min', 0, 'Max', 2, ...
                                    'FontSize', 12, ...
                                    'units', 'normalized', ...
                                    'Position', [0.05, 0.05, 0.4, 0.9], ...
                                    'Callback', @obj.selectListBoxObj);
        
        % Create ui controls of right side panel
        popupPosR = [0.55, 0.85, 0.4, 0.1];
        %btnPosR =  [0.55, 0.91, 0.4, 0.04];
        btnPosR =  [0.55, popupPosR(2), 0.4, 0.04];
        btnSpacing = 0.07;
        
        obj.roiclasspopup = uicontrol('Style', 'popupmenu', 'Parent', obj.sidePanelR, ...
                                    'String', obj.roiClasses, ...
                                    'Value', 1, ...
                                    'units', 'normalized', 'Position', popupPosR, ...
                                    'Callback', @obj.changeRoiClass);
        
        obj.btnDrawRoi = uicontrol('Style', 'togglebutton', 'Parent', obj.sidePanelR, ...
                                    'String', 'Draw Rois', 'Value', 0, ...
                                    'Units', 'normalized', 'Position', btnPosR, ...
                                    'Callback', @obj.drawRoi);
        
        btnPosR(2) = btnPosR(2) - btnSpacing;
        obj.btnAutoDetect = uicontrol('Style', 'togglebutton', 'Parent', obj.sidePanelR, ...
                                    'String', 'Autodetect Rois', 'Value', 0, ...
                                    'Units', 'normalized', 'Position', btnPosR, ...
                                    'Callback', @obj.autoDetectRoi);
                                
        btnPosR(2) = btnPosR(2) - btnSpacing;
        obj.btnEditRoi = uicontrol('Style', 'togglebutton', 'Parent', obj.sidePanelR, ...
                                    'String', 'Edit Rois', 'Value', 0,...
                                    'Units', 'normalized', 'Position', btnPosR, ...
                                    'Callback', @obj.editRoi);
        
        btnPosR(2) = btnPosR(2) - btnSpacing;
        obj.btnRemoveRoi = uicontrol('Style', 'pushbutton', 'Parent', obj.sidePanelR, ...
                                    'String', 'Remove Roi', ...
                                    'Units', 'normalized', 'Position', btnPosR, ...
                                    'Callback', @obj.removeRois);
        
        btnPosR(2) = btnPosR(2) - btnSpacing;
        obj.btnShowSignal = uicontrol('Style', 'togglebutton', 'Parent', obj.sidePanelR, ...
                                    'String', 'Show Signal', ...
                                    'Units', 'normalized', 'Position', btnPosR, ...
                                    'Callback', @obj.showSignalPlot);
                                                        
%         btnPosR(2) = btnPosR(2) - 0.08;
%         obj.btnRunAutoSegmentation = uicontrol('Style', 'pushbutton', 'Parent', obj.sidePanelR, ...
%                                     'String', 'Run auto segmentation', ...
%                                     'Units', 'normalized', 'Position', btnPosR, ...
%                                     'Callback', @obj.runAutoSegmentation, ...
%                                     'Enable', 'off');
%                                 
%         if exist('initialize_components', 'file')
%             set(obj.btnRunAutoSegmentation, 'Enable', 'on')
%         end
                                              
        btnPosR(2) = btnPosR(2) - btnSpacing;
        obj.btnLoadRois = uicontrol('Style', 'pushbutton', 'Parent', obj.sidePanelR, ...
                                    'String', 'Load Rois', ...
                                    'Units', 'normalized', 'Position', btnPosR, ...
                                    'Callback', @obj.loadRois);
                                 
        btnPosR(2) = btnPosR(2) - btnSpacing;
        obj.btnExportRois = uicontrol('Style', 'pushbutton', 'Parent', obj.sidePanelR, ...
                                    'String', 'Export Rois', ...
                                    'Units', 'normalized', 'Position', btnPosR, ...
                                    'Callback', @obj.exportRois);
                                
        btnPosR(2) = btnPosR(2) - btnSpacing;
        obj.btnExportSignal = uicontrol('Style', 'pushbutton', 'Parent', obj.sidePanelR, ...
                                    'String', 'Export Signal', ...
                                    'Units', 'normalized', 'Position', btnPosR, ...
                                    'Callback', @obj.exportSignal);
                                 
        btnPosR(2) = btnPosR(2) - btnSpacing;
        obj.btnClearAllRois  = uicontrol('Style', 'pushbutton', 'Parent', obj.sidePanelR, ...
                                    'String', 'Clear All Rois', ...
                                    'Units', 'normalized', 'Position', btnPosR, ...
                                    'Callback', @obj.clearRois);
                                 
        btnPosR(2) = btnPosR(2) - btnSpacing;
        obj.btnShowTags = uicontrol('Style', 'pushbutton', 'Parent', obj.sidePanelR, ...
                                    'String', 'Show Tags', ...
                                    'Units', 'normalized', 'Position', btnPosR, ...
                                    'Callback', @obj.showTags);
                                
        btnPosR(2) = btnPosR(2) - btnSpacing;
        obj.btnSetRoiSize = uicontrol('Style', 'pushbutton', 'Parent', obj.sidePanelR, ...
                                    'String', 'Set Roi Size for Autodetection', ...
                                    'Units', 'normalized', 'Position', btnPosR, ...
                                    'Callback', @obj.setRoiSize);
                                
        sliderPos = [0.55, btnPosR(2) - 0.04, 0.4, 0.03];                     
        jSlider = com.jidesoft.swing.RangeSlider(0, 30, obj.roiInnerDiameter, obj.roiOuterDiameter);
        [obj.roiSizeSlider, obj.roiSizeSliderContainer] = javacomponent(jSlider);
        obj.roiSizeSlider = handle(obj.roiSizeSlider, 'CallbackProperties');
        set(obj.roiSizeSlider, 'StateChangedCallback', @obj.sliderValueChange);
        set(obj.roiSizeSliderContainer, 'Parent', obj.sidePanelR, 'units', 'normalized', 'Position', sliderPos)
        set(obj.roiSizeSliderContainer, 'Visible', 'off')
                                 
        % Set some initial gui state varibles
        obj.mouseMode = 'Select';
        obj.nFrames = 0;
        obj.currentFrameNo = 0;  
        obj.roiCount = 0;
        
        % Load session if provided as argument to constructor
        if ~isempty(sessionID)
            obj.sessionID = sessionID;
            obj = loadSession(obj);
        end
        
        % Activate callback functions
        set(obj.fig, 'WindowButtonMotionFcn', {@obj.mouseOver})
        
        set(obj.fig, 'CurrentObject', obj.fig)
        
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
            
            if obj.btnShowSignal.Value
                set(obj.axStackDisplay, 'Position', [0.12, 0.12, 0.76, 0.94])
            end
            
            
%             % Resize ax for image display to keep it square
%             set(obj.imPanel, 'units', 'pixel')
%             panelPos = get(obj.imPanel, 'Position');
%             panelAR = (panelPos(3) / panelPos(4));
%             set(obj.imPanel, 'units', 'normalized')
%             set(obj.axStackDisplay, 'Position', [0.03/panelAR, 0.03, 0.94/panelAR, 0.94])
% 
        end
        
        
        function obj = setMouseMode(obj, newMouseMode)
        % Change the mode of mouseclicks in the GUI
            
            % Cancel rois if draw is unselected
            switch newMouseMode
                case {'Select', 'Autodetect', 'Set Roi Diameter'}
                    if obj.btnDrawRoi.Value && ~isempty(obj.RoiTmpEdges)
                        obj = cancelRoi(obj);
                    elseif obj.btnEditRoi.Value && ~isempty(obj.RoiTmpEdges)
                        obj = cancelRoi(obj);
                    end
                case 'EditSelect'
                    if obj.btnDrawRoi.Value && ~isempty(obj.RoiTmpEdges)
                        obj = cancelRoi(obj);
                    end
                case 'Draw'
                    if obj.btnEditRoi.Value && ~isempty(obj.RoiTmpEdges)
                        obj = cancelRoi(obj);
                    end
            end
            
            % Set mousemode
            switch newMouseMode
                case 'Previous'
                    if obj.btnDrawRoi.Value; 
                        obj.mouseMode = 'Draw';
                    elseif obj.btnEditRoi.Value
                        if isempty(obj.RoiTmpEdges)
                            obj.mouseMode = 'EditSelect';
                            obj.deselectRois();
                        else
                            obj.mouseMode = 'EditDraw';
                        end
                    elseif obj.btnAutoDetect.Value
                        obj.mouseMode = 'Autodetect';
                    elseif strcmp(obj.btnSetRoiSize.String, 'Confirm')
                        obj.mouseMode = 'Set Roi Diameter';
                    else
                        obj.mouseMode = 'Select';
                    end
                    
                case 'EditSelect'
                    obj.prevMouseMode = obj.mouseMode;
                    obj.mouseMode = newMouseMode;
                    obj.deselectRois();
                    
                case 'EditDraw'
                    obj.prevMouseMode = obj.mouseMode;
                    obj.mouseMode = newMouseMode;
                    
                otherwise
                    obj.prevMouseMode = obj.mouseMode;
                    obj.mouseMode = newMouseMode;
            end
            
            % Take care of togglebuttons. Only one active at the same time
            switch newMouseMode
                case 'Draw'
                    if ~obj.btnDrawRoi.Value; obj.btnDrawRoi.Value = 1; end
                    if obj.btnEditRoi.Value; obj.btnEditRoi.Value = 0; end
                    if obj.btnAutoDetect.Value; obj.btnAutoDetect.Value = 0; end
                    
                case 'Autodetect'
                    if obj.btnDrawRoi.Value; obj.btnDrawRoi.Value = 0; end
                    if obj.btnEditRoi.Value; obj.btnEditRoi.Value = 0; end
                    if ~obj.btnAutoDetect.Value; obj.btnAutoDetect.Value = 1; end
                
                case {'EditSelect', 'EditDraw'}
                    if obj.btnDrawRoi.Value; obj.btnDrawRoi.Value = 0; end
                    if ~obj.btnEditRoi.Value; obj.btnEditRoi.Value = 1; end
                    if obj.btnAutoDetect.Value; obj.btnAutoDetect.Value = 0; end
                
                case 'Select'
                    if obj.btnDrawRoi.Value; obj.btnDrawRoi.Value = 0; end
                    if obj.btnEditRoi.Value; obj.btnEditRoi.Value = 0; end
                    if obj.btnAutoDetect.Value; obj.btnAutoDetect.Value = 0; end
            end
            
            if obj.insideImageAx();
                obj.updatePointer();
            end
        
        end
        
        
        function obj = updatePointer(obj)
        % Change pointers according to mousemode

            if obj.insideImageAx()
                mousePoint = get(obj.axStackDisplay, 'CurrentPoint');
                mousePoint = mousePoint(1, 1:2);
                
                currentPointer = get(obj.fig, 'Pointer');
                switch obj.mouseMode
                    case {'Draw', 'EditDraw'}
                        xlim = get(obj.axStackDisplay, 'XLim');
                        impoint_extent = diff(xlim)/100;
                        if any(abs(obj.RoiTmpPosX - mousePoint(1)) < impoint_extent)
                            idx = find(abs(obj.RoiTmpPosX - mousePoint(1)) < impoint_extent);
                            if any(abs(obj.RoiTmpPosY(idx) - mousePoint(2)) < impoint_extent)
                                set(obj.fig,'Pointer', 'fleur');
                            else
                                set(obj.fig, 'Pointer', 'crosshair');
                            end
                        elseif ~strcmp(currentPointer, 'crosshair')
                           set(obj.fig, 'Pointer', 'crosshair');
                        end
                    case 'Autodetect'
                        if ~strcmp(currentPointer, 'cross')
                            set(obj.fig, 'Pointer', 'cross');
                        end
                    case 'EditSelect'
                        if ~strcmp(currentPointer, 'hand')
                           set(obj.fig, 'Pointer', 'hand');
                        end
                    case 'Set Roi Diameter'
                        if ~strcmp(currentPointer, 'circle')
                             set(obj.fig, 'Pointer', 'circle');
                        end
                    case 'Select'
                        if ~strcmp(currentPointer, 'hand')
                            set(obj.fig,'Pointer','hand');
                        end
                    case 'Zoom In'
                        if ~strcmp(currentPointer, 'custom') || strcmp(obj.prevMouseMode, 'Zoom Out')
                            setptr(obj.fig, 'glassplus');
                        end
                    case 'Zoom Out'
                        if ~strcmp(currentPointer, 'custom') || strcmp(obj.prevMouseMode, 'Zoom In')
                            setptr(obj.fig, 'glassminus');
                        end
                end
                
            else
                set(obj.fig, 'Pointer', 'arrow');
            end
            
        end
        
        
        function imageZoom(obj, direction)
        % Zoom in image    
            
            switch direction
                case 'in'
                        zoomF = -obj.zoomFactor;
                case 'out'
                        zoomF = obj.zoomFactor;
            end
                    
            xLim = get(obj.axStackDisplay, 'XLim');
            yLim = get(obj.axStackDisplay, 'YLim');

            mp_f = get(obj.fig, 'CurrentPoint');
            mp_a = get(obj.axStackDisplay, 'CurrentPoint');
            mp_a = mp_a(1, 1:2);

            % Find ax position and limits in figure units.
            figsize = get(obj.fig, 'Position');
            panelPos = get(obj.imPanel, 'Position') .* [figsize(3:4), figsize(3:4)];  % pixel units
            axPos = get(obj.axStackDisplay, 'Position') .* [panelPos(3:4), panelPos(3:4)];  % pixel units
            axPos = [panelPos(1:2), 0, 0] + axPos;
            axLim = axPos + [0, 0, axPos(1), axPos(2)];

            % Check if mousepoint is within axes limits.
            insideImageAx = ~any(any(diff([axLim(1:2); mp_f; axLim(3:4)]) < 0));

            xLimNew = xLim + [-1, 1] * zoomF * diff(xLim);
            yLimNew = yLim + [-1, 1] * zoomF * diff(yLim);

            if insideImageAx
                mp_f = mp_f - [axPos(1), axPos(2)];

                shiftX = (axPos(3)-mp_f(1)) / axPos(3)               * diff(xLimNew) - (xLim(1) + diff(xLim)/2 + diff(xLimNew)/2 - mp_a(1)) ;
                shiftY = (axPos(4)-abs(axPos(4)-mp_f(2))) / axPos(4) * diff(yLimNew) - (yLim(1) + diff(yLim)/2 + diff(yLimNew)/2 - mp_a(2)) ;
                xLimNew = xLimNew + shiftX;
                yLimNew = yLimNew + shiftY;
            end

            if diff(xLimNew) > obj.imWidth
                xLimNew = [0, obj.imWidth];
            elseif xLimNew(1) < 0
                xLimNew = xLimNew - xLimNew(1);
            elseif xLimNew(2) > obj.imWidth
                xLimNew = xLimNew - (xLimNew(2) - obj.imWidth);
            end

            if diff(yLimNew) > obj.imHeight
                yLimNew = [0, obj.imHeight];
            elseif yLimNew(1) < 0
                yLimNew = yLimNew - yLimNew(1);
            elseif yLimNew(2) > obj.imHeight
                yLimNew = yLimNew - (yLimNew(2) - obj.imHeight);
            end

            set(obj.axStackDisplay, 'XLim', xLimNew, 'YLim', yLimNew)
            
        end
        
        
        function imageZoomRect(obj)
        % Zoom in image according to rectangle coordinates.
        
            xData = get(obj.zoomRectPlotHandle, 'XData');
            yData = get(obj.zoomRectPlotHandle, 'YData');
            
            xLimNew = [min(xData), max(xData)];
            yLimNew = [min(yData), max(yData)];
                        
            if diff(xLimNew) > diff(yLimNew)
                yLimNew = yLimNew + [-1, 1] * (diff(xLimNew) - diff(yLimNew)) / 2;
            elseif diff(xLimNew) < diff(yLimNew)
                xLimNew = xLimNew + [-1, 1] * (diff(yLimNew) - diff(xLimNew)) / 2;
            end
            
            set(obj.axStackDisplay, 'XLim', xLimNew, 'YLim', yLimNew)
            
        end
        
        
        function bool = insideImageAx(obj)
        % Check if mousepoint is within axes limits of stack display
        
            currentPoint = get(obj.fig, 'CurrentPoint') ;
            
            % Find ax position and limits in figure units.
            figsize = get(obj.fig, 'Position');
            panelPos = get(obj.imPanel, 'Position') .* [figsize(3:4), figsize(3:4)];  % pixel units
            axPos = get(obj.axStackDisplay, 'Position') .* [panelPos(3:4), panelPos(3:4)];  % pixel units
            axPos = [panelPos(1:2), 0, 0] + axPos;
            axLim = axPos + [0, 0, axPos(1), axPos(2)];

            % Check if mousepoint is within axes limits.
            bool = ~any(any(diff([axLim(1:2); currentPoint; axLim(3:4)]) < 0));
            
        end
            
            
        function obj = keyPress(obj, ~, event)
        % Function to handle keyboard shortcuts. 
        
        % Pan and zoom functions are modified from axdrag (https://github.com/gulley/Ax-Drag)
        
            switch event.Key
                case 'd'
                    switch obj.mouseMode
                        case 'Draw'
                            obj.setMouseMode('Select');
                        otherwise
                            obj.setMouseMode('Draw');
                    end

                case 'a'
                    switch obj.mouseMode
                        case 'Autodetect'
                            obj.setMouseMode('Select');
                        otherwise
                            obj.setMouseMode('Autodetect');
                    end
                    
                case 'e'
                    switch obj.mouseMode
                        case 'EditSelect'
                            obj.setMouseMode('Select');
                        case 'EditDraw'
                            obj.setMouseMode('Select');
                        otherwise
                            obj.setMouseMode('EditSelect');
                    end
                    
                case 's'
                    obj.setMouseMode('Select');
                    
                case 'f'
                    obj.finishRoi();
                    
                case 'escape'
                    obj.cancelRoi();
                    
                case 'backspace'
                    obj.removeRois();
                
                case 'leftarrow'
                    xLim = get(obj.axStackDisplay, 'XLim');
                    xLimNew = xLim - obj.panFactor * diff(xLim);
                    if xLimNew(1) > 0 && xLimNew(2) < obj.imWidth
                        set(obj.axStackDisplay, 'XLim', xLimNew);
                    end
                
                case 'rightarrow'
                    xLim = get(obj.axStackDisplay, 'XLim');
                    xLimNew = xLim + obj.panFactor * diff(xLim);
                    if xLimNew(1) > 0 && xLimNew(2) < obj.imWidth
                        set(obj.axStackDisplay, 'XLim', xLimNew);
                    end
                
                case 'uparrow'
                    yLim = get(obj.axStackDisplay, 'YLim');
                    yLimNew = yLim - obj.panFactor * diff(yLim);
                    if yLimNew(1) > 0 && yLimNew(2) < obj.imWidth
                        set(obj.axStackDisplay, 'YLim', yLimNew);
                    end
                
                case 'downarrow'
                    yLim = get(obj.axStackDisplay, 'YLim');
                    yLimNew = yLim + obj.panFactor * diff(yLim);
                    if yLimNew(1) > 0 && yLimNew(2) < obj.imWidth
                        set(obj.axStackDisplay, 'YLim', yLimNew);
                    end
                    
                case {'z', 'Z'}
                    if event.Character == 'z'
                        obj.imageZoom('in');
                    else
                        obj.imageZoom('out');
                    end
                    
                case 'q'
                    switch obj.mouseMode
                        case 'Zoom In'
                            obj.setMouseMode('Previous');
                        otherwise
                            obj.setMouseMode('Zoom In');
                    end
                    
                case 'w'
                    switch obj.mouseMode
                        case 'Zoom Out'
                            obj.setMouseMode('Previous');
                        otherwise
                            obj.setMouseMode('Zoom Out');
                    end
                    
                case 'r'
                    set(obj.axStackDisplay, 'XLim', [0, obj.imWidth], 'YLim', [0, obj.imHeight])
                    
            end
            
        end
        
        
        function obj = mousePress(obj, ~, event)
        % Callback function to handle mouse presses on image obj
        
            % Record mouse press and current mouse position
            obj.mouseDown = true;
            
            % Get current mouse position in ax
            x = event.IntersectionPoint(1);
            y = event.IntersectionPoint(2);
            
            obj.prevMousePointAx = [x, y];
            obj.prevMouseClick = [x, y];
            obj.prevMousePointFig = get(obj.fig, 'CurrentPoint');
            
            switch obj.mouseMode 
                case {'Draw', 'EditDraw'}        % Convert mouseclick to roi vertex
                    switch get(obj.fig, 'SelectionType')
                        case 'normal'
                            obj.RoiTmpPosX(end+1) = x;
                            obj.RoiTmpPosY(end+1) = y;
                            obj = addTmpRoiVertex(obj, obj.axStackDisplay, x, y);
                            drawTmpRoi(obj, obj.axStackDisplay);
                        case {'extend', 'alt'}
                            obj.finishRoi();
                    end
                    
                case 'Autodetect'
                    newRoi = autodetect(obj, x, y);
                    wasInRoi = 0;
                    for i = 1:length(obj.roiArray);
                        if obj.isInRoi(obj.roiArray(i), x, y)
                            wasInRoi = 1;
                            oldRoi = obj.roiArray(i);
                            break
                        end
                    end
                    
                    if wasInRoi
                        newRoi = obj.inheritRoiProperties(newRoi, oldRoi);
                        newRoi.Shape = oldRoi.Shape;
                        % Replot the roi
                        obj.roiArray(i) = newRoi;
                        updateRoiPlot(obj, i, newRoi);
                         
                    elseif ~isempty(newRoi)
                        newRoi.Group = obj.roiclasspopup.String{obj.roiclasspopup.Value};
                        newRoi.Shape = 'Autothreshold';
                        newRoi.ID = obj.roiCount + 1;
                        newRoi.Tag = [obj.roiTags{obj.roiclasspopup.Value}, num2str(newRoi.ID,'%03d')];
                        newRoi.Selected = false;
                        obj.roiArray(end+1) = newRoi;
                        obj = plotRoi(obj, newRoi);
                        obj.roiCount = obj.roiCount + 1;
                        obj = updateListBox(obj);
                    end
                
                case 'EditSelect'
                    wasInRoi = 0;
                    for i = 1:length(obj.roiArray);
                        if obj.isInRoi(obj.roiArray(i), x, y)
                            wasInRoi = 1;
                            obj.selectedRois = i;
                            roi = obj.roiArray(i);
                            break
                        end
                    end
                    
                    if wasInRoi
                        if isempty(roi.imPointsX) % Use boundary to create impoints
                        	roi.imPointsX = roi.Boundary{1}(1:5:end, 2);
                            roi.imPointsY = roi.Boundary{1}(1:5:end, 1);
                        end
                        obj.RoiTmpPosX = roi.imPointsX;
                        obj.RoiTmpPosY = roi.imPointsY;
                        
                        % Add impoints to ax.
                        for i = 1:length(obj.RoiTmpPosX)
                            x = obj.RoiTmpPosX(i);
                            y = obj.RoiTmpPosY(i);
                            obj = addTmpRoiVertex(obj, obj.axStackDisplay, x, y);
                        end
                        
                        % Remove plot of selected roi
                        hold on
                        h = obj.RoiPlotHandles(obj.selectedRois);
                        set(h, 'XData', 0, 'YData', 0)
                        hold off
                        
                        % Draw the draggable polygon selection
                        obj = drawTmpRoi(obj, obj.axStackDisplay);
                        
                        obj.setMouseMode('EditDraw');
                    end
                    
                case 'Set Roi Diameter'
                    obj.roiTemplateCenter = [x, y];
                    obj.plotRoiTemplate();

                case 'Select'           % Change status of roi if it was clicked
                    
                    wasInRoi = 0;
                    for i = 1:length(obj.roiArray);
                        if obj.isInRoi(obj.roiArray(i), x, y)
                            wasInRoi = 1;
                            selectedRoi = i;
                            break
                        end
                    end
                    
                    if ~wasInRoi
                        selectedRoi = nan;
                    end
                    
                    switch get(obj.fig, 'SelectionType');
                    
                        case 'normal'
                            unselectedRois = obj.selectedRois(obj.selectedRois ~= selectedRoi);

                            if wasInRoi && ~any(obj.selectedRois == selectedRoi)   
                                    obj.RoiPlotHandles(selectedRoi).Color = 'White';
                                    obj.RoiTextHandles(selectedRoi).Color = 'White';
                            end

                            for i = unselectedRois
                                color = obj.getRoiColor(obj.roiArray(i));
                                obj.RoiPlotHandles(i).Color = color;
                                obj.RoiTextHandles(i).Color = color;
                            end
                            
                            if obj.btnShowSignal.Value
                                if wasInRoi
                                    obj.updateSignalPlot(selectedRoi, 'overwrite');
                                else
                                    obj.resetSignalPlot();
                                end
                            end
                            
                            % Update selected rois array and listbox 
                            if isnan(selectedRoi); selectedRoi = []; end
                            obj.selectedRois = selectedRoi;
                            obj.roiListBox.Value = selectedRoi;
                            
                        case 'extend'
                            if wasInRoi && ~any(obj.selectedRois == selectedRoi)   
                                obj.RoiPlotHandles(selectedRoi).Color = 'White';
                                obj.RoiTextHandles(selectedRoi).Color = 'White';
                                    if obj.btnShowSignal.Value
                                        obj.updateSignalPlot(selectedRoi, 'append');
                                    end
                                obj.selectedRois = horzcat(obj.selectedRois, selectedRoi); % test
                                obj.roiListBox.Value = horzcat(obj.roiListBox.Value,selectedRoi); %test
                                    
                            end
                    end
                 
                case 'Zoom In'
                    axes(obj.axStackDisplay)
                    hold on
                    if isempty(obj.zoomRectPlotHandle)
                        obj.zoomRectPlotHandle = plot(nan, nan);
                    else
                        set(obj.zoomRectPlotHandle, 'XData', nan, 'Ydata', nan)
                    end
                    set(obj.zoomRectPlotHandle, 'Visible', 'on')
                 
                case 'Zoom Out'
                    obj.imageZoom('out');
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
        
            obj.mouseDown = false;
            
            switch obj.mouseMode
                case 'Zoom In'
                    currentPoint = get(obj.axStackDisplay, 'CurrentPoint');
                    currentPoint = currentPoint(1, 1:2);
                    
                    set(obj.zoomRectPlotHandle, 'Visible', 'off')
                    
                    if all((abs(obj.prevMouseClick - currentPoint)) < 1) % No movement
                        obj.imageZoom('in');
                    else
                        obj.imageZoomRect(); % Set new limits based on new and old point
                    end
                    
                    axes(obj.axStackDisplay)
                    hold off
                    
                case 'Select'
                    if obj.roiDisplacement ~= 0
                        obj.moveRoi(obj.roiDisplacement);
                        obj.roiDisplacement = 0;
                    end
            end      
            
        end
        
        
        function obj = mouseOver(obj, ~, ~)
        % Callback funtion to handle mouse movement over figure
            
            % Get mousepoint coordinates in ax and figure units
            newMousePointFig = get(obj.fig, 'CurrentPoint');
            newMousePointAx = get(obj.axStackDisplay, 'CurrentPoint');
            newMousePointAx = newMousePointAx(1, 1:2);
            
            obj.updatePointer();
            
            if obj.insideImageAx() && obj.mouseDown   % "Click and Drag"
                set(obj.fig, 'CurrentObject', obj.imPanel)
                
                switch obj.mouseMode
                    case 'Select'

                        % Move roi to new position
                        if ~isempty(obj.selectedRois)
                            shift = newMousePointAx - obj.prevMousePointAx;
                            obj.roiDisplacement = obj.roiDisplacement + shift;
                            obj.shiftRoiPlot([shift, 0]);
                            
                        % Move image to new position (pan). 
                        else
                            % Need to use figure coordinates, because axes coordinates are
                            % continuously changed
                            shift = newMousePointFig - obj.prevMousePointFig;
                            obj.moveImage(shift);
                        end
                        
                        % Reset previous coordinates to current
                        obj.prevMousePointAx = newMousePointAx;
                        obj.prevMousePointFig = newMousePointFig;
                    
                    case 'Zoom In'
                        % Plot a rectangle 
                        x1 = obj.prevMouseClick(1);
                        x2 = newMousePointAx(1);
                        y1 = obj.prevMouseClick(2);
                        y2 = newMousePointAx(2);
                        set(obj.zoomRectPlotHandle, 'XData', [x1, x1, x2, x2, x1], ...
                                                    'YData', [y1, y2, y2, y1, y1])

                end
         
            else % Release mouseDown if mouse moves out of image.
                set(obj.fig, 'CurrentObject', obj.fig)
                if obj.mouseDown
                    obj.mouseDown = false;
                end
            end
        end
        
        
        function obj = moveImage(obj, shift)
        % Move image in ax according to shift
            
            % Get ax position in figure coordinates
            figsize = get(obj.fig, 'Position');
            panelPos = get(obj.imPanel, 'Position') .* [figsize(3:4), figsize(3:4)];  % pixel units
            axPos = get(obj.axStackDisplay, 'Position') .* [panelPos(3:4), panelPos(3:4)];  % pixel units
            axPos = [panelPos(1:2), 0, 0] + axPos;
        
            % Get current axes limits
            xlim = get(obj.axStackDisplay, 'XLim');
            ylim = get(obj.axStackDisplay, 'YLim');
            
            % Convert mouse shift to image shift
            imshift = shift ./ axPos(3:4) .* [diff(xlim), diff(ylim)];
            xlim = xlim - imshift(1);
            ylim = ylim + imshift(2);

            % Dont move outside of image boundaries..
            if xlim(1) > 0 && xlim(2) < obj.imWidth
                set(obj.axStackDisplay, 'XLim', xlim);
            end
            if ylim(1) > 0 && ylim(2) < obj.imHeight
                set(obj.axStackDisplay, 'YLim', ylim);
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
        % Get sessionID and number of blocks. Create list of blocks for
        % block popupmenu.
            
            if source.Value ~= 1
                obj.sessionID = source.String{source.Value};
                % Find number of blocks for session
                sessionInfo = loadSessionInfo(obj.sessionID);
                nBlocks = sessionInfo.nBlocks;
                blockStr = arrayfun(@(x) ['Block ' num2str(x)], 1:nBlocks, 'uni', 0);
                obj.blockpopup.String = horzcat({'Select Block'}, blockStr );
                obj.blockpopup.Value = 1;             
            else
                obj.sessionID = [];
            end
            
        end
        
        
        function obj = loadSession(obj)
        % Load first stack of a session and roi array if it exists
            %Change session
            
            % Change Mouse
            mouse = strrep(obj.sessionID(1:4), 'm', 'mouse');
            obj.mousepopup.Value = find(strcmp(obj.mousepopup.String, mouse));
            obj.changeMouse(obj.mousepopup, []);
            
            % Change Session
            obj.sessionpopup.Value = find(strcmp(obj.sessionpopup.String, obj.sessionID));
            obj.changeSession(obj.sessionpopup, []);
            
            % Open first block
            obj.blockpopup.Value = 2; % Later, 1 will be subtracted
            obj.loadStack();
            
            sessionFolder = getSessionFolder(obj.sessionID);
            roiFiles = dir(fullfile(sessionFolder, 'roi_arr*'));
            if ~isempty(roiFiles)
                roiFileVar = load(fullfile(sessionFolder, roiFiles(1).name));
                rois = roiFileVar.roi_arr;
                obj = appendRoiArray(obj, rois);
            end
            
            
        end
        
        
        function obj = loadStack(obj, ~, ~)
        % Load an image stack into the GUI
            
            % Start browsing from session folder or desktop
            if ~isempty(obj.sessionID)
                initpath = getSessionFolder(obj.sessionID);
            else
                initpath = obj.initPath;
            end
            
            % If no block is selected, open the filebrowser.
            if isempty(obj.blockpopup)
                openBrowser = true;
            else
                if obj.blockpopup.Value == 1
                    openBrowser = true;
                else 
                    openBrowser = false;
                end
            end
            
            if openBrowser
                [obj.fileName, obj.filePath, ~] =  uigetfile({'tif', 'Tiff Files (*.tif)'; ...
                                            'tiff', 'Tiff Files (*.tiff)'; ...
                                            '*', 'All Files (*.*)'}, ...
                                            'Find Stack', ...
                                            initpath);

                if obj.fileName == 0 % User pressed cancel
                    return
                else
                   obj.initPath = obj.filePath;
                end

                obj.imFilePath = fullfile(obj.filePath, obj.fileName);
                
                % Determine channel
                strindex = strfind(obj.fileName, 'ch');
                if ~isempty(strindex)
                    set(obj.channel, 'String', obj.fileName(strindex+2))
                end
            
            % If block is selected, automatically open aligned image stack
            % for that block
            else
                block = obj.blockpopup.Value - 1;
                blockFiles = dir(fullfile(initpath, 'calcium_images_aligned', '*block*'));
                
                %Find channels
                strIdx = cellfun(@(fn) strfind(fn, 'ch'), {blockFiles.name}, 'uni', 0);
                ch = arrayfun(@(x) blockFiles(x).name(strIdx{x}+2), 1:length(blockFiles), 'uni', 0);
                uniqueCh = unique(ch);
                
                % Open selected channel and block...
                selectedChannel = get(obj.channel, 'String');
                if any(strcmp(uniqueCh, selectedChannel))
                    strPattern = ['*block', num2str(block, '%03d'), '_ch', selectedChannel, '*'];
                    fileMatch = regexp({blockFiles.name}, regexptranslate('wildcard', strPattern));
                    fileIdx = find(cellfun( @(x) ~isempty(x), fileMatch));
                    blockFiles(fileIdx(1)).name
                    obj.fileName = blockFiles(fileIdx(1)).name;
                else
                    error('Can not find images for selected channel')
                end
                
                obj.filePath = initpath;
                obj.imFilePath = fullfile(obj.filePath, 'calcium_images_aligned', obj.fileName );   
            end
            
            % Try to open image stack as a TIFFStack object. If fail: load to array
%             try
%                 obj.tiffStack = TIFFStack(obj.imFilePath);
%                 obj.tiffClass = 'TIFFStack';
%             catch
                obj.tiffStack = stack2mat(obj.imFilePath, true);
                obj.tiffClass = 'double';
%             end
            
            obj.tiffStackMedfilt = [];
            
            % Get image dimensions
            [obj.imWidth, obj.imHeight, obj.nFrames] = size(obj.tiffStack);
            
            % Load average and max stack projections
            obj = loadStackProjections(obj);
            
            % Determine channel
            strindex = strfind(obj.fileName, 'ch');
            set(obj.channel, 'String', obj.fileName(strindex+2))
            
            % (Re)set current frame to first frame
            obj.currentFrameNo = 1;
            
            % Set up frame indicators and frameslider
            if obj.nFrames < 11
                sliderStep = [1/(obj.nFrames-1), 1/(obj.nFrames-1)];
            else
                sliderStep = [1/(obj.nFrames-1), 10/(obj.nFrames-10)];
            end
            
            set(obj.currentFrameIndicator, 'String', ['Current Frame: 1/' num2str(obj.nFrames)] )
            set(obj.currentFileName, 'String',  obj.fileName)
            set(obj.inputJumptoFrame, 'String', '1')
            set(obj.frameslider, 'Max', obj.nFrames, ...
                                 'Value', obj.currentFrameNo, ...
                                 'SliderStep', sliderStep, ...
                                 'Visible', 'on');
            
            % Set limits of signal Plot
            set(obj.axSignalPlot, 'Xlim', [1, obj.nFrames])
                             
                             
            % Reset some buttons
            set(obj.btnShowMovingAvg, 'Value', 0)
            set(obj.btnShowMovingStd, 'Value', 0) 
            set(obj.btnShowMovingMax, 'Value', 0)                 
                             
            % Display image
            obj = updateImageDisplay(obj);

        end
        
         function obj = loadNextStack(obj, ~, ~)
        % Load an image stack into the GUI
            % Reset some buttons
            set(obj.btnShowMovingAvg, 'Value', 0)
            set(obj.btnShowMovingStd, 'Value', 0) 
            set(obj.btnShowMovingMax, 'Value', 0)                 
                             
            % Display image
            obj = updateImageDisplay(obj);

        end
        
        function obj = loadStackProjections(obj)
        % Load average and max stack projections into the GUI
            
            % Load average or max projection from session folder
            if ~isempty(obj.sessionID)
                if obj.nFrames < 20 % No need to store projection on hdd
                    obj.stackMax = max(obj.tiffStack, [], 3);
                    obj.stackAvg = mean(obj.tiffStack, 3);
                else
                    loadPath = fullfile(getSessionFolder(obj.sessionID), 'preprocessed_data');
                    filenmAvg = strrep(obj.fileName, 'calcium_images', 'stackAVG');
                    filenmMax = strrep(obj.fileName, 'calcium_images', 'stackMax');
                    
                    if exist(fullfile(loadPath, filenmAvg), 'file')
                        obj.stackAvg = imread(fullfile(loadPath, filenmAvg));
                    else 
                        if strcmp(obj.tiffClass, 'TIFFStack') % Need array to apply mean and max
                            tmpTiffStack = stack2mat(obj.imFilePath);
                            obj.stackAvg = uint8(mean(tmpTiffStack, 3));
                        else
                            obj.stackAvg = uint8(mean(obj.tiffStack, 3));
                        end
                        %imwrite(uint8(obj.stackAvg), fullfile(loadPath, filenmAvg), 'TIFF')
                    end
                    
                    if exist(fullfile(loadPath, filenmMax), 'file')
                        obj.stackMax = imread(fullfile(loadPath, filenmMax));
                    else
                        if strcmp(obj.tiffClass, 'TIFFStack') && exist('tmpTiffStack', 'var')
                            obj.stackMax = uint8(max(tmpTiffStack, [], 3));
                        elseif strcmp(obj.tiffClass, 'TIFFStack') && ~exist('tmpTiffStack', 'var') % Need array to apply mean and max
                            tmpTiffStack = stack2mat(obj.imFilePath);
                            obj.stackMax = uint8(max(tmpTiffStack, [], 3));
                        else
                            obj.stackMax = max(obj.tiffStack, [], 3);
                        end
                        %imwrite(uint8(obj.stackAvg), fullfile(loadPath, filenmAvg), 'TIFF')
                    end
                end
            
            else
                if strcmp(obj.tiffClass, 'TIFFStack') % Need array to apply mean and max
                    tmpTiffStack = stack2mat(obj.imFilePath, [], 'on');
                    obj.stackMax = max(tmpTiffStack, [], 3);
                    obj.stackAvg = uint8(mean(tmpTiffStack, 3)); 
                else
                    obj.stackMax = max(obj.tiffStack, [], 3);
                    obj.stackAvg = uint8(mean(obj.tiffStack, 3)); 
                end
            end
            
            if exist('tmpTiffStack', 'var')
                clearvars tmpTiffStack
            end
                        
        end

        
        function obj = updateImageDisplay(obj)
        % Updates the image in the image display
        
            frameNo = obj.currentFrameNo;
            
            if obj.nFrames > 1 
                set( obj.currentFrameIndicator, 'String', ...
                      ['Current Frame: ' num2str(obj.currentFrameNo) '/' num2str(obj.nFrames)] )
            end

            showMovingAvg = get(obj.btnShowMovingAvg, 'Value');
            showMovingStd = get(obj.btnShowMovingStd, 'Value');
            showMovingMax = get(obj.btnShowMovingMax, 'Value');

            if showMovingAvg || showMovingMax || showMovingStd
                if frameNo < ceil(obj.binningSize/2);
                    binIdx = 1:obj.binningSize;
                elseif (obj.nFrames - frameNo)  < ceil(obj.binningSize/2)
                    binIdx = obj.nFrames-obj.binningSize+1:obj.nFrames;
                else
                    binIdx = frameNo - floor(obj.binningSize/2):frameNo + floor(obj.binningSize/2);
                end
                 
            end

            if showMovingAvg
                group = obj.tiffStack(:, :, binIdx);
                caframe = uint8(mean(group, 3));
            elseif showMovingMax
                group = obj.tiffStackMedfilt(:, :, binIdx);
                caframe = max(group, [], 3);
            elseif showMovingStd
                group = double(obj.tiffStackMedfilt(:, :, binIdx));
                %group = double(obj.tiffStack(:, :, binIdx));
                caframe = std(group, [], 3);
                caframe = uint8(caframe/max(caframe(:))*255);
            else
                caframe = obj.tiffStack(:, :, frameNo);
            end
            
            if isempty(obj.imageObj) % First time initialization. Create image object
               obj.imageObj = imshow(caframe, [0, 255], 'Parent', obj.axStackDisplay, 'InitialMagnification', 'fit');
               set(obj.imageObj, 'ButtonDownFcn', @obj.mousePress)
            else
               set(obj.imageObj, 'cdata', caframe);
            end
            
            obj.updateFrameMarker();
            
        end
        
        
        function obj = changeFrame(obj, source, event, action)
        % Callback from different sources to change the current frame.

            switch action
                case 'mousescroll'
                    i = event.VerticalScrollCount*3;
                case {'slider', 'buttonclick'}
                    newValue = source.Value;
                    i = newValue -  obj.currentFrameNo;
                    i = round(i);
                case {'jumptoframe'}
                    i = str2double(source.String) -  obj.currentFrameNo;
                    i = round(i);
                case 'playvideo'
                    i = 1;
                otherwise
                    i = 0;   
            end

            % Check that new value is within range and update current frame/slider info
            if (obj.currentFrameNo + i) >= 1  && (obj.currentFrameNo + i) <= obj.nFrames
                obj.currentFrameNo = round(obj.currentFrameNo + i);
                set(obj.frameslider, 'Value', obj.currentFrameNo );
                set(obj.inputJumptoFrame, 'String', num2str(obj.currentFrameNo))
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
                obj.plotFrameMarker = plot(obj.axSignalPlot, [1, 1], get(obj.axSignalPlot, 'ylim'), 'r', 'Visible', 'off', 'HitTest', 'off');
            else
                set(obj.plotFrameMarker, 'XData', [frameNo, frameNo]);
            end
        end
              
        
        function obj = drawRoi(obj, source, ~)
        % Button Callback. Start or finish marking of a roi. 
            
            if source.Value
                obj.setMouseMode('Draw');
                set(obj.btnAutoDetect, 'Value', 0)
                
            else
                obj.cancelRoi();
                obj.setMouseMode('Select');
                obj.unFocusButton(obj.btnDrawRoi)
            end  
                      
        end
        
        
        function obj = finishRoi(obj)
        % Finish a "drawn" roi object
        
        switch obj.mouseMode
            case 'Draw'
                newRoi = makeRoi(obj);
                if ~isempty(newRoi)
                    obj.roiArray(end+1) = newRoi;
                    obj = plotRoi(obj, newRoi);
                    obj.roiCount = obj.roiCount + 1;
                end
                obj = updateListBox(obj);
                obj = removeTmpRoi(obj);
                
            case 'EditDraw'
                roi = obj.roiArray(obj.selectedRois);
                % Make new roi with some inherited properties
                newRoi = makeRoi(obj);
                newRoi = obj.inheritRoiProperties(newRoi, roi);
                obj.roiArray(obj.selectedRois) = newRoi;
                
                % Replot the roi
                updateRoiPlot(obj, obj.selectedRois, newRoi);

                % Remove the temporary roi polygon 
                obj = removeTmpRoi(obj);
                obj.setMouseMode('EditSelect');
        end
            
        end
        
        
        function obj = cancelRoi(obj)
        % Cancel a "drawn" roi object
            
            % Remove Temporary Roi Object
            obj = removeTmpRoi(obj);
            
            % Replot Roi if edit mode is active
            if strcmp(obj.mouseMode, 'EditDraw')
                updateRoiPlot(obj, obj.selectedRois, obj.roiArray(obj.selectedRois));
                obj.setMouseMode('EditSelect');
            end
        end
        
        
        function obj = autoDetectRoi(obj, source, ~)
        % Button Callback. Start or finish autodetection of roi by clicking on it. 
            
            if source.Value
                obj.setMouseMode('Autodetect');
            else
                obj.setMouseMode('Select');
                obj.unFocusButton(obj.btnAutoDetect)
            end  
        end
            
        
        function obj = editRoi(obj, source, ~)
        % Button Callback. Start or finish editing of rois.

            if source.Value
                obj.setMouseMode('EditSelect');
                set(obj.btnAutoDetect, 'Value', 0)
                
            else
                obj.cancelRoi();
                obj.setMouseMode('Select');
                obj.unFocusButton(obj.btnDrawRoi)
            end  
            
        end
        
        
        function obj = removeRois(obj, ~, ~)
        % Button callback. Remove selected rois from gui
        
            obj.roiListBox.Value = [];
            
            % Loop through selected rois, remove roi objects and associated
            % plots. Also clear the roi from the listbox
            for i = fliplr(obj.selectedRois)
                obj.roiArray(i) = [];
                delete(obj.RoiPlotHandles(i))
                delete(obj.RoiTextHandles(i))
                obj.RoiPlotHandles(i) = [];
                obj.RoiTextHandles(i) = [];
                obj.roiListBox.String(i) = []; 
            end
            obj.selectedRois = [];
            
            obj.reorderRoiIds();
            
            
        end

        
        function obj = clearRois(obj, ~, ~)
        % Button callback. Remove all rois from gui and listbox, and remove
        % all plots and labels.
            
            obj.roiListBox.Value = [];
            obj.roiArray = RoI.empty;
            if ~isempty(obj.RoiPlotHandles)
                for i = 1:length(obj.RoiPlotHandles)
                    delete(obj.RoiPlotHandles(i))
                end
            end
            if ~isempty(obj.RoiTextHandles)
                for i = 1:length(obj.RoiTextHandles)
                    delete(obj.RoiTextHandles(i))
                end
            end

            obj.RoiPlotHandles = [];
            obj.RoiTextHandles = [];
            obj.roiListBox.String = {};
            obj.selectedRois = [];
            obj.roiCount = 0;
            
        end
        
              
        function obj = drawTmpRoi(obj, ax)
        % Draw the lines between the impoints of tmp roi. 
        
            % Get list of vertex points
            x = obj.RoiTmpPosX;
            y = obj.RoiTmpPosY;
            
            if length(x) < 2 || length(y) < 2
                return
            end
            
            % Close the circle
            x(end+1) = x(1);
            y(end+1) = y(1);
            
            % There should only be one instance of the tmp roi plot. 
            if isempty(obj.RoiTmpPlotHandle) || ~isvalid(obj.RoiTmpPlotHandle)
                axes(ax);
                hold on
                obj.RoiTmpPlotHandle = plot(0,0);
                obj.RoiTmpPlotHandle.HitTest = 'off';
                obj.RoiTmpPlotHandle.PickableParts = 'none';
                hold off
            end
            set(obj.RoiTmpPlotHandle,'XData',x,'YData',y);
        end
        
        
        function obj = addTmpRoiVertex(obj, ax, x, y)
        % ADDTMPROIVERTEX adds a new tmp roi vertex to the axes.  
        % After the impoint is created it is also configured.
        %   addTmpRoiVertex(obj, ax, x, y)
        %   x, y       - Coordinates in pixels. 
        %
        %   See also configImpoint, impoint

            % Find the index of this edge.
            i = length(obj.RoiTmpEdges) + 1;
            
            % The vertices are impoints that can be moved around. 
            tmpRoiVertex = impoint(ax, x, y);
            configImpoint(obj, ax, tmpRoiVertex, i);
            obj.RoiTmpEdges{end+1} = tmpRoiVertex;
        end
        
        
        function obj = moveTmpRoiVertex(obj, ax, x, y, i)
        %MOVETMPROIVERTEX moves a vertex (impoint) of the tmproi. Will also redraw
        %the lines between the vertices. 
        %   moveTmpRoiVertex(obj, ax, x, y, i)
        %   x, y          - New coordinates in pixels. 
        %   i             - Index of the vertex in obj.RoiTmpPos
        %
        % See also callbackRoiPosChanged.

            obj.RoiTmpPosX(i) = x;
            obj.RoiTmpPosY(i) = y;
            % Draw the lines between the edges.
            obj = drawTmpRoi(obj, ax);
            % Move the impoint objects to the edges. 
            obj.RoiTmpEdges{i}.setPosition([x,y]);
            
        end

        
        function configImpoint(obj, ax, impointObj, i)
        %CONFIGIMPOINT configures an impoint. 
        % Sets the new position callback of impoints. They are responsible for
        % updating the plot when a vertex is moved. 
        %   configImpoint(obj, ax, impointObj, i)
        %   impointObj    - impoint to configure. 
        %   i             - Sent to the move callback. Index of the impoint. 
        %
        % See also impoint, moveTmpRoiVertex

            impointObj.addNewPositionCallback(@(pos)callbackRoiPosChanged(obj, pos, ax, i));
            impointObj.setPositionConstraintFcn(@(pos)lockImpointInZoomMode(obj, pos, i))
            impointObj.Deletable = false;
        end
        
        
        function constrained_pos = lockImpointInZoomMode(obj, new_pos, i)
        % Callback function when dragging impoint. Locks impoint in place
        % during zoom mode.
            switch obj.mouseMode
                case {'Zoom In', 'Zoom Out'}
                	x = obj.RoiTmpPosX(i);
                    y = obj.RoiTmpPosY(i);
                    constrained_pos = [x, y];
                otherwise
                    constrained_pos = new_pos;
            end
                            
        end
        
        
        function obj = callbackRoiPosChanged(obj, pos, ax, i)
        % callback function of impoint. 
        % This function is called whenever a impoint is moved (Tmp RoI vertex). 
        %
        % See also configImpoint, impoint, moveTmpRoiVertex
        
            x = pos(1);
            y = pos(2);
            
            obj = moveTmpRoiVertex(obj, ax, x, y, i);
            
            
        end
        
        
        function roiNew = makeRoi(obj)
        %MAKEROI create a new RoI and add it to the gui. 
        %   roiNew = makeRoi(obj)
        %
        % obj           - Gui object. 
        %
        % Will set these properties in addition to RoI constructor:
        %   RoI.Group
        %   RoI.Shape
        %   RoI.ID
        %   RoI.Tag
        %   RoI.Channel
        %
        % See also RoI. 
        
            roiNew = [];
            x = obj.RoiTmpPosX;
            y = obj.RoiTmpPosY;
            if length(x) < 3 || length(y) < 3
                return
            end
            
            groupName = obj.roiclasspopup.String{obj.roiclasspopup.Value};
            id = obj.roiCount + 1;
            
            % Create a RoI object
            [m, n, ~] =  size(obj.tiffStack);
            bw = poly2mask(x, y, m, n);
            roiNew = RoI(bw);
            roiNew.imPointsX = x;
            roiNew.imPointsY = y;
            roiNew.Group = groupName;
            roiNew.Shape = 'Polygon';
            roiNew.ID = id;
            roiNew.Tag = [obj.roiTags{obj.roiclasspopup.Value}, num2str(id,'%03d')];
            roiNew.Selected = false;
            
        end
        
        
        function obj = removeTmpRoi(obj)
        %REMOVETMPROI clear the obj.RoiTmpPos or obj.RoiTmpEdges.

            obj.RoiTmpPosX = [];
            obj.RoiTmpPosY = [];
            len = length(obj.RoiTmpEdges);
            for i = 1:len
                delete(obj.RoiTmpEdges{i});
            end
            
            delete(obj.RoiTmpPlotHandle)

            obj.RoiTmpEdges = cell(0);
            
        end
         
         
        function obj = updateListBox(obj)
        % UPDATELISTBOX updates the listbox by creating a list of roi names based on 
        % roiArray. Selects the list box items according to the RoIs which
        % are selected.
            
            rois = obj.roiArray;
            tags = arrayfun(@(roi) roi.Tag, rois, 'uni', 0);
            obj.roiListBox.String = tags;

            % Find the tag index that belongs to roi nr. i . and mark rois in listbox
            % that are selected.
            %values = [];
            
%             for i = 1:length(rois)
%                 roiTag = rois(i).Tag;
%                 for j = 1:length(tags)
%                     if isequal(roiTag, tags{j})
%                         tagIdx = j;
%                         break
%                     end
%                 end
%                 if rois(i).Selected
%                     values(end+1) = tagIdx;
%                 end
%             end


            obj.roiListBox.Value = obj.selectedRois;
            
        end
         
         
        function obj = selectListBoxObj(obj, source, ~)
        % Change selection status of roi that are selected in listbox
        
            if ~strcmp(obj.mouseMode, 'EditSelect')
                selected = source.Value;
                newlySelected  = setdiff(selected, obj.selectedRois);
                unselectedRois = setdiff(obj.selectedRois, selected);

                if ~isempty(newlySelected)
                    for i = newlySelected
                        obj.RoiPlotHandles(i).Color = 'White';
                        obj.RoiTextHandles(i).Color = 'White';
                    end
                end

                if ~isempty(unselectedRois)
                    for i = unselectedRois
                        color = obj.getRoiColor(obj.roiArray(i));
                        obj.RoiPlotHandles(i).Color = color;
                        obj.RoiTextHandles(i).Color = color;
                    end
                end

                obj.selectedRois = selected;
                
                if obj.btnShowSignal.Value
                    obj.resetSignalPlot();
                    for i = selected
                        obj.updateSignalPlot(i, 'append');
                    end
                end
                
            else 
                source.Value = [];
            end
            
        end
        
        
        function obj = deselectRois(obj)
        % Deselect all selected rois
        
            for i = obj.selectedRois
                color = obj.getRoiColor(obj.roiArray(i));
                obj.RoiPlotHandles(i).Color = color;
                obj.RoiTextHandles(i).Color = color;
            end
            
            obj.selectedRois = [];
        
        end
        
        
        function obj = plotRoi(obj, roi)
        % Plot the roi in the ax.
        
            axes(obj.axStackDisplay);
            hold on
            
            roiColor = obj.getRoiColor(roi);
            % Add each boundary to the plot
            for j = 1:length(roi.Boundary)
                boundary = roi.Boundary{j};
                if j == 1
                    h = plot(boundary(:,2), boundary(:,1));
                else
                    h.XData = horzcat(h.XData, nan, boundary(:,2).');
                    h.YData = horzcat(h.YData, nan, boundary(:,1).');
                end
            end

            if isempty(obj.RoiPlotHandles)
                   obj.RoiPlotHandles = gobjects(0);
            end
            
            % Add plot handle to gui obj and set some properties
            obj.RoiPlotHandles(end+1) = h;
            h.HitTest = 'off';
            h.PickableParts = 'none';
            if roi.Selected
                h.Color = 'white';
            else
                h.Color = roiColor;
            end
                
             % Add the text tag of the roi.
            h = text(0,0,'');
            
            if isempty(obj.RoiTextHandles)
                obj.RoiTextHandles = gobjects(0);
            end
            
            % Add text handle to gui obj and set some properties
            obj.RoiTextHandles(end+1) = h;
            h.HitTest = 'off';
            h.PickableParts = 'none';
            h.HorizontalAlignment = 'center';
            h.String = roi.Tag;
            h.Position = [roi.Center(1), roi.Center(2), 0];
            if roi.Selected
                h.Color = 'white';
            else
                h.Color = roiColor;
            end
            
            % Set visibility of text based on button "Show/Hide Tags"
            switch obj.btnShowTags.String
                case 'Show Tags'
                    h.Visible = 'off';
                case 'Hide Tags'
                    h.Visible = 'on';
            end
            
            hold off
             
        end
         
        
        function obj = updateRoiPlot(obj, idx, newRoi)
        % Replot the roi at idx in roiArray
            hold on
            for j = 1:length(newRoi.Boundary)
                boundary = newRoi.Boundary{j};
                if j == 1
                    set(obj.RoiPlotHandles(idx), 'XData', boundary(:,2), 'YData', boundary(:,1));
                else
                    obj.RoiPlotHandles(idx).XData = horzcat(obj.RoiPlotHandles(idx).XData, nan, boundary(:,2)');
                    obj.RoiPlotHandles(idx).YData = horzcat(obj.RoiPlotHandles(idx).YData, nan, boundary(:,1)');
                end

            end

            % Move roi label/tag to new center position
            set(obj.RoiTextHandles(idx), 'Position', [newRoi.Center, 0])
            hold off
            
        end
        
        
        function obj = shiftRoiPlot(obj, shift)
        % Shift Roi plots according to a shift [x, y, 0]
            % Get active roi
            for i = obj.selectedRois
                
                xData = get(obj.RoiPlotHandles(i), 'XData');
                yData = get(obj.RoiPlotHandles(i), 'YData');
            
                % Calculate and update position 
                xData = xData + shift(1);
                yData = yData + shift(2);
                set(obj.RoiPlotHandles(i), 'XData', xData)
                set(obj.RoiPlotHandles(i), 'YData', yData)
            
                % Shift text to new position
                textpos = get(obj.RoiTextHandles(i), 'Position');
                textpos = textpos + shift;
                set(obj.RoiTextHandles(i), 'Position', textpos);
            end
        end
        
        
        function obj = moveRoi(obj, shift)
        % Update RoI positions based on shift.
        
            % Get active roi
            for i = obj.selectedRois
                roi = obj.roiArray(i);
            
                % Use boundary to create roi impoints
                if isempty(roi.imPointsX)
                    roi.imPointsX = roi.Boundary{1}(1:5:end, 2);
                    roi.imPointsY = roi.Boundary{1}(1:5:end, 1);
                end
            
                % Calculate new position of roi vertices.
                obj.RoiTmpPosX = roi.imPointsX + shift(1);
                obj.RoiTmpPosY = roi.imPointsY + shift(2);

                % Create new roi object at new position, inherit some properties
                shiftedRoi = makeRoi(obj);
                shiftedRoi = obj.inheritRoiProperties(shiftedRoi, roi);
                %shiftedRoi.Selected = roi.Selected;

                % Add replace original roi with shifted roi
                obj.roiArray(i) = shiftedRoi;
                
                % Clear roi temporary positions.
                obj.RoiTmpPosX = [];
                obj.RoiTmpPosY = [];
                
            end
            
        end
        
        
        function obj = loadRois(obj, ~, ~)
        % Load rois from file. Keep rois which are in gui from before
            
            % Open filebrowser in same location as tiffstack was loaded from
            initpath = obj.filePath;
            
            [roiFileName, pathName, ~] =  uigetfile({'mat', 'Mat Files (*.mat)'; ...
                                          '*', 'All Files (*.*)'}, ...
                                          'Find Roi File', ...
                                          initpath);
                                      
            if roiFileName == 0 % User pressed cancel
                return
            end

            roiFile = fullfile(pathName, roiFileName);
            roiFileVar = load(roiFile);
            rois = roiFileVar.roi_arr;
            
            obj = appendRoiArray(obj, rois);
        end
           
        
        function obj = appendRoiArray(obj, rois)
        % Append a list of rois to the roiArray and to the listbox. Plot rois
        % and create a textlabel.
        
            newtags = arrayfun(@(roi) roi.Tag, rois, 'uni', 0)';
            obj.roiArray = horzcat(obj.roiArray, rois);
            obj.roiListBox.String = vertcat(obj.roiListBox.String, newtags);
            
            for n = 1:length(rois)
                obj = plotRoi(obj, rois(n));
            end
            
            obj.roiCount = obj.roiCount + length(rois);
            
        end
        
        
        function obj = exportRois(obj, ~, ~)
        % Export rois to file. Save to sessionfolder if available
            
            obj = reorderRoiIds(obj);
            strId = strfind(obj.fileName, 'ch');
            if isempty(strId)
                if isempty(get(obj.channel, 'String'))
                    strId = strfind(obj.fileName, 'Ch');
                    ch = ['ch', obj.fileName(strId+2:strId+2)]
                else
                    ch = ['ch', get(obj.channel, 'String')];
                end
            else
                ch = obj.fileName(strId:strId+2);
            end
            
            if isempty(obj.sessionID)
                savePath = obj.filePath;
            else
                savePath = getSessionFolder(obj.sessionID);
            end
            disp(get(obj.channel, 'String'))
            
            if ~isempty(strfind(obj.fileName,'_plane'))
                planeNum_indx = strfind(obj.fileName,'_plane');
                planeNum = obj.fileName(planeNum_indx+6:planeNum_indx+8);
            else
                planeNum = '001';
            end
            
            roiFilenm = ['roi_arr_', ch,'_plane',planeNum, '.mat'];
            roi_arr = obj.roiArray;
            save(fullfile(savePath, roiFilenm), 'roi_arr')
        end
        
        
        function obj = exportSignal(obj, ~, ~)
        % Export signals to file. Save to sessionfolder if available
            tic
%            strId = strfind(obj.fileName, 'ch');
%             if isempty(strId)
%                 ch = ['ch', get(obj.channel, 'String')];
%             else
%                 ch = obj.fileName(strId:strId+2);
%             end
            
            if isempty(obj.sessionID)
                savePath = obj.filePath;
%                 signalFilenm = ['signalData_', ch, '.mat'];
                signalFilenm = [obj.fileName, '_signal.mat'];
            else
                sessionFolder = getSessionFolder(obj.sessionID);
                savePath = fullfile(sessionFolder, 'extracted_calcium_signals');
                if ~exist(savePath, 'dir'); mkdir(savePath); end
                signalFilenm = strrep(obj.fileName, 'calcium_images', 'extracted_signals');
                signalFilenm = strrep(signalFilenm, '.tif', '.mat');
            end
            signalData = extractSignal(obj.tiffStack, obj.roiArray);
            save(fullfile(savePath, signalFilenm), 'signalData')
            toc
        end
        
        
        function obj = showTags(obj, source, ~)
        % Change visibility of roi tags based on state of button "Show Tags"
            
            switch source.String
                case 'Show Tags'
                    set(obj.btnShowTags, 'String', 'Hide Tags')
                    for n = 1:length(obj.RoiTextHandles)
                        set(obj.RoiTextHandles(n), 'Visible', 'on')
                    end
                case 'Hide Tags'
                    obj.unFocusButton(obj.btnShowTags)
                    set(obj.btnShowTags, 'String', 'Show Tags')
                    for n = 1:length(obj.RoiTextHandles)
                        set(obj.RoiTextHandles(n), 'Visible', 'off')
                    end
            end

        end
       
        
        function obj = runAutoSegmentation(obj, ~, ~)
        % Calls autodetection package from Pnevmatikakis et al (Paninski)
        % and adds detected rois to gui
        
            numRois = str2double(inputdlg('Enter number of Rois to search for'));
            disp('Starting the roi autodetection program')
            imArrayPath = fullfile(obj.filePath, obj.fileName);
            autoRois = CaSourceExtractWrapper(imArrayPath, numRois, obj.roiCount);
            obj = appendRoiArray(obj, autoRois);
            
        end
        
        
        function obj = showStack(obj, ~, ~)
        % Shows current frame in image display
            obj.unFocusButton(obj.btnShowStack)
            set(obj.frameslider, 'Visible', 'on');
            set(obj.btnShowMovingAvg, 'Value', 0)
            set(obj.btnShowMovingMax, 'Value', 0)
            obj.updateImageDisplay();
        end
        
        
        function obj = showAvg(obj, ~, ~)
        % Shows stack average projection in image display
            obj.unFocusButton(obj.btnShowAvg)
            if ~isempty(obj.stackAvg)
                set(obj.btnShowMovingAvg, 'Value', 0)
                set(obj.btnShowMovingStd, 'Value', 0)
                set(obj.btnShowMovingMax, 'Value', 0)
                set(obj.frameslider, 'Visible', 'off');
                set( obj.currentFrameIndicator, 'String', ...
                          'Current Frame: Avg Image' )
                caframe = obj.stackAvg;
                set(obj.imageObj,'cdata',caframe);
            end
        end
        
        
        function obj = showMax(obj, ~, ~)
        % Shows stack average projection in image display
            obj.unFocusButton(obj.btnShowMax)
            if ~isempty(obj.stackMax)
                set(obj.btnShowMovingAvg, 'Value', 0)
                set(obj.btnShowMovingStd, 'Value', 0)
                set(obj.btnShowMovingMax, 'Value', 0)
                set(obj.frameslider, 'Visible', 'off');
                set( obj.currentFrameIndicator, 'String', ...
                          'Current Frame: Max Image' )

                caframe = obj.stackMax;
                set(obj.imageObj,'cdata',caframe);
            end
        end           

        
        function roiNew = autodetect(obj, x, y)
        %autodetect autodetects roi by automatic thresholding.   
            % Set some parameters
            
            d1 = obj.roiInnerDiameter; 
            d2 = obj.roiOuterDiameter; 
            minRoiSize = round(pi*(d2/2)^2/2);
            x = round(x);
            y = round(y);
            % retrieve box 2xroi size around x and y
            
            roiMask = zeros(size(obj.imageObj.CData(:, :,1)));
            
            % /todo take care of image borders
            im = obj.imageObj.CData(y-d2:y+d2, x-d2:x+d2, 1);
            %imChunk = obj.tiffStack(y-d2:y+d2, x-d2:x+d2, :);
            
            
            % Define center coordinates and radius
            imdim = size(im);
            x_mask = imdim(1)/2;
            y_mask = imdim(2)/2;
            r1 = d1/2;
            r2 = d2/2;

            % Generate grid with binary mask representing the outer circle. Credit
            % StackOverflow??
            [xx, yy] = ndgrid((1:imdim(1)) - y_mask, (1:imdim(2)) - x_mask);
            mask1 = (xx.^2 + yy.^2) < r1^2;
            mask2 = (xx.^2 + yy.^2) < r2^2;
            mask3 = logical(mask2-mask1);
            
            nucleus_values = im(mask1);
            soma_values = im(mask2);
            ring_values = im(mask3);
            surround_values = im(~mask2);
            
            im = medfilt2(im, [5, 5]);
            %imshow(im);
            if ~isempty(nucleus_values)
                nucleus_val = median(nucleus_values);
                ring_val = median(ring_values);
                surround_val = median(surround_values(1:round(end*0.6)));
                threshold = double((ring_val - surround_val) / 2 + surround_val);
            else 
            	high_val = median(soma_values);
                low_val = median(surround_values);
            
                threshold = double((high_val - low_val) / 2 + low_val);
                % Create roimask
                
            end    
            
            % Create roimask
            localRoiMask = im2bw(im, threshold/255);
            if ~isempty(nucleus_values)
                localRoiMask(mask1) = 1;
            end

            roiMask(y-d2:y+d2, x-d2:x+d2) = localRoiMask;
            
            % remove small "holes"
            roiMask = bwareaopen(roiMask, minRoiSize);
            
            if sum(roiMask(:)) > 0
                % Create a RoI object
                roiNew = RoI(roiMask);
            else
                roiNew = [];
            end
            
        end
        
  
        function obj = showMovingAvg(obj, source, ~)
        % Shows stack running average projection in image display
        
            if ~source.Value
                obj.unFocusButton(obj.btnShowMovingAvg)
            end
            
            set(obj.btnShowMovingMax, 'Value', 0)
            set(obj.btnShowMovingStd, 'Value', 0)
            obj.updateImageDisplay();
            
        end
        
        
        function obj = showMovingStd(obj, source, ~)
        % Shows stack running standard deviation projection in image display
        
            if ~source.Value
                obj.unFocusButton(obj.btnShowMovingAvg)
            end
            
            set(obj.btnShowMovingMax, 'Value', 0)
            set(obj.btnShowMovingAvg, 'Value', 0)
            
            if isempty(obj.tiffStackMedfilt)
                obj.despeckleStack();
            end
            
            obj.updateImageDisplay();
            
        end
        
        
        function obj = showMovingMax(obj, source, ~)
        % Shows stack running maximum projection in image display
        
            if ~source.Value
                obj.unFocusButton(obj.btnShowMovingMax)
            end
        
            set(obj.btnShowMovingAvg, 'Value', 0)
            set(obj.btnShowMovingStd, 'Value', 0)
            
            if isempty(obj.tiffStackMedfilt)
                obj.despeckleStack();
            end
            
            obj.updateImageDisplay(); 
            
        end
        
        
        function obj = despeckleStack(obj)
        % Create a stack which is median filtered (despeckled)
        
            h = waitbar(0, 'Please wait while performing median filtering');
            
            imType = class(obj.tiffStack);
            obj.tiffStackMedfilt = zeros(obj.imHeight, obj.imWidth, obj.nFrames, imType);

            for f = 1:obj.nFrames
                obj.tiffStackMedfilt(:,:,f) = medfilt2(obj.tiffStack(:, :, f));
                if mod(f,100)==0
                    waitbar(f/obj.nFrames, h)
                end
            end

            close(h)
            
        end
        

        function obj = updateBinningSize(obj, source, ~)
        % Updates the binning size for moving averages. Forces new value to
        % be odd
            newBinningSize = str2double(source.String);
            if ~mod(newBinningSize, 2)
                newBinningSize = newBinningSize - 1;
            end
            obj.binningSize = newBinningSize;
            set(obj.setBinningSize, 'String', num2str(obj.binningSize))
        
        end
        
        
        function obj = setRoiSize(obj, source,  ~)
        % Callback for button to set the roi diameter to use for autodetection
        
            switch source.String
                case 'Set Roi Size for Autodetection'
                    set(obj.btnSetRoiSize, 'String', 'Confirm')
                    set(obj.roiSizeSliderContainer, 'Visible', 'on')
                    set(obj.btnSetRoiSize, 'TooltipString', 'Move cursor to image and click to reposition the Roi Template')
                    obj.setMouseMode('Set Roi Diameter');
                    if isempty(obj.roiTemplateCenter)
                        xlim = get(obj.axStackDisplay, 'Xlim');
                        ylim = get(obj.axStackDisplay, 'Ylim');
                        obj.roiTemplateCenter = [xlim(1) + diff(xlim)/2, ylim(1) + diff(ylim)/2];
                        obj = plotRoiTemplate(obj);
                    end
                    
                    set(obj.roiTemplatePlotHandle, 'Visible', 'on')
                    
                case 'Confirm'
                    set(obj.btnSetRoiSize, 'String', 'Set Roi Size for Autodetection')
                    set(obj.roiSizeSliderContainer, 'Visible', 'off')
                    set(obj.btnSetRoiSize, 'TooltipString', '')
                    set(obj.roiTemplatePlotHandle, 'Visible', 'off')
                    obj.unFocusButton(obj.btnSetRoiSize)
                    obj.setMouseMode('Previous');
            end        
        
        end
            
        
        function obj = sliderValueChange(obj, slider, ~)
        % Callback function for value change of roi diameter slider 
            obj.roiInnerDiameter = slider.Low;
            obj.roiOuterDiameter = slider.High;
            obj = plotRoiTemplate(obj);
            
        end
        
        
        function obj = brightnessValueChange(obj, slider, ~)
        % Callback function for value change of brightness slider 
            min_brightness = slider.Low;
            max_brightness = slider.High;
            set(obj.axStackDisplay, 'CLim', [min_brightness, max_brightness])
            
        end
        
        
        function obj = plotRoiTemplate(obj)
        % Plot a circle with diameter equal to roi template diameter.
            if ~isempty(obj.roiTemplateCenter) && ~isempty(obj.imageObj)
                % Define center coordinates and radius
                
                x = obj.roiTemplateCenter(1);
                y = obj.roiTemplateCenter(2);
                r1 = obj.roiInnerDiameter/2;
                r2 = obj.roiOuterDiameter/2;

                th = 0:pi/50:2*pi;
                xdata1 = r1 * cos(th) + x;
                ydata1 = r1 * sin(th) + y;
                xdata2 = r2 * cos(th) + x;
                ydata2 = r2 * sin(th) + y;
                
                if r1 > 0
                    xData = horzcat(xdata1, nan, xdata2);
                    yData = horzcat(ydata1, nan, ydata2);
                else
                    xData = xdata2;
                    yData = ydata2;
                end
                
                hold(obj.axStackDisplay, 'on')
                if isempty(obj.roiTemplatePlotHandle)
                    obj.roiTemplatePlotHandle = plot(obj.axStackDisplay, xData, yData, 'yellow');
                else
                    set(obj.roiTemplatePlotHandle, 'XData', xData, 'YData', yData)
                end
                hold(obj.axStackDisplay, 'off')
            end
        end
        
        
        function obj = reorderRoiIds(obj)
        % Reorder roi IDs to span from 1 to N (number or rois)
            for i = 1:length(obj.roiArray)
                roi = obj.roiArray(i);
                roi.ID = i;
                classmatch = cellfun(@(g) strcmp(g, roi.Group), obj.roiClasses, 'uni', 0);
                if any(cell2mat(classmatch))
                   roi.Tag = [obj.roiTags{find(cell2mat(classmatch))}, num2str(i,'%03d')];
                else
                   roi.Tag = [roi.Group(1:4), num2str(i,'%03d')];
                end
                set(obj.RoiTextHandles(i), 'String', roi.Tag);
            end
            obj.updateListBox();
        end
        
        
        function signal = extractSignal(obj, selectedRoi)
        % Extract signal from currently selected roi
        
            currentRoi = obj.roiArray(selectedRoi);
            minX = min(currentRoi.PixelsX);
            minY = min(currentRoi.PixelsY);
            maxX = max(currentRoi.PixelsX);
            maxY = max(currentRoi.PixelsY);
            
            imChunk = obj.tiffStack(minY:maxY, minX:maxX, :);
            roiMask = repmat(currentRoi.Mask(minY:maxY, minX:maxX), 1,1,obj.nFrames);
            imChunk(~roiMask) = 0;
            signal = squeeze(sum(sum(imChunk, 1), 2)) / length(currentRoi.PixelsX);
%            signal = smooth(signal, 10);
            sorted = sort(signal);
            
            f0 = median(sorted(1:round(end*0.2)));
            deltaFoverF = (signal - f0) ./ f0;
            signal = deltaFoverF;
%             [minS, minId] = min(signal);
%             [maxS, maxId] = max(signal);

            
        end
        
        
        function obj = showSignalPlot(obj, source, ~)
            if source.Value
                set(obj.axSignalPlot, 'Visible', 'on')  
                set(obj.signalPlotHandle, 'Visible', 'on')
                set(obj.plotFrameMarker, 'Visible', 'on')
                set(obj.axStackDisplay, 'Position', [0.12, 0.2, 0.76, 0.76])
                drawnow
                set(obj.imageObj, 'ButtonDownFcn', @obj.mousePress)
            else
                obj.resetSignalPlot();
                set(obj.axSignalPlot, 'Visible', 'off')
                set(obj.signalPlotHandle, 'Visible', 'off')
                set(obj.plotFrameMarker, 'Visible', 'off')
                set(obj.axStackDisplay, 'Position', [0.03, 0.03, 0.94, 0.94])
            end
            
        end
        
        
        function obj = updateSignalPlot(obj, selectedRoi, mode)
        % Update signal plot
            
            df_F = extractSignal(obj, selectedRoi);
            
            ylim = [min(df_F) * 0.9, max(df_F) * 1.1];
            %ylim=[0,1];
            set(obj.axSignalPlot, 'YLim', ylim)
            set(obj.axSignalPlot, 'YTick', 0:0.5:max(ylim))
            
            if isempty(obj.signalPlotHandle)
                obj.signalPlotHandle = plot(obj.axSignalPlot, df_F, 'HitTest', 'off');
            else
                switch mode
                    case 'append'
                        obj.signalPlotHandle(end+1) = plot(obj.axSignalPlot, df_F, 'HitTest', 'off');
                    case 'overwrite'
                        set(obj.signalPlotHandle(end), 'YData', df_F)
                end
            end
            

            
            set(obj.plotFrameMarker, 'YData', ylim)
        end
        
        
        function obj = resetSignalPlot(obj)
            for i = 1:length(obj.signalPlotHandle)
                delete(obj.signalPlotHandle(i))
            end
            obj.signalPlotHandle=gobjects(0);
        end
        
        
        function obj = playVideo(obj, ~, ~)
            % Callback for play button. Plays calcium images as video
            
            if obj.btnPlayVideo.Value
                                
                while obj.currentFrameNo < obj.nFrames
                    t1 = tic;
                    obj.changeFrame([], [], 'playvideo');
                    if ~ obj.btnPlayVideo.Value
                        break
                    end
                    t2 = toc(t1);
                    pause(0.033 / obj.playbackspeed-t2)
                end
                
                obj.btnPlayVideo.Value = 0;
            end
            
        end
        
        
        function obj = btnPlaybackSpeed(obj, source, ~)
            switch source.String
                case '2x'
                    if source.Value
                        if obj.btn4x.Value
                            obj.btn4x.Value = 0;
                        elseif obj.btn8x.Value
                            obj.btn8x.Value = 0;
                        end
                        obj.playbackspeed = 2;
                    end
                case '4x'
                    if source.Value
                        if obj.btn2x.Value
                            obj.btn2x.Value = 0;
                        elseif obj.btn8x.Value
                            obj.btn8x.Value = 0;
                        end
                        obj.playbackspeed = 4;
                    end
                case '8x'
                    if source.Value
                        if obj.btn2x.Value
                            obj.btn2x.Value = 0;
                        elseif obj.btn4x.Value
                            obj.btn4x.Value = 0;
                        end
                        obj.playbackspeed = 8;
                    end                    
            end
            
            
        end
        
                   
        function color = getRoiColor(obj, roi)
        % Return a color for the roi based on which group it belongs to.

            groupmatch = cellfun(@(x) strcmp(x, roi.Group), obj.roiClasses, 'uni', 0);
            if any(cell2mat(groupmatch))
                color = obj.roiColors{cell2mat(groupmatch)};
            else
                color = 'red';
            end
        end
            
        
        function obj = changeRoiClass(obj, source, ~)
            % Change roiclass of roi if popupmenu is changed.
            if ~isempty(obj.selectedRois)
                for i = obj.selectedRois
                    groupName = source.String{source.Value};
                    obj.roiArray(i).Group = groupName;
                    obj.roiArray(i).Tag = [obj.roiTags{source.Value}, num2str(obj.roiArray(i).ID,'%03d')];
                    
                end
                obj.updateListBox();
         
            end
                        
        end
        
        
    end
   
    
    
    methods (Static)
        
        
        function unFocusButton(btnHandle)
        	set(btnHandle, 'Enable', 'off');
            drawnow;
            set(btnHandle, 'Enable', 'on');
        end
       
        
        function bool = isInRoi(roi, x, y)
        %ISINROI check if the point (x,y) is a part of the roi.
        %   val = isInRoi(roi,x,y,)
        %
        % roi       - Single RoI object.
        % x         - (int) Position in image as pixels.
        % y         - (int) Position in image as pixels.
        %
        % See also: RoI

            v1 = uint32([x, y]);
            v2 = [roi.PixelsX, roi.PixelsY];
            bool = ismember(v1,v2,'rows');
            
        end
        
        
        function newRoi = inheritRoiProperties(newRoi, roi)
            newRoi.Group = roi.Group;
            newRoi.ID = roi.ID;
            newRoi.Tag = roi.Tag;
            newRoi.nFrames = roi.nFrames;
            newRoi.signalArtifact = roi.signalArtifact;
        end
        
        
    end

    
    
end


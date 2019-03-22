 classdef roimanager < handle
    %GUI for drawing rois and exploring signals.
    %   ROIMANAGER opens a GUI for drawing rois and plotting signals
    %
    %   Usage:
    %       - Load a tiff stack
    %       - Use draw button (or press 'd' on the keyboard) to activate a 
    %         polygon selection tool for drawing rois in the image. Press 
    %         'f' on the keyboard) to complete the roi.
    %       - Or: Use Autodetect rois ('a') or Circledetect ('o')
    %             to point and click to select rois.
    %       - Or: Explore the autosegmentation method from Pnevmatikakis.
    %       
    %   Useful features
    %       - RoIs can be moved around by dragging them in the image using
    %         the mouse
    %       - Multiple rois can be selected and moved by holding down the
    %         shift button during roi selection and moving.
    %       - Keyboard zoom shortcuts ('z' - zoom in, 'Z' - zoom out)
    %       - Keyboard pan shortcuts (use arrow keys)
    %       - Other keyboard shortcuts:
    %           'numeric 1-4' - change channels
    %           'numeric 0' - show all channels
    %           'e' - toggle edit mode
    %           'q' - toggle "zoom in" mouse mode
    %           'w' - toggle "zoom out" mouse mode
    %           'r' - reset zoom (zoom out to show entire image)
    %           's' - go to select mode
    %           'escape' - cancel drawing or editing of roi
    %           'backspace' - remove selected rois
    %
    %
    %   Optional additions:
    %       For automatic roi segmentation: 
    %           - ca_source_extraction:   https://github.com/epnev/ca_source_extraction
    %           - cvx:                    http://cvxr.com/cvx/download/
    %                                     currently commented out (see line 409-418)
    

    % Eivind Hennestad | Vervaeke Lab
    
    
    
    properties (Constant = true)
        chExpr = 'ch'                   % str before channel number in filename
        ptExpr = 'part'                 % str before part number in filename
        sIdExpr = 'm\d*-\d*-\d*-\d*';   % sessionId = m0100-20180101-1200-001
        USE_DEFAULTSETTINGS = true      %Not implemented...
    end
    
    
    
    properties
        
        % User settings
        
        filePathSettings = struct(...
            'initPath', '', ...
            'roiArrayPath', fullfile('..', 'roi_signals'), ...
            'signalPath', fullfile('..', 'roi_signals') );
        
        signalExtractionSettings = struct(...
            'extractNeuropil', true, ...
            'neuropilExtractionMethod', struct('Alternatives', {{'None', 'Standard', 'Fissa'}}, 'Selection', {'Standard'}), ... 
            'deconvolveSignal', true, ...
            'deconvolutionMethod', struct('Alternatives', {{'CaImAn', 'Suite2P'}}, 'Selection', {'CaImAn'}), ...
            'extractFromFiles', true, ...
            'caimanParameters', struct('spkSnr', 0.99, 'lamPr', 0.5), ...
            'filterSpikesByNoiseLevel', true, ...
            'extractSignalsInBackground', true, ...
            'savePath', fullfile('..', 'roisignals'));
%             'spikeEstimationParameters', struct('spikeThreshold', 0.05, 'noiseFilter', true), ...
        
        settings = struct('showTags', false, 'nElementsLog', 50, 'showNpMask', false)
        
        
        initPath = '';                 % Path to start browsing from

        
        % Pan and zoom factors for image window
        panFactor = 0.1;                % Determines image shift when using arrow keys
        zoomFactor = 0.25;              % Determines zoom when using zoom keys (z and Z)
        scrollFactor = 6;               % Determines how fast to scroll through frames 
        binningSize = 9;                % Bin size used for moving averages or maximums.

        % Different roi classes, their abbreviations, and color for plots.
        roiClasses = {'Neuronal Soma', 'Neuronal Dendrite', 'Neuronal Axon', 'Neuropill','Astrocyte Soma','Astrocyte Endfoot','Astrocyte Process','Gliopill', 'Artery', 'Vein', 'Capillary'};
        roiTags = {'NS', 'ND', 'NA','Np','AS', 'AE', 'AP','Gp','Ar','Ve','Ca'}
        roiColors = {'Red', [.96 .45 .027], [.96 .65 .027], [.75 .5 0], 'Green', [0.016 .61 .51], [.63 .90 .02], [.067 .48 0], [.24 .09 .66], [.43 .051 .64], [.76, .02 .47]}
        
        % Layers where rois are drawn
        corticalLayers = {'n/a', 'Layer I', 'Layer II', 'Layer II/III', 'Layer III', ...
                          'Layer IV', 'Layer V', 'Layer VI',}
        % Channel settings
        channelIds = {'1', '2', '3', '4'}
        channelColors = {'yellow', 'red', 'green', 'blue'}
        celltypes = {'', 'astrocytes', 'neurons', ''}
        
        % Figure and figure settings
        
        fig                             % GUI Figure Window
        imfig
        margins                         % Side margins within the GUI window
        padding                         % Padding between objects in the GUI window
        
        % UI panels
        
        panelLeft                       % Left sidepanel
        panelImage                      % Image Panel for displaying imgTseries (center)
        panelRight                      % Right sidepanel
        panelRoiInfo
        
        % Ax and image for displaying the imagestack
        
        axImageDisplay                  % Axes to display images from the imgTseries
        axSignalPlot

        % Handles to objects that will be displayed on the axes
        
        himage                          % Image object for the displayed image
        hlineSignal = struct()          % Line handle for signals in signal plot
        hlineCurrentFrame               % Line handle for vertical line showing current frame in signal plot
        hlineTmpRoi                     % Line handle for temporary lines of roi polygon
        hlineRoiTemplate                % Line handle of roitemplate for autodetection
        hlineCurrentFrame2
        hpatchFrameSelection
        
        % Image dimensions
        
        imWidth                         % Width (pixels) of images in image time series
        imHeight                        % Height (pixels) of images in image time series
        nFrames = 0                     % Number of frames in image time series
        
        % Roi handles for creating and displaying rois
        
        tmpImpoints                     % A list of impoints for the temporary roi polygon
        selectedImpoint                 % Number of selected impoint
        tmpRoiPosX                      % X coordinate values of the temporary roi
        tmpRoiPosY                      % Y coordinate values of the temporary roi
        RoiPlotHandles = {}             % A list of plot handles for all finished rois
        RoiTextHandles = {}             % A list of text handles for all finished rois
        roiOuterDiameter = 10;          % Roi diameter in pixels used for autodetection
        roiInnerDiameter = 5;           % Roi inner diameter in pixels used for autodetection
        roiDisplacement = 0;            % Temporary "keeper" of roi displacement if rois are moved
        circleToolHandle
        circleToolCoords
        
        % Data which is loaded into gui
        
        imgTseries = {}                 % A Tseries of images on which to draw roi (cell array of matrices, one per channel)
        imgTseriesMedfilt = {}          % A Tseries of images which are median filtered (cell array of matrices, one per channel)
        imgAvg = {}                     % An average projection image of the tiff stack
        imgMax = {}                     % An maximum projection image of the tiff stack
        imgCn = {}                      % A correlation image
        roiArray = {}                   % A cell array of arrays of RoI objects
        signalArray = struct            % A struct array with different signals for each roi and each channel.
        selectedRois                    % Numbers of the selected/active rois                   
        actionLog
        logPosition = 0
        lastLogPosition = 0
        cnmfData = []
        cnmfResults = []
        
        % GUI state properties
        sessionObj
        
        channel                         % Recording channel for current tiff stack
        loadedChannels                  % Channel ID of loaded channels
        nLoadedChannels                 % Number of loaded channels
        currentChannel                  % Number of current channel (numeric index for loadedChannels
        channelDisplayMode = 'single'   % Variable used internally for setting display mode
        currentFrameNo = 0              % Number of the current frame which is displayed
        selectFrameMode
        selectedFrames
        roiCount = {}                   % A counter for the number of rois that have been drawn
        playbackspeed = 1
        signal2display = {'roiMeanF'}
        
        % Mouse state and recorded cursor positions
        
        mouseMode = 'Select'            % MouseMode ('Draw' or 'Select')
        mouseModePrev                   % Previous active mousemode
        mouseDown = 0                   % Indicates if mouse button is pressed
        prevMouseClick                  % Axes coordinates when mouse was last clicked.
        prevMousePointAx                % Needed for moving RoIs. Last registered axes coordinates
        prevMousePointFig               % Needed for panning image display in select mode
        roiTemplateCenter               % Needed when setting the roi diameter
        zoomRectPlotHandle              % Handle for rectangle plot when drag-zooming
        
        % Filepaths
        loadedFileName                  % Filename of loaded image file (cell array, one fnm per channel)
        
        % Buttons
        
        btnLoadImages                   % Open file dialog to find and load a tiff-stack
        btnRunAutoSegmentation          % Run automatic roi detection (Paninski code)
        btnShowCurrentFrame             % Show current frame of tiff stack in image display
        btnShowAvg                      % Show average projection of tiff stack in image display
        btnShowMax                      % Show maximum projection of tiff stack in image display
        btnShowMovingAvg                % Togglebutton for showing moving average projection
        btnShowMovingStd                % Togglebutton for showing moving average projection
        btnShowMovingMax                % Togglebutton for showing moving maximum projection
        btnDrawRoi                      % Button used for drawing a new RoI
        btnAutoDetect                   % Button used to activate "autodetection clicktool"
        btnEditRoi                      % Button used for editing an existing RoI
        btnGrowRoi
        btnShrinkRoi
        btnCircleTool
        btnDoMagic
        btnShowSignal                   % Button used for extracting signal from a roi
        btnSignalType                   % Button for selecting raw signal or df/f based on surrounding neuropil subtraction
        btnShowRaw
        btnShowDFF
        btnShowDemixed
        btnShowDenoised
        btnShowSpikes
        connectedRoiInfo
        editSpikeThresh
        editSpikeSNR
        editLambdaPr
        btnRemoveRoi                    % Button used for removing selected rois
        btnLoadRois                     % Button used for loading rois from file
        btnSaveRois                     % Button used for exporting rois to file
        btnSaveSignal                   % Button used for exporting signal to file
        btnClearAllRois                 % Button used for removing all rois
        btnSetRoiTemplateSize          	% Button to quickly set the size of roi to autodetect
        btnPlayVideo                    % Button to start/stop video.
        btn2x
        btn4x
        btn8x
        btnShowSingleChannel
        btnUndockImage
        
        % Other UIcontrols
        
        popupRoiclass                   % Popupmenu for selecting roi type/Groupname
        popupLayer                      % Popupmenu for selection of layer
        boolOverfilled
        inputJumptoFrame                % Input field to display specified frame in image display
        inputSetBinningSize             % Input field to set binning size for moving averages
        textCurrentFrame                % Textstring that shows which frame is displayed
        textCurrentFileName             % Textstring with current filename
        roiListBox                      % A listbox containing the name of all rois
        frameslider                     % A sliderbar for scrolling through frames
        fsContainer
        btnPrev
        btnNext
        roiSizeSlider                   % A sliderbar to set the roisize for autodetection
        roiSizeSliderContainer          % A container for the roi size sliderbar
        brightnessSlider
        brightnessSliderContainer
        editExpName
        
    end
    
    
    
    methods (Access = 'private', Hidden = true)
        
        
        function initializeGui(obj)
            
            obj.createGuiFigure()
            obj.createMenu()
            obj.createGuiPanels()
            obj.createComponentsLeftPanel()
            obj.createComponentsImagePanel()
            obj.createComponentsRightPanel()
            
            % Add a java scrollbar
            jScrollbar = javaObjectEDT('javax.swing.JScrollBar');
            jScrollbar.setOrientation(jScrollbar.HORIZONTAL);                          
            [obj.frameslider, obj.fsContainer] = javacomponent(jScrollbar);
            
            % Add a callback for value changes
            obj.frameslider = handle(obj.frameslider, 'CallbackProperties');
            set(obj.frameslider, 'AdjustmentValueChangedCallback', {@obj.changeFrame, 'slider'});
            
            % Set scrollbar range and positions
            set(obj.frameslider, 'minimum', 1, 'maximum', 1, 'VisibleAmount', 1);
            obj.fsContainer.Parent = obj.fig;
            obj.fsContainer.Units = 'normalized';
            obj.fsContainer.Position = [obj.panelImage.Position(1), 0.01, ...
                         obj.panelImage.Position(3), 0.015] ;
            obj.fsContainer.Visible = 'off';        
            obj.frameslider.Value = 1;
           
% %             obj.frameslider = uicontrol('Style', 'slider');
% %             obj.frameslider.Visible = 'off';
% %             obj.frameslider.Min = 1; 
% %             obj.frameslider.Max = 1;
% %             obj.frameslider.Value = 1;
% %             obj.frameslider.Units = 'normalized';
% %             obj.frameslider.Position = [obj.panelImage.Position(1), 0.02, ...
% %                                         obj.panelImage.Position(3), 0.02] ;
% %             obj.frameslider.Callback = {@obj.changeFrame, 'slider'};
             
            n = obj.settings.nElementsLog;
            obj.actionLog = struct( 'ch', cell(n,1), ...
                                    'roiIdx', cell(n,1), ...
                                    'rois', cell(n,1), ...
                                    'action', cell(n,1) );

            % Activate callback functions
            obj.fig.WindowButtonMotionFcn = @obj.mouseOver;
            obj.fig.SizeChangedFcn = @obj.figsizeChanged;

        end
            
        
        function createGuiFigure(obj)
        % Create gui figure. Default is to cover the whole screen
        
            screenSize = get(0, 'Screensize');
        
            % Create Figure and set properties and callbacks
            obj.fig = figure;
            obj.fig.Visible = 'on';
            obj.fig.MenuBar = 'none';
            obj.fig.Name = 'Roimanager';
            obj.fig.NumberTitle = 'off';
            obj.fig.Position = screenSize;
            obj.fig.WindowScrollWheelFcn = {@obj.changeFrame, 'mousescroll'};
            obj.fig.WindowKeyPressFcn = @obj.keyPress;
            obj.fig.WindowKeyReleaseFcn = @obj.keyRelease;
            obj.fig.WindowButtonUpFcn = @obj.mouseRelease;
            obj.fig.CloseRequestFcn = @obj.quitRoimanager;
                        
            % Pause for half a second to avoid resizing of components
            pause(0.5)
            
        end
        
        
        function createMenu(obj)
            
            % Create a 'file' menu category
            try
                m = uimenu(obj.fig, 'Text','File');
                textKey = 'Text';
                callbackKey = 'MenuSelectedFcn';
            catch
                m = uimenu(obj.fig, 'Label','File');
                textKey = 'Label';
                callbackKey = 'Callback';
            end
                
            mitem1 = uimenu(m, textKey,'Load Image Stacks');
            mitem1.(callbackKey) = @obj.loadStack;
            mitem2 = uimenu(m, textKey,'Load Roi Array');
            mitem2.(callbackKey) = @obj.loadRois;
            mitem2 = uimenu(m, textKey,'Save Rois as...');
            mitem2.(callbackKey) = {@obj.saveRois, 'Open browser'};
            mitem2 = uimenu(m, textKey,'Save Signals as...');
            mitem2.(callbackKey) = {@obj.saveSignal, 'Open browser'};
            
            % Create a 'edit' menu category
            m = uimenu(obj.fig, textKey,'Edit');
            mitem1 = uimenu(m, textKey,'Split Roi');
            mitem1.(callbackKey) = @obj.splitRois;
            
            mitem1 = uimenu(m, textKey,'Merge Rois (cmd-m)');
            mitem1.(callbackKey) = @obj.mergeRois;
            
            mitem1 = uimenu(m, textKey,'Connect Rois (cmd-c)');
            mitem1.(callbackKey) = @obj.connectRois;
            
            mitem1 = uimenu(m, textKey,'Select Frames');
            mitem1.(callbackKey) = @obj.menuCallback_SelectFrames;
            
            mitem1 = uimenu(m, textKey,'Reset Frame Selection');
            mitem1.(callbackKey) = @obj.menuCallback_ResetFrameSelection;
            
            mitem1 = uimenu(m, textKey,'Send RoI Cube to WS');
            mitem1.(callbackKey) = @obj.menuCallback_RoiToWorkspace;
                                    
            % Create a 'settings' menu category
            m = uimenu(obj.fig, textKey,'Settings');
            mitem1 = uimenu(m, textKey,'Edit General Settings');
            mitem1.(callbackKey) = @obj.editGuiSettings;
            mitem2 = uimenu(m, textKey,'Edit Signal Settings');
            mitem2.(callbackKey) = @obj.editGuiSettings;
              
            % Create a 'show' menu category
            m = uimenu(obj.fig, textKey,'Show');
            mitem1 = uimenu(m, textKey,'Show Tags');
            mitem1.(callbackKey) = @obj.setObjectVisibility;
            mitem1 = uimenu(m, textKey,'Hide Rois');
            mitem1.(callbackKey) = @obj.setObjectVisibility;
            mitem1 = uimenu(m, textKey,'Show Neuropil Mask on Roi Selection');
            mitem1.(callbackKey) = @obj.setObjectVisibility;
            mitem1 = uimenu(m, textKey,'Show Correlation Image');
            mitem1.(callbackKey) = @obj.setObjectVisibility;
            mitem1 = uimenu(m, textKey, 'Show Roi Correlation Matrix');
            mitem1.(callbackKey) = @obj.setObjectVisibility;
            mitem1 = uimenu(m, textKey, 'Show Roi Correlation Image');
            mitem1.(callbackKey) = @obj.showRoiCorrelationImage;
            
        end
        
        
        function createGuiPanels(obj)
        % Create Panels for the GUI
            
            % Find aspectratio of figure 
            figsize = get(obj.fig, 'Position');
            aspectRatio = figsize(3)/figsize(4);

            % Specify obj.margins (for figure window) and obj.padding (space between objects)
            obj.margins = 0.03 ./ [aspectRatio*(3/5), 1];  %sides, top/bottom
            obj.padding = 0.05 ./ [aspectRatio, 1];  %sides, top/bottom

            % Set up UI panel positions
            imagePanelSize = [0.94/aspectRatio, 0.94]; % This panel determines the rest.
            availableWidth = 1 - imagePanelSize(1) - obj.margins(1)*2 - obj.padding(1)*2;
            lSidePanelSize = [availableWidth/3*1, 0.94];
            rSidePanelSize = [availableWidth/3*2, 0.94];

            lSidePanelPos = [obj.margins(1), obj.margins(2), lSidePanelSize];
            imagePanelPos = [obj.margins(1) + lSidePanelSize(1) + obj.padding(1), obj.margins(2), imagePanelSize];
            rSidePanelPos = [imagePanelPos(1) + imagePanelSize(1) + obj.padding(1), obj.margins(2), rSidePanelSize];

            % Create left side UI panel for image controls
            obj.panelLeft = uipanel('Title','Image Controls');
            obj.panelLeft.Parent = obj.fig;
            obj.panelLeft.FontSize = 12;
            obj.panelLeft.Units = 'normalized'; 
            obj.panelLeft.Position = lSidePanelPos;

            % Create center UI panel for image display             
            obj.panelImage = uipanel('Title', 'Image Stack');
            obj.panelImage.Parent = obj.fig;
            obj.panelImage.FontSize = 12;
            obj.panelImage.Units = 'normalized'; 
            obj.panelImage.Position = imagePanelPos;

            set(obj.panelImage, 'units', 'pixel')
            panelAR = (obj.panelImage.Position(3) / obj.panelImage.Position(4));
            set(obj.panelImage, 'units', 'normalized')

            % Add the ax for image display to the image panel. (Use 0.03 units as margins)
            obj.axImageDisplay = axes('Parent', obj.panelImage);
            obj.axImageDisplay.XTick = []; 
            obj.axImageDisplay.YTick = [];
            obj.axImageDisplay.Position = [0.03/panelAR, 0.03, 0.94/panelAR, 0.94];

            % Add axes for plotting signals
            obj.axSignalPlot = axes('Parent', obj.panelImage);
            obj.axSignalPlot.XTick = []; 
            obj.axSignalPlot.YTick = [];
            obj.axSignalPlot.Position = [0.03, 0.01, 0.94, 0.15];
            obj.axSignalPlot.Visible = 'off';
            obj.axSignalPlot.Box = 'on';
            obj.axSignalPlot.ButtonDownFcn = @obj.mousePressPlot;
            hold(obj.axSignalPlot, 'on')                   

            % Create right side UI panel for roimanager controls
            obj.panelRight = uipanel('Title','RoiManager');
            obj.panelRight.Parent = obj.fig;
            obj.panelRight.FontSize = 12;
            obj.panelRight.Units = 'normalized';
            obj.panelRight.Position = rSidePanelPos;
        end
        
        
        function createComponentsLeftPanel(obj)
        % Create ui controls of left side panel
            
            txtExpName = uicontrol('Style', 'text');
            txtExpName.Parent = obj.panelLeft;
            txtExpName.String = 'Experiment Name:';
            txtExpName.HorizontalAlignment = 'Left';
            txtExpName.FontSize = 14;
            txtExpName.Units = 'normalized';
            txtExpName.Position = [0.1, 0.94, 0.8, 0.04];
            
            obj.editExpName = uicontrol('Style', 'edit');
            obj.editExpName.Parent = obj.panelLeft;
            obj.editExpName.String = '';
            obj.editExpName.HorizontalAlignment = 'Left';
            obj.editExpName.Units = 'normalized';
            obj.editExpName.Position = [0.1, 0.91, 0.8, 0.03];
            
            
            btnPosL = [0.1, 0.84, 0.8, 0.04];
            obj.btnLoadImages = uicontrol('Style', 'pushbutton', 'Parent', obj.panelLeft, ...
                                        'String', 'Load Image Stacks', ...
                                        'Units', 'normalized', 'Position', btnPosL, ...
                                        'Callback', @obj.loadStack);

            uiTextPos = [0.1, btnPosL(2) - 0.05, 0.5, 0.025];
            uicontrol('Style', 'text', 'Parent', obj.panelLeft, ...
                      'String', 'Enter channel', ...
                      'HorizontalAlignment', 'left', ...
                      'Units', 'normalized', 'Position', uiTextPos)

            uiEditPos = [uiTextPos(1) + uiTextPos(3) + 0.025, uiTextPos(2), 0.25, 0.025];
            obj.channel = uicontrol('Style', 'edit', 'Parent', obj.panelLeft, ...
                                        'String', '1', ...
                                        'Units', 'normalized', ...
                                        'Position', uiEditPos, ...
                                        'Callback', @obj.changeCurrentChannel);

            btnPosL(2) = uiTextPos(2) - 0.05;
            obj.btnShowSingleChannel = uicontrol('Style', 'pushbutton', 'Parent', obj.panelLeft, ...
                                        'String', 'Show All Channels', ...
                                        'Units', 'normalized', 'Position', btnPosL, ...
                                        'Callback', @obj.changeChannelDisplayMode);

            btnPosL(2) = btnPosL(2) - 0.08; 
            obj.btnShowCurrentFrame = uicontrol('Style', 'pushbutton', 'Parent', obj.panelLeft, ...
                                        'String', 'Show Current Frame', ...
                                        'Units', 'normalized', 'Position', btnPosL, ...
                                        'Callback', @obj.showStack);                         

            btnPosL(2) = btnPosL(2) - 0.05;                        
            obj.btnShowAvg = uicontrol('Style', 'togglebutton', 'Parent', obj.panelLeft, ...
                                        'String', 'Show Avg', ...
                                        'Units', 'normalized', 'Position', btnPosL, ...
                                        'Callback', @obj.showAvg);

            btnPosL(2) = btnPosL(2) - 0.05;                           
            obj.btnShowMax = uicontrol('Style', 'togglebutton', 'Parent', obj.panelLeft, ...
                                        'String', 'Show Max', ...
                                        'Units', 'normalized', 'Position', btnPosL, ...
                                        'Callback', @obj.showMax);

            sliderPos = [0.1, btnPosL(2) - 0.04, 0.8, 0.03];                     
            jSlider = com.jidesoft.swing.RangeSlider(0, 255, 0, 255);
            [obj.brightnessSlider, obj.brightnessSliderContainer] = javacomponent(jSlider);
            obj.brightnessSlider = handle(obj.brightnessSlider, 'CallbackProperties');
            set(obj.brightnessSlider, 'StateChangedCallback', @obj.changeBrightness);
            set(obj.brightnessSliderContainer, 'Parent', obj.panelLeft, 'units', 'normalized', 'Position', sliderPos)

            uiTextPos(2) = sliderPos(2) - 0.08;
            uicontrol('Style', 'text', 'Parent', obj.panelLeft, ...
                      'String', 'Go to frame', ...
                      'HorizontalAlignment', 'left', ...
                      'Units', 'normalized', 'Position', uiTextPos)


            uiEditPos(2) = uiTextPos(2) + 0.005;
            obj.inputJumptoFrame = uicontrol('Style', 'edit', 'Parent', obj.panelLeft, ...
                                        'String', 'N/A', ...
                                        'Units', 'normalized', ...
                                        'Position', uiEditPos, ...
                                        'Callback', {@obj.changeFrame, 'jumptoframe'});

            btnPosL(2) = uiTextPos(2) - 0.08;                        
            obj.btnShowMovingAvg = uicontrol('Style', 'togglebutton', 'Parent', obj.panelLeft, ...
                                        'String', 'Show Moving Average', 'Value', 0, ...
                                        'Units', 'normalized', 'Position', btnPosL, ...
                                        'Callback', @obj.showMovingAvg);     

            btnPosL(2) = btnPosL(2) - 0.05;                        
            obj.btnShowMovingStd = uicontrol('Style', 'togglebutton', 'Parent', obj.panelLeft, ...
                                        'String', 'Show Moving Std', 'Value', 0, ...
                                        'Units', 'normalized', 'Position', btnPosL, ...
                                        'Callback', @obj.showMovingStd); 

            btnPosL(2) = btnPosL(2) - 0.05;                        
            obj.btnShowMovingMax = uicontrol('Style', 'togglebutton', 'Parent', obj.panelLeft, ...
                                        'String', 'Show Moving Maximum', 'Value', 0, ...
                                        'Units', 'normalized', 'Position', btnPosL, ...
                                        'Callback', @obj.showMovingMax); 

            uiTextPos(2) = btnPosL(2) - 0.05;
            uicontrol('Style', 'text', 'Parent', obj.panelLeft, ...
                      'String', 'Set Bin Size', ...
                      'HorizontalAlignment', 'left', ...
                      'Units', 'normalized', 'Position', uiTextPos)
            uiEditPos(2) = uiTextPos(2) + 0.005;
            obj.inputSetBinningSize = uicontrol('Style', 'edit', 'Parent', obj.panelLeft, ...
                                        'String', num2str(obj.binningSize), ...
                                        'Units', 'normalized', ...
                                        'Position', uiEditPos, ...
                                        'Callback', @obj.changeBinningSize);

            btnPosL(2) = uiTextPos(2) - 0.08;                        
            obj.btnUndockImage = uicontrol('Style', 'pushbutton', 'Parent', obj.panelLeft, ...
                                        'String', 'Undock Image Window', ...
                                        'Units', 'normalized', 'Position', btnPosL, ...
                                        'Callback', @obj.undockImageWindow);     
            btnPosL(2) = btnPosL(2) - 0.08;
            obj.btnRunAutoSegmentation = uicontrol('Style', 'pushbutton', 'Parent', obj.panelLeft, ...
                                        'String', 'Run Auto Segmentation', ...
                                        'Units', 'normalized', 'Position', btnPosL, ...
                                        'Callback', @obj.runAutoSegmentation, ...
                                        'Enable', 'on');

            if exist('initialize_components', 'file')
                set(obj.btnRunAutoSegmentation, 'Enable', 'on')
            end
            
        end
        
        
        function createComponentsImagePanel(obj)
            
            obj.textCurrentFrame = uicontrol('Style', 'text');
            obj.textCurrentFrame.Parent = obj.panelImage;
            obj.textCurrentFrame.String = 'Current frame: N/A';
            obj.textCurrentFrame.Units = 'normalized';
            obj.textCurrentFrame.HorizontalAlignment = 'right';
            obj.textCurrentFrame.Position = [0.78, 0.9725, 0.185, 0.025];

            obj.textCurrentFileName = uicontrol('Style', 'text', 'Parent', obj.panelImage, ...
                                        'String', 'Current file: N/A', ...
                                        'units', 'normalized', ...
                                        'HorizontalAlignment', 'right', ...
                                        'Position', [0.43, 0.9725, 0.3, 0.025]);

            obj.btnPlayVideo = uicontrol('Style', 'togglebutton', 'Parent', obj.panelImage, ...
                                        'String', 'Play', ...
                                        'units', 'normalized', ...
                                        'HorizontalAlignment', 'right', ...
                                        'Position', [0.1, 0.975, 0.05, 0.02], ...
                                        'Callback', @obj.playVideo );
            obj.btn2x = uicontrol('Style', 'togglebutton', 'Parent', obj.panelImage, ...
                                        'String', '2x', ...
                                        'units', 'normalized', ...
                                        'HorizontalAlignment', 'right', ...
                                        'Position', [0.17, 0.975, 0.04, 0.02], ...
                                        'Callback', @obj.buttonCallback_SetPlaybackSpeed );

            obj.btn4x = uicontrol('Style', 'togglebutton', 'Parent', obj.panelImage, ...
                                        'String', '4x', ...
                                        'units', 'normalized', ...
                                        'HorizontalAlignment', 'right', ...
                                        'Position', [0.23, 0.975, 0.04, 0.02], ...
                                        'Callback', @obj.buttonCallback_SetPlaybackSpeed );

            obj.btn8x = uicontrol('Style', 'togglebutton', 'Parent', obj.panelImage, ...
                                        'String', '8x', ...
                                        'units', 'normalized', ...
                                        'HorizontalAlignment', 'right', ...
                                        'Position', [0.29, 0.975, 0.04, 0.02], ...
                                        'Callback', @obj.buttonCallback_SetPlaybackSpeed );
            
            obj.btnPrev = uicontrol('Style', 'pushbutton');
            obj.btnPrev.Units = 'normalized';
            obj.btnPrev.Parent = obj.panelImage;
            obj.btnPrev.String = '<';
            obj.btnPrev.Position = [0.35, 0.975, 0.02, 0.02];
            obj.btnPrev.Callback = {@obj.changeFrame, 'prev'};
            
            obj.btnNext = uicontrol('Style', 'pushbutton');
            obj.btnNext.Units = 'normalized';
            obj.btnNext.Parent = obj.panelImage;
            obj.btnNext.String = '>';
            obj.btnNext.Position = [0.39, 0.975, 0.02, 0.02];
            obj.btnNext.Callback = {@obj.changeFrame, 'next'};

%             % Add buttons in imagepanel
%             obj.btnSignalType = uicontrol('Style', 'pushbutton', ...
%                                      'Parent', obj.panelImage, ...
%                                      'String', 'Show Delta F over F', ...
%                                      'Units', 'Normalized', ...
%                                       'Visible', 'off', ...
%                                      'Position', [0.03, 0.17, 0.15, 0.02], ...
%                                      'Callback', @obj.changeSignalType);
                                 
            obj.btnShowRaw = uicontrol('Style', 'togglebutton');
            obj.btnShowRaw.Parent = obj.panelImage;
            obj.btnShowRaw.String = 'Show Raw';
            obj.btnShowRaw.Value = 1;
            obj.btnShowRaw.Units = 'normalized';
            obj.btnShowRaw.Visible = 'off';
            obj.btnShowRaw.Position = [0.03, 0.17, 0.14, 0.02];
            obj.btnShowRaw.Callback = @obj.changeSignalType;
            
            obj.btnShowDemixed = uicontrol('Style', 'togglebutton');
            obj.btnShowDemixed.Parent = obj.panelImage;
            obj.btnShowDemixed.String = 'Show Demixed';
            obj.btnShowDemixed.Value = 0;
            obj.btnShowDemixed.Units = 'normalized';
            obj.btnShowDemixed.Visible = 'off';
            obj.btnShowDemixed.Position = [0.22, 0.17, 0.15, 0.02];
            obj.btnShowDemixed.Callback = @obj.changeSignalType;
            
            obj.btnShowDFF = uicontrol('Style', 'togglebutton');
            obj.btnShowDFF.Parent = obj.panelImage;
            obj.btnShowDFF.String = 'Show DFF';
            obj.btnShowDFF.Value = 0;
            obj.btnShowDFF.Units = 'normalized';
            obj.btnShowDFF.Visible = 'off';
            obj.btnShowDFF.Position = [0.42, 0.17, 0.14, 0.02];
            obj.btnShowDFF.Callback = @obj.changeSignalType;
                        
            obj.btnShowDenoised = uicontrol('Style', 'togglebutton');
            obj.btnShowDenoised.Parent = obj.panelImage;
            obj.btnShowDenoised.String = 'Show Denoised';
            obj.btnShowDenoised.Value = 0;
            obj.btnShowDenoised.Units = 'normalized';
            obj.btnShowDenoised.Visible = 'off';
            obj.btnShowDenoised.Position = [0.61, 0.17, 0.15, 0.02];
            obj.btnShowDenoised.Callback = @obj.changeSignalType;
            
            obj.btnShowSpikes = uicontrol('Style', 'togglebutton');
            obj.btnShowSpikes.Parent = obj.panelImage;
            obj.btnShowSpikes.String = 'Show Spikes';
            obj.btnShowSpikes.Value = 0;
            obj.btnShowSpikes.Units = 'normalized';
            obj.btnShowSpikes.Visible = 'off';
            obj.btnShowSpikes.Position = [0.82, 0.17, 0.14, 0.02];
            obj.btnShowSpikes.Callback = @obj.changeSignalType;

                        
        end
        
        
        function createComponentsRightPanel(obj)
            
            % Set Position of listbox and subpanels
            listboxPos = [0.05, 0.05, 0.25, 0.9];
            subpanelAPos = [0.4, 0.65, 0.53, 0.31];
            subpanelBPos = [0.4, 0.43, 0.52, 0.17];
            subpanelCPos = [0.4, 0.05, 0.52, 0.33];
            
            % Create listbox for showing the list of all rois
            obj.roiListBox = uicontrol('Style', 'listbox');
            obj.roiListBox.Parent = obj.panelRight;
            obj.roiListBox.Min = 0;
            obj.roiListBox.Max = 2;
            obj.roiListBox.FontSize = 12;
            obj.roiListBox.Units = 'normalized';
            obj.roiListBox.Position = listboxPos;
            obj.roiListBox.Callback = @obj.selectListBoxObj;

            % Create subpanel with buttons for creating and modifying rois          
            roiEditPanel = uipanel('Title', 'Roi Tools');
            roiEditPanel.Parent = obj.panelRight;
            roiEditPanel.FontSize = 12;
            roiEditPanel.Units = 'normalized'; 
            roiEditPanel.Position = subpanelAPos;
            
            btnX = [0.1, 0.5]; btnY = [0.81, 0.62, 0.43, 0.24, 0.05];
            btnH = 0.04 / subpanelAPos(4);
            
            obj.btnDrawRoi = uicontrol('Style', 'togglebutton');
            obj.btnDrawRoi.Parent = roiEditPanel;
            obj.btnDrawRoi.String = 'draw (d)';
            obj.btnDrawRoi.Value = 0;
            obj.btnDrawRoi.Units = 'normalized';
            obj.btnDrawRoi.Position = [btnX(1), btnY(1), 0.3, btnH];
            obj.btnDrawRoi.Callback = @obj.buttonCallback_DrawRois;

            obj.btnAutoDetect = uicontrol('Style', 'togglebutton');
            obj.btnAutoDetect.Parent = roiEditPanel;
            obj.btnAutoDetect.String = 'autodetect (a)';
            obj.btnAutoDetect.Value = 0;
            obj.btnAutoDetect.Units = 'normalized';
            obj.btnAutoDetect.Position = [btnX(2), btnY(1), 0.4, btnH];
            obj.btnAutoDetect.Callback = @obj.buttonCallback_AutodetectRois;

            obj.btnEditRoi = uicontrol('Style', 'togglebutton'); 
            obj.btnEditRoi.Parent = roiEditPanel;
            obj.btnEditRoi.String = 'edit (e)';
            obj.btnEditRoi.Value = 0;
            obj.btnEditRoi.Units = 'normalized';
            obj.btnEditRoi.Position = [btnX(1), btnY(2), 0.3, btnH];
            obj.btnEditRoi.Callback = @obj.buttonCallback_EditRois;

            obj.btnRemoveRoi = uicontrol('Style', 'pushbutton');
            obj.btnRemoveRoi.Parent = roiEditPanel;
            obj.btnRemoveRoi.String = 'remove (<--)';
            obj.btnRemoveRoi.Units = 'normalized';
            obj.btnRemoveRoi.Position = [btnX(2), btnY(2), 0.4, btnH];
            obj.btnRemoveRoi.Callback = @obj.removeRois;
            
            obj.btnGrowRoi = uicontrol('Style', 'pushbutton');
            obj.btnGrowRoi.Parent = roiEditPanel;
            obj.btnGrowRoi.String = 'grow (g)';
            obj.btnGrowRoi.Units = 'normalized';
            obj.btnGrowRoi.Position = [btnX(1), btnY(3), 0.3, btnH];
            obj.btnGrowRoi.Callback = @obj.growRois;
            
            obj.btnShrinkRoi = uicontrol('Style', 'pushbutton');
            obj.btnShrinkRoi.Parent = roiEditPanel;
            obj.btnShrinkRoi.String = 'shrink (h)';
            obj.btnShrinkRoi.Units = 'normalized';
            obj.btnShrinkRoi.Position = [btnX(2), btnY(3), 0.4, btnH];
            obj.btnShrinkRoi.Callback = @obj.shrinkRois;
            

%             btnPosR(2) = btnPosR(2) - btnSpacing;
%             obj.btnClearAllRois  = uicontrol('Style', 'pushbutton', 'Parent', obj.panelRight, ...
%                                         'String', 'Clear All Rois', ...
%                                         'Units', 'normalized', 'Position', [0.43, 0.3, 0.2, 0.04], ...
%                                         'Callback', @obj.clearRois);


            obj.btnDoMagic = uicontrol('Style', 'pushbutton');
            obj.btnDoMagic.Parent = roiEditPanel;
            obj.btnDoMagic.String = 'Do Magic';
            obj.btnDoMagic.Units = 'normalized';
            obj.btnDoMagic.Position = [btnX(1)+0.28, btnY(4), 0.6, btnH];
            obj.btnDoMagic.Callback = @obj.improveRoiEstimate;
            
            obj.btnCircleTool = uicontrol('Style', 'togglebutton');
            obj.btnCircleTool.Parent = roiEditPanel;
            obj.btnCircleTool.String = 'O';
            obj.btnCircleTool.Units = 'normalized';
            obj.btnCircleTool.Position = [btnX(1)-0.02, btnY(4), 0.25, btnH];
            obj.btnCircleTool.Callback = @obj.buttonCallback_CircleTool;
            
            
            obj.btnSetRoiTemplateSize = uicontrol('Style', 'pushbutton');
            obj.btnSetRoiTemplateSize.Parent = roiEditPanel;
            obj.btnSetRoiTemplateSize.String = 'Set Autodetection Size';
            obj.btnSetRoiTemplateSize.Units = 'normalized';
            obj.btnSetRoiTemplateSize.Position = [btnX(1), btnY(5), 0.8, btnH];
            obj.btnSetRoiTemplateSize.Callback = @obj.setRoiTemplateSize;
            

            sliderPos = [0.05, 0.05, 0.7, 0.1];                     
            jSlider = com.jidesoft.swing.RangeSlider(0, 30, obj.roiInnerDiameter, obj.roiOuterDiameter);
            [obj.roiSizeSlider, obj.roiSizeSliderContainer] = javacomponent(jSlider);
            obj.roiSizeSlider = handle(obj.roiSizeSlider, 'CallbackProperties');
            set(obj.roiSizeSlider, 'StateChangedCallback', @obj.changeRoiSize);
            set(obj.roiSizeSliderContainer, 'Parent', roiEditPanel, 'units', 'normalized', 'Position', sliderPos)
            set(obj.roiSizeSliderContainer, 'Visible', 'off')
           
            % Create center UI panel for image display             
            loadsavePanel = uipanel('Title', 'Load/Save');
            loadsavePanel.Parent = obj.panelRight;
            loadsavePanel.FontSize = 12;
            loadsavePanel.Units = 'normalized'; 
            loadsavePanel.Position = subpanelBPos;
            
            btnX = [0.05, 0.55]; btnY = [0.55, 0.15];
            btnW = 0.4; btnH = 0.05 / subpanelBPos(4);
            
            obj.btnLoadRois = uicontrol('Style', 'pushbutton');
            obj.btnLoadRois.Parent = loadsavePanel;
            obj.btnLoadRois.String = 'Load Rois';
            obj.btnLoadRois.Units = 'normalized';
            obj.btnLoadRois.Position = [btnX(1), btnY(1), btnW, btnH]; 
            obj.btnLoadRois.Callback = @obj.loadRois;

            obj.btnSaveRois = uicontrol('Style', 'pushbutton');
            obj.btnSaveRois.Parent = loadsavePanel;
            obj.btnSaveRois.String = 'Save Rois';
            obj.btnSaveRois.Units = 'normalized';
            obj.btnSaveRois.Position = [btnX(2), btnY(1), btnW, btnH]; 
            obj.btnSaveRois.Callback = @obj.saveRois;
                        
            obj.btnShowSignal = uicontrol('Style', 'togglebutton');
            obj.btnShowSignal.Parent = loadsavePanel;
            obj.btnShowSignal.String = 'Show Signal';
            obj.btnShowSignal.Enable = 'off';
            obj.btnShowSignal.Units = 'normalized';
            obj.btnShowSignal.Position = [btnX(1), btnY(2), btnW, btnH]; 
            obj.btnShowSignal.Callback = @obj.showSignalPlot;
            
            obj.btnSaveSignal = uicontrol('Style', 'pushbutton');
            obj.btnSaveSignal.Parent = loadsavePanel;
            obj.btnSaveSignal.String = 'Save Signal';
            obj.btnSaveSignal.Units = 'normalized';
            obj.btnSaveSignal.Position = [btnX(2), btnY(2), btnW, btnH]; 
            obj.btnSaveSignal.Callback = @obj.saveSignal;
            
            % Create subpanel for showing roi information        
            obj.panelRoiInfo = uipanel('Title', 'Roi Info');
            obj.panelRoiInfo.Parent = obj.panelRight;
            obj.panelRoiInfo.FontSize = 12;
            obj.panelRoiInfo.Units = 'normalized'; 
            obj.panelRoiInfo.Position = subpanelCPos;
            
            obj.popupRoiclass = uicontrol('Style', 'popupmenu');
            obj.popupRoiclass.Parent = obj.panelRoiInfo;
            obj.popupRoiclass.String = obj.roiClasses;
            obj.popupRoiclass.Value = 1;
            obj.popupRoiclass.Units = 'normalized'; 
            obj.popupRoiclass.Position = [0.05, 0.8, 0.9, 0.1];
            obj.popupRoiclass.Callback = @obj.changeRoiClass;

            obj.popupLayer = uicontrol('Style', 'popupmenu');
            obj.popupLayer.Parent = obj.panelRoiInfo;
            obj.popupLayer.String = obj.corticalLayers;
            obj.popupLayer.Value = 1;
            obj.popupLayer.Units = 'normalized';
            obj.popupLayer.Position = [0.05, 0.6, 0.9, 0.1];
            obj.popupLayer.Callback = @obj.changeCorticalLayer;
               
            txtConnectedRois = uicontrol('Style', 'text');
            txtConnectedRois.Parent = obj.panelRoiInfo;
            txtConnectedRois.String = 'Conn. Rois :';
            txtConnectedRois.Units = 'normalized';
            txtConnectedRois.HorizontalAlignment = 'left';
            txtConnectedRois.Position = [0.1, 0.45, 0.3, 0.08];

            obj.connectedRoiInfo = uicontrol('Style', 'edit');
            obj.connectedRoiInfo.Parent = obj.panelRoiInfo;
            obj.connectedRoiInfo.String = '';
            obj.connectedRoiInfo.Enable = 'off';
            obj.connectedRoiInfo.Units = 'normalized';
            obj.connectedRoiInfo.HorizontalAlignment = 'left';
            obj.connectedRoiInfo.Position = [0.45, 0.45, 0.45, 0.08];
            
            txtOverfilled = uicontrol('Style', 'text');
            txtOverfilled.Parent = obj.panelRoiInfo;
            txtOverfilled.String = 'Overfilled :';
            txtOverfilled.Units = 'normalized';
            txtOverfilled.HorizontalAlignment = 'left';
            txtOverfilled.Position = [0.1, 0.35, 0.3, 0.08];
            
            obj.boolOverfilled = uicontrol('Style', 'checkbox');
            obj.boolOverfilled.Parent = obj.panelRoiInfo;
            obj.boolOverfilled.Value = false;
            obj.boolOverfilled.Units = 'normalized';
            obj.boolOverfilled.HorizontalAlignment = 'left';
            obj.boolOverfilled.Position = [0.45, 0.35, 0.1, 0.08];
            obj.boolOverfilled.Callback = {@obj.tagRois, 'Overfilled'};
            
            
            
            
            
            
            obj.editSpikeThresh = uicontrol('Style', 'edit');
            obj.editSpikeThresh.Parent = obj.panelRoiInfo;
            obj.editSpikeThresh.String = '';
            obj.editSpikeThresh.Units = 'normalized';
            obj.editSpikeThresh.Enable = 'off';
            obj.editSpikeThresh.Position = [0.05, 0.05, 0.2, 0.1];
            obj.editSpikeThresh.Tag = 'SpikeTreshold';
            obj.editSpikeThresh.Callback = @obj.changeSignalParameter;
            
            txtSpikeThresh = uicontrol('Style', 'text');
            txtSpikeThresh.Parent = obj.panelRoiInfo;
            txtSpikeThresh.String = 'Sp.Thresh:';
            txtSpikeThresh.Units = 'normalized';
            txtSpikeThresh.HorizontalAlignment = 'left';
            txtSpikeThresh.Position = [0.05, 0.1, 0.33, 0.15];
            
            obj.editSpikeThresh = uicontrol('Style', 'edit');
            obj.editSpikeThresh.Parent = obj.panelRoiInfo;
            obj.editSpikeThresh.String = '';
            obj.editSpikeThresh.Units = 'normalized';
            obj.editSpikeThresh.Enable = 'off';
            obj.editSpikeThresh.Position = [0.05, 0.05, 0.2, 0.1];
            obj.editSpikeThresh.Tag = 'SpikeTreshold';
            obj.editSpikeThresh.Callback = @obj.changeSignalParameter;
            
            txtSpikeSNR = uicontrol('Style', 'text');
            txtSpikeSNR.Parent = obj.panelRoiInfo;
            txtSpikeSNR.String = 'Sp.SNR:';
            txtSpikeSNR.Units = 'normalized';
            txtSpikeSNR.HorizontalAlignment = 'left';
            txtSpikeSNR.Visible = 'on';
            txtSpikeSNR.Position = [0.38, 0.1, 0.3, 0.15];
            
            obj.editSpikeSNR = uicontrol('Style', 'edit');
            obj.editSpikeSNR.Parent = obj.panelRoiInfo;
            obj.editSpikeSNR.String = '0.99';
            obj.editSpikeSNR.Units = 'normalized';
            obj.editSpikeSNR.Enable = 'on';
            obj.editSpikeSNR.Visible = 'on';
            obj.editSpikeSNR.Position = [0.38, 0.05, 0.2, 0.1];
            obj.editSpikeSNR.Tag = 'SpikeSNR';
            obj.editSpikeSNR.Callback = @obj.changeSignalParameter;
            
            txtLamdaPr = uicontrol('Style', 'text');
            txtLamdaPr.Parent = obj.panelRoiInfo;
            txtLamdaPr.String = 'Lam.Pr:';
            txtLamdaPr.Units = 'normalized';
            txtLamdaPr.HorizontalAlignment = 'left';
            txtLamdaPr.Visible = 'on';
            txtLamdaPr.Position = [0.7, 0.1, 0.3, 0.15];
            
            obj.editLambdaPr = uicontrol('Style', 'edit');
            obj.editLambdaPr.Parent = obj.panelRoiInfo;
            obj.editLambdaPr.String = '0.5';
            obj.editLambdaPr.Units = 'normalized';
            obj.editLambdaPr.Enable = 'on';
            obj.editLambdaPr.Visible = 'on';
            obj.editLambdaPr.Position = [0.7, 0.05, 0.2, 0.1];
            obj.editLambdaPr.Tag = 'LambdaPr';
            obj.editLambdaPr.Callback = @obj.changeSignalParameter;

        end
        
        
        
    end
    
   
    
    methods
        
        
        function obj = roimanager(sessionObj)
        %Constructs the GUI window and places all objects within it.
        
            if nargin
                obj.sessionObj = sessionObj;
            end
        
            % Create and configure GUI window
            obj.initializeGui()

            if nargout == 0
                clear obj
            end
                      
        end
        
        
        function obj = figsizeChanged(obj, ~, ~)
        % Callback function to resize/move ui panels if figure size is changed
        
            figsize = get(obj.fig, 'Position');
            aspectRatio = figsize(3)/figsize(4);
            
            obj.margins(1) = obj.margins(2) / aspectRatio; 
            obj.padding(1) = obj.padding(2) / aspectRatio;
            
            % Calculate new panel positions
            panelImageSize = [0.94/aspectRatio, 0.94]; % This panel determines the rest.
            availableWidth = 1 - panelImageSize(1) - obj.margins(1)*2 - obj.padding(1)*2;
            lSidePanelSize = [availableWidth/3*1, 0.94];
        	rSidePanelSize = [availableWidth/3*2, 0.94];
                
            lSidePanelPos = [obj.margins(1), obj.margins(2), lSidePanelSize];
            panelImagePos = [obj.margins(1) + lSidePanelSize(1) + obj.padding(1), obj.margins(2), panelImageSize];
            rSidePanelPos = [panelImagePos(1) + panelImageSize(1) + obj.padding(1), obj.margins(2), rSidePanelSize];

            % Reset panel positions
            set(obj.panelLeft, 'Position', lSidePanelPos);
            set(obj.panelImage, 'Position', panelImagePos)
            set(obj.panelRight, 'Position', rSidePanelPos);
            
            % Scale frameslider to keep same width as panelImage
            fslidePos = get(obj.fsContainer, 'Position');
            fslidePos(1) = panelImagePos(1);
            fslidePos(3) = panelImagePos(3);
            set(obj.fsContainer, 'Position', fslidePos)
            
            if obj.btnShowSignal.Value
                set(obj.axImageDisplay, 'Position', [0.12, 0.20, 0.76, 0.76])
            end

        end
        
        
        function editGuiSettings(obj, src, ~)
            
            
            switch src.Label
                case 'Edit Signal Settings'
                    oldSettings = obj.signalExtractionSettings;
                    newSettings = utilities.editStruct(oldSettings, 'all', 'Signal Extraction Settings');
                    obj.signalExtractionSettings = newSettings;
                case 'Edit General Settings'
                    oldSettings = obj.settings;
                    newSettings = utilities.editStruct(oldSettings, 'all', 'General Settings');
                    obj.settings = newSettings;
                otherwise
                    return
            end
            
            fields = fieldnames(oldSettings);
            
            for i = 1:numel(fields)
                if ~isequal(newSettings.(fields{i}), oldSettings.(fields{i}))
                    obj.changeSetting(fields{i}, newSettings.(fields{i}))
                end
            end
            
        end
        
        
        function changeSetting(obj, name, val)
            switch name
                case 'showTags'
                    if val
                        set(obj.RoiTextHandles{obj.currentChannel}, 'Visible', 'on')
                    else
                        set(obj.RoiTextHandles{obj.currentChannel}, 'Visible', 'off')
                    end
            end
        end
        
        
        function addToActionLog(obj, ch, roiIdx, action)
            
            % Update log position. If at the end of log, move elements up.
            if obj.logPosition == length(obj.actionLog)
                obj.actionLog = circshift(obj.actionLog, - 1);
            else
                obj.logPosition = obj.logPosition + 1;
            end
            
            jj = obj.logPosition; % proxy
            obj.lastLogPosition = jj;
            
            % Add entries to current position in log
            obj.actionLog(jj).ch = ch;
            obj.actionLog(jj).roiIdx = roiIdx;
            obj.actionLog(jj).action = action;
            
            rois = RoI.empty;
            for i = roiIdx
                rois(end+1) = obj.roiArray{ch}(i).copy;
            end
            
            obj.actionLog(jj).rois = rois; 
            
        end
        
        
        function traverseActionLog(obj, direction)

            switch direction
                case 'up'
                    jj = obj.logPosition; 
                    newLogPosition = obj.logPosition - 1;
                case 'down'
                    jj = obj.logPosition + 1; 
                    newLogPosition = obj.logPosition + 1;
            end
            
            % Return if beginning or end of log is reached.
            if newLogPosition < 0 || jj > obj.lastLogPosition
                disp('Nådd enden av loggen')
                return
            end
            
            if isequal(direction, 'up')
                obj.logPosition = newLogPosition;
            end
            
            if obj.actionLog(jj).ch ~= obj.currentChannel
                chTmp = obj.currentChannel;
                obj.changeCurrentChannel(struct('String', obj.loadedChannels(obj.actionLog(jj).ch)));
            end
            
            % obj.lastLogPosition always updated when performing an action.
            % When traversing the log, this variable has to be manually
            % updated set here. Get current value:
            tmpLastLogPosition = obj.lastLogPosition;
            
            ch = obj.currentChannel;
            
            switch obj.actionLog(jj).action
                case 'add'
                    % Remove roi that was added
                    obj.selectedRois = obj.actionLog(jj).roiIdx;
                    obj.removeRois([], []);
                    
                case 'remove'
                    nRois = numel(obj.actionLog(jj).rois);
                    if isequal(obj.actionLog(jj).roiIdx, obj.roiCount{ch} - fliplr(1:nRois) + 1)
                        mode = 'append';
                    else
                        mode = 'insert';
                    end
                    obj.addRois(obj.actionLog(jj).rois, obj.actionLog(jj).roiIdx, mode);
                    
                case 'reshape' % hvilket nummer i loggen? Er det samme eller er det ny?
                    for i = 1:numel(obj.actionLog(jj).roiIdx)
                        roiIdx = obj.actionLog(jj).roiIdx(i);

                        % Exchange objects in log and roiArray
                        roi = obj.actionLog(jj).rois(i);
                        roiBak = obj.roiArray{ch}(roiIdx);
                        obj.roiArray{ch}(roiIdx) = roi;
                        obj.actionLog(jj).rois(i) = roiBak;

                        % Replot the roi in the roiArray
                        updateRoiPlot(obj, roiIdx)
                        
                    end
                    
            end
            
            % Going back and forth in the log does not change the length of
            % the log, so update the value of the lastLogPosition:
            obj.lastLogPosition = tmpLastLogPosition;
            
            obj.logPosition = newLogPosition;
            switch direction
                case 'up'
                    fprintf('Angret, nåværende loggposisjon er %d, siste loggelement er %d\n', obj.logPosition, obj.lastLogPosition)
                case 'down'
                    fprintf('Gjorde om igjen, nåværende loggposisjon er %d, siste loggelement er %d\n', obj.logPosition, obj.lastLogPosition)
                    
            end
            
            if exist('chTmp', 'var')
                obj.changeCurrentChannel(struct('String', obj.loadedChannels(chTmp)));
            end
        
        end
        
        
        function setObjectVisibility(obj, src, ~)
            switch src.Label
                case 'Show Tags'
                    set(obj.RoiTextHandles{obj.currentChannel}, 'Visible', 'on')
                    src.Label = 'Hide Tags';
                case 'Hide Tags'
                    set(obj.RoiTextHandles{obj.currentChannel}, 'Visible', 'off')
                    src.Label = 'Show Tags';
                case 'Show Rois'
                    set(obj.RoiPlotHandles{obj.currentChannel}, 'Visible', 'on')
                    src.Label = 'Hide Rois';
                case 'Hide Rois'
                    set(obj.RoiPlotHandles{obj.currentChannel}, 'Visible', 'off')
                    src.Label = 'Show Rois';
                case 'Show Neuropil Mask on Roi Selection'
                    obj.settings.showNpMask = true;
                    src.Label = 'Hide Neuropil Mask on Roi Selection';
                case 'Hide Neuropil Mask on Roi Selection'
                    obj.removeNeuropilPatch('all')
                    obj.settings.showNpMask = false;
                    src.Label = 'Show Neuropil Mask on Roi Selection';
                case 'Show Correlation Image'
                    if isempty(obj.imgCn{obj.currentChannel})
                        %Credit: Eftychios A. Pnevmatikakis & Pengcheng Zhou
                        obj.imgCn{obj.currentChannel} = correlation_image(obj.imgTseries{obj.currentChannel});
                        obj.imgCn{obj.currentChannel} = uint8(obj.imgCn{obj.currentChannel}*255);
                    end
                    obj.updateImageDisplay('Correlation Image')
                    obj.unToggleShowButtons([]);
                case 'Show Roi Correlation Matrix'
                    chNo = obj.currentChannel;
                    roiIdx = obj.selectedRois;
                    if isempty(roiIdx); error('Requires a selection of 2 rois or more'); end
                    signalData = obj.signalArray(chNo).dff(:, roiIdx);
                    for j = 1:size(signalData, 2)
                        if all(isnan(signalData(:, j)))
                            obj.extractSignal(roiIdx(j), 'dff')
                        end
                    end
                    signalData = obj.signalArray(chNo).dff(:, roiIdx);

                    tmpfig = figure('Position', [400,200, 400, 400]);
                    s1 = axes('Position', [0.1,0.1,0.8,0.8], 'Parent', tmpfig);
%                     s2 = subplot(122, 'Parent', tmpfig);
                    [RHO, PVAL] = corr(signalData);
                    imshow(RHO, [0, 1], 'Parent', s1, 'InitialMagnification', 'fit');
%                     imshow(PVAL<0.05, [0, 1], 'Parent', s2, 'InitialMagnification', 'fit');
                    colormap(s1, 'parula');
%                     colormap(s2, 'gray');
                    s1.YAxis.Visible = 'on';
                    s1.XAxis.Visible = 'on';
%                     s1.XTick = 1:size(signalData,2);
%                     s1.YTick = 1:size(signalData,2);
%                     s1.XTickLabel = 1:size(signalData,2);
%                     s1.YTickLabel = 1:size(signalData,2);

            end
            
        end

        function showRoiCorrelationImage(obj, ~, ~)
            
            if isempty(obj.selectedRois); return; end
                    
            ch = obj.currentChannel;
            roiIdx = obj.selectedRois(end); % Dont want to do this for many rois.

            if isempty(obj.selectedFrames) || sum(obj.selectedFrames) == 0
                frames = 1:obj.nFrames;
            else
                frames = find(obj.selectedFrames);
            end

            [y, x] = find(obj.roiArray{ch}(roiIdx).mask);
            minX = min(x); maxX = max(x);
            minY = min(y); maxY = max(y);

            croppedMask = obj.roiArray{ch}(roiIdx).mask(minY:maxY, minX:maxX);
            pixelChunk = obj.imgTseries{ch}(minY:maxY, minX:maxX, :);

            f0 = prctile(pixelChunk, 20, 3);
            dff = (pixelChunk - f0) ./ f0;

            pixelChunk = dff(:, :, frames);

            roiCn = correlation_image(pixelChunk);
            roiCn = uint8(roiCn*255);


            tmpfig = figure('Position', [400, 200, round(range(x)*10), round(range(y)*10)]);
            tmpfig.MenuBar = 'none';

            s1 = axes('Position', [0.1,0.1,0.8,0.8], 'Parent', tmpfig);
            colormap(s1, 'parula');
            imagesc(s1, roiCn)
            s1.XAxis.Visible = 'off';
            s1.YAxis.Visible = 'off';

%                     
%                     mask = repmat(croppedMask, 1, 1, numel(frames));
%                     pixPerFrame = sum(croppedMask(:));
%                     pixelSignals = reshape(pixelChunk(mask), pixPerFrame, numel(frames))'; % nframes x npixels
%                     
% %                     tmpfig = figure('Position', [400, 200, 800, 400]);
% %                     s1 = subplot(121, 'Parent', tmpfig);
% %                     s2 = subplot(122, 'Parent', tmpfig);
%                     RHO = corr(single(pixelSignals));
% %                     imshow(RHO, [0, 1], 'Parent', s1, 'InitialMagnification', 'fit');
% %                     colormap(s1, 'parula');
% %                     s1.YAxis.Visible = 'on';
% %                     s1.XAxis.Visible = 'on';
%                     
%                     diagIdx = sub2ind(size(RHO), 1:length(RHO), 1:length(RHO));
%                     RHO(diagIdx)=0;
%                     
%                     modeRho=mode(RHO(:));
%                     medRho=nanmedian(RHO(:));
%                     lowprctile = prctile(RHO(:), 0.1);
%                     threshMode = modeRho+(modeRho-lowprctile);
%                     threshMed = medRho+(medRho-lowprctile);
%                     
%                     bwRho = RHO > 0;
% %                     
% %                     B = imgaussfilt(RHO);
% %                     figure;imagesc(B);
% %                     C = medfilt2(RHO);
% %                     figure;imagesc(C);
% %                     D = wiener2(RHO);
% %                     figure;imagesc(D);
% %                     
%                     E = imguidedfilter(RHO);
% %                     figure;imagesc(E);
% %                     medE=nanmedian(E(:));
% %                     threshMed = medE+(medE-lowprctile);
% 
% 
% %                     intImage = integralImage(RHO);
% %                     avgH = integralKernel([1 1 5 5], 1/25);
% %                     J = integralFilter(intImage, avgH);
% %                     figure
% %                     imagesc(J);
% %                     
% %                     histogram(s2, RHO)
% %                     hold(s2, 'on')
% %                     plot(s2, [threshMode, threshMode], s2.YLim, 'r')
% %                     plot(s2, [threshMed, threshMed], s2.YLim, '--r')
% 
% %                     [x, y] = find(RHO>threshMed);
%                     [x, y] = find(E>threshMed);
%                     idx = find(croppedMask);
%                     
%                     pixId = unique(x);
%                                         
%                     newMask = false(size(croppedMask));
%                     newMask(idx(pixId)) = true;
% %                     newMask = imerode(newMask, nhood);
% %                     newMask = imdilate(newMask, nhood);
% %                     newMask = imdilate(newMask, nhood);
% %                     newMask = imerode(newMask, nhood);
%                     newMask = bwareaopen(newMask, 8);
%                                
%                     if sum(newMask) < 10
%                         return
%                     end
%                     
%                     fullmask = false(size(obj.roiArray{ch}(roiIdx).mask));
%                     fullmask(minY:maxY, minX:maxX) = newMask;
%                                         
%                     newRoi = RoI('Mask', fullmask, size(fullmask));
%                     newRoi = obj.editRoiProperties(newRoi);
%                     newRoi.grow(1);
%                     obj.addRois(newRoi);
        end
        
        
        function obj = setMouseMode(obj, newMouseMode)
        % Change the mode of mouseclicks in the GUI
            
            % Cancel rois if new mouse mode is not edit mode or zoom modes
            switch newMouseMode
                case {'Select', 'Autodetect', 'Set Roi Diameter', ...
                      'EditSelect', 'Draw', 'CircleSelect'}
                    if ~isempty(obj.tmpImpoints)
                        obj.cancelRoi();
                    end
            end
            
            % Make circle selection tool invisible
            if isequal(obj.mouseMode, 'CircleSelect') && ~isequal(newMouseMode, 'CircleSelect')
                delete(obj.circleToolHandle)
                obj.circleToolHandle = [];
            end
            
            % Set mousemode
            switch newMouseMode
                % When releasing some mouse modes (e.g. zoom), change back
                % to the previous mode.
                case 'Previous'
                    if obj.btnDrawRoi.Value
                        obj.mouseMode = 'Draw';
                    elseif obj.btnEditRoi.Value
                        if isempty(obj.tmpImpoints)
                            obj.mouseMode = 'EditSelect';
                            obj.deselectRois(obj.selectedRois);
                        else
                            obj.mouseMode = 'EditDraw';
                        end
                    elseif obj.btnAutoDetect.Value
                        obj.mouseMode = 'Autodetect';
                    elseif strcmp(obj.btnSetRoiTemplateSize.String, 'Confirm')
                        obj.mouseMode = 'Set Roi Diameter';
                    else
                        obj.mouseMode = 'Select';
                    end
                    
                case 'EditSelect'
                    obj.mouseModePrev = obj.mouseMode;
                    obj.mouseMode = newMouseMode;
                    obj.deselectRois(obj.selectedRois);
                    
                case 'EditDraw'
                    obj.mouseModePrev = obj.mouseMode;
                    obj.mouseMode = newMouseMode;
                    
                case 'CircleSelect'
                    obj.mouseModePrev = obj.mouseMode;
                    obj.mouseMode = newMouseMode;
                    if isempty(obj.roiTemplateCenter)
                        xlim = get(obj.axImageDisplay, 'Xlim');
                        ylim = get(obj.axImageDisplay, 'Ylim');
                        obj.roiTemplateCenter = [xlim(1) + diff(xlim)/2, ylim(1) + diff(ylim)/2];
                    end
                
                    obj.plotCircleTool();
                    
                otherwise
                    obj.mouseModePrev = obj.mouseMode;
                    obj.mouseMode = newMouseMode;
            end
            
            % Take care of togglebuttons. Only one active at the same time
            switch newMouseMode
                case 'Draw'
                    obj.toggleEditButton(obj.btnDrawRoi);
                case 'Autodetect'
                    obj.toggleEditButton(obj.btnAutoDetect);
                case {'EditSelect', 'EditDraw'}
                    obj.toggleEditButton(obj.btnEditRoi);
                case 'CircleSelect'
                    obj.toggleEditButton(obj.btnCircleTool);
                case 'Select'
                    obj.toggleEditButton([]);
            end
            
            if obj.isCursorInsideAxes(obj.axImageDisplay) || obj.isCursorInsideAxes(obj.axSignalPlot)
                obj.updatePointer();
            end
        
        end
        
        
        function obj = updatePointer(obj)
        % Change pointers according to mousemode

            imfig = ancestor(obj.axImageDisplay, 'figure');
        
            if obj.isCursorInsideAxes(obj.axImageDisplay)
                mousePoint = get(obj.axImageDisplay, 'CurrentPoint');
                mousePoint = mousePoint(1, 1:2);
                
                currentPointer = get(imfig, 'Pointer');
                switch obj.mouseMode
                    case {'Draw', 'EditDraw'}
                        if obj.isCursorOnImpoint(mousePoint(1), mousePoint(2))
                            set(imfig,'Pointer', 'fleur');
                        elseif ~strcmp(currentPointer, 'crosshair')
                            set(imfig, 'Pointer', 'crosshair');
                        end
                    case 'Autodetect'
                        if ~strcmp(currentPointer, 'cross')
                            set(imfig, 'Pointer', 'cross');
                        end
                    case 'CircleSelect'
                        if ~strcmp(currentPointer, 'crosshair')
                            set(imfig, 'Pointer', 'crosshair');
                        end
                        if isequal(obj.circleToolHandle.Visible, 'off')
                            obj.circleToolHandle.Visible = 'on';
                        end
                    case 'EditSelect'
                        if ~strcmp(currentPointer, 'hand')
                           set(imfig, 'Pointer', 'hand');
                        end
                    case 'Set Roi Diameter'
                        if ~strcmp(currentPointer, 'circle')
                             set(imfig, 'Pointer', 'circle');
                        end
                    case 'Select'
                        if ~strcmp(currentPointer, 'hand')
                            set(imfig,'Pointer','hand');
                        end
                    case 'Zoom In'
                        if ~strcmp(currentPointer, 'custom') || strcmp(obj.mouseModePrev, 'Zoom Out')
                            setptr(imfig, 'glassplus');
                        end
                    case 'Zoom Out'
                        if ~strcmp(currentPointer, 'custom') || strcmp(obj.mouseModePrev, 'Zoom In')
                            setptr(imfig, 'glassminus');
                        end
                    case 'Multiselect'
                        if ~strcmp(currentPointer, 'crosshair')
                            set(imfig,'Pointer','crosshair');
                        end
                end
            elseif obj.isCursorInsideAxes(obj.axSignalPlot)
                currentPointer = get(obj.fig, 'Pointer');
                if isequal(obj.mouseMode, 'Zoom In')
                    if ~strcmp(currentPointer, 'custom') || strcmp(obj.mouseModePrev, 'Zoom Out')
                        setptr(obj.fig, 'glassplus');
                    end
                elseif isequal(obj.mouseMode, 'Zoom Out')
                    if ~strcmp(currentPointer, 'custom') || strcmp(obj.mouseModePrev, 'Zoom In')
                        setptr(obj.fig, 'glassminus');
                    end
                else
                    set(obj.fig, 'Pointer', 'arrow');
                end
            else
                set(imfig, 'Pointer', 'arrow');
                if ~isempty(obj.circleToolHandle)
                    obj.circleToolHandle.Visible = 'off';
                end
            end
            
        end
        
     
        function bool = isCursorInsideAxes(obj, ax)
        % Check if mousepoint is within axes limits of image display
            
            if nargin < 2
                ax = gca;
            end
        
            currentPoint = get(ax, 'CurrentPoint');
            currentPoint = currentPoint(1, 1:2);

            xLim = get(ax, 'XLim');
            yLim = get(ax, 'YLim');
            axLim = [xLim(1), yLim(1), xLim(2), yLim(2)];

            % Check if mousepoint is within axes limits.
            bool = ~any(any(diff([axLim(1:2); currentPoint; axLim(3:4)]) < 0));
        end
        
        
        function zoomOnRoi(obj, i)
            
            % Zoom in on roi if roi is not within limits.
            xLim = get(obj.axImageDisplay, 'XLim');
            yLim = get(obj.axImageDisplay, 'YLim');

            ch = obj.currentChannel;
            roiCenter = obj.roiArray{ch}(i).center;
            
            % Decide if field of view should be changed (if roi is not inside image)
            [y,x] = find(obj.roiArray{ch}(i).mask);
            roiPositionLimits = [min(x), max(x); min(y), max(y)];
            if ~ ( roiPositionLimits(1,1) > xLim(1) && roiPositionLimits(1,2) < xLim(2) )
                changeFOV = true;
            elseif ~ ( roiPositionLimits(2,1) > yLim(1) && roiPositionLimits(2,2) < yLim(2) )
                changeFOV = true;
            else
                changeFOV = false;
            end
            
            if changeFOV
                shiftX = roiCenter(1) - mean(xLim);
                shiftY = roiCenter(2) - mean(yLim);
                xLimNew = xLim + shiftX;
                yLimNew = yLim + shiftY;
                obj.setNewImageLimits(xLimNew, yLimNew);
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
                    
            xLim = get(obj.axImageDisplay, 'XLim');
            yLim = get(obj.axImageDisplay, 'YLim');

            mp_f = get(obj.fig, 'CurrentPoint');
            mp_a = get(obj.axImageDisplay, 'CurrentPoint');
            mp_a = mp_a(1, 1:2);

            % Find ax position and limits in figure units.
            figsize = get(obj.fig, 'Position');
            panelPos = get(obj.panelImage, 'Position') .* [figsize(3:4), figsize(3:4)];  % pixel units
            axPos = get(obj.axImageDisplay, 'Position') .* [panelPos(3:4), panelPos(3:4)];  % pixel units
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
            
            setNewImageLimits(obj, xLimNew, yLimNew)
            
        end
        
        
        function imageZoomRect(obj)
        % Zoom in image according to rectangle coordinates.
        
            xData = get(obj.zoomRectPlotHandle, 'XData');
            yData = get(obj.zoomRectPlotHandle, 'YData');
            
            xLimNew = [min(xData), max(xData)];
            yLimNew = [min(yData), max(yData)];
            
            % Sometimes happens on very fast click and drag.
            if any(isnan(xLimNew)) || any(isnan(yLimNew))
                return
            end
            
            % Sometimes happens when dragging an impoint
            if isempty(xLimNew) || isempty(yLimNew)
                return
            end
            
            if diff(xLimNew) > diff(yLimNew)
                yLimNew = yLimNew + [-1, 1] * (diff(xLimNew) - diff(yLimNew)) / 2;
            elseif diff(xLimNew) < diff(yLimNew)
                xLimNew = xLimNew + [-1, 1] * (diff(yLimNew) - diff(xLimNew)) / 2;
            end

            if isequal(obj.zoomRectPlotHandle.Parent, obj.axImageDisplay)
                setNewImageLimits(obj, xLimNew, yLimNew)
            elseif isequal(obj.zoomRectPlotHandle.Parent, obj.axSignalPlot)
                setXLimitsZoom(obj, xLimNew)
                % Change frame so that current fram is in center of region
                % which is zoomed in on.
                obj.changeFrame(struct('String', num2str(round(mean(xLimNew)))), [], 'jumptoframe');
            else
                error('This is a bug, please report')
            end
            
        end
        
        
        function setNewImageLimits(obj, xLimNew, yLimNew)
            
            set(obj.axImageDisplay, 'units', 'pixel')
            pos = get(obj.axImageDisplay, 'Position');
            set(obj.axImageDisplay, 'units', 'normalized')

            arAx = pos(3)/pos(4);
            arNewLim = abs(diff(xLimNew) / diff(yLimNew));
            if ~(arAx-0.01 <= arNewLim && arNewLim <= arAx+0.01)
                yLimNew = yLimNew*arNewLim/arAx;
            end
            
            set(obj.axImageDisplay, 'XLim', xLimNew, 'YLim', yLimNew)
            
        end
        
        
        function plotZoom(obj, direction)
           
            oldLim = obj.axSignalPlot.XLim;
            oldCenter = mean(oldLim);
            
            switch direction
                case 'in'
                    newRange = diff(oldLim) * 0.9;
                case 'out'
                    newRange = diff(oldLim) / 0.9;
            end
            
            newWidth = mean([1, newRange]);
            newLim = [oldCenter-newWidth, oldCenter+newWidth];
            
            % Calculate shift for good zoom in on frame
            x0 = obj.currentFrameNo;
            
            newXmin = -1 * ((x0-oldLim(1)) / diff(oldLim) * diff(newLim) - x0);
            shiftX = newLim(1) - newXmin;
            xLimNew = newLim - shiftX;
            
            obj.setXLimitsZoom(xLimNew)

        end
        
        
        function setXLimitsZoom(obj, newLimits)
        % Specify newLimits in frames
            
            absLimits = [1, obj.nFrames];
            oldLimits = obj.axSignalPlot.XLim;
            
            % Sanity checks
            if isequal(oldLimits, newLimits)
                return
            elseif newLimits(2) < newLimits(1)
                return
            end
            
            newLimits = round(newLimits);
            
            % Check that limits are within absolute limits (force if not)
            if newLimits(1) < absLimits(1)
                newLimits(1) = absLimits(1);
            end
            
            if newLimits(2) > absLimits(2)
                newLimits(2) = absLimits(2);
            end     
                        
            % Current frame should remain in the image, preferably in the
            % center. So I will check if the new limits have to be shifted.
            
%             % Find maximum shift allowed... 
%             maxShiftLeft = absLimits(1) - newLimits(1);
%             maxShiftRight = absLimits(2) - newLimits(2);
%             
%             % Find shift to put current frame in center
%             shift = obj.currentFrameNo - round(mean(newLimits));
%             
%             % Don' allow values for shift outside max limits.
%             if shift < maxShiftLeft
%                 shift = maxShiftLeft;
%             elseif shift > maxShiftRight
%                 shift = maxShiftRight;
%             end
%             
%             % Shift the new limits
%             newLimits = newLimits + shift;
            
            % Set new limits
            obj.setNewXLims(newLimits)
        end
        
    
        function setXLimitsPan(obj, newLimits)
        % Check that limits are within absolute limits (force if not)
        
        % This is a lot of conditions. Should it be this effin long??
            absLimits = [1, obj.nFrames];
            tmpLimits = obj.axSignalPlot.XLim;
            
            direction = sign(newLimits(1)-tmpLimits(1));
            changeLimits = true;
            
            % Don't pan if current frame is close to abs limits.
            if obj.currentFrameNo < absLimits(1) + diff(tmpLimits)/2
                changeLimits = false;
            elseif obj.currentFrameNo < absLimits(1) - diff(tmpLimits)/2
                changeLimits = false;
            end
            
            % Don't pan if current frame passed midway of current limits.
            if direction == 1 
                if obj.currentFrameNo < round(diff(tmpLimits)/2 + tmpLimits(1))
                    changeLimits = false;
                end
            elseif direction == -1
                if obj.currentFrameNo > round(diff(tmpLimits)/2 + tmpLimits(1))
                    changeLimits = false;
                end
            else
               return 
            end
            
            % Not necessary in this context, but just for the sake of it.
            if newLimits(1) < absLimits(1) || newLimits(2) > absLimits(2)
                changeLimits = false;
            end
            
            % Change limits.
            if changeLimits
                obj.setNewXLims(newLimits)
            elseif ~changeLimits && obj.currentFrameNo < newLimits(1)
                newLimits = newLimits - (newLimits(1)-obj.currentFrameNo);
                obj.setNewXLims(newLimits)
            elseif ~changeLimits && obj.currentFrameNo > newLimits(2)
                newLimits = newLimits + (obj.currentFrameNo-newLimits(2));
                obj.setNewXLims(newLimits)
            else
                return
            end
            
        end
        
        
        function setNewXLims(obj, newLimits)
            % Set new limits
            set(obj.axSignalPlot, 'XLim', newLimits);
        end
        
        
        function obj = moveImage(obj, shift)
        % Move image in ax according to shift
            
            % Get ax position in figure coordinates
            figsize = get(obj.fig, 'Position');
            panelPos = get(obj.panelImage, 'Position') .* [figsize(3:4), figsize(3:4)];  % pixel units
            axPos = get(obj.axImageDisplay, 'Position') .* [panelPos(3:4), panelPos(3:4)];  % pixel units
            axPos = [panelPos(1:2), 0, 0] + axPos;
        
            % Get current axes limits
            xlim = get(obj.axImageDisplay, 'XLim');
            ylim = get(obj.axImageDisplay, 'YLim');
            
            % Convert mouse shift to image shift
            imshift = shift ./ axPos(3:4) .* [diff(xlim), diff(ylim)];
            xlim = xlim - imshift(1);
            ylim = ylim + imshift(2);

            % Dont move outside of image boundaries..
            if xlim(1) > 0 && xlim(2) < obj.imWidth
                set(obj.axImageDisplay, 'XLim', xlim);
            end
            if ylim(1) > 0 && ylim(2) < obj.imHeight
                set(obj.axImageDisplay, 'YLim', ylim);
            end 
        end
       
        
        function undockImageWindow(obj, src, ~)
            switch src.String
                case 'Undock Image Window'
                    obj.imfig = figure();
                    set(obj.imfig, 'WindowScrollWheelFcn', {@obj.changeFrame, 'mousescroll'}, ...
                    'WindowKeyPressFcn', @obj.keyPress, ...
                    'WindowButtonUpFcn', @obj.mouseRelease, ...
                    'WindowButtonMotionFcn', @obj.mouseOver )
                    set(obj.axImageDisplay, 'Parent', obj.imfig)
                    if obj.btnShowSignal.Value
                        set(obj.axImageDisplay, 'Position', [0.03, 0.03, 0.94, 0.94])
                    end
                    set(obj.btnUndockImage, 'String', 'Dock Image Window')
                    
                case 'Dock Image Window'
                    set(obj.axImageDisplay, 'Parent', obj.panelImage)
                    close(obj.imfig )
                    set(obj.btnUndockImage, 'String', 'Undock Image Window')
                    if obj.btnShowSignal.Value
                        set(obj.axImageDisplay, 'Position', [0.12, 0.2, 0.76, 0.76])
                    end

            end
            
        end
      
        
% % % % Mouse and keyboard callbacks

        function obj = keyPress(obj, ~, event)
        % Function to handle keyboard shortcuts. 
        
        % Pan and zoom functions are modified from axdrag (https://github.com/gulley/Ax-Drag)
            
            % Return if source is an input box
            
            currentObject = gco;
            
            if isa(currentObject, 'matlab.ui.control.UIControl')
                if isequal(currentObject.Style, 'edit')
                    return
                end
            end
            
            switch event.Key
                case 'd'
                    if contains(event.Modifier, 'command')
                        source = obj.popupRoiclass;
                        obj.popupRoiclass.Value = find(contains(obj.popupRoiclass.String, 'Neuronal Dendrite'));
                        obj.changeRoiClass(source, []);
                    else
                        switch obj.mouseMode
                            case 'Draw'
                                obj.setMouseMode('Select');
                            otherwise
                                obj.setMouseMode('Draw');
                        end
                    end

                case 'a'
                    switch obj.mouseMode
                        case 'Autodetect'
                            obj.setMouseMode('Select');
                        otherwise
                            obj.setMouseMode('Autodetect');
                    end
                    
                case {'o', 'c'}
                    if contains(event.Modifier, {'command', 'control'})
                        if isequal(event.Key, 'c')
                            obj.connectRois([], [])
                        end
                    else
                        switch obj.mouseMode
                            case 'CircleSelect'
                                obj.setMouseMode('Select');
                            otherwise
                                obj.setMouseMode('CircleSelect');
                        end
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
                    if contains(event.Modifier, 'command')
                        source = obj.popupRoiclass;
                        obj.popupRoiclass.Value = find(contains(obj.popupRoiclass.String, 'Neuronal Soma'));
                        obj.changeRoiClass(source, []);
                    else
                        obj.setMouseMode('Select');
                    end
                    
                case 'f'
                    obj.finishRoi();
                    
                case 'g'
                    if isequal(obj.mouseMode, 'CircleSelect')
                        tmpCoords = obj.circleToolCoords;
                        tmpCoords(3) = tmpCoords(3) + 1;
                        obj.plotCircleTool(tmpCoords)
                    elseif ~isempty(obj.selectedRois)
                        obj.growRois([], []);
                    end
                
                case 'h'
                    if isequal(obj.mouseMode, 'CircleSelect')
                        tmpCoords = obj.circleToolCoords;
                        tmpCoords(3) = tmpCoords(3) - 1;
                        obj.plotCircleTool(tmpCoords)
                    elseif ~isempty(obj.selectedRois)
                        obj.shrinkRois([], []);
                    end
                    
                    
                case 'escape'
                    obj.cancelRoi();
                    
                case '8'
                    obj.btnShowAvg.Value = 1;
                    obj.showAvg(obj.btnShowAvg); % Simulate button press
                    
                case '9'
                    obj.btnShowMax.Value = 1;
                    obj.showMax(obj.btnShowMax); % Simulate button press
                     
                case 'backspace'
                    switch obj.mouseMode
                        case {'Select', 'Autodetect', 'Multiselect'}
                            % Only remove things if current object is not
                            % uicontrol (exception if uicontrol is listbox)
                            if isequal(gco, obj.roiListBox) || ~isa(gco, 'matlab.ui.control.UIControl')
                                obj.removeRois();
                            end                                
                                
                        case {'Draw', 'EditDraw'}
                            % Only remove things if current object is not uicontrol
                            if ~isa(gco, 'matlab.ui.control.UIControl')
                                if ~isempty(obj.selectedImpoint)
                                    obj.removeImpoint();
                                end
                            end
                    end
                
                case 'leftarrow'
                    % Only move things if current object is not uicontrol
                    if ~isa(gco, 'matlab.ui.control.UIControl')
                        if ~isempty(obj.selectedRois)   % move rois
                        	obj.moveRoi( [-1, 0] );
                            obj.shiftRoiPlot( [-1, 0, 0] );
                        else                        
                            xLim = get(obj.axImageDisplay, 'XLim');
                            xLimNew = xLim - obj.panFactor * diff(xLim);
                            if xLimNew(1) > 0 && xLimNew(2) < obj.imWidth
                                set(obj.axImageDisplay, 'XLim', xLimNew);
                            end
                        end
                    end
                
                case 'rightarrow'
                	% Only move things if current object is not uicontrol
                    if ~isa(gco, 'matlab.ui.control.UIControl')
                        if ~isempty(obj.selectedRois)   % move rois
                        	obj.moveRoi( [1, 0] );
                            obj.shiftRoiPlot( [1, 0, 0] );
                        else
                            xLim = get(obj.axImageDisplay, 'XLim');
                            xLimNew = xLim + obj.panFactor * diff(xLim);
                            if xLimNew(1) > 0 && xLimNew(2) < obj.imWidth
                                set(obj.axImageDisplay, 'XLim', xLimNew);
                            end
                        end
                    end
                
                case 'uparrow'
                    % Only move things if current object is not uicontrol
                    if ~isa(gco, 'matlab.ui.control.UIControl')
                        if ~isempty(obj.selectedRois)   % move rois
                        	obj.moveRoi( [0, -1] );
                            obj.shiftRoiPlot( [0, -1, 0] );
                        else                            % move image                        
                            yLim = get(obj.axImageDisplay, 'YLim');
                            yLimNew = yLim - obj.panFactor * diff(yLim);
                            if yLimNew(1) > 0 && yLimNew(2) < obj.imWidth
                                set(obj.axImageDisplay, 'YLim', yLimNew);
                            end
                        end
                    end

                case 'downarrow'
                    % Only move things if current object is not uicontrol
                    if ~isa(gco, 'matlab.ui.control.UIControl')
                        if ~isempty(obj.selectedRois)   % move rois
                        	obj.moveRoi( [0, 1] );
                            obj.shiftRoiPlot( [0, 1, 0] );
                        else                            % move image
                            yLim = get(obj.axImageDisplay, 'YLim');
                            yLimNew = yLim + obj.panFactor * diff(yLim);
                            if yLimNew(1) > 0 && yLimNew(2) < obj.imWidth
                                set(obj.axImageDisplay, 'YLim', yLimNew);
                            end
                        end
                    end
                    
                case 'backquote'
                    if ~isempty(event.Modifier) && isequal(event.Modifier{1}, 'shift')
                        obj.changeFrame([], [], 'next')
                    else
                        obj.changeFrame([], [], 'prev')
                    end
                    
                case {'z', 'Z'}
                	
                    if contains('command', event.Modifier) && contains('shift', event.Modifier) ...
                            || contains('control', event.Modifier) && contains('shift', event.Modifier)
                        obj.traverseActionLog('down')
                    elseif contains('command', event.Modifier) || contains('control', event.Modifier) 
                        obj.traverseActionLog('up')
                    elseif event.Character == 'z'
                        obj.imageZoom('in');
                    elseif event.Character == 'Z'
                        obj.imageZoom('out');
                    end
                    
                case {'x', 'X'}
                    if event.Character == 'x'
                        obj.plotZoom('in');
                    else
                        obj.plotZoom('out');
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
                    set(obj.axImageDisplay, 'XLim', [0, obj.imWidth], 'YLim', [0, obj.imHeight])
                    set(obj.axSignalPlot, 'XLim', [1, obj.nFrames])
                    
                case {'1', '2', '3', '4'}
%                     src.String = event.Key;
                    if contains('shift', event.Modifier)
                        if isequal(event.Key, '1')
                            obj.setNewImageLimits([1, round(obj.imWidth/2)], [1, round(obj.imHeight/2)]);
                        elseif isequal(event.Key, '2')
                            obj.setNewImageLimits([round(obj.imWidth/2), obj.imWidth], [1, round(obj.imHeight/2)]);
                        elseif isequal(event.Key, '3')
                            obj.setNewImageLimits([1, round(obj.imWidth/2)], [round(obj.imHeight/2), obj.imHeight]);
                        elseif isequal(event.Key, '4')
                            obj.setNewImageLimits([round(obj.imWidth/2), obj.imWidth], [round(obj.imHeight/2), obj.imHeight]);
                        end
                    else
                    obj.changeCurrentChannel(struct('String', event.Key), []);
                    end
                    
                case '0'
                    if strcmp(event.Character, '0')
                        obj.changeChannelDisplayMode(obj.btnShowSingleChannel, []);
                    end
                    
                case 'm'
                    if contains(event.Modifier, {'command', 'control'})
                        obj.mergeRois([], [])
                    else
                        obj.setMouseMode('Multiselect');
                    end
                case 'u'
                    % Flush signal plot
                    obj = findall(obj.axSignalPlot, 'Type', 'Line');
                    delete(obj(1:end-1))
                case 'b'
                    obj.selectFrames('Start Selection')
                case 'p'
                    if obj.btnPlayVideo.Value
                        obj.btnPlayVideo.Value = 0;
                    else
                        obj.btnPlayVideo.Value = 1;
                        obj.playVideo([],[])
                    end
                        
            end
            
        end
        
        
        function obj = keyRelease(obj, ~, event)
        % Function to handle keyboard shortcuts. 
                switch event.Key
                    case 'b'
                        obj.selectFrames('Finish Selection')
                        
                    case 'v'
                        obj.setMouseMode('Previous');
                end
        end
        
        
        function obj = mousePress(obj, ~, event)
        % Callback function to handle mouse presses on image obj
        
            % Record mouse press and current mouse position
            obj.mouseDown = true;
            ch = obj.currentChannel;
            
            % Get current mouse position in ax
            x = event.IntersectionPoint(1);
            y = event.IntersectionPoint(2);
            
            obj.prevMousePointAx = [x, y];
            obj.prevMouseClick = [x, y];
            obj.prevMousePointFig = get(obj.fig, 'CurrentPoint');
            
            % Determine if mouse click was inside of a RoI
            switch obj.mouseMode
                case {'Autodetect', 'EditSelect', 'Select'}
                    wasInRoi = 0;
                    for i = 1:numel(obj.roiArray{ch})
                        if isInRoi(obj.roiArray{ch}(i), x, y)
                            wasInRoi = 1;
                            selectedRoi = i;
                            break
                        end
                    end
            end            
            
            % Perform appropriate actions according to mousemode.
            switch obj.mouseMode 
                case {'Draw', 'EditDraw'}        % Convert mouseclick to roi vertex
                	idx = obj.isCursorOnImpoint(x, y);
                    if idx == 0
                        obj.addImpoint(x, y);
                        obj.drawTmpRoi();
                    end
                    
                case 'Autodetect'
                    mask = obj.autodetect(x, y);
                    
                    if wasInRoi && ~isempty(mask)
                        obj.addToActionLog(ch, selectedRoi, 'reshape')
                        obj.roiArray{ch}(selectedRoi).reshape('Mask', mask);
                        obj.modifySignalArray(selectedRoi, 'reset')
                        obj.updateRoiPlot(selectedRoi);
%                         if obj.btnShowSignal.Value
%                             if isequal(selectedRoi, obj.selectedRois)
%                                 obj.updateSignalPlot(selectedRoi, 'overwrite')
%                             end
%                         end
                        obj.selectRois(selectedRoi, 'normal')

                         
                    elseif ~wasInRoi && ~isempty(mask)
                        newRoi = RoI('Mask', mask, [obj.imHeight, obj.imWidth]);
                        newRoi = obj.editRoiProperties(newRoi);
                        obj.addRois(newRoi);
                        obj.selectRois(obj.roiCount{ch}, 'normal')
                    end
                    
                case 'CircleSelect'
                    newRoi = RoI('Circle', obj.circleToolCoords, [obj.imHeight, obj.imWidth]);
                    newRoi = obj.editRoiProperties(newRoi);
                    obj.addRois(newRoi);
                    obj.selectRois(obj.roiCount{ch}, 'normal')
                    
                
                case 'EditSelect'
                    
                    if wasInRoi
                        
                        obj.selectedRois = selectedRoi;
                        roi = obj.roiArray{ch}(selectedRoi);
                        
                        if strcmp(roi.shape, 'Mask') % Use boundary to create impoints
                        	obj.tmpRoiPosX = roi.boundary{1}(1:5:end, 2)';
                            obj.tmpRoiPosY = roi.boundary{1}(1:5:end, 1)';
                        elseif strcmp(roi.shape, 'Polygon')
                            obj.tmpRoiPosX = roi.coordinates(:, 1)';
                            obj.tmpRoiPosY = roi.coordinates(:, 2)';                        
                        end

                        % Add impoints to roimanager.
                        for i = 1:length(obj.tmpRoiPosX)
                            x = obj.tmpRoiPosX(i);
                            y = obj.tmpRoiPosY(i);
                            obj.addImpoint(x, y);
                        end
                        obj.drawTmpRoi();

                        % Remove plot of selected roi
                        hold on
                        h = obj.RoiPlotHandles{ch}(obj.selectedRois);
                        set(h, 'XData', 0, 'YData', 0)
                        hold off
                                  
                        % Set mousemode to editdraw
                        obj.setMouseMode('EditDraw');
                    end

                case 'Set Roi Diameter'
                    obj.roiTemplateCenter = [x, y];
                    obj.plotRoiTemplate();

                case 'Select'           % Change status of roi if it was clicked
                    if ~wasInRoi
                        selectedRoi = nan;
                    end
                    obj.selectRois(selectedRoi, obj.fig.SelectionType)
                 
                case {'Zoom In', 'Multiselect'}
                    axes(obj.axImageDisplay)
                    hold on
                    if isempty(obj.zoomRectPlotHandle)
                        obj.zoomRectPlotHandle = plot(obj.axImageDisplay, nan, nan, 'Color', 'white');
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
            obj.mouseDown = true;
            
            % Get current mouse position in ax.
            x = event.IntersectionPoint(1);
            y = event.IntersectionPoint(2);
            
            obj.prevMousePointAx = [x, y];
            obj.prevMouseClick = [x, y];
            
            
            switch obj.mouseMode
                case 'Zoom In'
                    axes(obj.axSignalPlot)

                    if isempty(obj.zoomRectPlotHandle)
                        obj.zoomRectPlotHandle = plot(obj.axSignalPlot, nan, nan, 'Color', [0.6,0.6,0.9], 'LineStyle', '-', 'Marker', 'none');
                    else
                        set(obj.zoomRectPlotHandle, 'XData', nan, 'Ydata', nan)
                    end
                    set(obj.zoomRectPlotHandle, 'Visible', 'on')
                    
                case 'Zoom Out'
                    obj.plotZoom('out');
                    
                otherwise
                    x = event.IntersectionPoint(1);

                    source.String = num2str(round(x));
                    obj.changeFrame(source, [], 'jumptoframe');
            end
            
        end
        
        
        function obj = mouseRelease(obj, ~, ~)
        % Callback function when mouse button is released over figure.
        
            obj.mouseDown = false;
            
            switch obj.mouseMode
                case 'Zoom In'
                    currentPoint = get(gca, 'CurrentPoint');
                    currentPoint = currentPoint(1, 1:2);
                    
                    % make sure zoom only happens if we press in the image
                    if ~obj.isCursorInsideAxes(gca)
                        return
                    end
                    
                    if all((abs(obj.prevMouseClick - currentPoint)) < 5) % No movement
                        if isequal(gca, obj.axImageDisplay)
                            obj.imageZoom('in');
                        elseif isequal(gca, obj.axSignalPlot)
                            obj.plotZoom('in')
                        end
                    else
                        obj.imageZoomRect(); % Set new limits based on new and old point
                    end
                    
                    delete(obj.zoomRectPlotHandle)
                    obj.zoomRectPlotHandle = gobjects(0);
                    
                case 'Multiselect'
                    currentPoint = get(obj.axImageDisplay, 'CurrentPoint');
                    currentPoint = currentPoint(1, 1:2);
                    
                    % make sure selection only happens if we press in the image
                    if ~obj.isCursorInsideAxes(obj.axImageDisplay)
                        return
                    end
                    
                    if ~all((abs(obj.prevMouseClick - currentPoint)) < 1) % No movement
                        obj.multiSelectRois(); % Set new limits based on new and old point
                        obj.setMouseMode('Select');
                    end
                    
                    delete(obj.zoomRectPlotHandle)
                    obj.zoomRectPlotHandle = gobjects(0);
                    
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
            
            obj.updatePointer();
            
            if obj.isCursorInsideAxes(obj.axImageDisplay) && obj.mouseDown   % "Click and Drag"
                set(obj.fig, 'CurrentObject', obj.panelImage)
                newMousePointAx = get(obj.axImageDisplay, 'CurrentPoint');
                newMousePointAx = newMousePointAx(1, 1:2);
                
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
                    
                    case {'Zoom In', 'Multiselect'}
                        % Plot a rectangle 
                        x1 = obj.prevMouseClick(1);
                        x2 = newMousePointAx(1);
                        y1 = obj.prevMouseClick(2);
                        y2 = newMousePointAx(2);
                        set(obj.zoomRectPlotHandle, 'XData', [x1, x1, x2, x2, x1], ...
                                                    'YData', [y1, y2, y2, y1, y1])

                end
                
            elseif obj.isCursorInsideAxes(obj.axSignalPlot) && obj.mouseDown 
                newMousePointAx = get(obj.axSignalPlot, 'CurrentPoint');
                newMousePointAx = newMousePointAx(1, 1:2);
                
                switch obj.mouseMode
                    case {'Zoom In', 'Multiselect'}
                        % Plot a rectangle 
                        x1 = obj.prevMouseClick(1);
                        x2 = newMousePointAx(1);
                        y1 = obj.prevMouseClick(2);
                        y2 = newMousePointAx(2);
                        set(obj.zoomRectPlotHandle, 'XData', [x1, x1, x2, x2, x1], ...
                                                    'YData', [y1, y2, y2, y1, y1])
                end
                
            elseif obj.isCursorInsideAxes(obj.axImageDisplay) && ~obj.mouseDown
                if ~isempty(obj.circleToolHandle)
                    newMousePointAx = get(obj.axImageDisplay, 'CurrentPoint');
                    newMousePointAx = newMousePointAx(1, 1:2);
                    tmpCoords = [newMousePointAx, obj.circleToolCoords(3)];
                    obj.plotCircleTool(tmpCoords);
                end
            
            else % Release mouseDown if mouse moves out of image.
                set(obj.fig, 'CurrentObject', obj.fig)
                if obj.mouseDown
                    obj.mouseDown = false;
                end
            end
        end
        
               
% % % %  Methods for loading images
     
        function loadStack(obj, source, ~)
        % Load an image stack into the GUI

            if ~isempty(obj.sessionObj)
                folderPath = obj.sessionObj.getFolderPath('calcium_images_aligned');
                listing = dir(fullfile(folderPath, '*.tif'));
                fileName = {listing.name};
                fileName = fileName(1:4:end);
            
            else

                % Set path for where to start browsing.
                initpath = obj.initPath;

                % Open browser
                [fileName, folderPath, ~] =  uigetfile({'*.tif', 'Tiff Files (*.tif)'; ...
                                                '*.tiff', 'Tiff Files (*.tiff)'; ...
                                                '*', 'All Files (*.*)'}, ...
                                                'Find Stack', ...
                                                initpath, 'MultiSelect', 'on');

                % Return if user pressed cancel
                if isequal(fileName, 0)
                    return
                end

            end

%             folderPath = '/Users/eivinhen/Desktop';
%             fileName = 'Substack_ch2_part001.tif';
    
            % Reset list of names for loaded files
            obj.loadedFileName = cell(0);
                        
            % Multiselect is on, convert single selection to cell array
            if ischar(fileName)
                fileName = {fileName};
            end
            
            obj.initPath = folderPath;
            
            sessionID = regexp(fileName{1}, obj.sIdExpr, 'match');
            if ~isempty(sessionID)
                obj.editExpName.String = sessionID;
            end

            
            % Determine channel numbers. Assumes that all names 
            % are built the same way.
            
            chMatch = strfind(fileName{1}, obj.chExpr);
            
            if ~isempty(chMatch)
                % Find channel expression and number in filename
                [chMatchBeg, chMatchEnd] = regexp(fileName{1}, [obj.chExpr '\d*']);
                
                % Find unique channel number and number of channels
                chNumbers = cellfun(@(fn) fn(chMatchBeg(1):chMatchEnd(1)), fileName, 'uni', 0);
                
                [imgChannels, ~, ic] = unique(chNumbers);
                nChannels = numel(imgChannels);
                imgChannels = strrep(imgChannels, obj.chExpr, '');
               
                % Sort filenames after channels
                fileName = arrayfun(@(ch) fileName(ic==ch), 1:nChannels, 'uni', 0 );
                try
                    fileName = cat(1, fileName{:});
                catch
                    [cdata,map] = imread('trees.tif'); 
                    msgbox('Number of files per channel must be equal.', ...
                        sprintf('Error @ %s', obj.btnLoadImages.String), ...
                        'custom',cdata,map);
                    error(['Error using %s \n', ...
                           'Number of files per channel must be equal.'], obj.btnLoadImages.String )
                end
            else
                imgChannels = {'n/a'};
                nChannels = 1;
            end
  
            imFilePath = fullfile(folderPath, fileName);

            % Check if different channels are loaded. Then old rois will be
            % deleted.
            if ~isequal(imgChannels, obj.loadedChannels)
                obj.clearRois([], []);
                obj.roiCount = {};
            end

            % Reinitialize roi cell arrays to get rid of old data.
            obj.imgTseries = cell(nChannels, 1);
            obj.imgTseriesMedfilt = cell(nChannels, 1);
            obj.imgCn = cell(nChannels, 1);
            
            if isempty(obj.roiCount)
                % Set roiArray to cell array of roi arrays (one per channel)
                obj.roiArray = arrayfun(@(i) RoI.empty, 1:nChannels, 'uni', 0);
                obj.roiCount = arrayfun(@(i) 0, 1:nChannels, 'uni', 0);
                obj.RoiPlotHandles = cell(nChannels, 1);
                obj.RoiTextHandles = cell(nChannels, 1);
            end

            % Determine number of parts and load image timeseries for all parts and channels.
            nParts = size(fileName, 2);
            stacks = cell(nChannels, nParts);
            for i = 1:nParts
                for ch = 1:nChannels
                    msg = sprintf('Please wait... Loading calcium images (part %d/%d, ch %d/%d)...', i, nParts, ch, nChannels);
                    stacks{ch, i} = roimanager.stack2mat(imFilePath{ch, i}, true, msg);
                end
            end
            
            % Concatenate parts and create average images and roi arrays
            for ch = 1:nChannels
                obj.imgTseries{ch} = cat(3, stacks{ch, :});
            	obj.imgAvg{ch} = uint8(mean(obj.imgTseries{ch}, 3));
            	obj.imgMax{ch} = max(obj.imgTseries{ch}, [], 3);
            end
            
            % Load average and max stack projections
            %obj = loadStackProjections(obj);
                        
            % Get image dimensions (assume all channels are same dim)
            [obj.imHeight, obj.imWidth, obj.nFrames] = size(obj.imgTseries{1});
            
            % Reinitialize signalArray
            obj.initializeSignalArray(1:nChannels);
               
            % Set current channel to the first one.
            obj.currentChannel = 1;
            if isempty(imgChannels); imgChannels = {'1'}; end
            set(obj.channel, 'String', imgChannels{obj.currentChannel})
            
            % Add image channels to loaded channels.
            obj.loadedChannels = imgChannels;
            obj.nLoadedChannels = numel(obj.loadedChannels);
            
            % Extract filename "base" (remove parts expression and number...)
            ptMatch = strfind(fileName{1}, obj.ptExpr);
            if ~isempty(ptMatch)
                [ptMatchBeg, ptMatchEnd] = regexp(fileName{1}, [obj.ptExpr '\d*']);
            
                % Check if there is a filename "connector"
                if any(strcmp(fileName{1}(ptMatchBeg-1), {'_', '-', ' '}))
                    ptMatchBeg = ptMatchBeg - 1;
                end
                
                % Build new filename
                fileName =  fileName(:, 1);
                fileName = cellfun(@(fnm) [fnm(1:ptMatchBeg-1), fnm(ptMatchEnd+1:end)], fileName, 'uni', 0);
                
            else 
                fileName = fileName(:, 1);
            end
            
            % Remove the file extension and assign filenames to object
            for i = 1:nChannels
                [~, obj.loadedFileName{i}, ~] = fileparts(fileName{i});
            end
            
            % (Re)set current frame to first frame
            obj.currentFrameNo = 1;
            
            % Set up frame indicators and frameslider
            if obj.nFrames < 11
                sliderStep = [1/(obj.nFrames-1), 1/(obj.nFrames-1)];
            else
                sliderStep = [1/(obj.nFrames-1), 10/(obj.nFrames-10)];
            end
            
            set(obj.textCurrentFrame, 'String', ['Current Frame: 1/' num2str(obj.nFrames)] )
            set(obj.textCurrentFileName, 'String',  obj.loadedFileName{obj.currentChannel})
            set(obj.inputJumptoFrame, 'String', '1')
            set(obj.frameslider, 'maximum', obj.nFrames, 'VisibleAmount', 0.1);
            obj.fsContainer.Visible = 'on';
%             set(obj.frameslider, 'Max', obj.nFrames, ...
%                                  'Value', obj.currentFrameNo, ...
%                                  'SliderStep', sliderStep, ...
%                                  'Visible', 'on');
            
            % Set limits of signal Plot
            set(obj.axSignalPlot, 'Xlim', [1, obj.nFrames])
                   
            obj.resetSignalPlot;
            
            % Reset some buttons
            obj.unToggleShowButtons([]);                
                             
            % Display image
            updateImageDisplay(obj);
            
            obj.btnShowSignal.Enable = 'on';
            
%             % Load rois
%             obj.loadRois(source);

        end
        
        
        function initializeSignalArray(obj, channels)
            % Make signalArray with number of channels.
            
            signalNames = {'roiMeanF', 'npilMediF', 'demixedMeanF', 'dff', ...
                'deconvolved', 'denoised', 'spikes'};
            
            obj.signalArray = struct;
            
            for i = 1:channels
                nRois = obj.roiCount{i};
                for j = 1:numel(signalNames)
                    obj.signalArray(i).(signalNames{j}) = nan(obj.nFrames, nRois, 'single');
                end
                obj.signalArray(i).spkThr = ones(1, nRois, 'single');
                obj.signalArray(i).spkSnr = ones(1, nRois, 'single');
                obj.signalArray(i).lamPr = ones(1, nRois, 'single');
            end

            for i = 1:numel(signalNames)
                obj.hlineSignal.(signalNames{i}) = gobjects(0);
            end
                        
        end
        
        
        function modifySignalArray(obj, listOfRois, action)
            
            ch = obj.currentChannel;
            fields = fieldnames(obj.signalArray);
            
            for fNo = 1:numel(fields)

                switch action
                    case 'reset'
                        if isequal(fields{fNo}, 'spikeThreshold')
                            continue
                        end
                        obj.signalArray(ch).(fields{fNo})(:, listOfRois) = nan;
                    case 'append'
                        nRois = numel(listOfRois);
                        obj.signalArray(ch).(fields{fNo})(:, end+1:end+nRois) = nan;
                        
                    case 'insert'
                        %Rearrange. omfg...
                        nRois = numel(listOfRois);
                        obj.signalArray(ch).(fields{fNo})(:, end+1:end+nRois) = nan;
                        for i = listOfRois
                            obj.signalArray(ch).(fields{fNo}) = cat(2, obj.signalArray(ch).(fields{fNo})(:, 1:i-1), obj.signalArray(ch).(fields{fNo})(:, i), obj.signalArray(ch).(fields{fNo})(:, i:end-1));
                        end
                        
                    case 'remove'
                        obj.signalArray(ch).(fields{fNo})(:, listOfRois) = [];
                end
            end 
            
        end

        
        function loadStackProjections(obj)
        % Load average and max stack projections into the GUI
            
        %todo...
        
            obj.imgMax = max(obj.imgTseries, [], 3);
        	obj.imgAvg = uint8(mean(obj.imgTseries, 3)); 
                        
        end

        
% % % % Methods for changing frames and updating images
        
        function updateImageDisplay(obj, imageToDisplay)
        % Updates the image in the image display
        
            frameNo = obj.currentFrameNo;
            
            if obj.nFrames > 1 
                set( obj.textCurrentFrame, 'String', ...
                      ['Current Frame: ' num2str(obj.currentFrameNo) '/' num2str(obj.nFrames)] )
            end
            
            if nargin < 2; imageToDisplay = 'Unspecified'; end

            showMovingAvg = get(obj.btnShowMovingAvg, 'Value');
            showMovingStd = get(obj.btnShowMovingStd, 'Value');
            showMovingMax = get(obj.btnShowMovingMax, 'Value');
            showAvg = get(obj.btnShowAvg, 'Value');
            showMax = get(obj.btnShowMax, 'Value');

            % Get framenumbers to run window on
            if showMovingAvg || showMovingMax || showMovingStd
                if frameNo < ceil(obj.binningSize/2)
                    binIdx = 1:obj.binningSize;
                elseif (obj.nFrames - frameNo)  < ceil(obj.binningSize/2)
                    binIdx = obj.nFrames-obj.binningSize+1:obj.nFrames;
                else
                    binIdx = frameNo - floor(obj.binningSize/2):frameNo + floor(obj.binningSize/2);
                end
                 
            end
            
            % Show one or multiple channels?
            switch obj.channelDisplayMode
                case 'single'
                    chNo = obj.currentChannel;
                case 'multi'
                    chNo = 1:obj.nLoadedChannels;
                case 'correlation'
                    chNo = obj.currentChannel;
            end
             
            switch imageToDisplay
                case 'Unspecified'
                    % Result of integrating new things...
                    if strcmp(obj.channelDisplayMode, 'correlation') 
                        if strcmp(obj.btnShowSingleChannel.String, 'Show All Channels')
                            obj.changeChannelDisplayMode(struct('String', 'Show Single Channel'), [])
                        else
                            obj.changeChannelDisplayMode(struct('String', 'Show All Channels'), [])
                        end
                    end
                    
                    % Load images for specified channels 
                    caframe = cell(numel(chNo), 1);
                    for ch = chNo
                        if showMovingAvg
                            group = obj.imgTseries{ch}(:, :, binIdx);
                            caframe{ch} = uint8(mean(group, 3));
                        elseif showMovingMax
                            group = obj.imgTseriesMedfilt{ch}(:, :, binIdx);
                            caframe{ch} = max(group, [], 3);
                        elseif showMovingStd
                            group = double(obj.imgTseriesMedfilt{ch}(:, :, binIdx));
                            %group = double(obj.imgTseries(:, :, binIdx)); % very noisy
                            caframestd = std(group, [], 3);
                            caframe{ch} = uint8(caframestd/max(caframestd(:))*255);
                        elseif showAvg
                            caframe{ch} = obj.imgAvg{ch};
                        elseif showMax
                            caframe{ch} = obj.imgMax{ch};
                        else
                            caframe{ch} = obj.imgTseries{ch}(:, :, frameNo);
                        end

                        if strcmp(obj.channelDisplayMode, 'multi')
                            min_brightness = obj.brightnessSlider.Low;
                            max_brightness = obj.brightnessSlider.High;

                            if min_brightness ~= 0 || max_brightness ~= 255
                                min_brightness = min_brightness/255;
                                max_brightness = max_brightness/255;
                                caframe{ch} = imadjust(caframe{ch}, [min_brightness, max_brightness]);
                            end
                        end

                    end
                    
                case 'Correlation Image'
                    caframe{1} = obj.imgCn{obj.currentChannel};
                    obj.changeChannelDisplayMode(struct('String', 'Show Correlation Image'), []);
            end

            
            caframe = cat(3, caframe{:});
            if strcmp(obj.channelDisplayMode, 'multi')
                caframe = obj.setChColors(caframe);
            end
            
            if isempty(obj.himage) % First time initialization. Create image object
               obj.himage = imshow(caframe, [0, 255], 'Parent', obj.axImageDisplay, 'InitialMagnification', 'fit');
               set(obj.himage, 'ButtonDownFcn', @obj.mousePress)
            else
               set(obj.himage, 'cdata', caframe);
            end

            obj.updateFrameMarker();
            
        end
        
        
        function changeFrame(obj, source, event, action)
        % Callback from different sources to change the current frame.

            switch action
                case 'mousescroll'
                    i = event.VerticalScrollCount*obj.scrollFactor*obj.playbackspeed;
                    % My touchpad sometimes gives a scroll event when I
                    % move the cursor and click. This is very annoying when
                    % showing avg or max image.
                    if contains(obj.mouseMode, {'Draw', 'CircleSelect', 'Autodetect'})
                        if obj.btnShowMax.Value || obj.btnShowAvg.Value
                            i=0;
                        end
                    end
                case {'slider', 'buttonclick'}
                    newValue = source.Value;
                    i = newValue -  obj.currentFrameNo;
                    i = round(i);
                    if i == 0; return; end
                case {'jumptoframe'}
                    i = str2double(source.String) -  obj.currentFrameNo;
                    i = round(i);
                case 'playvideo'
                    i = source.Value;
                case 'prev'
                    i = -1*obj.playbackspeed;
                case 'next'
                    i = 1*obj.playbackspeed;
                otherwise
                    i = 0;   
            end

            % Check that new value is within range and update current frame/slider info
            if (obj.currentFrameNo + i) >= 1  && (obj.currentFrameNo + i) <= obj.nFrames
                obj.currentFrameNo = round(obj.currentFrameNo + i);
                set(obj.frameslider, 'Value', obj.currentFrameNo );
                set(obj.inputJumptoFrame, 'String', num2str(obj.currentFrameNo))
                if strcmp(obj.fsContainer.Visible, 'off')
                    obj.fsContainer.Visible = 'on';
                end
                
                if obj.btnShowAvg.Value || obj.btnShowMax.Value 
                    if ~contains(obj.mouseMode,  {'Draw', 'CircleSelect', 'Autodetect'})
                        obj.unToggleShowButtons([]);
                    end
                end
                
                obj.displaySelectedRegion();
                
            else
                i = 0;
            end
            
            % Pan along axes in signalPlot if zoom is on
            if ~isequal(obj.axSignalPlot.XLim, [1, obj.nFrames])
                if ~isequal(action, 'jumptoframe')
                    obj.setXLimitsPan(obj.axSignalPlot.XLim + i)
                end
            end

            if ~isempty(obj.imgTseries) && i~=0
                obj.updateImageDisplay();
            end
        end
        
        
        function updateFrameMarker(obj, flag)
        % Update line indicating current frame in plot.
        
            if nargin < 2; flag = 'update_x'; end
        
            frameNo = obj.currentFrameNo;
            if isempty(obj.hlineCurrentFrame) || ~isgraphics(obj.hlineCurrentFrame) 
                obj.hlineCurrentFrame = plot(obj.axSignalPlot, [1, 1], get(obj.axSignalPlot, 'ylim'), '-r', 'HitTest', 'off');
                if ~obj.btnShowSignal.Value
                    obj.hlineCurrentFrame.Visible = 'off';
                end
            elseif isequal(flag, 'update_y')
                set(obj.hlineCurrentFrame, 'YData', obj.axSignalPlot.YLim)
            else
                set(obj.hlineCurrentFrame, 'XData', [frameNo, frameNo]);
            end
        end
        
        
% % % % Button callbacks - RoI creation and removal
        
        function obj = buttonCallback_DrawRois(obj, source, ~)
        % Button Callback. Start or finish marking of a roi. 
            
            if source.Value
                obj.setMouseMode('Draw');
                set(obj.btnAutoDetect, 'Value', 0)
                
            else
                %obj.cancelRoi();
                obj.setMouseMode('Select');
                obj.unFocusButton(obj.btnDrawRoi)
            end  
                      
        end
        
        function buttonCallback_CircleTool(obj, source, ~)
            
            if source.Value
                obj.setMouseMode('CircleSelect');
            else
                obj.setMouseMode('Select');
                obj.unFocusButton(obj.btnCircleTool)
            end 
        end
        
        function obj = buttonCallback_AutodetectRois(obj, source, ~)
        % Button Callback. Start or finish autodetection of roi by clicking on it. 
            
            if source.Value
                obj.setMouseMode('Autodetect');
            else
                obj.setMouseMode('Select');
                obj.unFocusButton(obj.btnAutoDetect)
            end  
        end
            
        
        function obj = buttonCallback_EditRois(obj, source, ~)
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
        

        function obj = cancelRoi(obj)
        % Cancel a "drawn" roi object
        
            % Remove Temporary Roi Object
            obj = removeTmpRoi(obj);
            ch = obj.currentChannel;
            
            % Replot Roi if edit mode is active ( need to check the button
            % since sometimes roi can be canceled from zoom mode )
            if isequal(obj.mouseMode, 'EditSelect') 
                return
            elseif obj.btnEditRoi.Value || strcmp(obj.mouseMode, 'EditDraw')
                updateRoiPlot(obj, obj.selectedRois);
            end
            
            if strcmp(obj.mouseMode, 'EditDraw')
                obj.setMouseMode('EditSelect');
            end
        end
        
        
        function growRois(obj, ~, ~)
            
            ch = obj.currentChannel;
            obj.addToActionLog(ch, obj.selectedRois, 'reshape')
            
            for i = obj.selectedRois
                obj.roiArray{ch}(i).grow(1);
                updateRoiPlot(obj, i);
            end
            
        end
        
        
        function shrinkRois(obj, ~, ~)
            ch = obj.currentChannel;
            obj.addToActionLog(ch, obj.selectedRois, 'reshape')

            for i = obj.selectedRois
                obj.roiArray{ch}(i).shrink(1);
                updateRoiPlot(obj, i);
            end
            
        end
        
        
% % % % Methods for adding and removing rois from roimanager and roi array

        function obj = finishRoi(obj)
        % Finish a "drawn" roi object
        
        ch = obj.currentChannel;

        switch obj.mouseMode
            case 'Draw'
                newRoi = makeRoi(obj);
                if ~isempty(newRoi)
                    obj.addRois(newRoi);
                    obj.selectRois(obj.roiCount{obj.currentChannel}, 'normal')
                end
                obj = removeTmpRoi(obj);
                
            case 'EditDraw'
                % Get new polygon coordinates
                x = obj.tmpRoiPosX;
                y = obj.tmpRoiPosY;
                
                % Remove roi if less than 3 impoints are remaining
                if numel(x) < 3 || numel(y) < 3
                    obj.addToActionLog(ch, obj.selectedRois, 'remove')
                    obj.removeRois(obj.selectedRois);
                else % Reshape and replot
                    obj.addToActionLog(ch, obj.selectedRois, 'reshape')
                    obj.roiArray{ch}(obj.selectedRois).reshape('Polygon', [x', y']);
                    obj.modifySignalArray(obj.selectedRois, 'reset')
                    updateRoiPlot(obj, obj.selectedRois);
                end
                
                % Remove the temporary roi polygon 
                obj = removeTmpRoi(obj);
                obj.setMouseMode('EditSelect');
        end
        
        end
        
        function splitRois(obj, ~, ~)
            
            ch = obj.currentChannel;
            
            for i = obj.selectedRois
                
                roiBabies = obj.roiArray{ch}(i).split(4);
                
                obj.addRois(roiBabies);
                
            end
            
            obj.removeRois;

        end
        
        function mergeRois(obj, ~, ~)
            
            ch = obj.currentChannel;
            
            roiMasks = {obj.roiArray{ch}(obj.selectedRois).mask};
            roiMasks = cat(3, roiMasks{:});
            
            mergedMask = sum(roiMasks,3) ~= 0;
            
            mergedRoi = RoI('Mask', mergedMask, size(mergedMask));
            mergedRoi.structure = obj.roiArray{ch}(obj.selectedRois(end)).structure;
            mergedRoi.group = obj.roiArray{ch}(obj.selectedRois(end)).group;
            mergedRoi.celltype = obj.roiArray{ch}(obj.selectedRois(end)).celltype;
            
            obj.removeRois([], []);
            obj.addRois(mergedRoi);
            

        end
        
        
        function connectRois(obj, ~, ~)
            ch = obj.currentChannel;
            
            roiIndices = obj.selectedRois;
            
            
            for i = obj.selectedRois
                
                tmpIndices = setdiff(roiIndices, i);
                tmpRois = obj.roiArray{ch}(tmpIndices);
                roiIds = arrayfun(@(roi) roi.uid, tmpRois, 'uni', 0);
                obj.roiArray{ch}(i).connect(roiIds');
            end
            
        end
        

        function obj = addRois(obj, newRois, idx, mode)
        % addRois Plot a RoI in the roimanager and add to the list of rois.
        
            ch = obj.currentChannel;
            nRois = numel(newRois);

            if nargin < 3
                idx = obj.roiCount{ch} + (1:nRois);
            end
            
            if nargin < 4; mode = 'append'; end
            
            % Add rois, either by appending or by inserting into array.
            switch mode
                case 'append'
                    obj.roiArray{ch} = horzcat(obj.roiArray{ch}, newRois);
                case 'insert'
                    obj.roiArray{ch} = rmUtil.insertIntoArray(obj.roiArray{ch}, newRois, idx);
            end
            
            obj.roiCount{ch} = obj.roiCount{ch} + nRois; % This should happen before plot, update listbox and modify signal array. 

            obj.plotRoi(newRois, idx, mode);
            
            switch mode
                case 'insert'
                    obj.updateListBox(); % Need to update all rois.
                case 'append'
                    obj.updateListBox(idx);
            end
            
            obj.modifySignalArray(idx, mode)
            obj.addToActionLog(ch, idx, 'add')
            
            if ~isempty(obj.cnmfData)
                obj.updateCnmfData(idx, mode)
            end
                
        end
        

        function obj = removeRois(obj, ~, ~)
        % Button callback. Remove selected rois from gui
        
            ch = obj.currentChannel;

            obj.addToActionLog(ch, obj.selectedRois, 'remove')
            
            obj.roiListBox.Value = [];
        
            % Loop through selected rois, remove roi objects and associated
            % plots. Also clear the roi from the listbox
            obj.selectedRois = sort(obj.selectedRois, 'descend');
            for i = obj.selectedRois
                obj.removeNeuropilPatch(i)
                obj.roiArray{ch}(i) = [];
                obj.roiCount{ch} = obj.roiCount{ch} - 1;
                delete(obj.RoiPlotHandles{ch}(i))
                delete(obj.RoiTextHandles{ch}(i))
                obj.RoiPlotHandles{ch}(i) = [];
                obj.RoiTextHandles{ch}(i) = [];
                obj.roiListBox.String(i) = [];
            end
            
            obj.modifySignalArray(obj.selectedRois, 'remove')
            
            obj.selectedRois = [];
            
            obj.updateListBox();
            
            if ~isempty(obj.cnmfData)
                obj.updateCnmfData(obj.selectedRois, 'remove')
            end
            
            
        end

        
        function obj = clearRois(obj, ~, ~)
        % Button callback. Remove all rois from gui and listbox, and remove
        % all plots and labels.

        obj.roiListBox.Value = [];

        for ch = 1:obj.nLoadedChannels
            obj.roiArray{ch} = RoI.empty;
            if ~isempty(obj.RoiPlotHandles{ch})
                for i = 1:length(obj.RoiPlotHandles{ch})
                    delete(obj.RoiPlotHandles{ch}(i))
                end
            end
            if ~isempty(obj.RoiTextHandles{ch})
                for i = 1:length(obj.RoiTextHandles{ch})
                    delete(obj.RoiTextHandles{ch}(i))
                end
            end

            obj.RoiPlotHandles{ch} = [];
            obj.RoiTextHandles{ch} = [];
            obj.roiCount{ch} = 0;

        end

        obj.roiListBox.String = {};
        obj.selectedRois = [];

        end
        
        
% % % % Methods for drawing rois using polygon draw tool

        function obj = drawTmpRoi(obj)
        % Draw the lines between the impoints of tmp roi. 
        
            % Get list of vertex points
            x = obj.tmpRoiPosX;
            y = obj.tmpRoiPosY;
            
            if length(x) < 2 || length(y) < 2
                if ~isempty(obj.hlineTmpRoi)
                   set(obj.hlineTmpRoi,'XData',nan,'YData',nan);
                end
                return
            end
            
            % Close the circle
            x(end+1) = x(1);
            y(end+1) = y(1);
            
            % There should only be one instance of the tmp roi plot. 
            if isempty(obj.hlineTmpRoi) || ~isvalid(obj.hlineTmpRoi)
                axes(obj.axImageDisplay);
                hold on
                obj.hlineTmpRoi = plot(0,0);
                obj.hlineTmpRoi.HitTest = 'off';
                obj.hlineTmpRoi.PickableParts = 'none';
                hold off
            end
            set(obj.hlineTmpRoi,'XData',x,'YData',y);
        end
        
        
        function obj = removeTmpRoi(obj)
        %REMOVETMPROI clear the obj.RoiTmpPos or obj.tmpImpoints.

            obj.tmpRoiPosX = [];
            obj.tmpRoiPosY = [];
            for i = 1:numel(obj.tmpImpoints)
                delete(obj.tmpImpoints{i});
            end
            
            delete(obj.hlineTmpRoi)
            obj.hlineTmpRoi = [];

            obj.tmpImpoints = cell(0);
            obj.selectedImpoint = [];
            
        end

        
        function obj = addImpoint(obj, x, y)
        % addImpoint adds a new tmp roi vertex to the axes.  
        % After the impoint is created it is also configured.
        %   addImpoint<(obj, ax, x, y)
        %   x, y       - Coordinates in pixels. 
        %
        %   See also configImpoint, impoint

            % Find the index of this edge.
            i = numel(obj.tmpImpoints) + 1;

            % Add x and y to lists of coordinates
            obj.tmpRoiPosX(i) = x;
            obj.tmpRoiPosY(i) = y;
            
            % The vertices are impoints that can be moved around. 
            tmpRoiVertex = impoint(obj.axImageDisplay, x, y);
            obj.configImpoint(tmpRoiVertex, i);
            obj.tmpImpoints{end+1} = tmpRoiVertex;
            
            % Select the last added impoint
            obj.selectImpoint(i);
            
        end
        
        
        function obj = selectImpoint(obj, i)
        % select/highlight roivertex at number i in list of impoints.
            if i == 0
                return
            end
            
            if ~isequal(i, obj.selectedImpoint)
                obj.tmpImpoints{i}.setColor('yellow')
                if ~isempty(obj.selectedImpoint)
                    obj.tmpImpoints{obj.selectedImpoint}.setColor([0.2824, 0.2824, 0.9725])
                end
                obj.selectedImpoint = i;
            end

        end
        
        
        function obj = removeImpoint(obj)
        % removeImpoint removes a new tmp roi vertex from the axes.      

            i = obj.selectedImpoint;

            % Delete the impoint and remove it from the cell array
            delete(obj.tmpImpoints{i})
            obj.tmpImpoints(i) = [];

            % Remove x and y from lists of coordinates
            obj.tmpRoiPosX(i) = [];
            obj.tmpRoiPosY(i) = [];
            
            % Redraw lines between the vertices
            obj.drawTmpRoi();
            
            % Update position constraint function
            for n = 1:numel(obj.tmpImpoints)
            	obj.tmpImpoints{n}.setPositionConstraintFcn(@(pos)lockImpointInZoomMode(obj, pos, n))
            end
            
            
            obj.selectedImpoint = [];
            
            % Select new vertex (previous point)
            if i ~= 1
                i = i-1;
            else
                i = numel(obj.tmpImpoints);
            end
            
            obj.selectImpoint(i);
        end
        
        
        function idx = isCursorOnImpoint(obj, x, y)
        %isCursorOnImpoint Check if point (x, y) is close to tmp roi vertex
        %   idx = isCursorOnImpoint(obj, x, y) returns idx of tmproi vertex 
        %   if any tmproi vertex is close to point (x, y). If not idx is 0.
        
            % Get xlim of image and create a scaled vicinity measure for
            % impoints
            xlim = get(obj.axImageDisplay, 'XLim');
            impoint_extent = diff(xlim)/100;
            
            % Check is x coordinate is in vicinity of tmpRoi vertices
            xWithinVertex = abs(obj.tmpRoiPosX - x) < impoint_extent;
            if any(xWithinVertex)
                idx1 = find(xWithinVertex);
                yWithinVertex = abs(obj.tmpRoiPosY(idx1) - y) < impoint_extent;
                % Check is y coordinate is in vicinity of tmpRoi vertex
                if any(yWithinVertex)
                    idx = idx1(yWithinVertex);
                else
                    idx = 0;
                end
            else
                idx = 0;
            end
        end
        
        
        function configImpoint(obj, impointObj, i)
        %CONFIGIMPOINT configures an impoint. 
        % Sets the new position callback of impoints. They are responsible for
        % updating the plot when a vertex is moved. 
        %   configImpoint(obj, ax, impointObj, i)
        %   impointObj    - impoint to configure. 
        %   i             - Sent to the move callback. Index of the impoint. 
        %
        % See also impoint, moveTmpRoiVertex
            impointObj.addNewPositionCallback(@(pos)callbackRoiPosChanged(obj, pos));
            impointObj.setPositionConstraintFcn(@(pos)lockImpointInZoomMode(obj, pos, i))
            impointObj.Deletable = false;
        end
        
        
        function constrained_pos = lockImpointInZoomMode(obj, new_pos, i)
        % Callback function when dragging impoint. Locks impoint in place
        % during zoom mode.
            switch obj.mouseMode
                case {'Zoom In', 'Zoom Out'}
                	x = obj.tmpRoiPosX(i);
                    y = obj.tmpRoiPosY(i);
                    constrained_pos = [x, y];
                otherwise
                    constrained_pos = new_pos;
            end
                            
        end
        
        
        function obj = callbackRoiPosChanged(obj, pos)
        % callback function of impoint. 
        % This function is called whenever a impoint is moved (Tmp RoI vertex). 
        %
        % See also configImpoint, impoint, moveTmpRoiVertex

            points = cell2mat(cellfun(@(imp) imp.getPosition', obj.tmpImpoints, 'uni', 0));
            obj.tmpRoiPosX = points(1, :);
            obj.tmpRoiPosY = points(2, :);

            id1 = find(obj.tmpRoiPosX == pos(1));
            id2 = find(obj.tmpRoiPosY == pos(2));
            
            if id1 == id2
                % If two points are on top of each other, select one
                obj.selectImpoint(id1(1));
            end

            obj.drawTmpRoi();
            
        end
           
        
% % % % Methods for creating new rois

        function mask = autodetect(obj, x, y)
        %autodetect autodetects roi by automatic thresholding.   
            
            % Set some parameters
            d1 = obj.roiInnerDiameter; 
            d2 = obj.roiOuterDiameter; 
            minRoiSize = round(pi*(d2/2)^2/2);
            x = round(x);
            y = round(y);
            
            % retrieve box 2xroi size around x and y
            
            roiMask = zeros(size(obj.himage.CData(:, :,1)));
            
            % TODO make it work close to edges
            [nRows, nCols] = size(obj.himage.CData);
            if  y-d2 < 1 || x-d2 < 1 || y+d2 > nRows || x+d2 > nCols
                error('Sorry, autodetection does not work close to edges in the image')
            end
            
            im = obj.himage.CData(y-d2:y+d2, x-d2:x+d2, 1);
            %imChunk = obj.imgTseries(y-d2:y+d2, x-d2:x+d2, :);
            
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
                mask = roiMask;
            else
                mask = [];
            end
            
        end
        
        
        function improveRoiEstimate(obj, ~, ~)
            
            newRois = RoI.empty;
            
            for i = obj.selectedRois
            
                roiIdx = i;
            
                ch = obj.currentChannel;

                % Find roi and the dff of the roi
                roi = obj.roiArray{ch}(roiIdx);
                dff = obj.signalArray(ch).dff(:, roiIdx);

                if all(isnan(dff)) || isempty(dff)
                    dff = obj.extractSignal(roiIdx, 'dff');
                end

                f0 = prctile(dff, 20);
                fmax = max(dff);
                stddff = std(dff);

%                 frames = dff > (f0+stddff);
                if isempty(obj.selectedFrames) || sum(obj.selectedFrames) == 0
                    frames = dff > ((fmax-f0)/2);
                else
                    frames = logical(obj.selectedFrames);
                end
                
                [start, stop] = rmUtil.findTransitions(frames);
                
                f0Idx = find(dff>f0);
                
                for j = 1:numel(start)
                    [~, start(j)] = min(abs((start(j)-f0Idx)));
                end
                
%                 frames = imerode(frames, ones(20, 1));
                frames = imdilate(frames, ones(5, 1));
                [start, stop] = rmUtil.findTransitions(frames);
                nEvents = numel(start);

                aa=sort(cell2mat(arrayfun(@(i) start(i):stop(i), 1:numel(start), 'uni', 0)));
                frames(aa)=true;
                
                [roimask, surroundmask] = signalExtraction.standard.getMasks(obj.roiArray{ch}, roiIdx, 4);

                roimask = imdilate(roimask, ones(3,3)); % Remove the gap between masks which are added in the function above. Here only pixels part of the expanded mask are considered in the end.
                expandedroimask = roimask | surroundmask;

                [y, x] = find(expandedroimask);

                minX = min(x); maxX = max(x);
                minY = min(y); maxY = max(y);

                croppedMask = expandedroimask(minY:maxY, minX:maxX);
                pixelChunk = obj.imgTseries{ch}(minY:maxY, minX:maxX, :);

                f0 = prctile(pixelChunk, 20, 3);
                dffIm = (pixelChunk - f0) ./ f0;

                pixelChunk = dffIm(:, :, frames);
                pixelChunk = filterImArray(pixelChunk, 1, 'median');
                dff = dff(frames); 

                mask = repmat(croppedMask, 1, 1, sum(frames));
                pixPerFrame = sum(croppedMask(:));
                pixelSignals = reshape(pixelChunk(mask), pixPerFrame, sum(frames))'; % nframes x npixels

                pixelSignals = horzcat(dff, pixelSignals);
                
                RHO = corr(single(pixelSignals));
                RHO = RHO(2:end, 1);
                
                idx = find(croppedMask);
                
                corrim = nan(size(croppedMask));
                corrim(idx) = RHO;

                withinVal = nanmean(corrim(roimask(minY:maxY, minX:maxX)));
                outsideVal = nanmean(corrim(surroundmask(minY:maxY, minX:maxX)));
                threshold = mean([withinVal,withinVal,outsideVal]);
                
                pixId = unique(x);

                newMask = false(size(croppedMask));
                whichPixels = (RHO>threshold);
                newMask(idx(whichPixels)) = true;
                newMask = bwareaopen(newMask, 8);
                newMask = imfill(newMask,'holes');
                
                if sum(newMask(:)) < 10
                    return
                end

                fullmask = false(size(obj.roiArray{ch}(roiIdx).mask));
                fullmask(minY:maxY, minX:maxX) = newMask;

                newRoi = RoI('Mask', fullmask, size(fullmask));
                newRoi = obj.editRoiProperties(newRoi);
                if nEvents < 2
                    newRoi.grow(1);
                end

                newRois(end+1) = newRoi;
                
            end
            
            obj.removeRois([], []);
            obj.addRois(newRois);
            
        end
            

        
        function newRoi = makeRoi(obj)
        %MAKEROI create a new RoI and add it to the gui. 
        %   roiNew = makeRoi(obj)
        %
        % See also RoI. 
        
            newRoi = [];
            x = obj.tmpRoiPosX;
            y = obj.tmpRoiPosY;
            if length(x) < 3 || length(y) < 3
                return
            end
            
            % Create a RoI object
            newRoi = RoI('Polygon', [x; y], [obj.imHeight, obj.imWidth]);
            newRoi = obj.editRoiProperties(newRoi);
            
        end
        
        
        function roi = editRoiProperties(obj, roiIn, source)
        %editRoiProperties Edit roi properties from variables in GUI
        %   roi = obj.editRoiProperties(roi) returns a roi with given
        %   properties
        %   
        %   obj.editRoiProperties(roiIdx) edit properties of roi at index i 
            
            % Source is not required. E.g. when making a new roi.
            if nargin < 3
                source = [];
            end

            ch = obj.currentChannel;
            
            % If input is a number, extract roi with that number...
            if isa(roiIn, 'double')
                roi = obj.roiArray{ch}(roiIn);
            elseif isa(roiIn, 'RoI')
                roi = roiIn;
            else
                error('Wrong input to editRoiProperties')
            end
            
            % Stupid way of getting everything done in one function...
            if isempty(source)
                groupName = obj.popupRoiclass.String{obj.popupRoiclass.Value};
                corticalLayer = obj.popupLayer.String{obj.popupLayer.Value};
            elseif isequal(source, obj.popupRoiclass)
                groupName = source.String{source.Value};
                corticalLayer = roi.layer;
            elseif isequal(source, obj.popupLayer)
                groupName = roi.group;
                corticalLayer = source.String{source.Value};
            end
            
            roi.group = groupName;
            roi.layer = corticalLayer;
            switch groupName
                case 'Neuronal Soma'
                    roi.celltype = 'Neuron';
                    roi.structure = 'Soma';
                case {'Neuronal Dendrite', 'Dendrite'}
                    roi.celltype = 'Neuron';
                    roi.structure = 'Dendrite';
                case {'Neuronal Axon', 'Axon'}
                    roi.celltype = 'Neuron';
                    roi.structure = 'Axon';
                case {'Neuropill', 'NeuroPil'}
                    roi.celltype = 'Neuron';
                    roi.structure = 'Neuropil';
                    roi.group = 'Neuropil';
                case 'Astrocyte Soma'
                    roi.celltype = 'Astrocyte';
                    roi.structure = 'Soma';     
                case {'Astrocyte Endfoot', 'Endfoot'}
                    roi.celltype = 'Astrocyte';
                    roi.structure = 'Endfoot';
                case 'Astrocyte Process'
                    roi.celltype = 'Astrocyte';
                    roi.structure = 'Process';
                case 'Gliopill'
                    roi.celltype = 'Astrocyte';
                    roi.structure = 'Gliopil';
                case 'Artery'
                    roi.celltype = [];
                    roi.structure = 'Artery';
                case 'Vein'
                    roi.celltype = [];
                    roi.structure = 'Vein';                
                case 'Capillary'
                    roi.celltype = [];
                    roi.structure = 'Capillary';
            end
            
            if ~isa(roiIn, 'RoI')
                %obj.roiArray{ch}(roiIn) = roi; % not necessary as long as
                %RoI is a handle
                clearvars roi
            end
            
        end
        
        
        function obj = moveRoi(obj, shift)
        % Update RoI positions based on shift.
        
            ch = obj.currentChannel;
            
            obj.addToActionLog(ch, obj.selectedRois, 'reshape')
            
            % Get active roi
            for i = obj.selectedRois
                obj.roiArray{ch}(i).move(shift);
                removeNeuropilPatch(obj, i)
                addNeuropilPatch(obj, i)
            end
            
            obj.modifySignalArray(obj.selectedRois, 'reset')
            obj.updateSignalPlot(obj.selectedRois, 'overwrite')
            
        end

        
% % % % Methods for organizing listbox
        
        function obj = updateListBox(obj, roiIndices)
        % UPDATELISTBOX Update elements in the RoI listbox 
        %
        %   obj.updateListbox() updates the listbox based on the current
        %   roi array of the selected channel
        %
        %   obj.updateListbox(ROIINDICES) updates only the elements of 
        %   listbox which are provided in ROIINDICES
        %
        %   Listbox entries are based on the roi group and the number the 
        %   roi has in the roiArray. Selected rois are set as selected in
        %   the listbox.
        
            ch = obj.currentChannel;

            if nargin < 2 || isempty(roiIndices)
                roiIndices = 1:obj.roiCount{ch};
                obj.roiListBox.String = cell(numel(roiIndices), 1);
            end

            for i = roiIndices
                roi = obj.roiArray{ch}(i);
                tag = [roi.tag, num2str(i, '%03d')];
                roi.num = i; % Might remove this in future
                set(obj.RoiTextHandles{ch}(i), 'String', tag);
                if ~isempty(roi.layer) && ~strcmp(roi.layer, 'n/a') 
                    tag = strcat(tag, strrep(roi.layer, 'Layer ', '_L'));
                end

                obj.roiListBox.String{i} = tag;

            end

            obj.roiListBox.Value = obj.selectedRois;

        end

        
        function obj = resetListbox(obj)
            obj.roiListBox.String = cell(0);
            obj.roiListBox.Value = 0;
        end

        
        function updateRoiInfoPanel(obj)
            
            ch = obj.currentChannel;
            
            if ~isempty(obj.selectedRois)
                
                % Only show last selection
                displayedRoi = obj.selectedRois(end);
                
                % Set title of roi information box
                obj.panelRoiInfo.Title = sprintf('Roi Info (#%03d)', displayedRoi);
                if contains('Overfilled', obj.roiArray{ch}(displayedRoi).tags)
                    obj.boolOverfilled.Value = true;
                else
                    obj.boolOverfilled.Value = false;
                end
                
                % Show connected rois.
                connectedRoiIds = obj.roiArray{ch}(displayedRoi).connectedrois;
                if ~isempty(connectedRoiIds)
                    
                    roiUids = arrayfun(@(roi) roi.uid, obj.roiArray{ch}, 'uni', 0);
                    
                    connRoiTag={};
                    for j = 1:numel(connectedRoiIds)
                        % Find roi tag of roi:
                        connRoiId = find(contains(roiUids, connectedRoiIds{j}));
                        connRoiTag = cat(1, connRoiTag, obj.roiListBox.String{connRoiId});
                    end
                    
                    obj.connectedRoiInfo.String = strjoin(connRoiTag, ', ');
                end
                
                
                
                
                
            else
                obj.panelRoiInfo.Title = sprintf('Roi Info');
                obj.boolOverfilled.Value = false;
                obj.connectedRoiInfo.String = '';
            end
            
            
        end
        
        
% % % % Methods for selecting and deselecting rois

        function selectRois(obj, roiIndices, selectionType)
        % Takes care of selection of roi. Show roi as white in image,
        % update signal plot if it is open and change selection in listbox.
            
            ch = obj.currentChannel;
            
            if isnan(roiIndices)
                wasInRoi = false;
            else
                wasInRoi = true;
            end

            
            switch selectionType
                
                case 'normal'
                    
                    % Reset selection of all unselected rois
                    deselectedRois = setdiff(obj.selectedRois, roiIndices);
                    if ~isempty(deselectedRois)
                        obj.deselectRois(deselectedRois)
                    end
                    
                    % Make roi white if it was newly selected
                    if wasInRoi && ~any(obj.selectedRois == roiIndices)
                            addNeuropilPatch(obj, roiIndices)
                            obj.RoiPlotHandles{ch}(roiIndices).Color = 'White';
                            obj.RoiTextHandles{ch}(roiIndices).Color = 'White';
                    end

                    % Plot signal of Roi if signal plot is open
                    if obj.btnShowSignal.Value
                        if wasInRoi
                            obj.updateSignalPlot(roiIndices, 'overwrite');
                        else
                            obj.resetSignalPlot()
                        end
                    end

                    % Update selected rois array and listbox 
                    if isnan(roiIndices); roiIndices = []; end
                    obj.selectedRois = roiIndices;
                    obj.roiListBox.Value = roiIndices;

                case 'extend'
                    % Add roi to list of selected rois
                    if wasInRoi %&& ~any(obj.selectedRois == roiIndices)
                        counter = 1;
                        for i = roiIndices

                            if any(obj.selectedRois == i)
                                continue
                            end
                            
                            addNeuropilPatch(obj, i)
                            
                            obj.RoiPlotHandles{ch}(i).Color = 'White';
                            obj.RoiTextHandles{ch}(i).Color = 'White';
                            
                            if obj.btnShowSignal.Value && counter < 8
                                obj.updateSignalPlot(i, 'append');
                                counter = counter+1;
                            end

                            obj.selectedRois = horzcat(obj.selectedRois, i);
                            obj.roiListBox.Value = horzcat(obj.roiListBox.Value, i);
                        end
                    end
                    
                case 'listbox'
                    if wasInRoi %&& ~any(obj.selectedRois == roiIndices)
                        for i = roiIndices

                            if obj.btnShowSignal.Value
                                obj.updateSignalPlot(i, 'append');
                            end
                            
                            if any(obj.selectedRois == i)
                                continue
                            end
                            
                            obj.RoiPlotHandles{ch}(i).Color = 'White';
                            obj.RoiTextHandles{ch}(i).Color = 'White';

                            obj.selectedRois = horzcat(obj.selectedRois, i);
                            obj.roiListBox.Value = horzcat(obj.roiListBox.Value, i);
                        end
                    end
                    
            end
            
            obj.updateRoiInfoPanel()

            if wasInRoi
                obj.zoomOnRoi(obj.selectedRois(end))
            end
    
        end
        
        
        function deselectRois(obj, roiIndices)
        % Deselect all selected rois. Remove lines, reset color of roi in
        % image and unselect from listbox.
            
            ch = obj.currentChannel;

            for i = roiIndices
                color = obj.getRoiColor(obj.roiArray{ch}(i));
                obj.RoiPlotHandles{ch}(i).LineWidth = 0.5;
                obj.RoiPlotHandles{ch}(i).Color = color;
                obj.RoiTextHandles{ch}(i).Color = color;
                obj.removeNeuropilPatch(i)
            end
            
            toRemove = ismember(obj.selectedRois, roiIndices);
            if ~isempty(toRemove)
                obj.selectedRois(toRemove) = [];
                obj.roiListBox.Value = obj.selectedRois;
            end
            
            if obj.btnShowSignal.Value
                obj.resetSignalPlot()
            end

%             obj.editRoiLabel.String = '';
            
        end
        
        
        function addNeuropilPatch(obj, i)
        % Patch surrounding neuropil
        
        ch = obj.currentChannel;
        
            if obj.settings.showNpMask
                patchtag = sprintf('NpMask%03d', i);
                patches = findobj(obj.axImageDisplay, 'Tag', patchtag);
                if ~isempty(patches)
                    return
                end
                  
                % Find neuropil mask
                switch obj.signalExtractionSettings.neuropilExtractionMethod.Selection
                    case 'Standard'
                        imageMask = logical(mean(obj.imgTseries{ch}(:,:,1:10), 3));
                        [~, npMask] = signalExtraction.standard.getMasks(obj.roiArray{ch}, i, 4, imageMask);
                    case 'Fissa'
                        npMask = signalExtraction.fissa.getMasks(obj.roiArray{ch}(i).mask);
                    otherwise
                        return
                end
                   
                % Use patch roi function to patch the neuropil mask(s)
                for j = 1:size(npMask, 3)
                    patchRoi(obj, npMask(:, :, j), patchtag);
                end
            end
        end
        
        
        function removeNeuropilPatch(obj, i)
            if obj.settings.showNpMask
                if isequal(i, 'all')
                    patchtag = sprintf('NpMask');
                else
                    patchtag = sprintf('NpMask%03d', i);
                end
                patches = findobj(obj.axImageDisplay, '-regexp', 'Tag', patchtag);
                if ~isempty(patches)
                    delete(patches)
                end
            end
        end
        
        
        function multiSelectRois(obj)
            xData = get(obj.zoomRectPlotHandle, 'XData');
            yData = get(obj.zoomRectPlotHandle, 'YData');
            
            selectionLimitsX = round([min(xData), max(xData)]);
            selectionLimitsY = round([min(yData), max(yData)]);
            
            ch = obj.currentChannel;
            switch get(obj.fig, 'SelectionType')
                case 'normal'
                    obj.deselectRois(obj.selectedRois)
                    set(obj.fig, 'SelectionType', 'extend')
            end
            
            for i = 1:numel(obj.roiArray{ch})
                [y, x] = find(obj.roiArray{ch}(i).mask);
                if any(selectionLimitsX(1) <= x) && any(x <= selectionLimitsX(2))
                    if any(selectionLimitsY(1) <= y) && any( y <= selectionLimitsY(2))
                    	obj.selectRois(i, obj.fig.SelectionType);
                    end
                end
            end
            
        end

        
        function obj = selectListBoxObj(obj, source, ~)
        % Change selection status of roi that are selected in listbox
                
            if ~strcmp(obj.mouseMode, 'EditSelect')
                
                listboxSelection = source.Value;
                
                % Deselect Rois
                unselectedRois = setdiff(obj.selectedRois, listboxSelection);
                if ~isempty(unselectedRois)
                    obj.deselectRois(unselectedRois)
                end
                
                if numel(listboxSelection) == 1
                    obj.selectRois(listboxSelection, 'normal')
                else
                    obj.selectRois(listboxSelection, 'extend')
                end
                
            else 
                source.Value = [];
            end
            
        end
        
        
% % % % Methods for plotting rois
        
        function obj = plotRoi(obj, roiArray, idx, mode)
        % Plot the roi in the ax.
        
        % Default mode is append. Alternative: insert.
        
            ch = obj.currentChannel;
        
            if nargin < 3
                idx = obj.roiCount{ch} - fliplr(1:numel(roiArray)) + 1;
            end
            
            if nargin < 4; mode = 'append'; end
        
            axes(obj.axImageDisplay);
            hold on
            
            if isempty(obj.RoiPlotHandles{ch})
                obj.RoiPlotHandles{ch} = gobjects(0);
            end   
            
            if isempty(obj.RoiTextHandles{ch})
                obj.RoiTextHandles{ch} = gobjects(0);
            end
            
            % Preallocate some arrays
            nRois = numel(roiArray);
            colorCellArray = cell(nRois, 1);
            roiBoundaryCellArray = cell(2, nRois);
            centerPosArray = zeros(nRois, 2);

            % Find boundaries for all rois
            for roiNo = 1:numel(roiArray)
                colorCellArray{roiNo} = obj.getRoiColor(roiArray(roiNo));
                centerPosArray(roiNo, :) = roiArray(roiNo).center;

                for j = 1:length(roiArray(roiNo).boundary)

                    boundary = roiArray(roiNo).boundary{j};

                    if j == 1
                        roiBoundaryCellArray{1, roiNo} = boundary(:,2); 
                        roiBoundaryCellArray{2, roiNo} = boundary(:,1);

                    else
                        roiBoundaryCellArray{1, roiNo} = vertcat(roiBoundaryCellArray{1, roiNo}, nan, boundary(:,2));
                        roiBoundaryCellArray{2, roiNo} = vertcat(roiBoundaryCellArray{2, roiNo}, nan, boundary(:,1));
                    end
                end

            end

            % Plot lines and add text objects for all rois
            hLine = plot(roiBoundaryCellArray{:}, 'LineStyle', '-', 'Marker', 'None');
            hText = text(centerPosArray(:, 1), centerPosArray(:, 2), '');

            set(hLine, {'color'}, colorCellArray)
            set(hLine, 'HitTest', 'off')
            set(hLine, 'PickableParts', 'none')

            set(hText, {'color'}, colorCellArray)
            set(hText, 'HitTest', 'off')
            set(hText, 'PickableParts', 'none')
            set(hText, 'HorizontalAlignment', 'center')

            % Set visibility of text based on button "Show/Hide Tags"
            if obj.settings.showTags
                set(hText, 'Visible', 'on')
            else
                set(hText, 'Visible', 'off')
            end
            
            % Add to the end
            switch mode
                case 'append'
                    obj.RoiPlotHandles{ch}(idx) = hLine;
                    obj.RoiTextHandles{ch}(idx) = hText;
                case 'insert'
                    obj.RoiPlotHandles{ch} = rmUtil.insertIntoArray(obj.RoiPlotHandles{ch}, hLine, idx);
                    obj.RoiTextHandles{ch} = rmUtil.insertIntoArray(obj.RoiTextHandles{ch}, hText, idx);
            end

            hold off
             
        end
         
        
        function pObj = patchRoi(obj, mask, tag)
            
            [boundary, ~, N, A] = bwboundaries(mask);
                        
            patchCoords =  {};
            
            % Loop through outer boundaries
            for k = 1:N
                
                enclosedBoundary = find(A(:, k));
                nEnclosed = numel(enclosedBoundary);
                
                % Add enclosed boundaries if any
                if nEnclosed > 0
                    boundaryLength = length(boundary{k});
                    splitIdx = round(linspace(1, boundaryLength, nEnclosed+1));
                    connectedBoundary = zeros(0, 2);
                    for l = 1:nEnclosed
                        connectedBoundary = vertcat(connectedBoundary, boundary{k}(splitIdx(l):splitIdx(l+1), :), flipud(boundary{enclosedBoundary(l)}));
                    end
                    patchCoords{end+1} = connectedBoundary;
                else
                    patchCoords{end+1} = boundary{k};
                end
                    
            end
            
            colors = colormap(hsv(64));
            color = colors(randi(64), :);
            pObj = gobjects(numel(patchCoords), 1);
            for i = 1:numel(patchCoords)
                pObj(i) = patch(patchCoords{i}(:, 2), patchCoords{i}(:, 1), color, 'facealpha', 0.2, 'EdgeColor', 'None', 'Parent', obj.axImageDisplay, 'Tag', tag);
            end
            
            set(pObj,'HitTest', 'off', 'PickableParts', 'none')

        end
        
        
        function updateRoiPlot(obj, roiIdx)
        % Replot the roi at idx in roiArray
            hold on
            ch = obj.currentChannel;
            roi = obj.roiArray{ch}(roiIdx);
            for j = 1:length(roi.boundary)
                boundary = roi.boundary{j};
                if j == 1
                    set(obj.RoiPlotHandles{ch}(roiIdx), 'XData', boundary(:,2), 'YData', boundary(:,1));
                else
                    obj.RoiPlotHandles{ch}(roiIdx).XData = horzcat(obj.RoiPlotHandles{ch}(roiIdx).XData, nan, boundary(:,2)');
                    obj.RoiPlotHandles{ch}(roiIdx).YData = horzcat(obj.RoiPlotHandles{ch}(roiIdx).YData, nan, boundary(:,1)');
                end

            end
            
            if any(obj.selectedRois == roiIdx)
                removeNeuropilPatch(obj, roiIdx)
                addNeuropilPatch(obj, roiIdx)           
            end


            % Move roi label/tag to new center position
            set(obj.RoiTextHandles{ch}(roiIdx), 'Position', [roi.center, 0])
            hold off
            
        end
        
        
        function obj = shiftRoiPlot(obj, shift)
        % Shift Roi plots according to a shift [x, y, 0]
            % Get active roi
            ch = obj.currentChannel;
            
            for i = obj.selectedRois
                
                xData = get(obj.RoiPlotHandles{ch}(i), 'XData');
                yData = get(obj.RoiPlotHandles{ch}(i), 'YData');
            
                % Calculate and update position 
                xData = xData + shift(1);
                yData = yData + shift(2);
                set(obj.RoiPlotHandles{ch}(i), 'XData', xData)
                set(obj.RoiPlotHandles{ch}(i), 'YData', yData)
            
                % Shift text to new position
                textpos = get(obj.RoiTextHandles{ch}(i), 'Position');
                textpos = textpos + shift;
                set(obj.RoiTextHandles{ch}(i), 'Position', textpos);
            end
        end
                
        
% % % % Methods for loading and saving rois
        
        function obj = loadRois(obj, ~, ~)
        % Load rois from file. Keep rois which are in gui from before
        
                
        % Open filebrowser in same location as imgTseries was loaded from
        initpath = obj.initPath;

        [roiFileName, filePath, ~] = uigetfile({'*.mat', 'Mat Files (*.mat)'; ...
                                      '*', 'All Files (*.*)'}, ...
                                      'Find Roi File', ...
                                      initpath, 'MultiSelect', 'on');

        if isequal(roiFileName, 0) % User pressed cancel
            return
        end

        if ischar(roiFileName)
            roiFileName = {roiFileName};
        end
                        
        chNumberKeep = obj.currentChannel;
        
        fileChNumber = regexp(roiFileName, [obj.chExpr, '\d*'], 'match');
        
        % Determine channels and load rois to correct channel
        for f = 1:numel(roiFileName)
            
            filename = roiFileName{f};
            loadedChannel = fileChNumber{f};
            
            if ~isempty(loadedChannel)

                if ~any(strcmp(obj.loadedChannels, loadedChannel))
                    warning('Channel number of roi file does not correspond with channel number of image file')
                end
                
                % Change current channel to put rois in correct channel
                obj.changeCurrentChannel(struct('String', loadedChannel));
                
            end
            
            
            if exist(fullfile(filePath, filename), 'file')
                try
                load(fullfile(filePath, filename), 'roiArray')
                roi_arr = roiArray;
                catch
                load(fullfile(filePath, filename), 'roi_arr')
                end
            else
                continue
            end
            
            
            if isempty(roi_arr)
                continue
            end


            % Remove old rois when loading new rois.
            if isequal(obj.roiArray{obj.currentChannel}, roi_arr)
                continue
            else
                obj.selectedRois = 1:numel(obj.roiArray{obj.currentChannel});
                obj.removeRois();
                obj.initializeSignalArray(obj.currentChannel)
            end
                
            loadedRois = convertRois(roi_arr);
            loadedRois = checkRoiSizes(loadedRois, [obj.imHeight, obj.imWidth]);
            
            % Add rois to manager
            obj.addRois(loadedRois);
           
        end
        
        % Change to what was current channel before loading rois
        oldChNo = obj.loadedChannels(chNumberKeep);
        obj.changeCurrentChannel(struct('String', oldChNo));
        
        
        end
           
        
        function obj = saveRois(obj, source, ~, mode)
        % Export rois to file. Save to sessionfolder if available
                        
        if nargin < 4
            mode = 'Standard';
        end
        
            switch lower(mode)
                case 'open browser'
                    % Open filebrowser in same location as imgTseries was loaded from
                    initpath = obj.initPath;

                    savePath = uigetdir(initpath);

                    if isequal(savePath, 0) % User pressed cancel
                        return
                    end

                otherwise
                    savePath = obj.initPath;
                    settingsPath = obj.signalExtractionSettings.savePath;
                    savePath = rmUtil.validatePathString(settingsPath, savePath);
            end
            
            if ~exist(savePath, 'dir'); mkdir(savePath); end

            % Save roi arrays 
            for ch = 1:obj.nLoadedChannels
                
                roiFilenm = strcat( obj.loadedFileName{ch}, '_rois.mat' );

                switch lower(mode)
                    case 'open browser'
                    % Get filename from user
                    userInput = inputdlg({'Enter Filename'}, 'Filename Dialog Box', 1, {roiFilenm}, 'on' );
                    if ~isempty(userInput) 
                        roiFilenm = userInput{1};
                        assert(contains(roiFilenm, '.mat'), 'Filename must include .mat')
                    end
                end
                
                roi_arr = obj.roiArray{ch};
                save(fullfile(savePath, roiFilenm), 'roi_arr')
                
                if ~isempty(source)
                    fprintf('Rois saved to %s \n', fullfile(savePath, roiFilenm));
                end
                
            end
        end
        
        
        function obj = saveSignal(obj, ~, ~, mode)
        % Export signals to file.
            
        if nargin < 4
            mode = 'Standard';
        end
        
            switch lower(mode)
                case 'open browser'
                    % Open filebrowser in same location as imgTseries was loaded from
                    initpath = obj.initPath;

                    savePath = uigetdir(initpath);

                    if isequal(savePath, 0) % User pressed cancel
                        return
                    end

                otherwise
                    savePath = obj.initPath;
                    settingsPath = obj.signalExtractionSettings.savePath;
                    savePath = rmUtil.validatePathString(settingsPath, savePath);
            end
            
            if ~exist(savePath, 'dir'); mkdir(savePath); end
        
            options = obj.signalExtractionSettings;
            options.savePath = savePath;
            options.neuropilExtractionMethod = options.neuropilExtractionMethod.Selection;
            options.deconvolutionMethod = options.deconvolutionMethod.Selection;
            
            
            try
                sid = obj.sessionObj.sessionID;
                meta2P = loaddata(sid, 'meta2P');
                options.dt = meta2P.dt;
            catch
                options.dt=1/31;
            end
            
                
            % Save signaldata
            for ch = 1:obj.nLoadedChannels
                
                if isempty(obj.roiArray{ch})
                    continue
                end
                
                % Add some more items to options
                options.filename = sprintf('%s_signals.mat', obj.loadedFileName{ch});
                
                if options.extractFromFiles
                    % Find image files
                    chPattern = strcat(obj.chExpr, obj.loadedChannels(ch));
                    imListing = dir(fullfile(obj.initPath, '*.tif'));
                    chMatch = contains({imListing.name}, chPattern);
                    if ~isempty(chMatch)
                        images = fullfile(obj.initPath, {imListing(chMatch).name});
                    else
                        images = fullfile(obj.initPath, {imListing(1).name});
                    end
                else
                    images = obj.imgTseries{ch};
                end
                
                if options.extractSignalsInBackground
                    batch(@signalExtraction.extractAndSaveSignals, 0, ...
                        {images, obj.roiArray{ch}, options})
                    fprintf('Signals will be extracted on a separate worker to:\n %s\n', savePath)
                else
                	signalExtraction.extractAndSaveSignals(images, obj.roiArray{ch}, options)
                    fprintf('Signals saved to %s \n', savePath);
                end
                
            end
            
        end

        
        function obj = runAutoSegmentation(obj, src, ~)
        % Calls autodetection package from Pnevmatikakis et al (Paninski)
        % and adds detected rois to gui
           
        % todo: finish autosegmentation with individual roi radiuses...?
        
        switch src.String
            
            case 'No intervention'
                obj.runAutoSegmentation(struct('String', 'Run Auto Segmentation'))
                obj.runAutoSegmentation(struct('String', 'Continue Auto Segmentation'))
                
                
            case 'Run Auto Segmentation'
        
                % Get number of rois from user. Set size to the radius
                % specified by the autodetection size property.
                if isequal(src, obj.btnRunAutoSegmentation)
                    numRois = str2double(inputdlg('Enter number of Rois to search for'));
                else
                    numRois = 150;
                end

                roiSize = round(obj.roiOuterDiameter/2);
                disp('Starting the roi autodetection program')

                % Take every 5th frame and convert to single  
                Y = obj.imgTseries{obj.currentChannel};
                Y = Y(:,:,1:10:end);
                if ~isa(Y,'single');    Y = single(Y);  end    % convert to single

                % Data pre-processing
                p = 2; % order of autoregressive system (p = 0 no dynamics, p=1 just decay, p = 2, both rise and decay)
                [P,Y] = preprocess_data(Y,p);

                options = CNMF.getOptions(size(Y), roiSize);

                % fast initialization of spatial components using greedyROI and HALS
                [Ain,Cin,bin,fin,center] = initialize_components(Y, numRois, roiSize, options, P);  % initialize

                % Add found components to list of rois
                foundRois = CNMF.getRoiArray(Ain, options);
                obj.addRois(foundRois);
                
                obj.cnmfData = struct;
                obj.cnmfData.Y = Y;
                obj.cnmfData.P = P;
                obj.cnmfData.options = options;
                obj.cnmfData.Ain = Ain;
                obj.cnmfData.Cin = Cin;
                obj.cnmfData.bin = bin;
                obj.cnmfData.fin = fin;
                obj.cnmfData.center = center;
                
                set(obj.btnRunAutoSegmentation, 'String', 'Continue Auto Segmentation')
                
            case 'Continue Auto Segmentation'
                
                [foundRois, cnmfResults] = CNMF.finishAutoSegmentation(obj.cnmfData);
                
                obj.selectedRois = 1:obj.roiCount{obj.currentChannel};
                obj.removeRois([], []);
                
                clearvars obj.cnmfData
                obj.cnmfData = [];
                
                obj.addRois(foundRois);
                
                obj.cnmfResults = cnmfResults;
                
                set(obj.btnRunAutoSegmentation, 'String', 'Run Auto Segmentation')
        end
        
        end
        
        
        function updateCnmfData(obj, idx, mode)
            
            %Only supports append
                        
            switch mode
                
                case 'append'
                    rois = obj.roiArray{obj.currentChannel}(idx);
                    centers = arrayfun(@(roi) roi.center, rois, 'uni', 0);
                    centers = vertcat(centers{:});
                    areas = arrayfun(@(roi) roi.area, rois, 'uni', 1);
                    radius = sqrt(areas/pi); % Assuming circular rois..
                    
                    for i = 1:numel(idx)
                        [obj.cnmfData.Ain, obj.cnmfData.Cin, centerNew] = CNMF.addManualComponent(obj.cnmfData.Y, obj.cnmfData.Ain, obj.cnmfData.Cin, centers(i, :), radius, obj.cnmfData.options);
                        obj.cnmfData.center(end+1, :) = centerNew;
                    end
                                        
                case 'remove'
                    obj.cnmfData.Ain(:, idx) = [];
                    obj.cnmfData.Cin(idx, :) = [];
                    obj.cnmfData.center(idx, :) = [];
                    
                case 'insert'
                    error('Insert mode not supportedf for cnmfdata')
            end
        end
        
        
% % % % Callback for buttons to change image display
        
        function obj = showStack(obj, ~, ~)
        % Shows current frame in image display
            obj.unFocusButton(obj.btnShowCurrentFrame)
            set(obj.fsContainer, 'Visible', 'on');
            
            % Untoggle all other show buttons
            obj.unToggleShowButtons([]);
            
            obj.updateImageDisplay();
        end
        
        
        function obj = showAvg(obj, source, ~)
        % Shows stack average projection in image display
            obj.unFocusButton(obj.btnShowAvg)
            ch = obj.currentChannel;
            if ~isempty(obj.imgAvg{ch})
                
                % Untoggle all other show buttons
                obj.unToggleShowButtons(obj.btnShowAvg);
                
                if source.Value
                    set(obj.fsContainer, 'Visible', 'off');
                    set( obj.textCurrentFrame, 'String', ...
                              'Current Frame: Avg Image' )
                end
                obj.updateImageDisplay();
            end
        end
        
        
        function obj = showMax(obj, source, ~)
        % Shows stack average projection in image display
            obj.unFocusButton(obj.btnShowMax)
            ch = obj.currentChannel;
            if ~isempty(obj.imgMax{ch})
                
                % Untoggle all other show buttons
                obj.unToggleShowButtons(obj.btnShowMax);
                
                if source.Value
                    set(obj.fsContainer, 'Visible', 'off');
                    set( obj.textCurrentFrame, 'String', ...
                              'Current Frame: Max Image' )
                end
                obj.updateImageDisplay();
            end
        end           

  
        function obj = showMovingAvg(obj, source, ~)
        % Shows stack running average projection in image display
        
            if ~source.Value
                obj.unFocusButton(obj.btnShowMovingAvg)
            end
            
            % Untoggle all other show buttons
            obj.unToggleShowButtons(source);
            
            obj.updateImageDisplay();
            
        end
        
        
        function obj = showMovingStd(obj, source, ~)
        % Shows stack running standard deviation projection in image display
        
            if ~source.Value
                obj.unFocusButton(obj.btnShowMovingStd)
            end
            
            % Untoggle all other show buttons
            obj.unToggleShowButtons(source);
            
            if isempty(obj.imgTseriesMedfilt{obj.currentChannel})
                obj.despeckleStack();
            end
            
            obj.updateImageDisplay();
            
        end
        
        
        function obj = showMovingMax(obj, source, ~)
        % Shows stack running maximum projection in image display
        
            if ~source.Value
                obj.unFocusButton(obj.btnShowMovingMax)
            end
        
            % Untoggle all other show buttons
            obj.unToggleShowButtons(source);
            
            if isempty(obj.imgTseriesMedfilt{obj.currentChannel})
                obj.despeckleStack();
            end
            
            obj.updateImageDisplay(); 
            
        end
        
        
% % % % Two simple functions for button management 
        
        % TODO: Combine all this...
        function obj = unToggleShowButtons(obj, sourceBtn)
        % Untoggle all buttons except source button.
            buttons = {obj.btnShowMovingMax, ...
                obj.btnShowMovingStd, ...
                obj.btnShowMovingAvg, ...
                obj.btnShowAvg, obj.btnShowMax};
            
            for i = 1:numel(buttons)
                if ~isequal(buttons{i}, sourceBtn)
                    set(buttons{i}, 'Value', 0)
                end
            end
        end
        
        
        function obj = unToggleButtonGroup(obj, sourceBtn, buttons)
        % Untoggle all buttons except source button.            
            for i = 1:numel(buttons)
                if ~isequal(buttons{i}, sourceBtn)
                    set(buttons{i}, 'Value', 0)
                end
            end
        end
        
        
        function obj = toggleEditButton(obj, sourceBtn)
        % Toggle source button and make sure the other buttons are
        % untoggled
        
        buttons = { obj.btnDrawRoi, ...
                	obj.btnEditRoi, ...
                    obj.btnAutoDetect, ...
                    obj.btnCircleTool};
            
            for i = 1:numel(buttons)
                if isequal(buttons{i}, sourceBtn)
                    set(buttons{i}, 'Value', 1)
                else
                    set(buttons{i}, 'Value', 0)
                end
            end
        
        end
        
        
        function menuCallback_SelectFrames(obj, ~, ~)
        % Add booleans where there is a signal leakthrough or artifact in the roi signal. 

            if ~isempty(obj.hpatchFrameSelection)    
                if strcmp(obj.hpatchFrameSelection.Visible, 'on')
                    if isempty(obj.selectedFrames)
                        obj.selectedFrames = zeros(obj.nFrames, 1);
                    end
                    
                    frameStart = min([obj.hlineCurrentFrame2.XData(1), obj.hlineCurrentFrame.XData(1)]);
                    frameEnd = max([obj.hlineCurrentFrame2.XData(1), obj.hlineCurrentFrame.XData(1)]);

                    obj.selectedFrames(frameStart:frameEnd) = true;
                    obj.updateSelectedFramePatch('overwrite');

                    delete(obj.hlineCurrentFrame2); obj.hlineCurrentFrame2 = [];

                end
            end
                
        end
        
        
        function menuCallback_ResetFrameSelection(obj, ~, ~)

            obj.selectedFrames = zeros(obj.nFrames, 1);
            obj.updateSelectedFramePatch('delete')
        
        end
        
        
        function selectFrames(obj, mode)
            switch mode
                case 'Start Selection'
                    obj.selectFrameMode = true;

                    frameNo = obj.currentFrameNo;

                    if isempty(obj.hlineCurrentFrame2) || ~isgraphics(obj.hlineCurrentFrame2) 
                        obj.hlineCurrentFrame2 = plot(obj.axSignalPlot, [frameNo, frameNo], get(obj.axSignalPlot, 'ylim'), '--r', 'Visible', 'off', 'HitTest', 'off');
                    else
                        set(obj.hlineCurrentFrame2, 'XData', [frameNo, frameNo]);
                    end
                    
                case 'Finish Selection'
                    obj.selectFrameMode = false;
                    set(obj.hlineCurrentFrame2, 'Visible', 'off')
            end
        end

        
        function obj = displaySelectedRegion(obj)
            
            %todo when roi is changed. Should it disappear? Have to change ydata...
           if obj.selectFrameMode
                if strcmp(obj.hlineCurrentFrame2.Visible, 'off')
                    set(obj.hlineCurrentFrame2, 'Visible', 'on')
                    set(obj.hpatchFrameSelection, 'Visible', 'on')
                end
               
                prevFrame = get(obj.hlineCurrentFrame2, 'XData');
                prevFrame = prevFrame(1);
                xPatch = [prevFrame, obj.currentFrameNo, obj.currentFrameNo, prevFrame];
                ylim = get(obj.axSignalPlot, 'ylim');
                set(obj.hlineCurrentFrame2, 'YData', ylim);
                yPatch = [ylim(1), ylim(1), ylim(2), ylim(2)];
                
                if isempty(obj.hpatchFrameSelection) || ~isgraphics(obj.hpatchFrameSelection)
                    obj.hpatchFrameSelection = patch(xPatch, yPatch, [0.2,0.2,0.8] ,'Parent', obj.axSignalPlot, 'facealpha', 0.2,'edgecolor','none');
                else
                    set(obj.hpatchFrameSelection, 'XData', xPatch, 'YData', yPatch)
                end
                
               
           else
               if isgraphics(obj.hpatchFrameSelection)
                   if ~isempty(obj.hpatchFrameSelection) && strcmp(obj.hpatchFrameSelection.Visible, 'on')
                       obj.hpatchFrameSelection.Visible = 'off';
                   end
               end
           end
               
               
        end
    

        function updateSelectedFramePatch(obj, mode)
            
            switch mode
                case 'update_y'
                    [xCoord, yCoord] = rmUtil.getEventPatchCoordinates(obj.selectedFrames, obj.axSignalPlot.YLim);

                    if ~isempty(xCoord)
                        patch = findobj(obj.axSignalPlot, 'Tag', 'SelectedFramePatch');
                        
                        % Update y vertices of patch so that it covers from bottom to top of plot.
                        yVertices = patch.Vertices(:,2);
                        yVertices(yVertices==min(yVertices)) = min(yCoord(:));
                        yVertices(yVertices==max(yVertices)) = max(yCoord(:));
                        patch.Vertices(:,2) = yVertices;
                    end
                    
                case 'overwrite'
                    patches = findobj(obj.axSignalPlot, 'Tag', 'SelectedFramePatch');
                    delete(patches)
                    pobj = rmUtil.patchEvents(obj.axSignalPlot, obj.selectedFrames, 'blue');
                    pobj.Tag = 'SelectedFramePatch';
                    pobj.EdgeColor = 'None'; pobj.FaceAlpha = 0.3; 
                    pobj.HitTest = 'off'; pobj.PickableParts = 'none';
                case 'delete'
                    patches = findobj(obj.axSignalPlot, 'Tag', 'SelectedFramePatch');
                    delete(patches)
            end
        end
        
        
        function menuCallback_RoiToWorkspace(obj, ~, ~)
            
            ch = obj.currentChannel;

            if isempty(obj.selectedFrames) || sum(obj.selectedFrames) == 0
                frames = 1:obj.nFrames;
            else
                frames = find(obj.selectedFrames);
            end
            
            
            roiIndices = obj.selectedRois;
            
            for i = roiIndices
                
                npMask = signalExtraction.fissa.getMasks(obj.roiArray{ch}(i).mask);
                
                npMask = sum(npMask, 3);
                
                [y, x] = find(npMask~=0);
                
                minX = min(x); maxX = max(x);
                minY = min(y); maxY = max(y);

                pixelChunk = obj.imgTseries{ch}(minY:maxY, minX:maxX, :);
                
                varname = sprintf('imchunkRoi%03d', i);
                assignin('base', varname, pixelChunk)
                mask = obj.roiArray{ch}(i).mask;
                croppedMask = mask(minY:maxY, minX:maxX);
                varname = sprintf('roimask%03d', i);
                assignin('base', varname, croppedMask)
            end
            
        end
        
% % % % Callbacks for value change on gui sliders and input boxes
        
        function obj = changeBinningSize(obj, source, ~)
        % Updates the binning size for moving averages. Forces new value to
        % be odd
            newBinningSize = str2double(source.String);
            if ~mod(newBinningSize, 2)
                newBinningSize = newBinningSize - 1;
            end
            obj.binningSize = newBinningSize;
            set(obj.inputSetBinningSize, 'String', num2str(obj.binningSize))
        
        end
        
        
        function obj = setRoiTemplateSize(obj, source,  ~)
        % Callback for button to set the roi diameter to use for autodetection
        
            switch source.String
                case 'Set Autodetection Size'
                    set(obj.btnSetRoiTemplateSize, 'String', 'Ok')
                    obj.btnSetRoiTemplateSize.Position(1) = 0.8;
                    obj.btnSetRoiTemplateSize.Position(3) = 0.15;
                    set(obj.roiSizeSliderContainer, 'Visible', 'on')
                    set(obj.btnSetRoiTemplateSize, 'TooltipString', 'Move cursor to image and click to reposition the Roi Template')
                    obj.setMouseMode('Set Roi Diameter');
                    if isempty(obj.roiTemplateCenter)
                        xlim = get(obj.axImageDisplay, 'Xlim');
                        ylim = get(obj.axImageDisplay, 'Ylim');
                        obj.roiTemplateCenter = [xlim(1) + diff(xlim)/2, ylim(1) + diff(ylim)/2];
                        obj = plotRoiTemplate(obj);
                    end
                    
                    set(obj.hlineRoiTemplate, 'Visible', 'on')
                    
                case 'Ok'
                    obj.btnSetRoiTemplateSize.Position(1) = 0.1;
                    obj.btnSetRoiTemplateSize.Position(3) = 0.8;
                    set(obj.btnSetRoiTemplateSize, 'String', 'Set Autodetection Size')
                    set(obj.roiSizeSliderContainer, 'Visible', 'off')
                    set(obj.btnSetRoiTemplateSize, 'TooltipString', '')
                    set(obj.hlineRoiTemplate, 'Visible', 'off')
                    obj.unFocusButton(obj.btnSetRoiTemplateSize)
                    obj.setMouseMode('Previous');
            end        
        
        end
            
        
        function obj = changeRoiSize(obj, slider, ~)
        % Callback function for value change of roi diameter slider 
            obj.roiInnerDiameter = slider.Low;
            obj.roiOuterDiameter = slider.High;
            obj = plotRoiTemplate(obj);
            
        end
        
        
        function obj = changeBrightness(obj, slider, ~)
        % Callback function for value change of brightness slider
            min_brightness = slider.Low;
            max_brightness = slider.High;
            switch obj.channelDisplayMode
                case {'single', 'correlation'}
                    set(obj.axImageDisplay, 'CLim', [min_brightness, max_brightness])
                case 'multi'
                    obj.updateImageDisplay();
            end
            
        end
        
        
        function obj = changeRoiClass(obj, source, ~)
            % Change roiclass of roi if popupmenu is changed.
            if ~isempty(obj.selectedRois)
                for i = obj.selectedRois
                    obj.editRoiProperties(i, source);
                    obj.updateListBox(i);
                end
            end
        end
        
        
        function obj = changeCorticalLayer(obj, source, ~)
         % Change cortical layer of roi if popupmenu selection is changed.
            if ~isempty(obj.selectedRois)
                for i = obj.selectedRois
                    obj.editRoiProperties(i, source)
                    obj.updateListBox(i);
                end
            end
        end
        
        
        function tagRois(obj, src, ~, tag)
            % Add tag to tags property of selected rois.
            if ~isempty(obj.selectedRois)
                for i = obj.selectedRois
                    roi = obj.roiArray{obj.currentChannel}(i);
                    if src.Value
                        if contains(tag, roi.tags)
                            continue
                        else
                            roi.tags = cat(2, roi.tags, tag);
                        end
                    else
                        if contains(tag, roi.tags)
                            roi.tags = setdiff(roi.tags, tag);
                        else
                            continue
                        end
                            
                    end 
                end
            end
        end
        
        
        function obj = changeChannelDisplayMode(obj, source, ~)
        % Button callback to change display between showing single or
        % multiple channels.
        
        % This function was modified when I added the correlation image. It
        % was a button callback, but now it is also called from the
        % menu selection 'Show correlation image'. In this case I dont want
        % to update the image display, because it is done elsewhere.
        
            switch source.String
                case 'Show Single Channel'
                    set(obj.btnShowSingleChannel, 'String', 'Show All Channels')
                    obj.channelDisplayMode = 'single';
                    colormap(obj.axImageDisplay, gray(256))
                    min_brightness = obj.brightnessSlider.Low;
                    max_brightness = obj.brightnessSlider.High;
                    set(obj.axImageDisplay, 'CLim', [min_brightness, max_brightness])
                    obj.updateImageDisplay();
                    
                case 'Show All Channels'
                    set(obj.btnShowSingleChannel, 'String', 'Show Single Channel')
                    obj.channelDisplayMode = 'multi';
                    obj.updateImageDisplay();
                    
                case 'Show Correlation Image'
                    obj.channelDisplayMode = 'correlation';
                    colormap(obj.axImageDisplay, parula(256))
                    min_brightness = obj.brightnessSlider.Low;
                    max_brightness = obj.brightnessSlider.High;
                    set(obj.axImageDisplay, 'CLim', [min_brightness, max_brightness])
                otherwise
                    return
            end
            
        end
        
        
        function obj = changeCurrentChannel(obj, source, ~)
        % Callback for changing the current channel
            
            newChannel = source.String;
        
            % Selected channel as logical array.
            isNewChannel = cellfun(@(str) strcmp(str, newChannel), obj.loadedChannels);
            
            % Check that the selected channel is part of list of channels
            if ~any(isNewChannel)
                disp(strcat( 'Selected channel (', source.String, ') is not loaded'))
                return
%             elseif obj.currentChannel == find(isNewChannel)
%                 return
            end
            
            set(obj.channel, 'String', obj.loadedChannels{isNewChannel})
  
            % Cancel drawing or editing - Need to do before deselecting
            if ~isempty(obj.tmpRoiPosX)
                obj.cancelRoi();
            end
            
            % Reset selection of rois. Do before setting new
            % channel
            obj.deselectRois(obj.selectedRois);
            
            % Set new current channel and update listbox
            obj.currentChannel = find(isNewChannel);
            obj.resetListbox();
            obj.updateListBox();

            % Update image and filename
            obj.updateImageDisplay();
            set(obj.textCurrentFileName, 'String',  obj.loadedFileName{obj.currentChannel})
            
            % Change visibility of rois and text label
            for i = 1:obj.nLoadedChannels
                if i == obj.currentChannel
                    set(obj.RoiPlotHandles{i}, 'Visible', 'on')
                    if obj.settings.showTags
                        set(obj.RoiTextHandles{i}, 'Visible', 'on')
                    end
                else
                	set(obj.RoiPlotHandles{i}, 'Visible', 'off')
                    set(obj.RoiTextHandles{i}, 'Visible', 'off')
                end
            end
            
            obj.resetSignalPlot();
            
        end
        
                  
% % % %  Misc
        
        function obj = despeckleStack(obj)
        % Create a stack which is median filtered (despeckled)
        
            h = waitbar(0, 'Please wait while performing median filtering');
            
            ch = obj.currentChannel;
            obj.imgTseriesMedfilt{ch} = zeros(obj.imHeight, obj.imWidth, obj.nFrames, 'like', obj.imgTseries{ch});

            for f = 1:obj.nFrames
                obj.imgTseriesMedfilt{ch}(:,:,f) = medfilt2(obj.imgTseries{ch}(:, :, f));
                if mod(f,100)==0
                    waitbar(f/obj.nFrames, h)
                end
            end

            close(h)
            
        end
        
        function plotCircleTool(obj, coords)
            
            if nargin < 2
                if isempty(obj.circleToolCoords)
                    x = obj.roiTemplateCenter(1);
                    y = obj.roiTemplateCenter(2);
                    r = obj.roiOuterDiameter/2;
                    obj.circleToolCoords = [x, y, r];
                else
                    x = obj.circleToolCoords(1); y = obj.circleToolCoords(2); 
                    r = obj.circleToolCoords(3);
                end
                
            else
                x = coords(1); y = coords(2); r = coords(3);            
            end
            
            if r <= 0
                return
            else
                obj.circleToolCoords = [x, y, r];
            end
            
            % Create circular line
            th = 0:pi/50:2*pi;
            xData = r * cos(th) + x;
            yData = r * sin(th) + y;
            hold(obj.axImageDisplay, 'on')
            % Plot Line
            if isempty(obj.circleToolHandle)
                obj.circleToolHandle = plot(obj.axImageDisplay, xData, yData, 'c');
            else
                set(obj.circleToolHandle, 'XData', xData, 'YData', yData)
            end
            hold(obj.axImageDisplay, 'off')
        end
            
        

        function obj = plotRoiTemplate(obj)
        % Plot a circle with diameter equal to roi template diameter.
            if ~isempty(obj.roiTemplateCenter) && ~isempty(obj.himage)
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
                
                hold(obj.axImageDisplay, 'on')
                if isempty(obj.hlineRoiTemplate)
                    obj.hlineRoiTemplate = plot(obj.axImageDisplay, xData, yData, 'yellow');
                else
                    set(obj.hlineRoiTemplate, 'XData', xData, 'YData', yData)
                end
                hold(obj.axImageDisplay, 'off')
            end
        end
        
        
% % % % Methods for extracting and showing signal of RoIs

        function editSpikeThreshold(obj, src, ~)
            if src.Value
            	obj.editSpikeThresh.Enable = 'on';
            else
            	obj.editSpikeThresh.Enable = 'off';
            end
        end


        function changeSignalType(obj, source, ~)
            
            switch source.String
                case 'Show Raw'
                    signalName = 'roiMeanF';
                case 'Show DFF'
                    signalName = 'dff';
                case 'Show Demixed'
                    signalName = 'demixedMeanF';
                case 'Show Denoised'
                    signalName = 'denoised';
                case 'Show Spikes'
                    signalName = 'spikes';
            end
            
            if source.Value
                if isempty(obj.signal2display)
                    obj.signal2display = {signalName};
                else
                    obj.signal2display = cat(1, obj.signal2display, signalName);
                    if contains('spikes', obj.signal2display)
                        idx = find(contains(obj.signal2display, 'spikes'));
                        obj.signal2display(idx) = obj.signal2display(end);
                        obj.signal2display{end} = 'spikes';                    
                    end
                end
                set( obj.hlineSignal.(signalName), 'Visible', 'on' )
                

            else
                obj.signal2display = setdiff(obj.signal2display, signalName);
                set( obj.hlineSignal.(signalName), 'Visible', 'off' )
            end

            for i = 1:numel(obj.selectedRois)
                if i == 1
                    updateSignalPlot(obj, obj.selectedRois(i), 'overwrite');
                else
                    updateSignalPlot(obj, obj.selectedRois(i), 'append');
                end
            end
        end
        
        
        function changeSignalParameter(obj, src, ~)
            ch = obj.currentChannel;
            
            
            
            switch lower(src.Tag)
%                 case 'spikeThreshold'

                case 'spikesnr'
                    obj.modifySignalArray(obj.selectedRois, 'reset')
                    obj.updateSignalPlot(obj.selectedRois, 'overwrite')
                case 'lambdapr'
                    obj.modifySignalArray(obj.selectedRois, 'reset')
                    obj.updateSignalPlot(obj.selectedRois, 'overwrite')                
            end
            
            
            
            try
                spikeThreshold = str2double(src.String);
            catch
                error('Invalid input: %s', src.String)
            end
            
            obj.signalArray(ch).spikeThreshold(obj.selectedRois) = spikeThreshold;
            obj.signalArray(ch).spikes(:, obj.selectedRois) = nan;

            for i = 1:numel(obj.selectedRois)
                if i == 1
                    updateSignalPlot(obj, obj.selectedRois(i), 'overwrite');
                else
                    updateSignalPlot(obj, obj.selectedRois(i), 'append');
                end
            end
           
        end
            
            
        function [signal] = extractSignal(obj, roiIdx, signalName)
            % Generate a "neuropil mask", like a cheese with holes where all the rois are
            % taken out. This is pretty fast, otherwise I wouldnt do it every
            % time..
            
            ch = obj.currentChannel;
            currentRoi = obj.roiArray{ch}(roiIdx);

            h = waitbar(0, 'Please wait, extracting signals for Roi');
            
            if strcmp(signalName, 'roiMeanF')
                
                % Extract signal using extractRoiFluorescence function
                signal = signalExtraction.extractSignalFromImageData(obj.imgTseries{ch}, obj.roiArray{ch}, 'raw', roiIdx);
                signal = squeeze(signal);
                signal = movmean(signal, 20);
                
                assignin('base', sprintf('signal_roi%d', roiIdx), signal)
                
            elseif strcmp(signalName, 'dff')
%                 signal = signalExtraction.extractSignalFromImageData(obj.imgTseries{ch}, obj.roiArray{ch}, 'raw', roiIdx);
%                 signal = movmean(signal, 20); 
%                 f0 = prctile(signal, 10);
%                 signal = (signal-f0)/f0;
                
                [roiMask, npMask] = signalExtraction.standard.getMasks(obj.roiArray{ch}, roiIdx);
                signalArray = signalExtraction.extractRoiFluorescence(obj.imgTseries{ch}, roiMask, npMask, 'median');
                signal = signalExtraction.dff.dffRoiMinusDffNpil(signalArray(:,1), signalArray(:,2));

                
                
% %                 % Extract signal using extractRoiFluorescence function
% %                 signal = rmSignalExtraction.extractRoiFluorescence(currentRoi, obj.imgTseries{ch}, roiArrayMask, npMask);
% %                 sorted = sort(signal.fmeanRoi);
% %                 sorted_np = sort(signal.fmeanNeuropil);
% % 
% %                 % Calculate delta f over f.
% %                 f0 = median(sorted(1:round(end*0.2)));
% %                 f0_np = median(sorted_np(1:round(end*0.2)));
% % 
% %                 deltaFoverF = (signal.fmeanRoi - f0) ./ f0;
% %                 deltaFoverFnp = (signal.fmeanNeuropil - f0_np) ./ f0_np;
% %                 signal = deltaFoverF;
% %                 np_signal = deltaFoverFnp;
% %                 difference = smooth(np_signal, 10) - smooth(signal, 10);
% %                 tpidx = difference<0;
% %                 difference2 = difference;
% %                 difference2(tpidx) = 0;
% %                 correctionFactor = smoothdata(difference2);
% %                 signal = smooth(signal, 5) - smooth(np_signal, 5) + correctionFactor;
% % %                 signal = signal - np_signal + correctionFactor;

            elseif strcmp(signalName, 'demixedMeanF')
                
                switch obj.signalExtractionSettings.neuropilExtractionMethod.Selection
                    case 'Standard'
                        signal = signalExtraction.extractSignalFromImageData(obj.imgTseries{ch}, obj.roiArray{ch}, 'standard', roiIdx);
                        signal = signal(:, 1);
                    case 'Fissa'
                        extractedSignals = signalExtraction.extractSignalFromImageData(obj.imgTseries{ch}, obj.roiArray{ch}, 'fissa', roiIdx);
                        
                        % Call python script to run fissa separation
                        path = mfilename('fullpath');
                        [path, ~, ~] = fileparts(path);

                        pyscript = fullfile(path, '+signalExtraction/+fissa/fissa_separation.py');
                        
                        filepath_extracted = fullfile(path, '+signalExtraction/+fissa/tmp/extracted_signal.mat');
                        save(filepath_extracted, 'extractedSignals')
                        filepath_separated = strrep(filepath_extracted, 'extracted_signal', 'separated_signal');
                        
                        % Call python script to run fissa separation
                        [status, ~] = system(sprintf('python %s %s %s', pyscript, filepath_extracted, filepath_separated));
                        
                        load(filepath_separated, 'matchedSignals')
                        signal = matchedSignals(:, 1);
                end
                
            elseif any(strcmp(signalName, {'denoised', 'deconvolved'}))
                % TODO should depend on signal 2 deconvolve.
            	dff = obj.signalArray(ch).dff(:, roiIdx);
                if all(isnan(dff))
                    dff = obj.extractSignal(roiIdx, 'dff');
                end
                
                spk_SNR = str2double(obj.editSpikeSNR.String); % 10; %Default = 0.99
                lam_pr = str2double(obj.editLambdaPr.String); %Default = 0.5
                fr = 31;
                decay_time = 0.4;  % default value in CNMF: 0.4; Maybe this is for f?

                spkmin = spk_SNR*GetSn(dff);
                lam = choose_lambda(exp(-1/(fr*decay_time)),GetSn(dff),lam_pr);
                [cc,spk,opts_oasis] = deconvolveCa(dff, 'ar2', 'method','thresholded','optimize_pars',true,'maxIter',20, ...
                                            'window', 150,'lambda',lam, 'smin',spkmin);
                baseline = opts_oasis.b;
                den_df = cc(:) + baseline;
                dec_df = spk(:);
                neuron_sn = opts_oasis.sn;
                g = opts_oasis.pars(:)';
                
%                 [den_df, dec_df, ~] = deconvolveCa(dff, 'method', 'thresholded', 'optimize_pars', 'optimize_b');
                

                obj.signalArray(ch).denoised(:, roiIdx) = den_df;
                obj.signalArray(ch).deconvolved(:, roiIdx) = dec_df;
                if strcmp(signalName, 'denoised')
                    signal = den_df;
                else
                    signal = dec_df;
                end
           	
            elseif strcmp(signalName, 'spikes')
                %todo: set spikethreshold manually or automatically based
                % on magnitudes of dff and the deconvolved trace.
                
                dff = obj.signalArray(ch).dff(:, roiIdx);
                den = obj.signalArray(ch).denoised(:, roiIdx);

                f = obj.signalArray(ch).deconvolved(:, roiIdx);
                if all(isnan(f))
                    f = obj.extractSignal(roiIdx, 'deconvolved');
                end
                
% % %                 if isnan(obj.signalArray(ch).spikeThreshold(roiIdx))
% % %                     opt.spikethreshold = 0.05;
% % %                     obj.signalArray(ch).spikeThreshold(roiIdx) = opt.spikethreshold;
% % %                 else
% % %                     opt.spikethreshold = obj.signalArray(ch).spikeThreshold(roiIdx);
% % %                 end
                
                switch obj.signalExtractionSettings.deconvolutionMethod.Selection
                    case 'CaImAn'
                        opt.spikethreshold = 0.05;
                    case 'Suite2P'
                        opt.spikethreshold = 0.24;                        
                end
                
                obj.editSpikeThresh.String = num2str(opt.spikethreshold);

                f  = reshape(f , 1, 1, []);
                signal = squeeze(guestimateSpikesFromDeconvolved(f, opt));
            else
                fprintf('unknown signal, %s\n', signalName)
            end
            
            
            obj.signalArray(ch).(signalName)(:, roiIdx) = signal;
            close(h)
            
            if ~nargout
                clear signal
            end
            
        end
        
        
        function obj = showSignalPlot(obj, source, ~)
                            
            btnGroup = [obj.btnShowRaw, obj.btnShowDFF, ...
                        obj.btnShowDemixed, obj.btnShowDenoised, obj.btnShowSpikes ];
                    
            signalNames = {'roiMeanF', 'npilMediF', 'demixedMeanF', 'dff', ...
                            'deconvolved', 'denoised', 'spikes'};                    
            
            if source.Value
                set(obj.axSignalPlot, 'Visible', 'on')
                set(obj.axSignalPlot.Children, 'Visible', 'on')
                for h = 1:numel(signalNames)
                    set(obj.hlineSignal.(signalNames{h}), 'Visible', 'on')
                end
                
                set(obj.hlineCurrentFrame, 'Visible', 'on')
                if ~ strcmp(obj.btnUndockImage.String, 'Dock Image Window')
                    set(obj.axImageDisplay, 'Position', [0.12, 0.2, 0.76, 0.76])
                end
                drawnow
                set(obj.himage, 'ButtonDownFcn', @obj.mousePress)
                set(btnGroup, 'Visible', 'on')
                

            else
                obj.resetSignalPlot();
                set(obj.axSignalPlot, 'Visible', 'off')
                set(obj.axSignalPlot.Children, 'Visible', 'off')

                for h = 1:numel(signalNames)
                    set(obj.hlineSignal.(signalNames{h}), 'Visible', 'off')
                end
                set(obj.hlineCurrentFrame, 'Visible', 'off')
                set(obj.axImageDisplay, 'Position', [0.03, 0.03, 0.94, 0.94])
                set(btnGroup, 'Visible', 'off')
                                
                % Reset limits if the zoom was used. 
                set(obj.axSignalPlot, 'XLim', [1, obj.nFrames])
                
            end
            
            
        end
        
        
        function updateSignalPlot(obj, selectedRoi, mode)
        % Update signal plot
            if ~obj.btnShowSignal.Value || isempty(selectedRoi)
                return
            end
        
            if ~ishold(obj.axSignalPlot)
               hold(obj.axSignalPlot, 'on') 
            end
            
            yyaxis(obj.axSignalPlot, 'left')
            
            fields = fieldnames(obj.signalArray);
            fields = setdiff(fields, {'spkThr', 'spkSnr', 'lamPr', 'spikeThreshold'}); % Not a line object
            
            if isequal(mode, 'overwrite')
                obj.axSignalPlot.YLim = [ min(0, obj.axSignalPlot.YLim(1)), max(1, obj.axSignalPlot.YLim(2)) ];
                for i = 1:numel(fields) % Reset data in line handle
                    if ~isempty(obj.hlineSignal.(fields{i}))
                        set(obj.hlineSignal.(fields{i})(end), 'YData', nan)
                    end
                end
                    
            end
            
            %%% Why was this here???
%             pObj = findobj(obj.axImageDisplay, 'Type', 'Patch');
%             delete(pObj)

            colorSelection = {'Blues', 'Greens', 'Oranges', 'Reds', 'Purples'};
            plotColor = utilities.cbrewer('seq', colorSelection{randi(numel(colorSelection))}, 15);
            plotColor = plotColor(5:end, :);
            chNo = obj.currentChannel;
            obj.RoiPlotHandles{chNo}(selectedRoi).Color = plotColor(5, :);
            obj.RoiPlotHandles{chNo}(selectedRoi).LineWidth = 1;
            
            for i = 1:numel(obj.signal2display)
                signalName = obj.signal2display{i};
                colorIdx = find(contains(fields, signalName)) + 2;
                signalData = obj.signalArray(chNo).(signalName)(:, selectedRoi);
            
                if all(isnan(signalData))
                    signalData = obj.extractSignal(selectedRoi, signalName);
                end
                
                if ~isequal(signalName, 'spikes')
                    signalRange = range(signalData(:));
                    signalBounds = [min(signalData(:)), max(signalData(:))] + [-0.1*signalRange, 0.1*signalRange];
                    
                    
                    if isequal(signalName, 'dff') || isequal(signalName, 'denoised')
                        yyaxis(obj.axSignalPlot, 'right')
                        oldYlim = obj.axSignalPlot.YLim;
                        newYlim = [0-0.05*signalRange, max([signalBounds(2), oldYlim(2)])];
                        obj.axSignalPlot.YLim = newYlim;
                    else
                        yyaxis(obj.axSignalPlot, 'left')
                        oldYlim = obj.axSignalPlot.YLim;
                        newYlim = [0-0.05*signalRange, max([signalBounds(2), oldYlim(2)])];
                        obj.axSignalPlot.YLim = newYlim;
                    end

%                     % Update ylimits.
%                     oldYlim = obj.axSignalPlot.YLim;
%                     newYlim = [min([signalBounds(1), oldYlim(1)]), max([signalBounds(2), oldYlim(2)])];
%                     obj.axSignalPlot.YLim = newYlim;  

                    % Plot or update plot data
                    if isempty(obj.hlineSignal.(signalName))
                        obj.hlineSignal.(signalName) = plot(obj.axSignalPlot, signalData, 'LineStyle', '-', 'LineWidth', 1, 'Marker', 'None', 'HitTest', 'off', 'Color', plotColor(colorIdx, :));
                    else
                        switch mode
                            case 'append'
                                obj.hlineSignal.(signalName)(end:end+size(signalData,2)) = plot(obj.axSignalPlot, signalData, 'LineStyle', '-', 'LineWidth', 1, 'Marker', 'None', 'HitTest', 'off', 'Color', plotColor(colorIdx, :));
                            case 'overwrite'
                                set(obj.hlineSignal.(signalName)(end), 'YData', signalData, 'Color', plotColor(colorIdx, :))
                        end
                    end
            
                elseif isequal(signalName, 'spikes')
                    yyaxis(obj.axSignalPlot, 'right')
                    
                    if obj.signalExtractionSettings.filterSpikesByNoiseLevel
                        dff = obj.signalArray(chNo).dff(:, selectedRoi);
                        den = obj.signalArray(chNo).denoised(:, selectedRoi);
                        samples2ignore = signalExtraction.spikeEstimation.getSpikeFilter(dff, den);
                        signalData(samples2ignore) = 0;
                    end
                    
                    [X, Y] = utilities.createscatterhistogram(signalData);
                    yLim = obj.axSignalPlot.YLim;
                    rescaleSp = @(Y, b) ((Y-1) * range(yLim) * 0.01) + yLim(1) + (range(yLim) * b);
                    Y = rescaleSp(Y, 0.9);
                    
                    if isempty(obj.hlineSignal.(signalName))
                        obj.hlineSignal.(signalName) = plot(obj.axSignalPlot, X, Y, '.', 'HitTest', 'off', 'Color', plotColor(colorIdx, :));
                    else
                        switch mode
                            case 'append'
                                obj.hlineSignal.(signalName)(end+1) = plot(obj.axSignalPlot, X, Y, '.', 'HitTest', 'off', 'Color', plotColor(colorIdx, :));
                            case 'overwrite'
                                set(obj.hlineSignal.(signalName)(end), 'XData', X, 'YData', Y, 'Color', plotColor(colorIdx, :))
                        end
                    end
                end
            end
            
            % Set yticks and height of framemarker
            obj.axSignalPlot.YTick = [0, floor(obj.axSignalPlot.YLim(2))];
            yyaxis(obj.axSignalPlot, 'left')
            obj.updateFrameMarker('update_y')
            updateSelectedFramePatch(obj, 'update_y')
            
        end
        

        function resetSignalPlot(obj)
            
            signalNames = {'roiMeanF', 'npilMediF', 'demixedMeanF', 'dff', ...
                            'deconvolved', 'denoised', 'spikes'};
            
            lines = findobj(obj.axSignalPlot, 'Type', 'Line');
            delete(lines(1:end-1))
            
            for h = 1:numel(signalNames)
                if ~isempty(obj.hlineSignal.(signalNames{h}))
                    delete(obj.hlineSignal.(signalNames{h})(:))
                end
                obj.hlineSignal.(signalNames{h}) = gobjects(0);
            end


            for h = 1:numel(obj.signal2display)
                if isgraphics(obj.hlineSignal.(obj.signal2display{h}))
                    obj.hlineSignal.(obj.signal2display{h}).Visible = 'on';
                end
            end
            
        end
        
        
% % % % Methods for playing images as video
        
        function obj = playVideo(obj, ~, ~)
            % Callback for play button. Plays calcium images as video
            
            if obj.btnPlayVideo.Value
                
                  % AREE : loop when asked for play
                  if obj.currentFrameNo >= obj.nFrames - (obj.playbackspeed+1)
                      src.Value = round(1-obj.currentFrameNo);
                      obj.changeFrame(src, [], 'playvideo');
                  end
                
                while obj.currentFrameNo < obj.nFrames - (obj.playbackspeed+1)
                    t1 = tic;
                    src.Value = obj.playbackspeed;
                    obj.changeFrame(src, [], 'playvideo');
                    if ~ obj.btnPlayVideo.Value
                        break
                    end
                    t2 = toc(t1);
                    pause(0.033 - t2)
                end
                
                obj.btnPlayVideo.Value = 0;
            end
            
        end
        
        
        function obj = buttonCallback_SetPlaybackSpeed(obj, source, ~)
            % Todo set to 1 if none of the buttons are active
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
            
            if ~obj.btn2x.Value && ~obj.btn4x.Value && ~obj.btn8x.Value
                obj.playbackspeed = 1;
            end
            
            
        end
        
        
% % % % Color settings
        
        function color = getRoiColor(obj, roi)
        % Return a color for the roi based on which group it belongs to.

            groupmatch = cellfun(@(x) strcmp(x, roi.Group), obj.roiClasses, 'uni', 0);
            if any(cell2mat(groupmatch))
                color = obj.roiColors{cell2mat(groupmatch)};
            else
                color = 'red';
            end
        end
            
        
        function newFrame = setChColors(obj, caframe)
        % Creates an rgb frame based on channel color settings
        
            % Preallocate new frame
            newFrame = zeros(obj.imHeight, obj.imWidth, 3, 'like', caframe);
            
            % Go through image for each loaded channel and put in right
            % color channel of newFrame
            for i = 1:numel(obj.loadedChannels)
                colorIdx = cellfun(@(chID) strcmp(chID, obj.loadedChannels{i}), obj.channelIds);
                color = obj.channelColors{colorIdx};
                switch color
                    case 'red'
                        newFrame(:,:,1) = newFrame(:,:,1) + caframe(:,:, i);
                    case 'green'
                        newFrame(:,:,2) = newFrame(:,:,2) + caframe(:,:, i);
                    case 'blue'
                        newFrame(:,:,3) = newFrame(:,:,3) + caframe(:,:, i);
                    case 'yellow'
                        newFrame(:,:,[1, 2]) = newFrame(:,:,[1, 2]) + repmat(caframe(:,:,i), 1,1,2).*0.5;
                end
                
            end
            
            % Quick way to scale image if colors are overlapped.
            maxVal = max(newFrame(:));
            if maxVal > 255; newFrame = newFrame / maxVal; end
        end
        
        
% % % % Quit callback
        
        function quitRoimanager(obj, ~, ~)
        % Close figure callback. delete obj and close figure
        

            % Close figure
            closereq
            
            % Delete obj
            delete(obj)
            
            warning('on', 'MATLAB:dispatcher:nameConflict')
        
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
            [szY, szX] = size(roi.mask);
            if x > szX || y > szY
                bool = false;
            elseif roi.mask(round(y), round(x))
                bool = true;
            else
                bool = false;
            end
            
        end

        
        function [ imArray ] = stack2mat( stackPath, wb_on, msg)
            %STACK2MAT loads a tiff stack into an uint8 3dim array
            %   Y = STACK2MAT(filepath) is an uint8 3 dim array of images from specified file
            %
            %   Y = STACK2MAT(filepath, true) loads the file and opens 
            %   a waitbar to show progress while loading the file.


            % Default: waitbar is off
            if nargin < 2
                wb_on = false;
            end

            tiffFile = Tiff(stackPath, 'r');

            initialFrame = tiffFile.currentDirectory();

            % Get number of frames
            n = 1;
            tiffFile.setDirectory(1);
            complete = tiffFile.lastDirectory();
            while ~complete
                tiffFile.nextDirectory();
                n = n + 1;
                complete = tiffFile.lastDirectory();
            end

            % Get image dimensions and create empty array
            nRow = tiffFile.getTag('ImageLength');
            nCol = tiffFile.getTag('ImageWidth');
            imArray = zeros(nRow, nCol, n, 'uint8');

            if wb_on; h = waitbar(0, msg); end

            % Load images to array
            tiffFile.setDirectory(1);
            imArray(:,:,1) = tiffFile.read();
            for i = 2:n
                tiffFile.nextDirectory();
                imArray(:,:,i) = tiffFile.read();

                if mod(i, 100) == 0 && wb_on
                    waitbar(i/n, h)
                end

            end

            if wb_on; close(h); end

            tiffFile.setDirectory(initialFrame);
        end
        
    end
    
end


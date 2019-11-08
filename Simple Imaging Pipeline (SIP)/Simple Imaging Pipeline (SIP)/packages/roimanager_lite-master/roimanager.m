classdef roimanager < handle

    %GUI for drawing rois and exploring signals.
    %
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
        USE_DEFAULTSETTINGS = false
        darkMode = false; % Might cause java errors..
        version = '2019_08_20'
    end
    
    
    properties % User settings...

        % User settings
        
        fileSettings = struct(...
            'initPath', '', ...
            'chExpr', 'ch', ...                   % str before channel number in filename
            'ptExpr', 'part', ...                 % str before part number in filename
            'sIdExpr', 'm\d*-\d*-\d*-\d*', ...    % sessionId = m0100-20180101-1200-001
            'roiArrayPath', fullfile('..', 'roi_signals'), ...
            'signalPath', fullfile('..', 'roi_signals') );
        
        signalExtractionSettings = struct(...
            'dffMethod', struct('Alternatives', {{'dffRoiMinusDffNpil'}}, 'Selection', {'dffRoiMinusDffNpil'}), ...
            'autoSegmentationMethod', struct('Alternatives', {{'CaImAn', 'Suite2P', 'Able'}}, 'Selection', {'CaImAn'}), ...
            'extractNeuropil', true, ...
            'neuropilExtractionMethod', struct('Alternatives', {{'None', 'Standard', 'Fissa'}}, 'Selection', {'Standard'}), ... 
            'deconvolveSignal', true, ...
            'deconvolutionMethod', struct('Alternatives', {{'CaImAn', 'Suite2P'}}, 'Selection', {'CaImAn'}), ...
            'deconvolutionType', struct('Alternatives', {{'ar1', 'ar2', 'exp2', 'autoar'}}, 'Selection', {'ar2'}), ...
            'extractFromFiles', true, ...
            'fps', 31, ...
            'caimanParameters', struct('spkSnr', 0.99, 'lamPr', 0.5, 'tauDr', [550, 150]), ...
            'filterSpikesByNoiseLevel', true, ...
            'extractSignalsInBackground', true, ...
            'savePath', fullfile('..', 'roisignals'));
%             'spikeEstimationParameters', struct('spikeThreshold', 0.05, 'noiseFilter', true), ...

            settings = struct(...       % GUI settings
            'synchRoisAcrossChannels', false, ...
            'useReferenceChannel', false, ...
            'showTags', false, ...
            'nElementsLog', 50, ...
            'showNpMask', false, ...
            'showNpSignal', false, ...
            'lockScrollInDrawMode', false, ...
            'panFactor', 0.1, ...                       % Determines image shift when using arrow keys
            'zoomFactor', 0.25, ...                     % Determines zoom when using zoom keys (z and Z)
            'scrollFactor', 1, ...                      % Determines how fast to scroll through frames 
            'showWaitbar', true, ...
            'saveEnhancedRoiImages', true, ...          % Will save the enhanced ROI image from GUI when using "Save Rois"
            'saveSquareEnhancedRoiImages',true, ...     % Will save the above enhanced ROI images as 52 x 52 pixel images. TIP: Set this to false if working with longer ROIs, like dendrites, axons..
            'openRoiFigure', false);
        
        initPath = '';                 % Path to start browsing from
        
        % Pan and zoom factors for image window
        binningSize = 9;                % Bin size used for moving averages or maximums.

        % Different roi classes, their abbreviations, and color for plots.
        roiClasses = {'Neuronal Soma', 'Neuronal Dendrite', 'Neuronal Axon', 'Neuropill','Astrocyte Soma','Astrocyte Endfoot','Astrocyte Process','Gliopill', 'Artery', 'Vein', 'Capillary'};
        roiTags = {'NS', 'ND', 'NA','Np','AS', 'AE', 'AP','Gp','Ar','Ve','Ca'}
        roiColors = {'Red', 'Green', [.96 .65 .027], [.75 .5 0], [.96 .45 .027], [0.016 .61 .51], [.63 .90 .02], [.067 .48 0], [.24 .09 .66], [.43 .051 .64], [.76, .02 .47]}
        

        % Channel settings
        channelIds = {'1', '2', '3', '4'}
        channelColors = {'yellow', 'red', 'green', 'blue'}
        celltypes = {'', 'astrocytes', 'neurons', ''}
    
    end
    
    
    properties % Gui components and settings
        
        % Figure and figure settings
        
        fig                             % GUI Figure Window
        imfig

        % UI panels and axes
        panels = struct()       % left, center, right
        uiaxes = struct()       % imagedisplay, signalplot, smallroi

        
        % Handles to objects that will be displayed on the axes
        himage                          % Image object for the displayed image
        himageCurrentRoi
        
        hroiLineOverlay
        hlineSignal = struct()          % Line handle for signals in signal plot
        hlineCurrentFrame               % Line handle for vertical line showing current frame in signal plot
        hlineTmpRoi                     % Line handle for temporary lines of roi polygon
        hlineRoiTemplate                % Line handle of roitemplate for autodetection
        hlineCurrentFrame2
        hpatchFrameSelection
        
        doDrawRoiOutline = false
        hRoiOutline = gobjects(1)
        
        % Image dimensions
        
        imWidth                         % Width (pixels) of images in image time series
        imHeight                        % Height (pixels) of images in image time series
        nFrames = 1                     % Number of frames in image time series
        
        % Roi handles for creating and displaying rois
        
        tmpImpoints                     % A list of impoints for the temporary roi polygon
        selectedImpoint                 % Number of selected impoint
        tmpRoiPosX                      % X coordinate values of the temporary roi
        tmpRoiPosY                      % Y coordinate values of the temporary roi
        RoiPlotHandles = {}             % A list of plot handles for all finished rois
        RoiTextHandles = {}             % A list of text handles for all finished rois
        RoiLinePos
        RoiTextPos
        roiOuterDiameter = 10;          % Roi diameter in pixels used for autodetection
        roiInnerDiameter = 5;           % Roi inner diameter in pixels used for autodetection
        roiDisplacement = 0;            % Temporary "keeper" of roi displacement if rois are moved
        circleToolHandle
        circleToolCoords
        crosshairHandle
        
        % Data which is loaded into gui
        
%         imdata = struct('TSeries', {}, 'Projections', {})
        
        imgTseries = {}                 % A Tseries of images on which to draw roi (cell array of matrices, one per channel)
        imgTseriesMedfilt = {}          % A Tseries of images which are median filtered (cell array of matrices, one per channel)
%         imProjections = struct('avg', {}, 'max', {}, 'cn', {}, 'ec', {});
        imgAvg = {}                     % An average projection image of the tiff stack
        imgMax = {}                     % An maximum projection image of the tiff stack
        imgCn = {}                      % A correlation image
        imgBa = {}                      % A boosted activity image
        roiArray = {}                   % A cell array of arrays of RoI objects
        
        clipboardRois = {};
        signalArray = struct            % A struct array with different signals for each roi and each channel.
        selectedRois                    % Numbers of the selected/active rois                   
        unselectedRois
        actionLog
        logPosition
        lastLogPosition
        cnmfData = []
        cnmfResults = []
        
        % GUI state properties
        sessionObj
        dataViewer
        
        channel                         % Edit input box to set active channel
        loadedChannels                  % Channel ID of loaded channels
        nLoadedChannels                 % Number of loaded channels
        activeChannel = 1               % Number of active channel(s) which user interacts with (numeric index for loadedChannels)
        channelDisplayMode = 'single'   % Variable used internally for setting display mode
        currentFrameNo = 0              % Number of the current frame which is displayed
        selectFrameMode
        selectedFrames
        roiCount = {}                   % A counter for the number of rois that have been drawn
        playbackspeed = 1
        signal2display = {'dff'}
        
        % Mouse state and recorded cursor positions
        
        mouseMode = 'Select'            % MouseMode ('Draw' or 'Select')
        mouseModePrev                   % Previous active mousemode
        mouseDown = 0                   % Indicates if mouse button is pressed
        prevMouseClick                  % Axes coordinates when mouse was last clicked.
        prevMousePointAx                % Needed for moving RoIs. Last registered axes coordinates
        prevMousePointFig               % Needed for panning image display in select mode
        roiTemplateCenter               % Needed when setting the roi diameter
        zoomRectPlotHandle              % Handle for rectangle plot when drag-zooming
        zoomOutline
        
        % Filepaths
        loadedFileName                  % Filename of loaded image file (cell array, one fnm per channel)
        
        % Buttons
        uiButtons = struct();
        uiSliders = struct();
        uiInputs = struct();
        uiControls = struct();
        
        connectedRoiInfo
        editSpikeThresh
        editSpikeSNR
        editLambdaPr
        editTauRise
        editTauDecay
        
        
        dropdownImplementation
        dropdownMethod
        sliderTauDecay
        sliderTauDecayContainer
        sliderTauRise
        sliderTauRiseContainer
        textannotations
        
        % Other UIcontrols
        
        popupRoiclass                   % Popupmenu for selecting roi type/Groupname

        boolOverfilled
        inputJumptoFrame                % Input field to display specified frame in image display
        inputSetBinningSize             % Input field to set binning size for moving averages
        textCurrentFrame                % Textstring that shows which frame is displayed
        textCurrentFileName             % Textstring with current filename
        roiListBox                      % A listbox containing the name of all rois
        frameslider                     % A sliderbar for scrolling through frames
        fsContainer

        roiSizeSlider                   % A sliderbar to set the roisize for autodetection
        roiSizeSliderContainer          % A container for the roi size sliderbar
        brightnessSlider
        brightnessSliderContainer
        brightnessDictionary = struct('avg', struct('min', 1, 'max', 255), ...
                                      'max', struct('min', 1, 'max', 255), ...
                                      'norm', struct('min', 1, 'max', 255) )
        editExpName
        
    end
    
    
    
    methods (Access = 'private', Hidden = true)
        
        
        function initializeGui(obj)

            obj.createGuiFigure()
            obj.createMenu()
            obj.createGuiPanels()
            obj.loadSettings()
            obj.createComponentsLeftPanel()
            obj.createComponentsImagePanel()
            obj.createComponentsRightPanel()
            obj.initializeScroller()
            obj.initializeActionLog()

            % Activate callback functions
            obj.fig.WindowButtonMotionFcn = @obj.mouseOver;
            obj.fig.SizeChangedFcn = @obj.figsizeChanged;

            % SetTheme
            if obj.darkMode
                enterDarkMode(obj)
            end
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
            
            % static method to get ToolTipManager object
            tm = javax.swing.ToolTipManager.sharedInstance;
            % set tooltips to appear immediately
            javaMethodEDT('setInitialDelay',tm,0); 
            
        end
        
        
        function figsizeChanged(obj, ~, ~)
        % Callback function to resize/move ui panels if figuresize changes
        
            obj.positionMainPanels()
            
            % Scale frameslider to keep same width as panelImage
            obj.fsContainer.Position([1,3]) = obj.panels.image.Position([1,3]);
            
            % Adjust size of image axes if signal plot is open
            if obj.uiButtons.ShowSignal.Value
                set(obj.uiaxes.imagedisplay, 'Position', [0.12, 0.20, 0.77, 0.77])
            end
            
            buttons = struct2cell(obj.uiButtons);
            if ~isempty(buttons{1}.UserData)
                for i = 1:numel(buttons)
                   customization.configureButton(buttons{i}, buttons{i}.UserData)
                end
            end

        end
        
        
        function createMenu(obj)
            
            % Create a 'roimanager' menu category
            try
                m = uimenu(obj.fig, 'Text','Roimanager');
                textKey = 'Text';
                callbackKey = 'MenuSelectedFcn';
            catch
                m = uimenu(obj.fig, 'Label','Roimanager');
                textKey = 'Label';
                callbackKey = 'Callback';
            end
            
            mitem = uimenu(m, textKey,'Check for Updates', 'Enable', 'off');
%             mitem.(callbackKey) = @obj.update;
            mitem = uimenu(m, textKey,'Quit Roimanager', 'Separator', 'on');
            mitem.(callbackKey) = @obj.quitRoimanager;
            

            % File menu category
            m = uimenu(obj.fig, textKey, 'File');
            mitem = uimenu(m, textKey,'Load Images');
            mitem.(callbackKey) = @obj.loadStack;
            mitem = uimenu(m, textKey,'Load Rois');
            mitem.(callbackKey) = @obj.loadRois;
            mitem = uimenu(m, textKey,'Save Rois', 'Separator', 'on');
            mitem.(callbackKey) = {@obj.saveRois, 'Standard'};
            mitem = uimenu(m, textKey,'Save Rois as...');
            mitem.(callbackKey) = {@obj.saveRois, 'Open browser'};
            
            mitem = uimenu(m, textKey,'Save Signals');
            mitem.(callbackKey) = {@obj.saveSignal, 'Standard'};
            mitem = uimenu(m, textKey,'Save Signals as...');
            mitem.(callbackKey) = {@obj.saveSignal, 'Open browser'};
            
            % Create a 'edit' menu category
            m = uimenu(obj.fig, textKey,'Edit');
            mitem = uimenu(m, textKey,'Split Roi (shift-s)');
            mitem.(callbackKey) = @obj.splitRois;
            mitem = uimenu(m, textKey,'Merge Rois (shift-m)');
            mitem.(callbackKey) = @obj.mergeRois;
            mitem = uimenu(m, textKey,'Connect Rois (shift-c)');
            mitem.(callbackKey) = @obj.connectRois;
            mitem = uimenu(m, textKey,'Create Donuts (shift-d)');
            mitem.(callbackKey) = @obj.createDonutRois;
            mitem = uimenu(m, textKey,'Tag Rois as Unchecked (shift-u)');
            mitem.(callbackKey) = {@obj.tagRois, 'unchecked'};
            mitem = uimenu(m, textKey,'Select Frames', 'Separator', 'on');
            mitem.(callbackKey) = @obj.menuCallback_SelectFrames;
            mitem = uimenu(m, textKey,'Reset Frame Selection');
            mitem.(callbackKey) = @obj.menuCallback_ResetFrameSelection;
            mitem = uimenu(m, textKey,'Send RoI Cube to WS');
            mitem.(callbackKey) = @obj.menuCallback_RoiToWorkspace;
              
            % Create an image menu category
            m = uimenu(obj.fig, textKey, 'Image');
            mitem = uimenu(m, textKey,'Apply Okada Filter');
            mitem.(callbackKey) = {@obj.filterImage, 'okada'};
            mitem = uimenu(m, textKey,'Show Brightness Enhanced Image');
            mitem.(callbackKey) = @(src, event) obj.updateImageDisplay('BrightnessEqualized');
            mitem = uimenu(m, textKey,'Show Gradient Image');
            mitem.(callbackKey) = @(src, event) obj.updateImageDisplay('Gradient Image');
            mitem = uimenu(m, textKey,'Calculate Correlation Image');
            mitem.(callbackKey) = @obj.showCorrelationImage;
            mitem = uimenu(m, textKey,'Calculate Boosted Activity Image');
            mitem.(callbackKey) = @obj.showBoostedActivityImage;
            
            
            % Create a 'tools' menu category
            m = uimenu(obj.fig, textKey, 'Tools');
            mitem = uimenu(m, textKey, 'Validate Rois');
            mitem.(callbackKey) = @obj.validateRois;
%             mitem.(callbackKey) = @(src, event)obj.setMouseMode('Curate');

            mitem = uimenu(m, textKey, 'Apply Rois to Other Sessions', 'Separator', 'on');
            mitem.(callbackKey) = @obj.applyRoisToOtherSessions;
            mitem = uimenu(m, textKey, 'Load Rois from Other Sessions');
            mitem.(callbackKey) = @obj.loadRoisFromOtherSessions;
            mitem = uimenu(m, textKey, 'Reposition Rois ...');
            mitem.(callbackKey) = @obj.repositionRois;
            mitem = uimenu(m, textKey, 'Open Roi Figure on Selection', 'Separator', 'on');
            mitem.(callbackKey) = @obj.setObjectVisibility;
            mitem = uimenu(m, textKey, 'Run Seudo', 'Separator', 'on');
            mitem.(callbackKey) = @obj.runSeudo;
            
            % Create a 'show' menu category
            m = uimenu(obj.fig, textKey,'Show');
            mitem = uimenu(m, textKey,'Show Numbers');
            mitem.(callbackKey) = @obj.setObjectVisibility;
            mitem = uimenu(m, textKey,'Hide Roi Outlines');
            mitem.(callbackKey) = @obj.setObjectVisibility;
            mitem = uimenu(m, textKey,'Show Neuropil Mask');
            mitem.(callbackKey) = @obj.setObjectVisibility;
% % %             mitem = uimenu(m, textKey,'Show Neuropil Signal');
% % %             mitem.(callbackKey) = @obj.setObjectVisibility;
            %Todo
            mitem = uimenu(m, textKey, 'Show Roi Correlation Matrix');
            mitem.(callbackKey) = @obj.setObjectVisibility;
            mitem = uimenu(m, textKey, 'Show Roi Correlation Image');
            mitem.(callbackKey) = @obj.showRoiCorrelationImage;
            
            mitem = uimenu(m, textKey,'Color Roi By', 'Separator', 'on');
            alternatives = {'Activity Level', 'Category', 'Validation Status'};
            for i = 1:numel(alternatives)
                tmpItem = uimenu(mitem, textKey, alternatives{i});
                tmpItem.(callbackKey) = @obj.menuCallback_setRoiColoringScheme;
            end
            
            
            mitem = uimenu(m, textKey,'Set Colormap');
            colormapNames = {'Viridis', 'Inferno', 'Magma','Plasma', 'Nissl', ...
                'BuPu', 'GnBu', 'Greens', 'PuBuGn', 'YlOrRd', 'PuOr', 'Gray', ...
                'thermal', 'haline', 'solar', 'ice', 'gray', 'oxy', 'deep', 'dense', ...
                'algae','matter','turbid','speed', 'amp','tempo' };
            for i = 1:numel(colormapNames)
                tmpItem = uimenu(mitem, textKey, colormapNames{i});
                tmpItem.(callbackKey) = @obj.menuCallback_ChangeColormap;
            end
 
            % Create a 'settings' menu category
            m = uimenu(obj.fig, textKey,'Settings');
            mitem = uimenu(m, textKey,'Edit General Settings');
            mitem.(callbackKey) = @obj.editGuiSettings;
            mitem = uimenu(m, textKey,'Edit File Settings');
            mitem.(callbackKey) = @obj.editGuiSettings;
            mitem = uimenu(m, textKey,'Edit Signal Settings');
            mitem.(callbackKey) = @obj.editGuiSettings;
            mitem = uimenu(m, textKey,'Reset Image Display', 'Separator', 'on');
            mitem.(callbackKey) = @obj.resetImageDisplay;
            mitem = uimenu(m, textKey,'Reset Roi Data');
            mitem.(callbackKey) = @obj.resetRoi;
            mitem = uimenu(m, textKey,'Enter Dark Mode', 'Separator', 'on');
            mitem.(callbackKey) = @(src, event) obj.enterDarkMode;
            
            m = uimenu(obj.fig, textKey, 'Help');
            m.(callbackKey) = @(src, event) roimanager.showHelp;
           
            
        end
        
        
        function createGuiPanels(obj)
        % Create Panels for the GUI
            
            % Initialize the main panels
            obj.panels.left     = uipanel('Title', 'Image Controls');
            obj.panels.image    = uipanel('Title', 'Image Viewer');
            obj.panels.right    = uipanel('Title', 'RoiManager');
            
            % Set common properties of the main panels
            mainPanels = struct2cell(obj.panels);
            set([mainPanels{:}], 'Parent', obj.fig)
            set([mainPanels{:}], 'FontSize', 12)
            obj.positionMainPanels()
            
            
            set(obj.panels.image, 'units', 'pixel')
            panelAR = (obj.panels.image.Position(3) / obj.panels.image.Position(4));
            set(obj.panels.image, 'units', 'normalized')

            % Add the ax for image display to the image panel. (Use 0.03 units as margins)
            obj.uiaxes.imagedisplay = axes('Parent', obj.panels.image);
            obj.uiaxes.imagedisplay.XTick = []; 
            obj.uiaxes.imagedisplay.YTick = [];
            obj.uiaxes.imagedisplay.Position = [0.02/panelAR, 0.01, 0.96/panelAR, 0.96];
    
            % Add axes for plotting signals
            obj.uiaxes.signalplot = axes('Parent', obj.panels.image);
            obj.uiaxes.signalplot.XTick = []; 
            obj.uiaxes.signalplot.YTick = [];
            obj.uiaxes.signalplot.Position = [0.03, 0.01, 0.94, 0.15];
            obj.uiaxes.signalplot.Visible = 'off';
            obj.uiaxes.signalplot.Box = 'on';
            obj.uiaxes.signalplot.ButtonDownFcn = @obj.mousePressPlot;
            hold(obj.uiaxes.signalplot, 'on')                   


        end
        
        
        function positionMainPanels(obj)
            
            % Find aspectratio of figure 
            figsize = get(obj.fig, 'Position');
            aspectRatio = figsize(3)/figsize(4);

            % Specify obj.margins (for figure window) and obj.padding (space between objects)
            margins = 0.03 ./ [aspectRatio, 1];  %sides, top/bottom
            padding = 0.05 ./ [aspectRatio, 1];  %sides, top/bottom

            % Calculate UI panel positions
            imagePanelSize = [0.945/aspectRatio, 0.945]; % This panel determines the rest.
            availableWidth = 1 - imagePanelSize(1) - margins(1)*2 - padding(1)*2;
            lSidePanelSize = [availableWidth/3*1, 0.945];
            rSidePanelSize = [availableWidth/3*2, 0.945];

            lSidePanelPos = [margins(1), margins(2), lSidePanelSize];
            imagePanelPos = [margins(1) + lSidePanelSize(1) + padding(1), margins(2), imagePanelSize];
            rSidePanelPos = [imagePanelPos(1) + imagePanelSize(1) + padding(1), margins(2), rSidePanelSize];

            % Position the panels
            obj.panels.left.Position = lSidePanelPos;
            obj.panels.image.Position = imagePanelPos;
            obj.panels.right.Position = rSidePanelPos;
            
        end
        
        
        function createComponentsLeftPanel(obj)
        % Create ui controls of left side panel
            
            txtExpName = uicontrol('Style', 'text');
            txtExpName.Parent = obj.panels.left;
            txtExpName.String = 'Experiment Name:';
            txtExpName.HorizontalAlignment = 'Left';
            txtExpName.FontSize = 14;
            txtExpName.Units = 'normalized';
            txtExpName.Position = [0.1, 0.94, 0.8, 0.04];
            
            obj.editExpName = uicontrol('Style', 'edit');
            obj.editExpName.Parent = obj.panels.left;
            obj.editExpName.String = '';
            obj.editExpName.HorizontalAlignment = 'Left';
            obj.editExpName.Units = 'normalized';
            obj.editExpName.Position = [0.1, 0.91, 0.8, 0.03];
            
            
            btnPosL = [0.1, 0.84, 0.85, 0.04];
            obj.uiButtons.LoadImages = uicontrol('Style', 'pushbutton',...
                'Parent', obj.panels.left, ...
                'String', 'Load Images', ...
                'Units', 'normalized', ...
                'Position', btnPosL, ...
                'Callback', @obj.loadStack);

            uiTextPos = [0.1, btnPosL(2) - 0.05, 0.5, 0.025];
            tmp = uicontrol('Style', 'text', ...
                'Parent', obj.panels.left, ...
                'String', 'Enter channel', ...
                'HorizontalAlignment', 'left', ...
                'Units', ...
                'normalized', 'Position', uiTextPos);

            obj.centerAlignHandle(tmp, tmp.Position(2)+tmp.Position(4)/2)

            
            uiEditPos = [uiTextPos(1) + uiTextPos(3) + 0.025, uiTextPos(2), 0.25, 0.025];
            obj.channel = uicontrol('Style', 'edit', 'Parent', obj.panels.left, ...
                                        'String', '1', ...
                                        'Units', 'normalized', ...
                                        'Position', uiEditPos, ...
                                        'Callback', @obj.changeActiveChannel);
            obj.centerAlignHandle(obj.channel, tmp.Position(2)+tmp.Position(4)/2)

            btnPosL(2) = uiTextPos(2) - 0.05;
            obj.uiButtons.ShowSingleChannel = uicontrol('Style', 'pushbutton', ...
                'Parent', obj.panels.left, ...
                'String', 'Show All Channels', ...
                'Units', 'normalized', 'Position', btnPosL, ...
                'Callback', @obj.changeChannelDisplayMode);

            btnPosL(2) = btnPosL(2) - 0.08; 
            obj.uiButtons.ShowCurrentFrame = uicontrol('Style', 'pushbutton', 'Parent', obj.panels.left, ...
                                        'String', 'Show Current Frame', ...
                                        'Units', 'normalized', 'Position', btnPosL, ...
                                        'Callback', @obj.showStack);                         

            btnPosL(2) = btnPosL(2) - 0.05;                        
            obj.uiButtons.ShowAvg = uicontrol('Style', 'togglebutton', 'Parent', obj.panels.left, ...
                                        'String', 'Show Avg (n/b)', ...
                                        'Units', 'normalized', 'Position', btnPosL, ...
                                        'Callback', @obj.showAvg);

            btnPosL(2) = btnPosL(2) - 0.05;                           
            obj.uiButtons.ShowMax = uicontrol('Style', 'togglebutton', 'Parent', obj.panels.left, ...
                                        'String', 'Show Max (9)', ...
                                        'Units', 'normalized', 'Position', btnPosL, ...
                                        'Callback', @obj.showMax);

            sliderPos = [0.1, btnPosL(2) - 0.04, 0.8, 0.03];                     
            jSlider = com.jidesoft.swing.RangeSlider(0, 255, 0, 255);
            [obj.brightnessSlider, obj.brightnessSliderContainer] = javacomponent(jSlider);
            obj.brightnessSlider = handle(obj.brightnessSlider, 'CallbackProperties');
            set(obj.brightnessSlider, 'StateChangedCallback', @obj.changeBrightness);
            set(obj.brightnessSliderContainer, 'Parent', obj.panels.left, 'units', 'normalized', 'Position', sliderPos)

            uiTextPos(2) = sliderPos(2) - 0.08;
            tmp = uicontrol('Style', 'text', 'Parent', obj.panels.left, ...
                      'String', 'Go to frame', ...
                      'HorizontalAlignment', 'left', ...
                      'Units', 'normalized', 'Position', uiTextPos);
            obj.centerAlignHandle(tmp, tmp.Position(2)+tmp.Position(4)/2)

            uiEditPos(2) = uiTextPos(2) + 0.005;
            obj.inputJumptoFrame = uicontrol('Style', 'edit', 'Parent', obj.panels.left, ...
                                        'String', 'N/A', ...
                                        'Units', 'normalized', ...
                                        'Position', uiEditPos, ...
                                        'Callback', {@obj.changeFrame, 'jumptoframe'});

            obj.centerAlignHandle(obj.inputJumptoFrame, tmp.Position(2)+tmp.Position(4)/2)
                                    
                                    
            btnPosL(2) = uiTextPos(2) - 0.08;                        
            obj.uiButtons.ShowMovingAvg = uicontrol('Style', 'togglebutton', 'Parent', obj.panels.left, ...
                                        'String', 'Show Moving Average', 'Value', 0, ...
                                        'Units', 'normalized', 'Position', btnPosL, ...
                                        'Callback', @obj.showMovingAvg);     

            btnPosL(2) = btnPosL(2) - 0.05;                        
            obj.uiButtons.ShowMovingStd = uicontrol('Style', 'togglebutton', 'Parent', obj.panels.left, ...
                                        'String', 'Show Moving Std', 'Value', 0, ...
                                        'Units', 'normalized', 'Position', btnPosL, ...
                                        'Callback', @obj.showMovingStd); 

            btnPosL(2) = btnPosL(2) - 0.05;                        
            obj.uiButtons.ShowMovingMax = uicontrol('Style', 'togglebutton', 'Parent', obj.panels.left, ...
                                        'String', 'Show Moving Maximum', 'Value', 0, ...
                                        'Units', 'normalized', 'Position', btnPosL, ...
                                        'Callback', @obj.showMovingMax); 

            uiTextPos(2) = btnPosL(2) - 0.05;
            tmp = uicontrol('Style', 'text', 'Parent', obj.panels.left, ...
                      'String', 'Set Bin Size', ...
                      'HorizontalAlignment', 'left', ...
                      'Units', 'normalized', 'Position', uiTextPos);
            uiEditPos(2) = uiTextPos(2) + 0.005;
            
            obj.centerAlignHandle(tmp, tmp.Position(2)+tmp.Position(4)/2)

            obj.inputSetBinningSize = uicontrol('Style', 'edit', 'Parent', obj.panels.left, ...
                                        'String', num2str(obj.binningSize), ...
                                        'Units', 'normalized', ...
                                        'Position', uiEditPos, ...
                                        'Callback', @obj.changeBinningSize);

            obj.centerAlignHandle(obj.inputSetBinningSize, tmp.Position(2)+tmp.Position(4)/2)
                                    
            btnPosL(2) = uiTextPos(2) - 0.08; 
            obj.uiButtons.RunAutoSegmentation = uicontrol('Style', 'pushbutton', 'Parent', obj.panels.left, ...
                                        'String', 'Run Auto Segmentation', ...
                                        'Units', 'normalized', 'Position', btnPosL, ...
                                        'Callback', @obj.runAutoSegmentation, ...
                                        'Enable', 'on');
                                    
   
            
            btnPosL(2) = btnPosL(2) - 0.05;
            obj.uiButtons.ShowSignal = uicontrol('Style', 'togglebutton');
            obj.uiButtons.ShowSignal.Parent = obj.panels.left;
            obj.uiButtons.ShowSignal.String = 'Show Signal';
            obj.uiButtons.ShowSignal.Enable = 'on';
            obj.uiButtons.ShowSignal.Units = 'normalized';
            obj.uiButtons.ShowSignal.Position = btnPosL; 
            obj.uiButtons.ShowSignal.Callback = @obj.showSignalPlot;
            
            btnPosL(2) = btnPosL(2) - 0.05;
            obj.uiButtons.UndockImage = uicontrol('Style', 'pushbutton', 'Parent', obj.panels.left, ...
                                        'String', 'Undock Image Window', ...
                                        'Units', 'normalized', 'Position', btnPosL, ...
                                        'Callback', @obj.undockImageWindow);  
            
            if exist('initialize_components', 'file')
                set(obj.uiButtons.RunAutoSegmentation, 'Enable', 'on')
            end
            
        end
        
        
        function createComponentsImagePanel(obj)
            
            obj.textCurrentFrame = uicontrol('Style', 'text');
            obj.textCurrentFrame.Parent = obj.panels.image;
            obj.textCurrentFrame.String = 'Current frame: N/A';
            obj.textCurrentFrame.Units = 'normalized';
            obj.textCurrentFrame.HorizontalAlignment = 'right';
            obj.textCurrentFrame.Position = [0.78, 0.9725, 0.185, 0.025];

%             obj.textCurrentFileName = uicontrol('Style', 'text', 'Parent', obj.panels.image, ...
%                                         'String', 'Current file: N/A', ...
%                                         'min', 0, 'max', 1, ...
%                                         'units', 'normalized', ...
%                                         'HorizontalAlignment', 'right', ...
%                                         'Position', [0.43, 0.9725, 0.3, 0.025]);

            obj.uiButtons.PlayVideo = uicontrol('Style', 'togglebutton', 'Parent', obj.panels.image, ...
                                        'String', 'Play', ...
                                        'units', 'normalized', ...
                                        'HorizontalAlignment', 'right', ...
                                        'Position', [0.1, 0.975, 0.05, 0.02], ...
                                        'Callback', @obj.playVideo );
            obj.uiButtons.play2x = uicontrol('Style', 'togglebutton', 'Parent', obj.panels.image, ...
                                        'String', '2x', ...
                                        'units', 'normalized', ...
                                        'HorizontalAlignment', 'right', ...
                                        'Position', [0.17, 0.975, 0.04, 0.02], ...
                                        'Callback', @obj.buttonCallback_SetPlaybackSpeed );

            obj.uiButtons.play4x = uicontrol('Style', 'togglebutton', 'Parent', obj.panels.image, ...
                                        'String', '4x', ...
                                        'units', 'normalized', ...
                                        'HorizontalAlignment', 'right', ...
                                        'Position', [0.23, 0.975, 0.04, 0.02], ...
                                        'Callback', @obj.buttonCallback_SetPlaybackSpeed );

            obj.uiButtons.play8x = uicontrol('Style', 'togglebutton', 'Parent', obj.panels.image, ...
                                        'String', '8x', ...
                                        'units', 'normalized', ...
                                        'HorizontalAlignment', 'right', ...
                                        'Position', [0.29, 0.975, 0.04, 0.02], ...
                                        'Callback', @obj.buttonCallback_SetPlaybackSpeed );
            
            obj.uiButtons.Previous = uicontrol('Style', 'pushbutton');
            obj.uiButtons.Previous.Units = 'normalized';
            obj.uiButtons.Previous.Parent = obj.panels.image;
            obj.uiButtons.Previous.String = '<';
            obj.uiButtons.Previous.Position = [0.35, 0.975, 0.02, 0.02];
            obj.uiButtons.Previous.Callback = {@obj.changeFrame, 'prev'};
            
            obj.uiButtons.Next = uicontrol('Style', 'pushbutton');
            obj.uiButtons.Next.Units = 'normalized';
            obj.uiButtons.Next.Parent = obj.panels.image;
            obj.uiButtons.Next.String = '>';
            obj.uiButtons.Next.Position = [0.39, 0.975, 0.02, 0.02];
            obj.uiButtons.Next.Callback = {@obj.changeFrame, 'next'};

            obj.uiButtons.ShowRaw = uicontrol('Style', 'togglebutton');
            obj.uiButtons.ShowRaw.Parent = obj.panels.image;
            obj.uiButtons.ShowRaw.String = 'Show Raw';
            obj.uiButtons.ShowRaw.Value = 0;
            obj.uiButtons.ShowRaw.Units = 'normalized';
            obj.uiButtons.ShowRaw.Visible = 'off';
            obj.uiButtons.ShowRaw.Position = [0.03, 0.17, 0.14, 0.02];
            obj.uiButtons.ShowRaw.Callback = @obj.changeSignalType;
            
            obj.uiButtons.ShowDemixed = uicontrol('Style', 'togglebutton');
            obj.uiButtons.ShowDemixed.Parent = obj.panels.image;
            obj.uiButtons.ShowDemixed.String = 'Show Demixed';
            obj.uiButtons.ShowDemixed.Value = 0;
            obj.uiButtons.ShowDemixed.Units = 'normalized';
            obj.uiButtons.ShowDemixed.Visible = 'off';
            obj.uiButtons.ShowDemixed.Position = [0.22, 0.17, 0.15, 0.02];
            obj.uiButtons.ShowDemixed.Callback = @obj.changeSignalType;
            
            obj.uiButtons.ShowDFF = uicontrol('Style', 'togglebutton');
            obj.uiButtons.ShowDFF.Parent = obj.panels.image;
            obj.uiButtons.ShowDFF.String = 'Show DFF';
            obj.uiButtons.ShowDFF.Value = 1;
            obj.uiButtons.ShowDFF.Units = 'normalized';
            obj.uiButtons.ShowDFF.Visible = 'off';
            obj.uiButtons.ShowDFF.Position = [0.42, 0.17, 0.14, 0.02];
            obj.uiButtons.ShowDFF.Callback = @obj.changeSignalType;
                        
            obj.uiButtons.ShowDenoised = uicontrol('Style', 'togglebutton');
            obj.uiButtons.ShowDenoised.Parent = obj.panels.image;
            obj.uiButtons.ShowDenoised.String = 'Show Denoised';
            obj.uiButtons.ShowDenoised.Value = 0;
            obj.uiButtons.ShowDenoised.Units = 'normalized';
            obj.uiButtons.ShowDenoised.Visible = 'off';
            obj.uiButtons.ShowDenoised.Position = [0.61, 0.17, 0.15, 0.02];
            obj.uiButtons.ShowDenoised.Callback = @obj.changeSignalType;

            obj.uiButtons.ShowSpikes = uicontrol('Style', 'togglebutton');
            obj.uiButtons.ShowSpikes.Parent = obj.panels.image;
            obj.uiButtons.ShowSpikes.String = 'Show Deconvolved';
            obj.uiButtons.ShowSpikes.Value = 0;
            obj.uiButtons.ShowSpikes.Units = 'normalized';
            obj.uiButtons.ShowSpikes.Visible = 'off';
            obj.uiButtons.ShowSpikes.Position = [0.82, 0.17, 0.14, 0.02];
            obj.uiButtons.ShowSpikes.Callback = @obj.changeSignalType;
            
            
            % % Create second row with options for deconvolution

            % Initialize annotations for parameter inputs
            obj.textannotations = arrayfun(@(i) annotation(obj.panels.image, 'textbox'), 1:4, 'uni', 1);
            set(obj.textannotations, ...
                'Visible', 'off', ...
                'LineStyle', 'none', ...
                'HorizontalAlignment', 'right', ...
                'VerticalAlignment', 'middle', ...
                'Position', [0, 0, 0.05, 0.025], ...
                'HitTest', 'off', ...
                'PickableParts', 'none');
            
            centerPos = (obj.uiButtons.ShowRaw.Position(2) - 0.025);
            objpad = 0.05;
            xPos = 0.023;
            
            obj.dropdownImplementation = uicontrol('Style', 'popup');
            obj.dropdownImplementation.Parent = obj.panels.image;
            obj.dropdownImplementation.String = {'Choose Implementation', 'CaImAn', 'Suite2P'};
            obj.dropdownImplementation.Value = find(contains(obj.dropdownImplementation.String, obj.signalExtractionSettings.deconvolutionMethod.Selection));
            obj.dropdownImplementation.Visible = 'off';
            obj.dropdownImplementation.Units = 'normalized';
            obj.dropdownImplementation.Position = obj.uiButtons.ShowRaw.Position - [0,0.035,0,0];
            obj.dropdownImplementation.Callback = @obj.setDeconvolutionImplementation;
            obj.dropdownImplementation.Position(1) = xPos;
            obj.centerAlignHandle(obj.dropdownImplementation, centerPos)

            xPos = sum(obj.dropdownImplementation.Position([1,3]))+0.025;
            
            obj.dropdownMethod = uicontrol('Style', 'popup');
            obj.dropdownMethod.Parent = obj.panels.image;
            obj.dropdownMethod.String = {'Choose Method', 'Ar1', 'Ar2', 'Exp2', 'AutoAr'};
            obj.dropdownMethod.Value = find(contains(lower(obj.dropdownMethod.String), obj.signalExtractionSettings.deconvolutionType.Selection));
            obj.dropdownMethod.Visible = 'off';
            obj.dropdownMethod.Units = 'normalized';
            obj.dropdownMethod.Position = obj.uiButtons.ShowDemixed.Position - [0,0.035,0,0];
            obj.dropdownMethod.Callback = @obj.setDeconvolutionMethod;
            obj.dropdownMethod.Position(1) = xPos;
            obj.centerAlignHandle(obj.dropdownMethod, centerPos)

            xPos = sum(obj.dropdownMethod.Position([1,3]))+objpad;
% 
%             drawnow; pause(0.1);
%             javax.swing.UIManager.setLookAndFeel(originalLnF);
            
%             obj.dropdownImplementation.Visible = 'off';
%             obj.dropdownMethod.Visible = 'off';
            
            sliderPos = obj.uiButtons.ShowDFF.Position - [0, 0.04, 0, -0.01];    
            jSlider = javax.swing.JSlider(0, 1000);
            [obj.sliderTauRise, obj.sliderTauRiseContainer] = javacomponent(jSlider, [10,70,200,45]);
            obj.sliderTauRise = handle(obj.sliderTauRise, 'CallbackProperties');
            set(obj.sliderTauRise, 'StateChangedCallback', @obj.changeTau, 'MouseReleasedCallback', @obj.changeSignalParameter );
            set(obj.sliderTauRise, 'Value', 180, 'Name', 'TauRise', 'tooltip', sprintf('%d ms', 180))
            set(obj.sliderTauRiseContainer, 'Parent', obj.panels.image, 'units', 'normalized', 'Position', sliderPos)
            set(obj.sliderTauRiseContainer, 'Visible', 'off')
            obj.centerAlignHandle(obj.sliderTauRiseContainer, centerPos)
            obj.sliderTauRiseContainer.Position(1) = xPos;

            xPos = sum(obj.sliderTauRiseContainer.Position([1,3]))+objpad;
            
            set(obj.textannotations(1), 'String', '\tau_{rise}', 'FontSize', 11);
            obj.centerAlignHandle(obj.textannotations(1), centerPos)
            obj.textannotations(1).Position(1) = obj.sliderTauRiseContainer.Position(1)-obj.textannotations(1).Position(3);
            
            sliderPos = obj.uiButtons.ShowDenoised.Position - [0, 0.04, 0, -0.01];                  
            jSlider = javax.swing.JSlider(0, 5000);
            [obj.sliderTauDecay, obj.sliderTauDecayContainer] = javacomponent(jSlider);
            obj.sliderTauDecay = handle(obj.sliderTauDecay, 'CallbackProperties');
            set(obj.sliderTauDecay, 'StateChangedCallback', @obj.changeTau, 'MouseReleasedCallback', @obj.changeSignalParameter );
            set(obj.sliderTauDecay, 'Value', 550, 'Name', 'TauDecay', 'tooltip', sprintf('%d ms', 550))
            set(obj.sliderTauDecayContainer, 'Parent', obj.panels.image, 'units', 'normalized', 'Position', sliderPos)
            set(obj.sliderTauDecayContainer, 'Visible', 'off')
            obj.centerAlignHandle(obj.sliderTauDecayContainer, centerPos)
            obj.sliderTauDecayContainer.Position(1) = xPos;

            xPos = sum(obj.sliderTauDecayContainer.Position([1,3]))+objpad+0.02;
            
            set(obj.textannotations(2), 'String', '\tau_{decay}', 'FontSize', 11);
            obj.centerAlignHandle(obj.textannotations(2), centerPos)
            obj.textannotations(2).Position(1) = obj.sliderTauDecayContainer.Position(1)-obj.textannotations(2).Position(3);

            obj.editSpikeSNR = uicontrol('Style', 'edit');
            obj.editSpikeSNR.Parent = obj.panels.image;
            obj.editSpikeSNR.String = num2str(obj.signalExtractionSettings.caimanParameters.spkSnr);
            obj.editSpikeSNR.Units = 'normalized';
            obj.editSpikeSNR.Enable = 'on';
            obj.editSpikeSNR.Visible = 'off';
            obj.editSpikeSNR.Position = (obj.uiButtons.ShowSpikes.Position - [0, 0.04, 0, 0]) .* [1,1,0.4,1];
            obj.editSpikeSNR.Tag = 'SpikeSNR';
            obj.editSpikeSNR.Callback = @obj.changeSignalParameter;
            obj.editSpikeSNR.Position(1) = xPos;
            obj.centerAlignHandle(obj.editSpikeSNR, centerPos)

            xPos = sum(obj.editSpikeSNR.Position([1,3]))+objpad;
            
            set(obj.textannotations(3), 'String', 'Spk Snr');
            obj.centerAlignHandle(obj.textannotations(3), centerPos)
            obj.textannotations(3).Position(1) = obj.editSpikeSNR.Position(1)-obj.textannotations(3).Position(3);

            obj.editLambdaPr = uicontrol('Style', 'edit');
            obj.editLambdaPr.Parent = obj.panels.image;
            obj.editLambdaPr.String = num2str(obj.signalExtractionSettings.caimanParameters.lamPr);
            obj.editLambdaPr.Units = 'normalized';
            obj.editLambdaPr.Enable = 'on';
            obj.editLambdaPr.Visible = 'off';
            obj.editLambdaPr.Position = (obj.uiButtons.ShowSpikes.Position - [0, 0.04, 0, 0]) .* [1,1,0.4,1];
            obj.editLambdaPr.Position(1) = sum(obj.editSpikeSNR.Position([1,3]))+ 0.02;
            obj.editLambdaPr.Tag = 'LambdaPr';
            obj.editLambdaPr.Callback = @obj.changeSignalParameter;
            obj.editLambdaPr.Position(1) = xPos;
            obj.centerAlignHandle(obj.editLambdaPr, centerPos)
            
            set(obj.textannotations(4), 'String', '\lambda_{pr}', 'FontSize', 11);
            obj.centerAlignHandle(obj.textannotations(4), centerPos)
            obj.textannotations(4).Position(1) = obj.editLambdaPr.Position(1)-obj.textannotations(4).Position(3);

        end
        
        
        function createComponentsRightPanel(obj)
            
            % Set Position of listbox and subpanels
            listboxPos = [0.05, 0.05, 0.25, 0.9];
            subpanelAPos = [0.4, 0.65, 0.53, 0.31];
            subpanelBPos = [0.4, 0.38, 0.52, 0.23];
            subpanelCPos = [0.4, 0.05, 0.52, 0.29];

            
            % Create listbox for showing the list of all rois
            obj.roiListBox = uicontrol('Style', 'listbox');
            obj.roiListBox.Parent = obj.panels.right;
            obj.roiListBox.Min = 0;
            obj.roiListBox.Max = 2;
            obj.roiListBox.FontSize = 12;
            obj.roiListBox.Units = 'normalized';
            obj.roiListBox.Position = listboxPos;
            obj.roiListBox.Callback = @obj.selectListBoxObj;
            
            % Create subpanel with buttons for creating and modifying rois          
            roiEditPanel = uipanel('Title', 'Roi Tools');
            roiEditPanel.Parent = obj.panels.right;
            roiEditPanel.FontSize = 12;
            roiEditPanel.Units = 'normalized'; 
            roiEditPanel.Position = subpanelAPos;
            
            % Add different buttons
            btnX = [0.1, 0.5]; btnY = [0.81, 0.62, 0.43, 0.24, 0.05];
            btnH = 0.04 / subpanelAPos(4);
            
            obj.uiButtons.DrawRoi = uicontrol('Style', 'togglebutton');
            obj.uiButtons.DrawRoi.Parent = roiEditPanel;
            obj.uiButtons.DrawRoi.String = 'draw (d)';
            obj.uiButtons.DrawRoi.Value = 0;
            obj.uiButtons.DrawRoi.Units = 'normalized';
            obj.uiButtons.DrawRoi.Position = [btnX(1), btnY(1), 0.3, btnH];
            obj.uiButtons.DrawRoi.Callback = @obj.buttonCallback_DrawRois;

            obj.uiButtons.TraceRoi = uicontrol('Style', 'togglebutton');
            obj.uiButtons.TraceRoi.Parent = roiEditPanel;
            obj.uiButtons.TraceRoi.String = 'Trace (t)';
            obj.uiButtons.TraceRoi.Value = 0;
            obj.uiButtons.TraceRoi.Visible = 'off';
            obj.uiButtons.TraceRoi.Units = 'normalized';
            obj.uiButtons.TraceRoi.Position = [btnX(1), btnY(1), 0.3, btnH];
            obj.uiButtons.TraceRoi.Callback = @obj.buttonCallback_DrawRois;
            
            obj.uiButtons.AutoDetect = uicontrol('Style', 'togglebutton');
            obj.uiButtons.AutoDetect.Parent = roiEditPanel;
            obj.uiButtons.AutoDetect.String = 'autodetect (a)';
            obj.uiButtons.AutoDetect.Value = 0;
            obj.uiButtons.AutoDetect.Units = 'normalized';
            obj.uiButtons.AutoDetect.Position = [btnX(2), btnY(1), 0.4, btnH];
            obj.uiButtons.AutoDetect.Callback = @obj.buttonCallback_AutodetectRois;

            obj.uiButtons.EditRoi = uicontrol('Style', 'togglebutton'); 
            obj.uiButtons.EditRoi.Parent = roiEditPanel;
            obj.uiButtons.EditRoi.String = 'edit (e)';
            obj.uiButtons.EditRoi.Value = 0;
            obj.uiButtons.EditRoi.Units = 'normalized';
            obj.uiButtons.EditRoi.Position = [btnX(1), btnY(2), 0.3, btnH];
            obj.uiButtons.EditRoi.Callback = @obj.buttonCallback_EditRois;

            obj.uiButtons.RemoveRoi = uicontrol('Style', 'pushbutton');
            obj.uiButtons.RemoveRoi.Parent = roiEditPanel;
            obj.uiButtons.RemoveRoi.String = 'remove (<--)';
            obj.uiButtons.RemoveRoi.Units = 'normalized';
            obj.uiButtons.RemoveRoi.Position = [btnX(2), btnY(2), 0.4, btnH];
            obj.uiButtons.RemoveRoi.Callback = @obj.buttonCallback_RemoveRois;
            
            obj.uiButtons.GrowRoi = uicontrol('Style', 'pushbutton');
            obj.uiButtons.GrowRoi.Parent = roiEditPanel;
            obj.uiButtons.GrowRoi.String = 'grow (g)';
            obj.uiButtons.GrowRoi.Units = 'normalized';
            obj.uiButtons.GrowRoi.Position = [btnX(1), btnY(3), 0.3, btnH];
            obj.uiButtons.GrowRoi.Callback = @obj.growRois;
            
            obj.uiButtons.ShrinkRoi = uicontrol('Style', 'pushbutton');
            obj.uiButtons.ShrinkRoi.Parent = roiEditPanel;
            obj.uiButtons.ShrinkRoi.String = 'shrink (h)';
            obj.uiButtons.ShrinkRoi.Units = 'normalized';
            obj.uiButtons.ShrinkRoi.Position = [btnX(2), btnY(3), 0.4, btnH];
            obj.uiButtons.ShrinkRoi.Callback = @obj.shrinkRois;

            obj.uiButtons.DoMagic = uicontrol('Style', 'pushbutton');
            obj.uiButtons.DoMagic.Parent = roiEditPanel;
            obj.uiButtons.DoMagic.String = 'Do Magic';
            obj.uiButtons.DoMagic.Units = 'normalized';
            obj.uiButtons.DoMagic.Position = [btnX(1)+0.5, btnY(4), 0.35, btnH];
            obj.uiButtons.DoMagic.Callback = @obj.buttonCallback_DoMagic;
            
            obj.uiButtons.CircleTool = uicontrol('Style', 'togglebutton');
            obj.uiButtons.CircleTool.Parent = roiEditPanel;
            obj.uiButtons.CircleTool.String = 'O';
            obj.uiButtons.CircleTool.Units = 'normalized';
            obj.uiButtons.CircleTool.Position = [btnX(1)-0.05, btnY(4), 0.26, btnH];
            obj.uiButtons.CircleTool.Callback = @obj.buttonCallback_CircleTool;
            obj.uiButtons.CircleTool.FontSize = 10;
            
            obj.uiButtons.Crosshair = uicontrol('Style', 'togglebutton');
            obj.uiButtons.Crosshair.Parent = roiEditPanel;
            obj.uiButtons.Crosshair.String = '+';
            obj.uiButtons.Crosshair.Units = 'normalized';
            obj.uiButtons.Crosshair.Position = [btnX(1)+0.225, btnY(4), 0.26, btnH];
            obj.uiButtons.Crosshair.Callback = @obj.buttonCallback_MarkCenter;
            
            obj.uiButtons.SetRoiTemplateSize = uicontrol('Style', 'pushbutton');
            obj.uiButtons.SetRoiTemplateSize.Parent = roiEditPanel;
            obj.uiButtons.SetRoiTemplateSize.String = 'Set Autodetection Size';
            obj.uiButtons.SetRoiTemplateSize.Units = 'normalized';
            obj.uiButtons.SetRoiTemplateSize.Position = [btnX(1), btnY(5), 0.8, btnH];
            obj.uiButtons.SetRoiTemplateSize.Callback = @obj.setRoiTemplateSize;
            
            sliderPos = [0.05, 0.05, 0.7, 0.1];                     
            jSlider = com.jidesoft.swing.RangeSlider(0, 30, obj.roiInnerDiameter, obj.roiOuterDiameter);
            [obj.roiSizeSlider, obj.roiSizeSliderContainer] = javacomponent(jSlider);
            obj.roiSizeSlider = handle(obj.roiSizeSlider, 'CallbackProperties');
            set(obj.roiSizeSlider, 'StateChangedCallback', @obj.changeRoiSize);
            set(obj.roiSizeSlider, 'tooltip', sprintf('%d px', obj.roiOuterDiameter))
            set(obj.roiSizeSliderContainer, 'Parent', roiEditPanel, 'units', 'normalized', 'Position', sliderPos)
            set(obj.roiSizeSliderContainer, 'Visible', 'off')
           
            % Create center UI panel for image display             
            roiImPanel = uipanel('Title', 'Roi Image');
            roiImPanel.Parent = obj.panels.right;
            roiImPanel.FontSize = 12;
            roiImPanel.Units = 'normalized'; 
            roiImPanel.Position = subpanelBPos;
            
            obj.uiaxes.smallroi = axes('Parent', roiImPanel);
            obj.uiaxes.smallroi.Position = [0.05, 0.05, 0.9, 0.9];
            obj.uiaxes.smallroi.XTick = []; 
            obj.uiaxes.smallroi.YTick = [];
            
            % Create subpanel for showing roi information        
            obj.panels.roiInfo = uipanel('Title', 'Roi Info');
            obj.panels.roiInfo.Parent = obj.panels.right;
            obj.panels.roiInfo.FontSize = 12;
            obj.panels.roiInfo.Units = 'normalized'; 
            obj.panels.roiInfo.Position = subpanelCPos;
            
            obj.popupRoiclass = uicontrol('Style', 'popupmenu');
            obj.popupRoiclass.Parent = obj.panels.roiInfo;
            obj.popupRoiclass.String = obj.roiClasses;
            obj.popupRoiclass.Value = 1;
            obj.popupRoiclass.Units = 'normalized'; 
            obj.popupRoiclass.Position = [0.05, 0.8, 0.9, 0.1];
            obj.popupRoiclass.Callback = @obj.changeRoiClass;

            txtConnectedRois = uicontrol('Style', 'text');
            txtConnectedRois.Parent = obj.panels.roiInfo;
            txtConnectedRois.String = 'Conn. Rois:';
            txtConnectedRois.Units = 'normalized';
            txtConnectedRois.HorizontalAlignment = 'left';
            txtConnectedRois.Position = [0.1, 0.55, 0.3, 0.15];

            obj.connectedRoiInfo = uicontrol('Style', 'edit');
            obj.connectedRoiInfo.Parent = obj.panels.roiInfo;
            obj.connectedRoiInfo.String = '';
            obj.connectedRoiInfo.Enable = 'inactive';
            obj.connectedRoiInfo.Units = 'normalized';
            obj.connectedRoiInfo.HorizontalAlignment = 'left';
            obj.connectedRoiInfo.Position = [0.45, 0.55, 0.45, 0.1];
            
            txtOverfilled = uicontrol('Style', 'text');
            txtOverfilled.Parent = obj.panels.roiInfo;
            txtOverfilled.String = 'Overfilled :';
            txtOverfilled.Units = 'normalized';
            txtOverfilled.HorizontalAlignment = 'left';
            txtOverfilled.Position = [0.1, 0.4, 0.3, 0.08];
            
            obj.textannotations(end+1) = annotation(obj.panels.roiInfo, 'textbox');
            set(obj.textannotations(end), 'String', 'Tau Rise (ms)');
            set(obj.textannotations(end), 'Position', [0.25, 0.3, 0.3, 0.1]);
            obj.centerAlignHandle(obj.textannotations(end), 0.3)

            obj.textannotations(end+1) = annotation(obj.panels.roiInfo, 'textbox');
            set(obj.textannotations(end), 'String', 'Tau Decay (ms)');
            set(obj.textannotations(end), 'Position', [0.25, 0.1, 0.3, 0.1]);
            obj.centerAlignHandle(obj.textannotations(end), 0.15)
            set(obj.textannotations(end-1:end), ...
                'LineStyle', 'none', ...
                'HorizontalAlignment', 'right', ...
                'VerticalAlignment', 'middle')
    
            obj.editTauRise = uicontrol('Style', 'edit');
            obj.editTauRise.Parent = obj.panels.roiInfo;
            obj.editTauRise.String = '';
            obj.editTauRise.Units = 'normalized';
            obj.editTauRise.Enable = 'off';
            obj.editTauRise.Position = [0.6, 0.25, 0.3, 0.1];
            obj.editTauRise.Tag = 'TauRiseIndicator';
            obj.centerAlignHandle(obj.editTauRise, 0.3)
            
            obj.editTauDecay = uicontrol('Style', 'edit');
            obj.editTauDecay.Parent = obj.panels.roiInfo;
            obj.editTauDecay.String = '';
            obj.editTauDecay.Units = 'normalized';
            obj.editTauDecay.Enable = 'off';
            obj.editTauDecay.Position = [0.6, 0.1, 0.3, 0.1];
            obj.editTauDecay.Tag = 'TauDecayIndicator';
            obj.centerAlignHandle(obj.editTauDecay, 0.15)


            obj.boolOverfilled = uicontrol('Style', 'checkbox');
            obj.boolOverfilled.Parent = obj.panels.roiInfo;
            obj.boolOverfilled.Value = false;
            obj.boolOverfilled.Units = 'normalized';
            obj.boolOverfilled.HorizontalAlignment = 'left';
            obj.boolOverfilled.Position = [0.45, 0.4, 0.12, 0.08];
            obj.boolOverfilled.Callback = {@obj.tagRois, 'Overfilled'};
            
%             txtSpikeThresh = uicontrol('Style', 'text');
%             txtSpikeThresh.Parent = obj.panels.roiInfo;
%             txtSpikeThresh.String = 'Sp.Thresh:';
%             txtSpikeThresh.Units = 'normalized';
%             txtSpikeThresh.HorizontalAlignment = 'left';
%             txtSpikeThresh.Position = [0.05, 0.15, 0.33, 0.15];
%             
%             obj.editSpikeThresh = uicontrol('Style', 'edit');
%             obj.editSpikeThresh.Parent = obj.panels.roiInfo;
%             obj.editSpikeThresh.String = '';
%             obj.editSpikeThresh.Units = 'normalized';
%             obj.editSpikeThresh.Enable = 'off';
%             obj.editSpikeThresh.Position = [0.05, 0.1, 0.2, 0.1];
%             obj.editSpikeThresh.Tag = 'SpikeTreshold';
%             obj.editSpikeThresh.Callback = @obj.changeSignalParameter;

        end
        
        
        function initializeScroller(obj)
            
            % Add a java scrollbar
            jScrollbar = javaObjectEDT('javax.swing.JScrollBar');
            jScrollbar.setOrientation(jScrollbar.HORIZONTAL);                          
            [obj.frameslider, obj.fsContainer] = javacomponent(jScrollbar);
            obj.fsContainer.Visible = 'off';        
            % Add a callback for value changes
            obj.frameslider = handle(obj.frameslider, 'CallbackProperties');
            set(obj.frameslider, 'AdjustmentValueChangedCallback', {@obj.changeFrame, 'slider'});
            
            % Set scrollbar range and positions
            set(obj.frameslider, 'minimum', 1, 'maximum', obj.nFrames, 'VisibleAmount', 1);
            obj.fsContainer.Parent = obj.fig;
            obj.fsContainer.Units = 'normalized';
            obj.fsContainer.Position = [obj.panels.image.Position(1), 0.01, ...
                         obj.panels.image.Position(3), 0.015] ;
            obj.frameslider.Value = 1;

        end
        
        
        function enterDarkMode(obj)
            
            % Need to add jtattoo to the javapath.
            spath = javaclasspath('-static');
            if ~any(contains(spath, 'JTattoo'))
                folder = fileparts(mfilename('fullpath'));
                jtattoPath = fullfile(folder, '+utilities', 'JTattoo.jar');
                success = utilities.addStaticJavaPath(jtattoPath); 
                javaclasspath(fullfile(folder, '+utilities', 'JTattoo.jar') ) %Temp add to dynamic path...
                disp('Darkmode will work next time Matlab is started')
                return
            end
            
            % Specify the colors to use
            bgColor = [24,24,24] ./ 255;        % % Background color
            fgColor = [228,228,228] ./ 255;     % % Foreground color
            % Javacolors         
            jbgcolor = javax.swing.plaf.ColorUIResource(24/255, 24/255, 24/255);
            jfgcolor = javax.swing.plaf.ColorUIResource(255/255, 20/255, 67/255); % Does not appear to work

            obj.fig.Color = bgColor;

            % Apply colors to panels
            mainPanels = findobj(obj.fig, 'Type', 'uipanel');
            
            set(mainPanels, 'BackgroundColor', bgColor)
            set(mainPanels, 'ForegroundColor', [174,174,174]./255)
            set(mainPanels, 'BorderType', 'etchedin') %'etchedin' (default) | 'etchedout' | 'beveledin' | 'beveledout' | 'line' | 'none'
            set(mainPanels, 'HighlightColor', [40,40,40]./255)
            set(mainPanels, 'ShadowColor', [32,32,32]./255)
            
            % Apply colors to axes
            mainAxes = struct2cell(obj.uiaxes);
            set([mainAxes{:}], 'Color', bgColor)
            
            % Apply colors to buttons
            buttons = struct2cell(obj.uiButtons);
            set([buttons{:}], 'BackgroundColor', bgColor)
            set([buttons{:}], 'ForegroundColor', fgColor)
            
            set([buttons{:}], 'FontName', 'verdana')
            set([buttons{:}], 'FontSize', 12)
            
            txtObj = findobj(obj.fig, 'Style', 'text');
            set(txtObj, 'BackgroundColor', bgColor)
            set(txtObj, 'ForegroundColor', fgColor)
            
            editObj = findobj(obj.fig, 'Style', 'edit');
            set(editObj, 'BackgroundColor', [67,67,67]./255)
            set(editObj, 'ForegroundColor', fgColor)
            
            listObj = findobj(obj.fig, 'Style', 'listbox');
            set(listObj, 'BackgroundColor', [67,67,67]./255)
            set(listObj, 'ForegroundColor', fgColor)
            
            cbobj = findobj(obj.fig, 'Style', 'checkbox');
            set(cbobj, 'BackgroundColor', bgColor)
            
            pmobj = findobj(obj.fig, 'Style', 'popupmenu');
            set(pmobj, 'BackgroundColor', bgColor)
            set(pmobj, 'ForegroundColor', fgColor)

            % Set colors of slider containers and sliders.
            set(obj.brightnessSliderContainer, 'BackgroundColor', bgColor)
            set(obj.roiSizeSliderContainer, 'BackgroundColor', bgColor)
            set(obj.sliderTauDecayContainer, 'BackgroundColor', bgColor)
            set(obj.sliderTauRiseContainer, 'BackgroundColor', bgColor)

            
            set(obj.brightnessSlider, 'Background', jbgcolor)
            set(obj.brightnessSlider, 'Foreground', jfgcolor)
            set(obj.roiSizeSlider, 'Background', jbgcolor)
            set(obj.sliderTauDecay, 'Background', jbgcolor)
            set(obj.sliderTauRise, 'Background', jbgcolor)
            
            set(obj.frameslider, 'Background', jbgcolor)
            set(obj.fsContainer, 'Background', bgColor)
            
            set(obj.textannotations, 'Color', fgColor)
            drawnow
            
            folder = fullfile(fileparts(mfilename('fullpath')), 'graphics');

            btnim1 = imresize(imread(fullfile(folder, 'button2_selected.tif')), 0.45);
            btnim2 = imresize(imread(fullfile(folder, 'button2_unselected.tif')), 0.45);
            btnim3 = imresize(imread(fullfile(folder, 'button2_infocus.tif')), 0.45);
            btnim4 = imresize(imread(fullfile(folder, 'button2_infocus2.tif')), 0.45);
            
            userdata.Selected = btnim1;
            userdata.Unselected = btnim2;
            userdata.InFocus = btnim3;
            userdata.InFocus2 = btnim4;

            for i = 1:numel(buttons)
               customization.configureButton(buttons{i}, userdata);
            end
            
            javax.swing.UIManager.put('ToggleButton.background', 'com.apple.laf.AquaImageFactory$SystemColorProxy[r=40,g=40,b=40]');
            javax.swing.UIManager.put('ToggleButton.background', jbgcolor);
            
            % Change javatheme of some of the controls.

            % Open a temporary figure and move components there.
            tmpfig = figure('Position', [1, 1, 100, 20], 'MenuBar', 'none');

            drawnow; pause(0.2);

            originalLnF = javax.swing.UIManager.getLookAndFeel;
            
            javax.swing.UIManager.setLookAndFeel(com.jtattoo.plaf.aluminium.AluminiumLookAndFeel)
            
            obj.roiListBox.Parent = tmpfig;
            drawnow; pause(0.2);
               
            obj.roiListBox.Parent = obj.panels.right;
            drawnow; pause(0.2);

            javax.swing.UIManager.setLookAndFeel(com.jtattoo.plaf.hifi.HiFiLookAndFeel)
            delete(obj.frameslider)
            delete(obj.fsContainer)
            obj.initializeScroller()
            obj.dropdownImplementation.Parent = tmpfig;
            obj.dropdownMethod.Parent = tmpfig;
            obj.popupRoiclass.Parent = tmpfig;
            obj.dropdownImplementation.Visible = 'on';
            obj.dropdownMethod.Visible = 'on';
            
            drawnow; pause(0.2);
            
            obj.fsContainer.Parent = tmpfig;
            origPos = obj.fsContainer.Position;
            obj.fsContainer.Position = [0.1,0.2,0.8,0.8];
            obj.fsContainer.Visible = 'on';

            drawnow; pause(0.2)
            
            obj.dropdownImplementation.Parent = obj.panels.image;
            obj.dropdownMethod.Parent = obj.panels.image;
            obj.popupRoiclass.Parent = obj.panels.roiInfo;
            obj.fsContainer.Parent = obj.fig;
            obj.fsContainer.Position = origPos;
            drawnow; pause(0.2)
            
            javax.swing.UIManager.setLookAndFeel(originalLnF);

            obj.dropdownImplementation.Visible = 'off';
            obj.dropdownMethod.Visible = 'off';
            obj.fsContainer.Visible = 'off';
            
            close(tmpfig)
            
        end
        
        
        function loadSettings(obj)
        % Load some properties from a settings file
           
            if obj.USE_DEFAULTSETTINGS
                return
            else
                path = mfilename('fullpath');
                settingsPath = strcat(path, '_settings.mat');

                if exist(settingsPath, 'file') % Load settings from file
                    S = load(settingsPath, 'settings', 'fileSettings', 'signalExtractionSettings');
                    obj.settings = utilities.updateSettings(obj.settings, S.settings);
                    obj.fileSettings = utilities.updateSettings(obj.fileSettings, S.fileSettings);
                    obj.signalExtractionSettings = utilities.updateSettings(obj.signalExtractionSettings, S.signalExtractionSettings);
                
                else % Initialize settings file using default settings 
                    saveSettings(obj)
                end
            end
        end

        
        function saveSettings(obj)
        % Save some properties to a settings file
        
        % Don't overwrite saved settings if using default settings.
        
            if obj.USE_DEFAULTSETTINGS
                return
            end
            
            path = mfilename('fullpath');
            settingsPath = strcat(path, '_settings.mat');
            
            S.settings = obj.settings;
            S.fileSettings = obj.fileSettings;
            S.signalExtractionSettings = obj.signalExtractionSettings;
            save(settingsPath, '-struct', 'S');
                        
        end

        
    end
    
   
    
    methods
        
        
        function obj = roimanager(sessionObj)
        %Constructs the GUI window and places all objects within it.
        
            % Create and configure GUI window
            obj.initializeGui()
            
            
            if nargin
                obj.sessionObj = sessionObj;
                obj.loadStack([], []);
                obj.loadRois([])
            end


            if nargout == 0
                clear obj
            end
                      
        end
        

        function editGuiSettings(obj, src, ~)
            % Open window for changing settings
            
            switch src.Label
                case 'Edit File Settings'
                    oldSettings = obj.fileSettings;
                    newSettings = utilities.editStruct(oldSettings, 'all', 'File Settings');
                    obj.fileSettings = newSettings;
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
            
            % Check for change in settings. Change of some settings should 
            % have an immediate response, take care of that here.
            fields = fieldnames(oldSettings);
            for i = 1:numel(fields)
                if ~isequal(newSettings.(fields{i}), oldSettings.(fields{i}))
                    obj.changeSetting(fields{i}, newSettings.(fields{i}))
                end
            end
            
            obj.saveSettings()
            
        end
        
        
        function changeSetting(obj, name, val)
            switch name
                case 'showTags'
                    if val
                        set(obj.RoiTextHandles{obj.activeChannel}, 'Visible', 'on')
                    else
                        set(obj.RoiTextHandles{obj.activeChannel}, 'Visible', 'off')
                    end
                case 'caimanParameters'
                    obj.editLambdaPr.String = num2str(obj.signalExtractionSettings.caimanParameters.lamPr);
                    obj.editSpikeSNR.String = num2str(obj.signalExtractionSettings.caimanParameters.spkSnr);
                    obj.sliderTauDecay.Value = obj.signalExtractionSettings.caimanParameters.tauDr(1);
                    obj.sliderTauRise.Value = obj.signalExtractionSettings.caimanParameters.tauDr(2);

            end
        end
        
        
% % % % Functions for undo/redo functionality 
        
        function initializeActionLog(obj)
        %initializeActionLog Preallocate cell array for action log/history
        %
        %   The action log keeps track of rois that are added, modified or
        %   removed. It is a struct containing fields:
        %       'ch'            current channel where changes took place
        %       'roiIndices'    indices of the rois that were changed
        %       'action'        what type of action (add, modify, remove)
        %       'rois'          struct with roi properties of modified rois
        %
        %   See also traverseActionLog, addToActionLog
        
            n = obj.settings.nElementsLog;
            obj.actionLog = struct( 'activeCh', cell(n,1), ...
                                    'alteredCh', cell(n,1), ...
                                    'roiInd', cell(n,1), ...
                                    'rois', cell(n,1), ...
                                    'action', cell(n,1) );
            obj.logPosition = 0;
            obj.lastLogPosition = 0;
        end
        
        
        function addToActionLog(obj, ch, roiIndices, action)
        %addToActionLog Add roi parameters and action to the action log    
        %
        %   The action log keeps track of rois that are added, modified or
        %   removed. It is a struct containing fields:
        %       'ch'            current channel where changes took place
        %       'roiIndices'    indices of the rois that were changed
        %       'action'        what type of action (add, modify, remove)
        %       'rois'          struct with roi properties of modified rois
        %
        %   See also traverseActionLog, initializeActionLog
        

            % Update log position. If current position is at the end of the
            % log, move elements up by circshifting the log.
            if obj.logPosition == length(obj.actionLog)
                obj.actionLog = circshift(obj.actionLog, -1);
            else
                obj.logPosition = obj.logPosition + 1;
            end
            
            % Add current logPosition to lastLogPosition (Used in
            % traverseActionLog). This is the last element of the log.
            obj.lastLogPosition = obj.logPosition;
            
            % Tmp thing. Take rois from first channel. Should take from all
            % Convert rois to struct for performance
            roiStruct = utilities.roiarray2struct(obj.roiArray{ch(1)}(roiIndices));
            
            % Add entries to current position in log.
            ii = obj.logPosition;
            obj.actionLog(ii).activeCh = obj.activeChannel;
            obj.actionLog(ii).alteredCh = ch;
            obj.actionLog(ii).roiInd = roiIndices;
            obj.actionLog(ii).action = action;
            obj.actionLog(ii).rois = roiStruct;
             
        end
        
        
        function traverseActionLog(obj, direction)
        %traverseActionLog Put elements in and out of action log
        %
        %   The action log keeps track of rois that are added, modified or
        %   removed. It is a struct containing fields:
        %       'ch'            current channel where changes took place
        %       'roiIndices'    indices of the rois that were changed
        %       'action'        what type of action (add, modify, remove)
        %       'rois'          struct with roi properties of modified rois
        %
        %   See also initializeActionLog, addToActionLog
            
            switch direction
                case 'up'
                    ii = obj.logPosition; 
                    newLogPosition = obj.logPosition - 1;
                case 'down'
                    ii = obj.logPosition + 1; 
                    newLogPosition = obj.logPosition + 1;
            end
            
            % Return if beginning or end of log is reached.
            if newLogPosition < 0
                disp('Beginning of undo/redo log is reached')
                return
            elseif newLogPosition > obj.lastLogPosition
                disp('End of undo/redo log is reached')
                return
            end
            
            % This is not symmetric. See add to action log. Does it make
            % sense? Not prioritized...
            if isequal(direction, 'up')
                obj.logPosition = newLogPosition;
            end
            
            % Should remove this?? or modify so that it only happens if one
            % channel is affected.... 
            if obj.actionLog(ii).activeCh ~= obj.activeChannel
                obj.changeActiveChannel(struct('String', obj.loadedChannels(obj.actionLog(ii).activeCh)));
            end
            
            % obj.lastLogPosition is always updated when performing an 
            % action. When traversing the log, methods like addRois and
            % removeRois in turn call addToActionLog. This changes the
            % last lof position, although it should stay the same.
            % Temporarily keep the last log position and reset when done
            % with changes.
            tmpLastLogPosition = obj.lastLogPosition;
            
            ch = obj.activeChannel;
            
            switch obj.actionLog(ii).action
                case 'add' % Remove rois that were added
                    obj.removeRois(obj.actionLog(ii).roiInd, obj.actionLog(ii).alteredCh);
                    
                case 'remove' % Add rois that were removed
                    nRois = numel(obj.actionLog(ii).rois);
                    if isequal(obj.actionLog(ii).roiInd, obj.roiCount{ch} - fliplr(1:nRois) + 1)
                        mode = 'append';
                    else
                        mode = 'insert';
                    end
                    obj.addRois(obj.actionLog(ii).rois, obj.actionLog(ii).roiInd, mode, obj.actionLog(ii).alteredCh);
                    
                case 'reshape' % hvilket nummer i loggen? Er det samme eller er det ny?
                    for i = 1:numel(obj.actionLog(ii).roiInd)
                        roiIdx = obj.actionLog(ii).roiInd(i);

                        % Exchange objects in log and roiArray
                        roi = obj.actionLog(ii).rois(i);
                        roi = utilities.struct2roiarray(roi);
                        roiBak = obj.roiArray{ch}(roiIdx);
                        obj.roiArray{ch}(roiIdx) = roi;
                        obj.actionLog(ii).rois(i) = utilities.roiarray2struct(roiBak);

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
            
%             if exist('chTmp', 'var')
%                 obj.changeActiveChannel(struct('String', obj.loadedChannels(chTmp)));
%             end
        
        end
        
        
        function applyRoiActionToAllChannels(obj, ~, ~)
            % Messy work in progress.
                        
            allCh = 1:obj.nLoadedChannels;
            
            obj.actionLog(obj.logPosition).alteredCh = allCh;
            
            allCh = setdiff(allCh, obj.activeChannel);
            for ch = allCh
                roi = obj.roiArray{ch}(obj.selectedRois);
                roi = utilities.struct2roiarray(roi);
                coords = obj.roiArray{obj.activeChannel}(obj.selectedRois).coordinates;
                shape = obj.roiArray{obj.activeChannel}(obj.selectedRois).shape;
                roi = roi.reshape(shape, coords);
                roi = utilities.roiarray2struct(roi);
                obj.roiArray{ch}(obj.selectedRois) = roi;
                updateRoiPlot(obj, obj.selectedRois, ch); % Update plot handles
            end
            %obj.modifySignalArray(obj.selectedRois, 'reset')
            
            
            
        end
        
        
% % % % Functions for mouse interactivity
       
        function setMouseMode(obj, newMouseMode)
        % Change the mode of mouseclicks in the GUI
            
            % Cancel rois if new mouse mode is not edit mode or zoom modes
            switch newMouseMode
                case {'Select', 'Autodetect', 'Set Roi Diameter', ...
                      'EditSelect', 'Draw', 'CircleSelect'}
                    if ~isempty(obj.tmpImpoints)
                        obj.cancelRoi();
                    end
                    
                    if ~isempty(obj.hRoiOutline)
                        delete(obj.hRoiOutline)
                        obj.hRoiOutline = [];
                    end
            end
            
            % Make circle selection tool invisible
            if isequal(obj.mouseMode, 'CircleSelect') && ~isequal(newMouseMode, 'CircleSelect')
                delete(obj.circleToolHandle)
                obj.circleToolHandle = [];
            end
            
            % Make crosshair selection tool invisible
            if isequal(obj.mouseMode, 'CrosshairSelect') && ~isequal(newMouseMode, 'CrosshairSelect')
                delete(obj.crosshairHandle)
                obj.crosshairHandle = [];
            end
            
            % Set mousemode
            switch newMouseMode
                % When releasing some mouse modes (e.g. zoom), change back
                % to the previous mode.
                case 'Previous'
                    if obj.uiButtons.DrawRoi.Value
                        obj.mouseMode = 'Draw';
                    elseif obj.uiButtons.TraceRoi.Value
                        obj.mouseMode = 'Freehand';
                    elseif obj.uiButtons.EditRoi.Value
                        if isempty(obj.tmpImpoints)
                            obj.mouseMode = 'EditSelect';
                            obj.deselectRois(obj.selectedRois);
                        else
                            obj.mouseMode = 'EditDraw';
                        end
                    elseif obj.uiButtons.AutoDetect.Value
                        obj.mouseMode = 'Autodetect';
                    elseif obj.uiButtons.CircleTool.Value
                        obj.mouseMode = 'CircleSelect';
                    elseif obj.uiButtons.Crosshair.Value
                        obj.mouseMode = 'CrosshairSelect';
                    elseif strcmp(obj.uiButtons.SetRoiTemplateSize.String, 'Confirm')
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

                otherwise
                    obj.mouseModePrev = obj.mouseMode;
                    obj.mouseMode = newMouseMode;
            end
            
            % Take care of togglebuttons. Only one active at the same time
            switch newMouseMode
                case 'Draw'
                    obj.switchToggleButton(obj.uiButtons.DrawRoi, true)
                case 'Autodetect'
                    obj.switchToggleButton(obj.uiButtons.AutoDetect, true)
                case {'EditSelect', 'EditDraw'}
                    obj.switchToggleButton(obj.uiButtons.EditRoi, true)
                case 'CircleSelect'
                    obj.switchToggleButton(obj.uiButtons.CircleTool, true)
                case 'CrosshairSelect'
                    obj.switchToggleButton(obj.uiButtons.Crosshair, true)
                case 'Freehand'
                    obj.switchToggleButton(obj.uiButtons.TraceRoi, true)
                case 'Select'
                    obj.switchToggleButton(obj.uiButtons.DrawRoi, false)
            end
            
            if obj.isCursorInsideAxes(obj.uiaxes.imagedisplay) || obj.isCursorInsideAxes(obj.uiaxes.signalplot)
                obj.updatePointer()
            end
            
            % Plot custom mouse tools
            switch obj.mouseMode
                case 'CircleSelect'
                    if isempty(obj.roiTemplateCenter)
                        xlim = get(obj.uiaxes.imagedisplay, 'Xlim');
                        ylim = get(obj.uiaxes.imagedisplay, 'Ylim');
                        obj.roiTemplateCenter = [xlim(1) + diff(xlim)/2, ylim(1) + diff(ylim)/2];
                    end
                    obj.plotCircleTool();
                    
                case 'CrosshairSelect'
                    obj.plotCrosshair();
            end
            
        end
        
        
        function updatePointer(obj)
        % Change pointers according to mousemode

            imParentFig = ancestor(obj.uiaxes.imagedisplay, 'figure');
            
            if obj.isCursorInsideAxes(obj.uiaxes.imagedisplay)
                mousePoint = get(obj.uiaxes.imagedisplay, 'CurrentPoint');
                mousePoint = mousePoint(1, 1:2);
                
                currentPointer = get(imParentFig, 'Pointer');
                switch obj.mouseMode
                    case {'Draw', 'EditDraw'}
                        if obj.isCursorOnImpoint(mousePoint(1), mousePoint(2))
                            set(imParentFig,'Pointer', 'fleur');
                        elseif ~strcmp(currentPointer, 'crosshair')
                            set(imParentFig, 'Pointer', 'crosshair');
                        end
                    case 'Freehand'
                        pdata = NaN(16,16);
                        pdata(7:10, 7:10) = 2;
                        pdata(8:9, 8:9) = 1;
                        set(imParentFig, 'Pointer', 'custom', 'PointerShapeCData', pdata, 'PointerShapeHotSpot', [8,8])
                    case 'Autodetect'
                        if ~strcmp(currentPointer, 'cross')
                            set(imParentFig, 'Pointer', 'cross');
                        end
                    case 'CircleSelect'
                        if ~strcmp(currentPointer, 'crosshair')
                            set(imParentFig, 'Pointer', 'crosshair');
                        end
                        if isa(obj.circleToolHandle, 'handle')
                            if isequal(obj.circleToolHandle.Visible, 'off')
                                obj.circleToolHandle.Visible = 'on';
                            end
                        end
                        
                    case 'CrosshairSelect'
                        if ~strcmp(currentPointer, 'custom')
                            pdata = NaN(16,16);
                            pdata(7:10, 7:10) = 2;
                            pdata(8:9, 8:9) = 1;
                            
                            set(imParentFig, 'Pointer', 'custom', 'PointerShapeCData', pdata, 'PointerShapeHotSpot', [8,8])
%                             set(imParentFig, 'Pointer', 'crosshair');
                        end
%                         if isequal(obj.crosshairHandle.Visible, 'off')
%                             obj.crosshairHandle.Visible = 'on';
%                         end
                        
                    case 'EditSelect'
                        if ~strcmp(currentPointer, 'hand')
                           set(imParentFig, 'Pointer', 'hand');
                        end
                    case 'Set Roi Diameter'
                        if ~strcmp(currentPointer, 'circle')
                             set(imParentFig, 'Pointer', 'circle');
                        end
                    case 'Select'
                        if ~strcmp(currentPointer, 'hand')
                            set(imParentFig,'Pointer','hand');
                        end
                    case 'Zoom In'
                        if ~strcmp(currentPointer, 'custom') || strcmp(obj.mouseModePrev, 'Zoom Out') || strcmp(obj.mouseModePrev, 'CrosshairSelect') || strcmp(obj.mouseModePrev, 'Freehand')
                            setptr(imParentFig, 'glassplus');
                        end
                    case 'Zoom Out'
                        if ~strcmp(currentPointer, 'custom') || strcmp(obj.mouseModePrev, 'Zoom In') || strcmp(obj.mouseModePrev, 'CrosshairSelect') || strcmp(obj.mouseModePrev, 'Freehand')
                            setptr(imParentFig, 'glassminus');
                        end
                    case 'Multiselect'
                        if ~strcmp(currentPointer, 'crosshair')
                            set(imParentFig,'Pointer','crosshair');
                        end
                end
            elseif obj.isCursorInsideAxes(obj.uiaxes.signalplot)
                currentPointer = get(obj.fig, 'Pointer');
                if isequal(obj.mouseMode, 'Zoom In')
                    if ~strcmp(currentPointer, 'custom') || strcmp(obj.mouseModePrev, 'Zoom Out') || strcmp(obj.mouseModePrev, 'CrosshairSelect') 
                        setptr(obj.fig, 'glassplus');
                    end
                elseif isequal(obj.mouseMode, 'Zoom Out')
                    if ~strcmp(currentPointer, 'custom') || strcmp(obj.mouseModePrev, 'Zoom In') || strcmp(obj.mouseModePrev, 'CrosshairSelect') 
                        setptr(obj.fig, 'glassminus');
                    end
                else
                    set(obj.fig, 'Pointer', 'arrow');
                end
            else
                set(imParentFig, 'Pointer', 'arrow');
                if ~isempty(obj.circleToolHandle)
                    obj.circleToolHandle.Visible = 'off';
                end
            end
            
        end
        
     
        function bool = isCursorInsideAxes(~, ax)
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
        
        
% % % % Mouse and keyboard callbacks

        function keyPress(obj, ~, event)
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
                    if contains(event.Modifier, 'alt')
                        source = obj.popupRoiclass;
                        obj.popupRoiclass.Value = find(contains(obj.popupRoiclass.String, 'Neuronal Dendrite'));
                        obj.changeRoiClass(source, []);
                    elseif contains(event.Modifier, 'shift') 
                        obj.createDonutRois([], [])
                    else
                        switch obj.mouseMode
                            case 'Draw'
                                obj.setMouseMode('Select')
                            otherwise
                                obj.setMouseMode('Draw')
                        end
                    end
                    
                case 't' %trace
                    
                    switch obj.mouseMode
                        case 'Freehand'
                            obj.setMouseMode('Select')
                        otherwise
                            delete(obj.hRoiOutline)
                            obj.hRoiOutline = [];
                            obj.setMouseMode('Freehand')
                    end
                    
                case 'a'
                    
                    if contains(event.Modifier, {'command', 'control'})
                        roiInd = 1:obj.roiCount{obj.activeChannel};
                        obj.selectRois(roiInd, 'extend')
                        
                    elseif contains(event.Modifier, {'shift'})
                        switch obj.mouseMode
                            case 'CrosshairSelect'
                                obj.setMouseMode('Autodetect')
                        end
                    else
                        
                        switch obj.mouseMode
                            case 'Autodetect'
                                obj.setMouseMode('CrosshairSelect')
                            case 'CrosshairSelect'
                                obj.setMouseMode('Select')
                            otherwise
                                obj.setMouseMode('Autodetect')
                        end
                    end
                    
                    
                case 'v'
                    if contains(event.Modifier, {'command', 'control'})
                        obj.pasteRoisFromClipboard()
                    end
                    
                case 'o' % Activate circle selection tool
                    switch obj.mouseMode
                        case 'CircleSelect'
                            obj.setMouseMode('Select')
                        otherwise
                            obj.setMouseMode('CircleSelect')
                    end
                    
                case 'c' % Connect rois / copy rois to clipboard
                    if contains(event.Modifier, {'command', 'control'})
                        obj.copyRoisToClipboard()
                    elseif contains(event.Modifier, {'shift'})
                        obj.connectRois([], [])
                    elseif isempty(event.Modifier)
                        obj.showCorrelationImage()
                    end
                    
                case 'e' % Toggle edit mode
                    switch obj.mouseMode
                        case 'EditSelect'
                            obj.setMouseMode('Select')
                        case 'EditDraw'
                            obj.setMouseMode('Select')
                        otherwise
                            obj.setMouseMode('EditSelect')
                    end
                    
                case 's'
                    if contains(event.Modifier, {'command', 'ctrl','control'})
                        obj.saveRois([], [])
                    elseif contains(event.Modifier, 'alt')
                        source = obj.popupRoiclass;
                        obj.popupRoiclass.Value = find(contains(obj.popupRoiclass.String, 'Neuronal Soma'));
                        obj.changeRoiClass(source, []);
                    elseif contains(event.Modifier, 'shift')
                        obj.splitRois([], [])
                    else
                        obj.setMouseMode('Select')
                    end
                    
                case 'f'
                    if contains(event.Modifier, 'shift')
                        obj.repositionRois(struct('Label', 'Finish Reposition'), [])
                    else
                        obj.finishRoi();
                    end
                    
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
                    
                case {'8', 'n'}
                    obj.uiButtons.ShowAvg.Value = 1;
                    obj.showAvg(obj.uiButtons.ShowAvg); % Simulate button press
                    
                case '9'
                    obj.uiButtons.ShowMax.Value = 1;
                    obj.showMax(obj.uiButtons.ShowMax); % Simulate button press
                     
                case 'b'
                	obj.updateImageDisplay('BrightnessEqualized')

                case 'backspace'
                    switch obj.mouseMode
                                
                        case {'Draw', 'EditDraw'}
                            % Only remove things if current object is not uicontrol
                            if ~isa(gco, 'matlab.ui.control.UIControl')
                                if ~isempty(obj.selectedImpoint)
                                    obj.removeImpoint();
                                end
                            end
                            
                        otherwise
                            % Only remove things if current object is not
                            % uicontrol (exception if uicontrol is listbox)
                            if isequal(gco, obj.roiListBox) || ~isa(gco, 'matlab.ui.control.UIControl')
                                obj.removeRois(obj.selectedRois);
                            end
                            
                            
                    end
                    
                case {'return', 'space'}
                    if numel(obj.selectedRois) > 0
                        ch = obj.activeChannel;
                        isImported = arrayfun(@(roi) ~isempty(contains(roi.tags, 'imported')), obj.roiArray{ch}(obj.selectedRois), 'uni', 1);
                        obj.roiArray{ch}(obj.selectedRois(isImported)) = obj.roiArray{ch}(obj.selectedRois(isImported)).removeTag('imported');
                        obj.updateListBox(obj.selectedRois(isImported));
                        pause(0.05)
                        if isequal(gco, obj.roiListBox)
                            changeSelectedRoi(obj, 'next')
                        end
                    end
                    
                
                case 'leftarrow'
                    % Only move things if current object is not uicontrol
                    if ~isa(gco, 'matlab.ui.control.UIControl')
                        if contains(event.Modifier, 'shift')
                            if obj.activeChannel > 1 && obj.activeChannel <= obj.nLoadedChannels
                                newChannel = obj.loadedChannels(obj.activeChannel-1);
                                obj.changeActiveChannel(struct('String', newChannel));
                            end
                        elseif contains( event.Modifier, {'command', 'ctrl','control'})
                            xLim = get(obj.uiaxes.imagedisplay, 'XLim');
                            obj.moveImage([obj.settings.panFactor * diff(xLim), 0])
%                         elseif ~isempty(obj.selectedRois)   % move rois
%                         	obj.moveRoi( [-1, 0] );
%                             obj.shiftRoiPlot( [-1, 0, 0] );
                        elseif contains( event.Modifier, {'alt'})
                        	obj.moveRoi( [-1, 0] );
                            obj.shiftRoiPlot( [-1, 0, 0] );
                        else
                            obj.changeFrame([], [], 'prev')
                        end
                    else
                        if contains( event.Modifier, {'alt'})
                        	obj.moveRoi( [-1, 0] );
                            obj.shiftRoiPlot( [-1, 0, 0] );
                        end
                    end
                    
                case 'rightarrow'
                	% Only move things if current object is not uicontrol
                    if ~isa(gco, 'matlab.ui.control.UIControl')
                        if contains(event.Modifier, 'shift')
                            if obj.activeChannel >= 1 && obj.activeChannel < obj.nLoadedChannels
                                newChannel = obj.loadedChannels{obj.activeChannel+1};
                                obj.changeActiveChannel(struct('String', newChannel));
                            end
                        elseif contains( event.Modifier, {'command', 'ctrl','control'})
                            xLim = get(obj.uiaxes.imagedisplay, 'XLim');
                            obj.moveImage(-[obj.settings.panFactor * diff(xLim), 0])
%                         elseif ~isempty(obj.selectedRois)   % move rois
%                         	obj.moveRoi( [1, 0] );
%                             obj.shiftRoiPlot( [1, 0, 0] );
                        elseif contains( event.Modifier, {'alt'})
                        	obj.moveRoi( [1, 0] );
                            obj.shiftRoiPlot( [1, 0, 0] );
                        else
                            obj.changeFrame([], [], 'next')
                        end
                        
                    else
                        if contains( event.Modifier, {'alt'})
                        	obj.moveRoi( [1, 0] );
                            obj.shiftRoiPlot( [1, 0, 0] );
                        end
                    end
                
                case 'uparrow'
                    % Only move things if current object is not uicontrol
                    if ~isa(gco, 'matlab.ui.control.UIControl')
                        if ~isempty(obj.selectedRois)   % move rois
                        	obj.moveRoi( [0, -1] );
                            obj.shiftRoiPlot( [0, -1, 0] );
                        elseif contains( event.Modifier, {'command', 'ctrl','control'}) % move image                        
                            yLim = get(obj.uiaxes.imagedisplay, 'YLim');
                            obj.moveImage([0, -obj.settings.panFactor * diff(yLim)])
                        end
                        
                    else
                        if contains( event.Modifier, {'alt'})
                        	obj.moveRoi( [0, -1] );
                            obj.shiftRoiPlot( [0, -1, 0] );
                        end
                        
                    end

                case 'downarrow'
                    % Only move things if current object is not uicontrol
                    if ~isa(gco, 'matlab.ui.control.UIControl')
                        if ~isempty(obj.selectedRois)   % move rois
                        	obj.moveRoi( [0, 1] );
                            obj.shiftRoiPlot( [0, 1, 0] );
                        elseif  contains( event.Modifier, {'command', 'ctrl','control'}) % move image
                            yLim = get(obj.uiaxes.imagedisplay, 'YLim');
                            obj.moveImage([0, obj.settings.panFactor * diff(yLim)])
                        end
                    else
                        if contains( event.Modifier, {'alt'})
                        	obj.moveRoi( [0, 1] );
                            obj.shiftRoiPlot( [0, 1, 0] );
                        end
                    end
                    
                case 'backquote'
                    if ~isempty(event.Modifier) && isequal(event.Modifier{1}, 'shift')
                        obj.playbackspeed = obj.playbackspeed * 2;
                    else
                        obj.playbackspeed = obj.playbackspeed / 2;
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
                            obj.setMouseMode('Previous')
                        otherwise
                            obj.setMouseMode('Zoom In')
                    end
                    
                case 'w'
                    switch obj.mouseMode
                        case 'Zoom Out'
                            obj.setMouseMode('Previous')
                        otherwise
                            obj.setMouseMode('Zoom Out')
                    end
                    
                case 'r'
                    if contains('shift', event.Modifier)
                        obj.repositionRois(struct('Label', 'Undo Reposition and Continue'), [])
                    else
                        set(obj.uiaxes.imagedisplay, 'XLim', [0, obj.imWidth], 'YLim', [0, obj.imHeight])
                        set(obj.zoomOutline, 'Visible', 'off')
                        set(obj.uiaxes.signalplot, 'XLim', [0.99, obj.nFrames(obj.activeChannel)])
                    end
                    
                case {'1', '2', '3', '4'}
%                     src.String = event.Key;
                    if contains('shift', event.Modifier)
                        if isequal(event.Key, '1')
                            obj.setNewImageLimits([1, round(obj.imWidth/2)+10], [1, round(obj.imHeight/2)+10]);
                        elseif isequal(event.Key, '2')
                            obj.setNewImageLimits([round(obj.imWidth/2)-10, obj.imWidth], [1, round(obj.imHeight/2)+10]);
                        elseif isequal(event.Key, '3')
                            obj.setNewImageLimits([1, round(obj.imWidth/2)+10], [round(obj.imHeight/2)-10, obj.imHeight]);
                        elseif isequal(event.Key, '4')
                            obj.setNewImageLimits([round(obj.imWidth/2)-10, obj.imWidth], [round(obj.imHeight/2)-10, obj.imHeight]);
                        end
                    else
                    obj.changeActiveChannel(struct('String', event.Key), []);
                    end
                    
                case '0'
                    if strcmp(event.Character, '0')
                        obj.changeChannelDisplayMode(obj.uiButtons.ShowSingleChannel, []);
                    end
                    
                case 'm'
                    if contains(event.Modifier, {'command', 'control'})
                        % Save for something clever.
                    elseif contains(event.Modifier, {'shift'})
                        obj.mergeRois([], [])
                    else
                        obj.setMouseMode('Multiselect')
                    end
                case 'u'
                    if contains(event.Modifier, {'shift'})
                        obj.tagRois([], [], 'unchecked')
                    else
                        % Flush signal plot
                        lineobj = findall(obj.uiaxes.signalplot, 'Type', 'Line');
                        delete(lineobj(1:end-1))
                    end
                    
                case 'i'
                    obj.improveRoiEstimate()
                    
                case 'j'
                    obj.selectFrames('Start Selection')
                case 'p'
                    if obj.uiButtons.PlayVideo.Value
                        obj.uiButtons.PlayVideo.Value = 0;
                    else
                        obj.uiButtons.PlayVideo.Value = 1;
                        obj.playVideo([],[]);
                    end
                case 'k'
                    obj.checkRoiArtifacts(obj.selectedRois(1))
                    
                case 'tab'
                    if contains(event.Modifier, 'shift')
                        changeSelectedRoi(obj, 'previous')
                    else
                        changeSelectedRoi(obj, 'next')
                    end
                    
                case 'l'
                    %debug
                        
            end
            
        end
        
        
        function keyRelease(obj, ~, event)
        % Function to handle keyboard shortcuts. 
                switch event.Key
                    case 'j'
                        obj.selectFrames('Finish Selection')
                        
                    case 'v'
                        obj.setMouseMode('Previous')
                end
        end
        
        
        function mousePress(obj, ~, event)
        % Callback function to handle mouse presses on image obj
        
            % Record mouse press and current mouse position
            obj.mouseDown = true;
            ch = obj.activeChannel;
            
            % Get current mouse position in ax
            x = event.IntersectionPoint(1);
            y = event.IntersectionPoint(2);
%             fprintf('%d, %d\n', round(x), round(y))
            obj.prevMousePointAx = [x, y];
            obj.prevMouseClick = [x, y];

            currentFig = gcf;
            obj.prevMousePointFig = get(currentFig, 'CurrentPoint');
            
            % Determine if mouse click was inside of a RoI
            switch obj.mouseMode
                case {'Autodetect', 'EditSelect', 'Select', 'CrosshairSelect'}
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
%                     mask = obj.autodetectDonut(x, y);
                    
                    if wasInRoi && ~isempty(mask)
                        obj.addToActionLog(ch, selectedRoi, 'reshape')
                        obj.roiArray{ch}(selectedRoi) = obj.roiArray{ch}(selectedRoi).reshape('Mask', mask);
                        obj.modifySignalArray(selectedRoi, 'reset')
                        obj.updateRoiPlot(selectedRoi);
                        
%                         if obj.uiButtons.ShowSignal.Value
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
%                     obj.improveRoiEstimate()
                    
                case 'CrosshairSelect'

                    if event.Button == 3
                        if wasInRoi
                            obj.removeRois(selectedRoi, obj.activeChannel);
                        end
                    
                    elseif wasInRoi
                        for i = 1:2
                            obj.improveRoiEstimate(selectedRoi)
                        end
                        obj.selectRois(selectedRoi, 'normal')

                    elseif ~wasInRoi
                        
                        % Create a temporary circular roi...
                        circleCoords = [x, y, obj.roiOuterDiameter/2];
                        newRoi = RoI('Circle', circleCoords, [obj.imHeight, obj.imWidth]);
                        newRoi = obj.editRoiProperties(newRoi);
                        obj.addRois(newRoi);
                        obj.selectRois(obj.roiCount{obj.activeChannel}, 'normal')
                        
                        % ...Then use the improveRoiEstimate to make a
                        % better spatial fit
                        obj.improveRoiEstimate()
                        
                        % Edit the action log to make this on action
                        % instead of two.
                        
                        ii = obj.logPosition;
                        obj.actionLog(ii-1).rois = obj.actionLog(ii).rois;
                        obj.logPosition = ii-1;
                        obj.selectRois(obj.roiCount{obj.activeChannel}, 'normal')

                    end
                    
                    
                case 'EditSelect'
                    
                    if wasInRoi
                        
                        obj.selectedRois = selectedRoi;
                        
                        roi = obj.roiArray{ch}(selectedRoi);
                        
                        if strcmp(roi.shape, 'Mask') % Use boundary to create impoints
                            
                            x = roi.boundary{1}(:, 2)';
                            y = roi.boundary{1}(:, 1)';

                            k = convhull(x,y, 'simplify', true);

                        	obj.tmpRoiPosX = roi.boundary{1}(k(1:end-1), 2)';
                            obj.tmpRoiPosY = roi.boundary{1}(k(1:end-1), 1)';
                            
                        elseif strcmp(roi.shape, 'Polygon')
                            obj.tmpRoiPosX = roi.coordinates(:, 1)';
                            obj.tmpRoiPosY = roi.coordinates(:, 2)'; 
                        elseif strcmp(roi.shape, 'Circle')
                            obj.tmpRoiPosX = roi.boundary{1}(1:5:end, 2)';
                            obj.tmpRoiPosY = roi.boundary{1}(1:5:end, 1)';
                        else
                            error('Edit is not implemented for this roi shape')
                        end
                        
                        clearvars roi

                        % Add impoints to roimanager.
                        for i = 1:length(obj.tmpRoiPosX)
                            x = obj.tmpRoiPosX(i);
                            y = obj.tmpRoiPosY(i);
                            obj.addImpoint(x, y);
                        end
                        
                        obj.drawTmpRoi();

                        % Remove plot of selected roi
                        h = obj.RoiPlotHandles{ch}(obj.selectedRois);
                        set(h, 'XData', 0, 'YData', 0)
                                  
                        % Set mousemode to editdraw
                        obj.setMouseMode('EditDraw')
                    end

                case 'Set Roi Diameter'
                    obj.roiTemplateCenter = [x, y];
                    obj.plotRoiTemplate();

                case 'Select'           % Change status of roi if it was clicked
                    if ~wasInRoi
                        selectedRoi = nan;
                    end
                    
                    if event.Button == 3
                        if ~isnan(selectedRoi)
                            obj.removeRois(selectedRoi, obj.activeChannel);
                        end

%                         obj.selectRois(selectedRoi, 'normal', true)
%                         obj.displayRoiContextMenu(selectedRoi)
                    else
                        obj.selectRois(selectedRoi, currentFig.SelectionType, true)
                    end
                 
                case {'Zoom In', 'Multiselect'}
                    if isempty(obj.zoomRectPlotHandle)
                        obj.zoomRectPlotHandle = plot(obj.uiaxes.imagedisplay, nan, nan, 'Color', 'white', 'PickableParts', 'none', 'HitTest', 'off');
                    else
                        set(obj.zoomRectPlotHandle, 'XData', nan, 'Ydata', nan)
                    end
                    set(obj.zoomRectPlotHandle, 'Visible', 'on')
                 
                case 'Zoom Out'
                    obj.imageZoom('out');
            end
            
        end
        
        
        function mousePressPlot(obj, ~, event)
        % Callback function for mousepress within signal plot ax
            obj.mouseDown = true;
            
            % Get current mouse position in ax.
            newMousePointAx = get(obj.uiaxes.signalplot, 'CurrentPoint');
            obj.prevMousePointAx = newMousePointAx(1, 1:2);
            obj.prevMouseClick = newMousePointAx(1, 1:2);

            switch obj.mouseMode
                case 'Zoom In'
                    axes(obj.uiaxes.signalplot)

                    if isempty(obj.zoomRectPlotHandle)
                        obj.zoomRectPlotHandle = plot(obj.uiaxes.signalplot, nan, nan, 'Color', [0.6,0.6,0.9], 'LineStyle', '-', 'Marker', 'none');
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
        
        
        function mouseRelease(obj, ~, ~)
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
                        if isequal(gca, obj.uiaxes.imagedisplay)
                            obj.imageZoom('in');
                        elseif isequal(gca, obj.uiaxes.signalplot)
                            obj.plotZoom('in')
                        end
                    else
                        set(obj.zoomRectPlotHandle, 'Visible', 'off')
                        obj.imageZoomRect(); % Set new limits based on new and old point
                    end
                    
                    delete(obj.zoomRectPlotHandle)
                    obj.zoomRectPlotHandle = gobjects(0);
                    
                case 'Multiselect'
                    currentPoint = get(obj.uiaxes.imagedisplay, 'CurrentPoint');
                    currentPoint = currentPoint(1, 1:2);
                    
                    % make sure selection only happens if we press in the image
                    if ~obj.isCursorInsideAxes(obj.uiaxes.imagedisplay)
                        return
                    end
                    
                    if ~all((abs(obj.prevMouseClick - currentPoint)) < 1) % No movement
                        obj.multiSelectRois(); % Set new limits based on new and old point
                        obj.setMouseMode('Select')
                    end
                    
                    delete(obj.zoomRectPlotHandle)
                    obj.zoomRectPlotHandle = gobjects(0);
                    
                case 'Select'
                    if any(obj.roiDisplacement ~= 0) && ~isempty(obj.selectedRois)
                        obj.selectedRois = sort(horzcat(obj.selectedRois, obj.unselectedRois));
                        obj.selectedRois = unique(obj.selectedRois);
                        obj.moveRoi(obj.roiDisplacement);
                        obj.roiDisplacement = 0;
                        obj.unselectedRois = [];
                        
%                     elseif isequal(currentFig.SelectionType, 'normal')
                    else
%                         if numel(obj.selectedRois)==1
%                             obj.zoomOnRoi(obj.selectedRois(end))
%                         end
                        obj.deselectRois(obj.unselectedRois)
                    end
                    
                case 'Freehand'
                    obj.traceDendrites('pause')
            end      
            
        end
        
        
        function mouseOver(obj, ~, ~)
        % Callback funtion to handle mouse movement over figure
            
            % Get mousepoint coordinates in ax and figure units
            currentFig = gcf;
            newMousePointFig = get(currentFig, 'CurrentPoint');
            
            obj.updatePointer()
            
            if obj.isCursorInsideAxes(obj.uiaxes.imagedisplay) && obj.mouseDown   % "Click and Drag"
%                 set(obj.fig, 'CurrentObject', obj.panels.image) Why is this here?
                newMousePointAx = get(obj.uiaxes.imagedisplay, 'CurrentPoint');
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
                    case 'Freehand'
                        obj.traceDendrites()

                end
                
            elseif obj.isCursorInsideAxes(obj.uiaxes.signalplot) && obj.mouseDown 
                newMousePointAx = get(obj.uiaxes.signalplot, 'CurrentPoint');
                newMousePointAx = newMousePointAx(1, 1:2);
                
                switch obj.mouseMode
                    case {'Zoom In'}
                        % Plot a rectangle 
                        x1 = obj.prevMousePointAx(1);
                        x2 = newMousePointAx(1);
                        y1 = obj.prevMousePointAx(2);
                        y2 = newMousePointAx(2);
                        set(obj.zoomRectPlotHandle, 'XData', [x1, x1, x2, x2, x1], ...
                                                    'YData', [y1, y2, y2, y1, y1])
                end
                
            elseif obj.isCursorInsideAxes(obj.uiaxes.imagedisplay) && ~obj.mouseDown
                if ~isempty(obj.circleToolHandle)
                    newMousePointAx = get(obj.uiaxes.imagedisplay, 'CurrentPoint');
                    newMousePointAx = newMousePointAx(1, 1:2);
                    tmpCoords = [newMousePointAx, obj.circleToolCoords(3)];
                    obj.plotCircleTool(tmpCoords);
                end
                
                if ~isempty(obj.crosshairHandle)
                    newMousePointAx = get(obj.uiaxes.imagedisplay, 'CurrentPoint');
                    newMousePointAx = newMousePointAx(1, 1:2);
                    obj.plotCrosshair(newMousePointAx)
                end
                
            elseif obj.isCursorInsideAxes(obj.uiaxes.smallroi) && obj.doDrawRoiOutline
                obj.drawOutline()
                
            
            else % Release mouseDown if mouse moves out of image.
                if ~isempty(obj.zoomRectPlotHandle) && isvalid(obj.zoomRectPlotHandle)
                    parentAx = obj.zoomRectPlotHandle.Parent;
                    newMousePointAx = get(parentAx, 'CurrentPoint');
                    newMousePointAx = newMousePointAx(1, 1:2);

                    x1 = obj.prevMouseClick(1);
                    y1 = obj.prevMouseClick(2);

                    if newMousePointAx(1) < parentAx.XLim(1)
                        x2 = parentAx.XLim(1);
                    elseif newMousePointAx(1) > parentAx.XLim(2)
                        x2 = parentAx.XLim(2);
                    else
                        x2 = newMousePointAx(1);
                    end
                    
                    if newMousePointAx(2) < parentAx.XLim(1)
                        y2 = parentAx.YLim(1);
                    elseif newMousePointAx(2) > parentAx.YLim(2)
                        y2 = parentAx.YLim(2);
                    else
                        y2 = newMousePointAx(2);
                    end
                    
                    set(obj.zoomRectPlotHandle, 'XData', [x1, x1, x2, x2, x1], ...
                                                'YData', [y1, y2, y2, y1, y1])
                    
                end
%                 set(obj.fig, 'CurrentObject', obj.fig)
%                 if obj.mouseDown
%                     obj.mouseDown = false;
%                 end
            end
        end
        
        
% % % % Zoom and pan functions
        
        function zoomOnRoi(obj, i)
            
            % Zoom in on roi if roi is not within limits.
            xLim = get(obj.uiaxes.imagedisplay, 'XLim');
            yLim = get(obj.uiaxes.imagedisplay, 'YLim');

            ch = obj.activeChannel;
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
                        zoomF = -obj.settings.zoomFactor;
                case 'out'
                        zoomF = obj.settings.zoomFactor*2;
            end
                    
            xLim = get(obj.uiaxes.imagedisplay, 'XLim');
            yLim = get(obj.uiaxes.imagedisplay, 'YLim');

            currentFig = gcf;
            mp_f = get(currentFig, 'CurrentPoint');

            mp_a = get(obj.uiaxes.imagedisplay, 'CurrentPoint');
            mp_a = mp_a(1, 1:2);

            % Find ax position and limits in figure units.
            figsize = get(currentFig, 'Position');
            if isequal(currentFig, obj.fig)
                panelPos = get(obj.panels.image, 'Position') .* [figsize(3:4), figsize(3:4)];  % pixel units
                axPos = get(obj.uiaxes.imagedisplay, 'Position') .* [panelPos(3:4), panelPos(3:4)];  % pixel units
                axPos = [panelPos(1:2), 0, 0] + axPos;
            elseif isequal(currentFig, obj.imfig)
                axPos = get(obj.uiaxes.imagedisplay, 'Position') .* [figsize(3:4), figsize(3:4)];
            end
                
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
                xLimNew = [1, obj.imWidth];
            elseif xLimNew(1) <= 1
                xLimNew = xLimNew - xLimNew(1) + 1;
            elseif xLimNew(2) > obj.imWidth
                xLimNew = xLimNew - (xLimNew(2) - obj.imWidth);
            end

            if diff(yLimNew) > obj.imHeight
                yLimNew = [1, obj.imHeight];
            elseif yLimNew(1) <= 1
                yLimNew = yLimNew - yLimNew(1) + 1;
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
            
            if isequal(obj.zoomRectPlotHandle.Parent, obj.uiaxes.imagedisplay)
                setNewImageLimits(obj, xLimNew, yLimNew)
            elseif isequal(obj.zoomRectPlotHandle.Parent, obj.uiaxes.signalplot)
                setXLimitsZoom(obj, xLimNew)
                % Change frame so that current frame is in center of region
                % which is zoomed in on.
                obj.changeFrame(struct('String', num2str(round(mean(xLimNew)))), [], 'jumptoframe');
            else
                error('This is a bug, please report')
            end
            
        end
        
        
        function setNewImageLimits(obj, xLimNew, yLimNew)
        %setNewImageLimits Set new image limits (for zooming or panning).    
            
            set(obj.uiaxes.imagedisplay, 'units', 'pixel')
            pos = get(obj.uiaxes.imagedisplay, 'Position');
            set(obj.uiaxes.imagedisplay, 'units', 'normalized')

            axAR = pos(3)/pos(4); % Axes aspect ratio.
            
            xRange = diff(xLimNew); yRange = diff(yLimNew);

            % Adjust limits so that the zoomed image fills up the display
            if xRange/yRange > axAR
                yLimNew = yLimNew + [-1, 1] * (xRange/axAR - yRange)/2 ;
            elseif xRange/yRange < axAR
                xLimNew = xLimNew + [-1, 1] * (yRange*axAR-xRange)/2;
            end
            
            if diff(xLimNew) > obj.imWidth
                xLimNew = [1, obj.imWidth];
            elseif xLimNew(1) <= 1
                xLimNew = xLimNew - xLimNew(1) + 1;
            elseif xLimNew(2) > obj.imWidth
                xLimNew = xLimNew - (xLimNew(2) - obj.imWidth);
            end

            if diff(yLimNew) > obj.imHeight
                yLimNew = [1, obj.imHeight];
            elseif yLimNew(1) <= 1
                yLimNew = yLimNew - yLimNew(1) + 1;
            elseif yLimNew(2) > obj.imHeight
                yLimNew = yLimNew - (yLimNew(2) - obj.imHeight);
            end
            
            set(obj.uiaxes.imagedisplay, 'XLim', xLimNew, 'YLim', yLimNew)
            plotZoomRegion(obj, xLimNew, yLimNew)

        end
        
        
        function plotZoom(obj, direction)
           
            oldLim = obj.uiaxes.signalplot.XLim;
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
            
            absLimits = [1, obj.nFrames(obj.activeChannel)];
            oldLimits = obj.uiaxes.signalplot.XLim;
            
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
        
        
        function plotZoomRegion(obj, xLimNew, yLimNew)
        
            xRange = range(xLimNew);
            yRange = range(yLimNew);

            nFactor = [obj.imWidth, obj.imHeight, obj.imWidth, obj.imHeight];

            rect1 = [1,1,obj.imWidth, obj.imHeight] ./ nFactor;
            rect2 = [xLimNew(1), yLimNew(1), xRange, yRange] ./ nFactor;

            % Scale and offset:
            rect1 = (rect1 .* xRange .* 0.13) + [xLimNew(1), yLimNew(1), 0, 0]; 
            rect2 = (rect2 .* xRange .* 0.13) + [xLimNew(1), yLimNew(1), 0, 0];

            rect1(1:2) = rect1(1:2) + [xRange * 0.025, yRange * 0.025];
            rect2(1:2) = rect2(1:2) + [xRange * 0.025, yRange * 0.025];

            xData1 = [rect1(1), rect1(1)+rect1(3), rect1(1)+rect1(3), rect1(1)];
            xData2 = [rect2(1), rect2(1)+rect2(3), rect2(1)+rect2(3), rect2(1)];
            yData1 = [rect1(2), rect1(2), rect1(2)+rect1(4), rect1(2)+rect1(4)];
            yData2 = [rect2(2), rect2(2), rect2(2)+rect2(4), rect2(2)+rect2(4)];

            xData1(end+1) = xData1(1); xData2(end+1) = xData2(1);
            yData1(end+1) = yData1(1); yData2(end+1) = yData2(1);

            if isempty(obj.zoomOutline)
%                 hold(obj.ax, 'on')
                obj.zoomOutline = gobjects(2, 1);
                obj.zoomOutline(1) = plot(obj.uiaxes.imagedisplay, xData1, yData1, 'c', 'LineWidth', 1);
                obj.zoomOutline(2) = plot(obj.uiaxes.imagedisplay, xData2, yData2, 'c', 'LineWidth', 1);
            else
                set(obj.zoomOutline(1), 'XData', xData1, 'YData', yData1)
                set(obj.zoomOutline(2), 'XData', xData2, 'YData', yData2)
            end

            if isequal(round(xLimNew), [1, obj.imWidth]) && isequal(round(yLimNew), [1, obj.imHeight]) 
                set(obj.zoomOutline, 'Visible', 'off')
            else
                set(obj.zoomOutline, 'Visible', 'on')
            end
        end
        
        
        function setXLimitsPan(obj, newLimits)
        % Check that limits are within absolute limits (force if not)
        
        % This is a lot of conditions. Should it be this effin long??
            absLimits = [1, obj.nFrames(obj.activeChannel)];
            tmpLimits = obj.uiaxes.signalplot.XLim;
            
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
            set(obj.uiaxes.signalplot, 'XLim', newLimits);
        end
        
        
        function moveImage(obj, shift)
        % Move image in ax according to shift
            
            % Get ax position in figure coordinates
            figsize = get(obj.fig, 'Position');
            panelPos = get(obj.panels.image, 'Position') .* [figsize(3:4), figsize(3:4)];  % pixel units
            axPos = get(obj.uiaxes.imagedisplay, 'Position') .* [panelPos(3:4), panelPos(3:4)];  % pixel units
            axPos = [panelPos(1:2), 0, 0] + axPos;
        
            % Get current axes limits
            xlim = get(obj.uiaxes.imagedisplay, 'XLim');
            ylim = get(obj.uiaxes.imagedisplay, 'YLim');
            
            % Convert mouse shift to image shift
            imshift = shift ./ axPos(3:4) .* [diff(xlim), diff(ylim)];
            xlim = xlim - imshift(1);
            ylim = ylim + imshift(2);

            % Dont move outside of image boundaries..
            if xlim(1) > 0 && xlim(2) < obj.imWidth
                set(obj.uiaxes.imagedisplay, 'XLim', xlim);
                plotZoomRegion(obj, xlim, get(obj.uiaxes.imagedisplay, 'YLim'))

            end
            
            if ylim(1) > 0 && ylim(2) < obj.imHeight
                set(obj.uiaxes.imagedisplay, 'YLim', ylim);
                plotZoomRegion(obj, get(obj.uiaxes.imagedisplay, 'XLim'), ylim)
            end
        end
        
        
        function undockImageWindow(obj, src, ~)
            switch src.String
                case 'Undock Image Window'
                    obj.imfig = figure();
                    obj.imfig.MenuBar = 'none';
                    set(obj.imfig, 'WindowScrollWheelFcn', {@obj.changeFrame, 'mousescroll'}, ...
                    'WindowKeyPressFcn', @obj.keyPress, ...
                    'WindowButtonUpFcn', @obj.mouseRelease, ...
                    'WindowButtonMotionFcn', @obj.mouseOver )
                    set(obj.uiaxes.imagedisplay, 'Parent', obj.imfig)
                    if obj.uiButtons.ShowSignal.Value
                        set(obj.uiaxes.imagedisplay, 'Position', [0.03, 0.03, 0.94, 0.94])
                    end
                    set(obj.uiButtons.UndockImage, 'String', 'Dock Image Window')
                    
                case 'Dock Image Window'
                    set(obj.uiaxes.imagedisplay, 'Parent', obj.panels.image)
                    close(obj.imfig)
                    set(obj.uiButtons.UndockImage, 'String', 'Undock Image Window')
                    if obj.uiButtons.ShowSignal.Value
                        set(obj.uiaxes.imagedisplay, 'Position', [0.12, 0.2, 0.76, 0.76])
                    end

            end
            
        end
        
        
% % % %  Methods for loading images

        function loadStack(obj, src, ~)
        % Load an image stack into the GUI

            if ~isempty(obj.sessionObj) &&  ~isa(src, 'matlab.ui.container.Menu')
                sessionDir = getSessionFolder(obj.sessionObj.sessionID);
                folderPath = fullfile(sessionDir, 'average_images');
                listing = dir(fullfile(folderPath, '*binned-avg.tif'));
                fileName = {listing(1).name};
            else

                % Set path for where to start browsing.
                if isempty(obj.initPath)
                    initpath = obj.fileSettings.initPath;
                else
                    initpath = obj.initPath;
                end

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
            
            sessionID = regexp(fileName{1}, obj.fileSettings.sIdExpr, 'match');
            if ~isempty(sessionID) 
                obj.editExpName.String = sessionID;
            elseif ~isempty(obj.sessionObj)
                obj.editExpName.String = obj.sessionObj.sessionID;
            end

            
            % Determine channel numbers. Assumes that all names 
            % are built the same way.
            
            chMatch = strfind(fileName{1}, obj.fileSettings.chExpr);
            
            if ~isempty(chMatch)
                % Find channel expression and number in filename
                [chMatchBeg, chMatchEnd] = regexp(fileName{1}, [obj.fileSettings.chExpr '\d*']);
                
                % Find unique channel number and number of channels
                chNumbers = cellfun(@(fn) fn(chMatchBeg(1):chMatchEnd(1)), fileName, 'uni', 0);
                
                [imgChannels, ~, ic] = unique(chNumbers);
                nChannels = numel(imgChannels);
                imgChannels = strrep(imgChannels, obj.fileSettings.chExpr, '');
               
                % Sort filenames after channels
                fileName = arrayfun(@(ch) fileName(ic==ch), 1:nChannels, 'uni', 0 );
                
                % Note: The cat function concatenates into a string array.
                % It only works for filenames that has the same number of
                % characters. This is not ideal, and should be changed.
                
                try
                    fileName = cat(1, fileName{:});
                catch
                    [cdata,map] = imread('trees.tif'); 
                    msgbox('Number of files per channel must be equal.', ...
                        sprintf('Error @ %s', obj.uiButtons.LoadImages.String), ...
                        'custom',cdata,map);
                    error(['Error using %s \n', ...
                           'Number of files per channel must be equal.'], obj.uiButtons.LoadImages.String )
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
            obj.imgBa = cell(nChannels, 1);
            
            if isempty(obj.roiCount)
                % Set roiArray to cell array of roi arrays (one per channel)
                obj.roiArray = arrayfun(@(i) RoI.empty, 1:nChannels, 'uni', 0);
                obj.roiCount = arrayfun(@(i) 0, 1:nChannels, 'uni', 0);
                obj.RoiPlotHandles = cell(nChannels, 1);
                obj.RoiTextHandles = cell(nChannels, 1);
                obj.RoiLinePos = arrayfun(@(i) cell(0, 2), 1:nChannels, 'uni', 0);
                obj.RoiTextPos = arrayfun(@(i) cell(0, 1), 1:nChannels, 'uni', 0);
            end

            % Determine number of parts and load image timeseries for all parts and channels.
            nParts = size(fileName, 2);
            stacks = cell(nChannels, nParts);
            for i = 1:nParts
                for ch = 1:nChannels
                    msg = sprintf('Please wait... Loading calcium images (part %d/%d, ch %d/%d)...', i, nParts, ch, nChannels);
                    stacks{ch, i} = load.tiffs2mat(imFilePath{ch, i}, true, msg);
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
            
            % Changed my mind, find number of frames per channel.This is
            % relevant if e.g loading recordings from different days to
            % different channels.
            obj.nFrames = cellfun(@(im) size(im, 3), obj.imgTseries, 'uni', 1);
            
            % Reinitialize signalArray
            obj.signalArray = struct;
            obj.initializeSignalArray(1:nChannels);
            
%             % Check if size of rois are different from image size
%             for ch = 1:nChannels
%                 if obj.roiCount{ch} ~= 0
%                     obj.roiArray{ch} = checkRoiSizes(obj.roiArray{ch}, [obj.imHeight, obj.imWidth]);
%                 end
%             end
               
            % Set current channel to the first one.
            obj.activeChannel = 1;
            if isempty(imgChannels); imgChannels = {'1'}; end
            set(obj.channel, 'String', imgChannels{obj.activeChannel})
            
            % Add image channels to loaded channels.
            obj.loadedChannels = imgChannels;
            obj.nLoadedChannels = numel(obj.loadedChannels);
            
            % Extract filename "base" (remove parts expression and number...)
            ptMatch = strfind(fileName{1}, obj.fileSettings.ptExpr);
            if ~isempty(ptMatch)
                [ptMatchBeg, ptMatchEnd] = regexp(fileName{1}, [obj.fileSettings.ptExpr '\d*']);
            
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
            nImages = obj.nFrames(obj.activeChannel);
%             if nFrames < 11
%                 sliderStep = [1/(nFrames-1), 1/(nFrames-1)];
%             else
%                 sliderStep = [1/(nFrames-1), 10/(nFrames-10)];
%             end
            
            set(obj.textCurrentFrame, 'String', ['Current Frame: 1/' num2str(nImages)] )
%             set(obj.textCurrentFileName, 'String',  obj.loadedFileName{obj.activeChannel})
            set(obj.inputJumptoFrame, 'String', '1')
            set(obj.frameslider, 'maximum', nImages, 'VisibleAmount', 0.1);
            obj.fsContainer.Visible = 'on';

%             set(obj.frameslider, 'Max', obj.nFrames, ...
%                                  'Value', obj.currentFrameNo, ...
%                                  'SliderStep', sliderStep, ...
%                                  'Visible', 'on');
            
            % Set limits of signal Plot
            set(obj.uiaxes.signalplot, 'Xlim', [0.99, nImages])
                   
            obj.resetSignalPlot;
            
            % Reset some buttons
            obj.switchToggleButton(obj.uiButtons.ShowAvg, false)
                                         
            % Display image
            updateImageDisplay(obj);
            
            obj.uiButtons.ShowSignal.Enable = 'on';
            
%             % Load rois
%             obj.loadRois(source);

        end
        
        
        function loadStackProjections(obj)
        % Save average and max stack projections in the GUI
        %
        % Save projection images so that they are only calculated once...
            
        % obj.improjections.avg
        % obj.improjections.max
        
            obj.imgMax = max(obj.imgTseries, [], 3);
        	obj.imgAvg = uint8(mean(obj.imgTseries, 3)); 
                        
        end
        
        
        function loadSession(obj, sessionObj)
            % Warning: This function is very ad hoc and might have the
            % weirdest consequences.
            
            obj.sessionObj = sessionObj;
            
            if obj.settings.useReferenceChannel
                sessionDir = getSessionFolder(obj.sessionObj.sessionID);
                folderPath = fullfile(sessionDir, 'mean_image_stacks');
                listing = dir(fullfile(folderPath, '*runningAvg*.tif'));
                fileName = listing(1).name;
                
                obj.initPath = folderPath;
                
                obj.editExpName.String = obj.sessionObj.sessionID;
                
                
                ch = 2;
                obj.changeActiveChannel(struct('String', obj.loadedChannels(ch)));
                loadpath = fullfile(folderPath, fileName);
                obj.imgTseries{ch} = load.tiffs2mat(loadpath, true, 'Loading Images');
            	obj.imgAvg{ch} = uint8(mean(obj.imgTseries{ch}, 3));
            	obj.imgMax{ch} = max(obj.imgTseries{ch}, [], 3);
                obj.nFrames(ch) = size(obj.imgTseries{ch}, 3);
                obj.loadedFileName{ch} = fileName;
                
                
                % (Re)set current frame to first frame
                obj.currentFrameNo = 1;

                % Set up frame indicators and frameslider
                nImages = obj.nFrames(ch);
                set(obj.textCurrentFrame, 'String', ['Current Frame: 1/' num2str(nImages)] )
%                 set(obj.textCurrentFileName, 'String',  obj.loadedFileName{ch})
                set(obj.inputJumptoFrame, 'String', '1')
                set(obj.frameslider, 'maximum', nImages, 'VisibleAmount', 0.1);
                obj.fsContainer.Visible = 'on';

                % Set limits of signal Plot
                set(obj.uiaxes.signalplot, 'Xlim', [0.99, nImages])
                
                % Display image
                updateImageDisplay(obj);
            end
            
        end
        
        
        function initializeSignalArray(obj, channels)
            % Make signalArray with number of channels.
            
            signalNames = {'roiMeanF', 'npilMediF', 'demixedMeanF', 'dff', ...
                'deconvolved', 'denoised', 'spikes'};
            
            for i = channels
                nSamples = obj.nFrames(i);
                nRois = max([100, ceil(obj.roiCount{i}/100)*100]);
                for j = 1:numel(signalNames)
                    obj.signalArray(i).(signalNames{j}) = nan(nSamples, nRois, 'double');
                end
                obj.signalArray(i).spkThr = ones(1, nRois, 'single');
                obj.signalArray(i).spkSnr = ones(1, nRois, 'single');
                obj.signalArray(i).lamPr = ones(1, nRois, 'single');
            end

            for k = 1:numel(signalNames)
                obj.hlineSignal.(signalNames{k}) = gobjects(0);
            end
                        
        end
        
        
        function modifySignalArray(obj, roiInd, action, chInd, editFields)
            
            % Editfield was added to only reset some (not all fields).
            
            if nargin < 4 || isempty(chInd); chInd = obj.activeChannel; end
            if nargin < 5 || isempty(editFields); editFields = 'all'; end
            
            fields = fieldnames(obj.signalArray);
            
            if strcmp(editFields, 'all')
                editFields = fields;
            end
            
            if isequal(action, 'initialize')
                initializeSignalArray(obj, chInd)
            end
            
            for ch = chInd
                
                % Expand array if necessary
                expandArray = false;
                nCol = size(obj.signalArray(ch).(fields{1}), 2);
                switch action 
                    case {'append', 'insert'}
                        if nCol < obj.roiCount{ch}
                            expandArray = true;
                            nExpand = ceil((obj.roiCount{ch} - nCol)/100)*100;
                        end
                end
                
                for fNo = 1:numel(fields)
                    
                    if expandArray
                        obj.signalArray(ch).(fields{fNo})(:, end:end+nExpand) = nan;
                        nCol = size(obj.signalArray(ch).(fields{fNo}), 2);
                    end

                    switch action
                        case 'reset'
                            if isequal(fields{fNo}, 'spikeThreshold')
                                continue
                            elseif ~contains(fields{fNo}, editFields)
                                continue
                            end
                            obj.signalArray(ch).(fields{fNo})(:, roiInd) = nan;

                        case 'insert'
                            newInd = 1:nCol;
                            newInd = setdiff(newInd, roiInd);
                            
                            obj.signalArray(ch).(fields{fNo})(:, newInd) = obj.signalArray(ch).(fields{fNo})(:, 1:numel(newInd));
                            obj.signalArray(ch).(fields{fNo})(:, roiInd) = nan;

                        case 'remove'
                            if ~isempty(roiInd)
                                newInd = 1:nCol;
                                newInd = setdiff(newInd, roiInd);
                                obj.signalArray(ch).(fields{fNo})(:, 1:numel(newInd)) = obj.signalArray(ch).(fields{fNo})(:, newInd);
                            end
                    end
                end 
            end
        end
        
        
% % % % Methods for changing frames and updating images
        
        function resetImageDisplay(obj, ~, ~)
            children = obj.uiaxes.imagedisplay.Children;
            isWrongImg = cell2mat(arrayfun(@(ch) isa(ch, 'matlab.graphics.primitive.Image') & ~isequal(obj.himage, ch), children, 'uni', 0));
            delete(children(isWrongImg));
%             obj.himage = [];
        end
        
        
        function updateImageDisplay(obj, imageToDisplay)
        % Updates the image in the image display
        
            if all( cellfun(@(ts) isempty(ts), obj.imgTseries) ); return; end
        
            frameNo = obj.currentFrameNo;
            nImages = obj.nFrames(obj.activeChannel);
            if nImages > 1 
                set( obj.textCurrentFrame, 'String', ...
                      ['Current Frame: ' num2str(obj.currentFrameNo) '/' num2str(nImages)] )
            end
            
            if nargin < 2; imageToDisplay = 'Unspecified'; end

            showMovingAvg = get(obj.uiButtons.ShowMovingAvg, 'Value');
            showMovingStd = get(obj.uiButtons.ShowMovingStd, 'Value');
            showMovingMax = get(obj.uiButtons.ShowMovingMax, 'Value');
            showAvg = get(obj.uiButtons.ShowAvg, 'Value');
            showMax = get(obj.uiButtons.ShowMax, 'Value');

            % Get framenumbers to run window on
            if showMovingAvg || showMovingMax || showMovingStd
                if frameNo < ceil(obj.binningSize/2)
                    binIdx = 1:obj.binningSize;
                elseif (nImages - frameNo)  < ceil(obj.binningSize/2)
                    binIdx = nImages-obj.binningSize+1:nImages;
                else
                    binIdx = frameNo - floor(obj.binningSize/2):frameNo + floor(obj.binningSize/2);
                end
                 
            end
            
            % Show one or multiple channels?
            switch obj.channelDisplayMode
                case 'single'
                    chNo = obj.activeChannel;
                case 'multi'
                    chNo = 1:obj.nLoadedChannels;
                case 'correlation'
                    chNo = obj.activeChannel;
            end
             
            switch imageToDisplay
                case 'Unspecified'
                    % Result of integrating new things...
                    if strcmp(obj.channelDisplayMode, 'correlation') 
                        if strcmp(obj.uiButtons.ShowSingleChannel.String, 'Show All Channels')
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
                    caframe{1} = obj.imgCn{obj.activeChannel};
                    obj.changeChannelDisplayMode(struct('String', 'Show Correlation Image'), []);
                case 'Boosted Activity Image'
                    caframe{1} = obj.imgBa{obj.activeChannel};
                    obj.changeChannelDisplayMode(struct('String', 'Show Enhanced Contrast Image'), []);
                case 'BrightnessEqualized'
                    caframe{1} = adapthisteq(obj.imgAvg{chNo}, ...
                                                'NumTiles', [32, 32], ...
                                                'ClipLimit', 0.015, ...
                                                'Distribution', 'rayleigh');
                case 'Gradient Image'  
                    
                    grIm = gradient(single(obj.imgAvg{chNo}));
                    grIm = padarray(grIm,[1,1],0,'pre');

                    caframe{1} = utilities.makeuint8(grIm);
                            
            end

            
            caframe = cat(3, caframe{:});
            if strcmp(obj.channelDisplayMode, 'multi')
                caframe = obj.setChColors(caframe);
            end
            
            if isempty(obj.himage) % First time initialization. Create image object
                obj.himage = imshow(caframe, [0, 255], 'Parent', obj.uiaxes.imagedisplay, 'InitialMagnification', 'fit');
                set(obj.himage, 'ButtonDownFcn', @obj.mousePress)
               
                if ~ishold(obj.uiaxes.imagedisplay)  
                    hold(obj.uiaxes.imagedisplay, 'on') 
                end
                
                % Set image limits. When these are specified after the hold
                % on, axes limits are static.
                imSize = size(caframe);
                set(obj.uiaxes.imagedisplay, 'XLim', [1,imSize(2)]+0.5, ...
                                        'YLim', [1,imSize(1)]+0.5);
            else
                if obj.uiButtons.ShowMax.Value
                    clim = [obj.brightnessDictionary.max.min, obj.brightnessDictionary.max.max];
                elseif obj.uiButtons.ShowAvg.Value
                    clim = [obj.brightnessDictionary.avg.min, obj.brightnessDictionary.avg.max];
                else
                    clim = [obj.brightnessDictionary.norm.min, obj.brightnessDictionary.norm.max];
                end
                set(obj.himage, 'cdata', caframe);
                set(obj.uiaxes.imagedisplay, 'CLim', clim)        
               
            end
            
            if obj.uiButtons.ShowMax.Value
                set(obj.brightnessSlider, 'Low', obj.brightnessDictionary.max.min);
                set(obj.brightnessSlider, 'High', obj.brightnessDictionary.max.max);
%                 obj.changeBrightness(obj.brightnessSlider, [])
            
            elseif obj.uiButtons.ShowAvg.Value
                set(obj.brightnessSlider, 'Low', obj.brightnessDictionary.avg.min);
                set(obj.brightnessSlider, 'High', obj.brightnessDictionary.avg.max);
%                 obj.changeBrightness(obj.brightnessSlider, [])
            else
                set(obj.brightnessSlider, 'Low', obj.brightnessDictionary.norm.min);
                set(obj.brightnessSlider, 'High', obj.brightnessDictionary.norm.max);
%                 obj.changeBrightness(obj.brightnessSlider, [])
            end

            obj.updateFrameMarker();
            drawnow;
            
        end
        
        
        function updateCurrentRoiImage(obj, roiInd)
            
            if isempty(roiInd) || numel(roiInd) > 1; return; end
%             if obj.nFrames(obj.activeChannel) < 10; return; end
            
            ch = obj.activeChannel;
            
            im = obj.roiArray{ch}(roiInd).enhancedImage;
            ul = obj.roiArray{ch}(roiInd).getUpperLeftCorner(5);
            
            if isempty(im)
                [im, ul] = createRoiImage(obj, roiInd, 5);
            end
            
            if isempty(im); return; end
            
            usFactor = 4;
            
            im = imresize(im, usFactor);
            
            if isempty(obj.himageCurrentRoi) % First time initialization. Create image object
                obj.himageCurrentRoi = imshow(im, [0, 255], 'Parent', obj.uiaxes.smallroi, 'InitialMagnification', 'fit');
%                 set(obj.himageCurrentRoi, 'ButtonDownFcn', @obj.mousePress)
               
                if ~ishold(obj.uiaxes.smallroi)  
                    hold(obj.uiaxes.smallroi, 'on') 
                end
                
                % Set image limits. When these are specified after the hold
                % on, axes limits are static.

            else
                set(obj.himageCurrentRoi, 'cdata', im);
            end
            
            roiBoundary = fliplr(obj.roiArray{ch}(roiInd).boundary{1});
            roiBoundary = (roiBoundary - ul + [1,1]) * usFactor;
            
            if isempty(obj.hroiLineOverlay)
                obj.hroiLineOverlay = plot(obj.uiaxes.smallroi, roiBoundary(:,1), roiBoundary(:,2), 'LineStyle', '-', 'Marker', 'None', 'LineWidth', 2);
            else
                set(obj.hroiLineOverlay, 'XData', roiBoundary(:,1), 'YData', roiBoundary(:,2))
            end
            
            imSize = size(im);
            
            % To avoid erroring
            clims = [min(im(:)), max(im(:))];
            if clims(2) <= clims(1)
                clims(2) = clims(1) + 1;
            end
            
            
            set(obj.uiaxes.smallroi, 'XLim', [1,imSize(2)]+0.5, ...
                             'YLim', [1,imSize(1)]+0.5, ...
                             'CLim', clims );
            
        end
        
        
        function changeFrame(obj, source, event, action)
        % Callback from different sources to change the current frame.

            switch action
                case 'mousescroll'
                    i = event.VerticalScrollCount*obj.settings.scrollFactor*obj.playbackspeed;
                    % My touchpad sometimes gives a scroll event when I
                    % move the cursor and click. This is very annoying when
                    % showing avg or max image.
                    if contains(obj.mouseMode, {'Draw', 'CircleSelect', 'Autodetect'})
                        if obj.uiButtons.ShowMax.Value || obj.uiButtons.ShowAvg.Value
                            if obj.settings.lockScrollInDrawMode
                                i=0;
                            end
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
                case 'external gui'
                    i = source.currentFrameNo -  obj.currentFrameNo;
                otherwise
                    i = 0;   
            end

            % Check that new value is within range and update current frame/slider info
            if (obj.currentFrameNo + i) >= 1  && (obj.currentFrameNo + i) <= obj.nFrames(obj.activeChannel)
                obj.currentFrameNo = round(obj.currentFrameNo + i);
                set(obj.frameslider, 'Value', obj.currentFrameNo );
                set(obj.inputJumptoFrame, 'String', num2str(obj.currentFrameNo))
                if strcmp(obj.fsContainer.Visible, 'off')
                    obj.fsContainer.Visible = 'on';
                end
                
                if obj.uiButtons.ShowAvg.Value || obj.uiButtons.ShowMax.Value 
                    if ~contains(obj.mouseMode,  {'Draw', 'CircleSelect', 'Autodetect'})
                        obj.switchToggleButton(obj.uiButtons.ShowAvg, false)
                    end
                end
                
                obj.displaySelectedFrames();
                
            else
                i = 0;
            end
            
            % Pan along axes in signalPlot if zoom is on
            if ~isequal(obj.uiaxes.signalplot.XLim, [1, obj.nFrames(obj.activeChannel)])
                if ~isequal(action, 'jumptoframe')
                    obj.setXLimitsPan(obj.uiaxes.signalplot.XLim + i)
                end
            end

            if ~isempty(obj.imgTseries) && i~=0
                obj.updateImageDisplay();
                
                % Change frame in dataViewer
                if ~isempty(obj.dataViewer)
                    if isvalid(obj.dataViewer)
                        if ~isequal(source, obj.dataViewer)
                            obj.dataViewer.changeFrame(obj, [], 'external gui');
                        end
                    end
                end

            end
        end
        
        
        function updateFrameMarker(obj, flag)
        % Update line indicating current frame in plot.
        
            if nargin < 2; flag = 'update_x'; end
        
            frameNo = obj.currentFrameNo;
            if isempty(obj.hlineCurrentFrame) || ~isgraphics(obj.hlineCurrentFrame) 
                obj.hlineCurrentFrame = plot(obj.uiaxes.signalplot, [1, 1], get(obj.uiaxes.signalplot, 'ylim'), '-r', 'HitTest', 'off');
                obj.hlineCurrentFrame.Tag = 'FrameMarker';
                if ~obj.uiButtons.ShowSignal.Value
                    obj.hlineCurrentFrame.Visible = 'off';
                end
            elseif isequal(flag, 'update_y')
                set(obj.hlineCurrentFrame, 'YData', obj.uiaxes.signalplot.YLim)
            else
                set(obj.hlineCurrentFrame, 'XData', [frameNo, frameNo]);
            end
        end
        
        
% % % % Button callbacks - RoI creation and removal
        
        function buttonCallback_DrawRois(obj, source, ~)
        % Button Callback. Start or finish marking of a roi. 
            
            if source.Value
                obj.setMouseMode('Draw')
                set(obj.uiButtons.AutoDetect, 'Value', 0)
                
            else
                %obj.cancelRoi();
                obj.setMouseMode('Select')
                obj.unFocusButton(obj.uiButtons.DrawRoi)
            end  
                      
        end
        
        
        function buttonCallback_CircleTool(obj, source, ~)
            
            if source.Value
                obj.setMouseMode('CircleSelect')
            else
                obj.setMouseMode('Select')
                obj.unFocusButton(obj.uiButtons.CircleTool)
            end 
        end
        
        
        function buttonCallback_MarkCenter(obj, source, ~)
            
            if source.Value
                obj.setMouseMode('CrosshairSelect')
            else
                obj.setMouseMode('Select')
                obj.unFocusButton(obj.uiButtons.Crosshair)
            end 
        end
        
        
        function buttonCallback_AutodetectRois(obj, source, ~)
        % Button Callback. Start or finish autodetection of roi by clicking on it. 
            
            if source.Value
                obj.setMouseMode('Autodetect')
            else
                obj.setMouseMode('Select')
                obj.unFocusButton(obj.uiButtons.AutoDetect)
            end  
        end
        
        
        function buttonCallback_DoMagic(obj, ~, ~)
            obj.improveRoiEstimate();
            obj.updateCurrentRoiImage(obj.selectedRois);
        end

        
        function buttonCallback_EditRois(obj, source, ~)
        % Button Callback. Start or finish editing of rois.

            if source.Value
                obj.setMouseMode('EditSelect')
                set(obj.uiButtons.AutoDetect, 'Value', 0)
                
            else
                obj.cancelRoi();
                obj.setMouseMode('Select')
                obj.unFocusButton(obj.uiButtons.DrawRoi)
            end  
            
        end
        
        
        function buttonCallback_RemoveRois(obj, ~, ~)
            roiInd = obj.selectedRois;
            obj.removeRois(roiInd)
            obj.selectedRois = [];
        end
        

        function cancelRoi(obj)
        % Cancel a "drawn" roi object
        
            if isequal(obj.mouseMode, 'Freehand')
                delete(obj.hRoiOutline)
                obj.hRoiOutline = [];
                return
            end
        
            % Remove Temporary Roi Object
            removeTmpRoi(obj);
            
            % Replot Roi if edit mode is active ( need to check the button
            % since sometimes roi can be canceled from zoom mode )
            if isequal(obj.mouseMode, 'EditSelect') 
                return
            elseif obj.uiButtons.EditRoi.Value || strcmp(obj.mouseMode, 'EditDraw')
                updateRoiPlot(obj, obj.selectedRois);
            end
            
            if strcmp(obj.mouseMode, 'EditDraw')
                obj.setMouseMode('EditSelect')
            end
        end
        
        
        function growRois(obj, ~, ~)
            
            ch = obj.activeChannel;
            obj.addToActionLog(ch, obj.selectedRois, 'reshape')
            
            for i = obj.selectedRois
                obj.roiArray{ch}(i) = obj.roiArray{ch}(i).grow(1);
                updateRoiPlot(obj, i);
            end
            
        end
        
        
        function shrinkRois(obj, ~, ~)
            ch = obj.activeChannel;
            obj.addToActionLog(ch, obj.selectedRois, 'reshape')

            for i = obj.selectedRois
                obj.roiArray{ch}(i) = obj.roiArray{ch}(i).shrink(1);
                updateRoiPlot(obj, i);
            end
            
        end
        
        
% % % % Methods for adding and removing rois from roimanager and roi array

        function finishRoi(obj)
        % Finish a "drawn" roi object
        
        ch = obj.activeChannel;

        switch obj.mouseMode
            case 'Draw'
                newRoi = makeRoi(obj);
                if ~isempty(newRoi)
                    obj.addRois(newRoi);
                    obj.selectRois(obj.roiCount{obj.activeChannel}, 'normal')
                end
                removeTmpRoi(obj);
                
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
                    obj.roiArray{ch}(obj.selectedRois) = obj.roiArray{ch}(obj.selectedRois).reshape('Polygon', [x', y']);
                    obj.modifySignalArray(obj.selectedRois, 'reset')
                    updateRoiPlot(obj, obj.selectedRois);
                end
                
                % Remove the temporary roi polygon 
                removeTmpRoi(obj);
                obj.setMouseMode('EditSelect')
                
            case 'Freehand'
                
                % Abort if there is no outline
                if isempty(obj.hRoiOutline)
                    return
                end
                
                x = round(obj.hRoiOutline.XData);
                y = round(obj.hRoiOutline.YData);
                
                % Abort if outline is very small.
                if numel(x) < 3
                    return
                end

                mask = false([obj.imHeight, obj.imWidth]);
                ind = sub2ind([obj.imHeight, obj.imWidth], y, x);
                ind(isnan(ind)) = [];
                mask(ind) = true;
                
                mask = imdilate(mask, strel('disk', 3));
                
                % Create a RoI object
                newRoi = RoI('Mask', mask, [obj.imHeight, obj.imWidth]);
                newRoi = obj.editRoiProperties(newRoi);
                
                if ~isempty(newRoi)
                    obj.addRois(newRoi);
                    obj.selectRois(obj.roiCount{obj.activeChannel}, 'normal')
                end
                
                delete(obj.hRoiOutline)
                obj.hRoiOutline = [];
                
        end
        
        end
        
        
        function splitRois(obj, ~, ~)
            
            ch = obj.activeChannel;
            
            for i = obj.selectedRois
                
                roiBabies = obj.roiArray{ch}(i).split(4);
                
                obj.addRois(roiBabies);
                
            end
            
            obj.removeRois;

        end
        
        
        function mergeRois(obj, ~, ~)
            
            if numel(obj.selectedRois) == 1; return; end
            
            ch = obj.activeChannel;
            
            roiMasks = {obj.roiArray{ch}(obj.selectedRois).mask};
            roiMasks = cat(3, roiMasks{:});
            
            mergedMask = sum(roiMasks,3) ~= 0;
            
            mergedRoi = RoI('Mask', mergedMask, size(mergedMask));
            mergedRoi.structure = obj.roiArray{ch}(obj.selectedRois(end)).structure;
            mergedRoi.group = obj.roiArray{ch}(obj.selectedRois(end)).group;
            mergedRoi.celltype = obj.roiArray{ch}(obj.selectedRois(end)).celltype;
            
            obj.removeRois();
            obj.addRois(mergedRoi);
            

        end
        
        
        function connectRois(obj, ~, ~)
            ch = obj.activeChannel;
            
            roiIndices = obj.selectedRois;
            
            
            for i = obj.selectedRois
                
                tmpIndices = setdiff(roiIndices, i);
                tmpRois = obj.roiArray{ch}(tmpIndices);
                roiIds = arrayfun(@(roi) roi.uid, tmpRois, 'uni', 0);
                obj.roiArray{ch}(i) = obj.roiArray{ch}(i).connect(roiIds');
            end
            
        end
        
        
        function createDonutRois(obj, ~, ~)
            
            ch = obj.activeChannel;
            obj.addToActionLog(ch, obj.selectedRois, 'reshape')
            
            for i = obj.selectedRois
                obj.roiArray{ch}(i) = obj.roiArray{ch}(i).goDonuts();
                updateRoiPlot(obj, i);
            end
            
        end

        
        function addRois(obj, newRois, roiInd, mode, chInd)
            % addRois Plot a RoI in the roimanager and add to the list of rois.

            % Count number of rois
            nRois = numel(newRois);
            
            if iscolumn(newRois); newRois = newRois'; end

            % Set default values of input arguments.
            if nargin < 5
                if obj.settings.synchRoisAcrossChannels
                    chInd = 1:obj.nLoadedChannels;
                else
                    chInd = obj.activeChannel; 
                end
            end
            if nargin < 4; mode = 'append'; end
            
            if nargin < 3 || isempty(roiInd)
                roiInd = obj.roiCount{chInd(1)} + (1:nRois);
            end
            
            if obj.roiCount{obj.activeChannel} == 0; mode = 'initialize'; end

            % Go through channels.
            if iscolumn(chInd); chInd = chInd'; end
            for ch = chInd

% %                 % Convert rois to RoI or struct depending on channel status.
% %                 if obj.settings.synchRoisAcrossChannels
                    if ch ~= obj.activeChannel
                        if isa(newRois, 'RoI')
                            newRois = utilities.roiarray2struct(newRois);
                        end
                    else
                        if isa(newRois, 'struct')
                            newRois = utilities.struct2roiarray(newRois);
                        end
                    end

                % Add rois, either by appending or by inserting into array.
                switch mode
                    case 'initialize'
                        obj.roiArray{ch} = newRois;
                    case 'append'
                        obj.roiArray{ch} = horzcat(obj.roiArray{ch}, newRois);
                    case 'insert'
                        obj.roiArray{ch} = utilities.insertIntoArray(obj.roiArray{ch}, newRois, roiInd, 2);
                end

                % This should happen before plot, update listbox and modify
                % signal array:
                obj.roiCount{ch} = obj.roiCount{ch} + nRois; 

                % Plot rois. Here it is important to handle channels correct
                obj.plotRoi(newRois, roiInd, mode, ch);

                % If this is the active channel, listbox needs to be updated
                if ch == obj.activeChannel
                    switch mode
                        case 'insert' % Need to update all rois
                            obj.updateListBox(); 
                        case {'append', 'initialize'} % Only update indices
                            obj.updateListBox(roiInd);
                    end
                end

                obj.modifySignalArray(roiInd, mode, ch)

                if ~isempty(obj.cnmfData) && ch == obj.activeChannel
                    obj.updateCnmfData(roiInd, mode)
                end

            end

            % Add this to the action log.
            obj.addToActionLog(chInd, roiInd, 'add')
                
        end
        

        function removeRois(obj, roiInd, chInd)
        % Button callback. Remove selected rois from gui

            if nargin < 3
                if obj.settings.synchRoisAcrossChannels
                    chInd = 1:obj.nLoadedChannels;
                else
                    chInd = obj.activeChannel; 
                end
            end
            
            if nargin < 2; roiInd = obj.selectedRois; end
            removedRois = roiInd; %See last lines of function...

            if isempty(roiInd); return; end
            
            obj.addToActionLog(chInd, roiInd, 'remove')

            for ch = chInd
            
                if ch == obj.activeChannel
%                     obj.roiListBox.Value = setdiff(obj.roiListBox.Value, roiInd);
                    obj.roiListBox.Value = [];
                    obj.selectedRois = setdiff(obj.selectedRois, roiInd);
                end
        
                % Loop through selected rois, remove roi objects and associated
                % plots. Also clear the roi from the listbox
                roiInd = sort(roiInd, 'descend');
                for i = roiInd
                    obj.roiCount{ch} = obj.roiCount{ch} - 1;
                    
                    if ch == obj.activeChannel
                        decrement = obj.selectedRois > i;
                        obj.selectedRois(decrement) = obj.selectedRois(decrement) - 1;                       
                        obj.removeNeuropilPatch(i)
                        obj.roiArray{ch}(i) = [];
                        delete(obj.RoiPlotHandles{ch}(i))
                        delete(obj.RoiTextHandles{ch}(i))
                        obj.RoiPlotHandles{ch}(i) = [];
                        obj.RoiTextHandles{ch}(i) = [];
                        obj.roiListBox.String(i) = [];
                        obj.RoiLinePos{ch}(i, :) = [];
                        obj.RoiTextPos{ch}(i) = [];
                    else
                        obj.roiArray{ch}(i) = [];
                        obj.RoiLinePos{ch}(i, :) = [];
                        obj.RoiTextPos{ch}(i) = [];
                    end
                    
                end
            
                obj.modifySignalArray(roiInd, 'remove', ch)
                
                if ch == obj.activeChannel
                    obj.updateListBox();
                end                
            end
            
            if ~isempty(obj.cnmfData)
                obj.updateCnmfData(obj.selectedRois, 'remove')
            end
            
            % What was the purpose of this??? Select next roi??
            if numel(removedRois) == 1 && removedRois < obj.roiCount{ch}
                if isequal(gco, obj.roiListBox)
                    obj.selectRois(removedRois, 'normal')
                end
            end
            
        end

        
        function clearRois(obj, ~, ~)
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


        function traceDendrites(obj, mode)
            if nargin < 2; mode = 'trace'; end
        
            point = obj.uiaxes.imagedisplay.CurrentPoint;

            switch mode
                case 'pause'
                    xNew = nan;
                    yNew = nan;
                otherwise
                    xNew = point(1,1);
                    yNew = point(1,2);
            end
            
            if isempty(obj.hRoiOutline) 
                xData = xNew;
                yData = yNew;
            else 
                xData = horzcat(obj.hRoiOutline.XData, xNew);
                yData = horzcat(obj.hRoiOutline.YData, yNew);
            end

            win = max([1,numel(xData)-4]):numel(xData);
            
            if ~any(isnan(xData(win)))
                xData(win) = smoothdata(xData(win));
                yData(win) = smoothdata(yData(win));
            end
            
            if isempty(obj.hRoiOutline) 
                obj.hRoiOutline = plot(obj.uiaxes.imagedisplay, xData, yData, '-', 'LineWidth', 2, 'Color', 'c');
                obj.hRoiOutline.HitTest = 'off';
                obj.hRoiOutline.PickableParts = 'None';
            else 
                set(obj.hRoiOutline, 'XData', xData)
                set(obj.hRoiOutline, 'YData', yData)
            end
    
        end

    
        function drawOutline(obj, finish)
            
            if nargin < 2; finish = false; end
            
            point = obj.uiaxes.smallroi.CurrentPoint;
            xNew = point(1,1);
            yNew = point(1,2);
            
            if isempty(obj.hRoiOutline) 
                xData = xNew;
                yData = yNew;
            else 
                xData = obj.hRoiOutline.XData;
                yData = obj.hRoiOutline.YData;
                if ~finish
                    xData = horzcat(xData, xNew);
                    yData = horzcat(yData, yNew);
                else
                    xData(end+1) = xData(1);
                    yData(end+1) = yData(1);
                end
            end

            win = max([1,numel(xData)-4]):numel(xData);
            
            xData(win) = smoothdata(xData(win));
            yData(win) = smoothdata(yData(win));
            
            if isempty(obj.hRoiOutline) 
                obj.hRoiOutline = plot(obj.uiaxes.smallroi, xData, yData, '-', 'LineWidth', 2, 'Color', 'c');

            else 
                set(obj.hRoiOutline, 'XData', xData)
                set(obj.hRoiOutline, 'YData', yData)
            end

        end


        function drawTmpRoi(obj)
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
                axes(obj.uiaxes.imagedisplay);
                obj.hlineTmpRoi = plot(0,0);
                obj.hlineTmpRoi.HitTest = 'off';
                obj.hlineTmpRoi.PickableParts = 'none';
            end
            set(obj.hlineTmpRoi,'XData',x,'YData',y);
        end
        
        
        function removeTmpRoi(obj)
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

        
        function addImpoint(obj, x, y)
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
            tmpRoiVertex = impoint(obj.uiaxes.imagedisplay, x, y);
            obj.configImpoint(tmpRoiVertex, i);
            obj.tmpImpoints{end+1} = tmpRoiVertex;
            
            % Select the last added impoint
            obj.selectImpoint(i);
            
        end
        
        
        function selectImpoint(obj, i)
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
        
        
        function removeImpoint(obj)
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
            xlim = get(obj.uiaxes.imagedisplay, 'XLim');
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
        
        
        function callbackRoiPosChanged(obj, pos)
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

        function mask = autodetect(obj, x, y, frames)
        %autodetect autodetects roi by automatic thresholding.   
        
            ch = obj.activeChannel;
        
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
            
            if nargin < 4
                im = obj.himage.CData(y-d2:y+d2, x-d2:x+d2, 1);
            else
                im = obj.imgTseries{ch}(y-d2:y+d2, x-d2:x+d2, frames);
                im = uint8(mean(im, 3));
            end
            
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
%                 nucleus_val = median(nucleus_values);
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
%             localRoiMask = im2bw(im, threshold/255);
            localRoiMask = imbinarize(im, threshold/255);
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
        
        
        function mask = autodetectDonut(obj, x_orig, y_orig, frames)
            
            ch = obj.activeChannel;

            d1 = obj.roiInnerDiameter; 
            d2 = obj.roiOuterDiameter; 
            
            x = round(x_orig);
            y = round(y_orig);
            
            r = round(d2 * 2 / 3);
            
            [nRows, nCols] = size(obj.himage.CData);
            if  y-r < 1 || x-r < 1 || y+r > nRows || x+r > nCols
                error('Sorry, autodetection does not work close to edges in the image')
            end
            
            if nargin < 4
                im = obj.himage.CData(y-r:y+r, x-r:x+r, 1);
            else
                im = obj.imgTseries{ch}(y-r:y+r, x-r:x+r, frames);
                im = mean(im, 3) ;
                im = uint8( (im - min(im(:))) ./ (max(im(:)) - min(im(:)) ) * 255 );
            end
            
            % Upsample and smooth image.
            upSampleFactor = 3;
            im = imresize(im, upSampleFactor);
            im = imgaussfilt(im, 1);
%             imviewer(im)
            unrolled = utilities.unrollImage(im);
            
            v=2;
            showPlot = false;
            
            if v==1
                [maxval, maxind] = max(double(unrolled));
                outerRadius = maxind+upSampleFactor;
                
            elseif v==2
                
                % Look for edges.
                grad = diff(double(unrolled)); 

                [~, outerBnd] = min(grad);
                [~, innerBnd] = max(grad);
                
                % Remove outliers and smooth data for the outer boundary
                baseline = utilities.circularsmooth(outerBnd, 10, 'movmedian');
                outerBnd2 = outerBnd - baseline;
                outerBnd2 = filloutliers(outerBnd2, 'pchip', 'gesd', 'ThresholdFactor', 1);
                outerBnd1 = outerBnd2 + baseline;
                outerBnd1 = utilities.circularsmooth(outerBnd1, 5, 'movmean');
                
                % Remove outliers and smooth data for the inner boundary
                baseline = utilities.circularsmooth(innerBnd, 10, 'movmedian');
                innerBnd2 = innerBnd - baseline;
                innerBnd2 = filloutliers(innerBnd2, 'pchip', 'gesd', 'ThresholdFactor', 1);
                innerBnd1 = innerBnd2 + baseline;
                %innerBnd1 = utilities.circularsmooth(innerBnd1, 5, 'movmean');
                
                if showPlot
                    figure('Position', [300,300,300,300]); axes('Position', [0,0,1,1]);
                    imagesc(unrolled); hold on
                    plot(1:size(unrolled,2), outerBnd, 'ow')
                    plot(1:size(unrolled,2), outerBnd1, 'r')
                    plot(1:size(unrolled,2), innerBnd, 'or')
                    plot(1:size(unrolled,2), innerBnd1, 'r')
                end
                
                innerRadius = innerBnd1 + upSampleFactor;
                outerRadius = outerBnd1 + upSampleFactor;
            end 
            
            % Scale back (spatial down sample)
            outerRadius = outerRadius ./ upSampleFactor;
            
            % transform back to cartesian coordinates
            theta = 0 : (360 / (size(unrolled,2))) : 360;
            
            [xi, yi] = pol2cart(deg2rad(theta(1:end-1)), outerRadius);
            
% %             % Calculate the convex hull
% %             k = convhull(xi,yi);
            
            mask = poly2mask(x+xi-0.25, y-yi-0.25, obj.imHeight, obj.imWidth);
            
        end
        

        function improveRoiEstimate(obj, roiInd)
            %Todo: Rewrite function so that it takes a roi as an input...
            %Todo: Rename function
            ch = obj.activeChannel;
           
            if nargin < 2
                roiInd = obj.selectedRois;
            end
            
            for roiNum = roiInd

                frames = getActiveFrames(obj, roiNum);
                
                x = obj.roiArray{ch}(roiNum).center(1);
                y = obj.roiArray{ch}(roiNum).center(2);
                
%                 mask = obj.autodetect(x, y, frames);
                mask = obj.autodetectDonut(x, y, frames);
                
                obj.addToActionLog(ch, roiNum, 'reshape')
                obj.roiArray{ch}(roiNum) = obj.roiArray{ch}(roiNum).reshape('Mask', mask);
                obj.modifySignalArray(roiNum, 'reset')
                obj.updateRoiPlot(roiNum);
                
%                 [roimask, surroundmask] = signalExtraction.standard.getMasks(obj.roiArray{ch}, roiIdx, 4);
% 
%                 roimask = imdilate(roimask, ones(3,3)); % Remove the gap between masks which are added in the function above. Here only pixels part of the expanded mask are considered in the end.
%                 expandedroimask = roimask | surroundmask;
% 
%                 [y, x] = find(expandedroimask);
% 
%                 minX = min(x); maxX = max(x);
%                 minY = min(y); maxY = max(y);
% 
%                 croppedMask = expandedroimask(minY:maxY, minX:maxX);
%                 pixelChunk = obj.imgTseries{ch}(minY:maxY, minX:maxX, :);
% 
%                 f0 = prctile(pixelChunk, 20, 3);
%                 dffIm = (pixelChunk - f0) ./ f0;
% 
%                 pixelChunk = dffIm(:, :, frames);
%                 pixelChunk = filterImArray(pixelChunk, 1, 'median');
%                 dff = dff(frames); 
% 
%                 mask = repmat(croppedMask, 1, 1, sum(frames));
%                 pixPerFrame = sum(croppedMask(:));
%                 pixelSignals = reshape(pixelChunk(mask), pixPerFrame, sum(frames))'; % nframes x npixels
% 
%                 pixelSignals = horzcat(dff, pixelSignals);
%                 
%                 RHO = corr(single(pixelSignals));
%                 RHO = RHO(2:end, 1);
%                 
%                 idx = find(croppedMask);
%                 
%                 corrim = nan(size(croppedMask));
%                 corrim(idx) = RHO;
% 
%                 withinVal = nanmean(corrim(roimask(minY:maxY, minX:maxX)));
%                 outsideVal = nanmean(corrim(surroundmask(minY:maxY, minX:maxX)));
%                 threshold = mean([withinVal,withinVal,outsideVal]);
%                 
% %                 pixId = unique(x);
% 
%                 newMask = false(size(croppedMask));
%                 whichPixels = (RHO>threshold);
%                 newMask(idx(whichPixels)) = true;
%                 newMask = bwareaopen(newMask, 8);
%                 newMask = imfill(newMask,'holes');
%                 
%                 if sum(newMask(:)) < 10
%                     return
%                 end
% 
%                 fullmask = false(size(obj.roiArray{ch}(roiIdx).mask));
%                 fullmask(minY:maxY, minX:maxX) = newMask;

%                 newRoi = RoI('Mask', fullmask, size(fullmask));
%                 newRoi = obj.editRoiProperties(newRoi);
%                 if nEvents < 2
%                     newRoi.grow(1);
%                 end
% 
%                 newRois(end+1) = newRoi;
                
            end
            
%             obj.removeRois(obj.selectedRois);
%             obj.addRois(newRois);

        end
            

        function frames = getActiveFrames(obj, roiInd)
        %getActiveFrames Return framenumbers where roi is active
        
        % Todo: rewrite function to take roi as input?
        % Pro: can pass any roi, it does not need to be registered in the
        % gui. Against: Need to extract signal every time. 
        
            if nargin < 2; roiInd = obj.selectedRois; end
            
            if numel(roiInd) > 1
                error('This function does not work for multiple rois'); 
            end
            
            % In case only a projection image is loaded.
            if obj.nFrames(obj.activeChannel) == 1
                frames = 1; return
            end

            ch = obj.activeChannel;
            
            % Get (or extract) the dff for this roi
            dff = obj.signalArray(ch).dff(:, roiInd);

            waitbarStatus = obj.settings.showWaitbar;
            obj.settings.showWaitbar = false;
            if all(isnan(dff)) || isempty(dff)
                dff = obj.extractSignal(roiInd, 'dff');
            end
            obj.settings.showWaitbar = waitbarStatus;

            % Find the baseline and the max
            f0 = prctile(dff, 20);
            fmax = max(dff);
            
            %Todo: Use sn as a threshold

            if isempty(obj.selectedFrames) || sum(obj.selectedFrames) == 0
                frames = dff > ((fmax-f0)/2);
            else
                frames = logical(obj.selectedFrames);
            end

            % Dilate frames ...
            [start, ~] = utilities.findTransitions(frames);

            f0Idx = find(dff>f0);

            for j = 1:numel(start)
                [~, start(j)] = min(abs((start(j)-f0Idx)));
            end

%                 frames = imerode(frames, ones(20, 1));
            frames = imdilate(frames, ones(5, 1));
            [start, stop] = utilities.findTransitions(frames);
            
            % Also set result of dilation to true in the frame logical vec
            aa = sort(cell2mat(arrayfun(@(i) start(i):stop(i), 1:numel(start), 'uni', 0)));
            frames(aa)=true;
        end
        
        
        function [im, ul] = createRoiImage(obj, roiInd, marg)
            
            ch = obj.activeChannel;
            if nargin < 3; marg = 7; end

%             x0 = obj.roiArray{ch}(roiInd).center(1);
%             y0 = obj.roiArray{ch}(roiInd).center(2);            
        
            [y, x] = find(obj.roiArray{ch}(roiInd).mask);
                        
            minX = min(x)-marg; maxX = max(x)+marg;
            minY = min(y)-marg; maxY = max(y)+marg;
            
            if minX < 1; minX = 1; end 
            if minY < 1; minY = 1; end 
            if maxX > obj.imWidth; maxX = obj.imWidth; end 
            if maxY > obj.imHeight; maxY = obj.imHeight; end 

            ul = [minX, minY];

            frames = getActiveFrames(obj, roiInd);
            
            im = obj.imgTseries{ch}(minY:maxY, minX:maxX, frames);
            im = mean(im, 3) ;
            im = uint8( (im - min(im(:))) ./ (max(im(:)) - min(im(:)) ) * 255 );
            obj.roiArray{ch}(roiInd).enhancedImage = im;
            
        end
        
        
        function checkRoiArtifacts(obj, roiInd)
            
            ch = obj.activeChannel;
            dffDenoised = obj.signalArray(ch).denoised(:, roiInd);
            
            % Check if any signals are missing and extract if needed
            isMissingSignal = any(isnan(dffDenoised));
            if any(isMissingSignal)
                obj.extractSignal(roiInd, 'denoised');
            end
            
            dffDenoised = obj.signalArray(ch).denoised(:, roiInd);
            
            [ii, ee] = findTransitions(dffDenoised > 0.01);
            ii = ii-10;
            ee = ee+10;
            
            ii(ii<1) = 1; ee(ee>obj.nFrames) = obj.nFrames;
            
            
            for n = 1:numel(ii)
                if ee(n)-ii(n) < 100; continue; end
                obj.selectedFrames = false(obj.nFrames, 1);
                obj.selectedFrames(ii(n):ee(n)) = true;
                obj.changeFrame(struct('String', num2str(ii(n))), [], 'jumptoframe')
                showRoiCorrelationImage(obj, [], [])
            end
            
            extractSignal(obj, roiInd, 'deconvolved');
            extractSignal(obj, roiInd, 'spikes');
            obj.updateSignalPlot(roiInd, 'overwrite')

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

            ch = obj.activeChannel;
            
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
            elseif isequal(source, obj.popupRoiclass)
                groupName = source.String{source.Value};
            end
            
            roi.group = groupName;
%             roi.layer = corticalLayer;
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
          
        end
        
        
        function moveRoi(obj, shift)
        % Update RoI positions based on shift.
        
            wb_on = false;
            if numel(obj.selectedRois) > 50
                h = waitbar(0, 'Moving Roi Objects'); 
                wb_on = true; c=0;
            end
        
            ch = obj.activeChannel;
            
            obj.addToActionLog(ch, obj.selectedRois, 'reshape')
            
            % Get active roi
            for i = obj.selectedRois
                obj.roiArray{ch}(i) = obj.roiArray{ch}(i).move(shift);
                removeNeuropilPatch(obj, i)
                addNeuropilPatch(obj, i)
                if wb_on; c=c+1; waitbar(c/numel(obj.selectedRois), h); end
            end
            if wb_on; close(h); end

            % Move the text tags now if they are invisible.
            if ~obj.settings.showTags
                textpos = {obj.RoiTextHandles{ch}(obj.selectedRois).Position};
                textpos = cellfun(@(pos) pos + [shift, 0], textpos, 'uni', 0);
                set(obj.RoiTextHandles{ch}(obj.selectedRois), {'Position'}, textpos')
            end
            
            obj.modifySignalArray(obj.selectedRois, 'reset')
            obj.updateSignalPlot(obj.selectedRois, 'overwrite')
            obj.updateCurrentRoiImage(obj.selectedRois)

        end

        
% % % % Methods for organizing listbox
        
        function updateListBox(obj, roiIndices)
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
        
            ch = obj.activeChannel;

            if nargin < 2 || isempty(roiIndices)
                roiIndices = 1:obj.roiCount{ch};
            end
            
            if isempty(obj.roiListBox.String) && isempty(roiIndices)
                return
            end
            
            % Assemble text labels for the listbox
            tags = {obj.roiArray{ch}(roiIndices).tag};
            nums = arrayfun(@(i) num2str(i, '%03d'), roiIndices, 'uni', 0);
            
            % Add '-i' for imported rois
            isImported = arrayfun(@(roi) any(contains(roi.tags, 'imported')), obj.roiArray{ch}(roiIndices), 'uni', 1);
            tags2 = repmat({''}, 1, numel(roiIndices));
            tags2(isImported) = {'*'};
            
            % Set strings and values of listbox.
            obj.roiListBox.String(roiIndices) = strcat(tags, nums, tags2);
            obj.roiListBox.Value = obj.selectedRois;
                        
            % Set texthandles
            set(obj.RoiTextHandles{ch}(roiIndices), {'String'}, strcat(tags, nums)');

        end

        
        function resetListbox(obj)
            obj.roiListBox.String = cell(0);
            obj.roiListBox.Value = 0;
        end

        
        function updateRoiInfoPanel(obj)
            
            ch = obj.activeChannel;
            
            if ~isempty(obj.selectedRois)
                
                % Only show last selection
                displayedRoi = obj.selectedRois(end);
                roiUid = obj.roiArray{ch}(displayedRoi).uid;
                % Set title of roi information box
                obj.panels.roiInfo.Title = sprintf('Roi Info (#%03d (%s))', displayedRoi, roiUid(1:8));
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
                
                
                % Get time constants and update the boxes when a rois
                % is selected.   
                
                if obj.nFrames(obj.activeChannel) < 100; return; end
                
                dff = obj.signalArray(ch).dff(:, displayedRoi);
                
                % Check if any dffsignals are missing and extract if needed
                isMissingSignal = any(isnan(dff));
                if any(isMissingSignal)
                    obj.extractSignal(displayedRoi, 'dff');
                    dff = obj.signalArray(ch).dff(:, displayedRoi);
                end
                
                fps = obj.signalExtractionSettings.fps;
%                 tauRDms = signalExtraction.CaImAn.getTauFromMCMC(dff', fps);
                if any(isnan(dff))
                    tauRDms = [nan, nan];
                else
                    tauDR = estimate_time_constant(dff, 2, GetSn(dff));
                    [tauR, tauD] = signalExtraction.CaImAn.getArConstantsInMs(tauDR, fps);
                    tauRDms = [tauR, tauD];
                end
                
                obj.editTauDecay.String = sprintf('%d', round(tauRDms(2)));
                obj.editTauRise.String = sprintf('%d', round(tauRDms(1)));

            else
                obj.panels.roiInfo.Title = sprintf('Roi Info');
                obj.boolOverfilled.Value = false;
                obj.connectedRoiInfo.String = '';
                obj.editTauDecay.String = '';
                obj.editTauRise.String = '';
            end
            
            
        end
        
        
% % % % Methods for selecting and deselecting rois

        function selectRois(obj, roiIndices, selectionType, isMousePress)
        % Takes care of selection of roi. Show roi as white in image,
        % update signal plot if it is open and change selection in listbox.
        %
        % This function can be activated by the following actions:
        %   Press a RoI in the image Display
        %   Press a RoI in the Listbox
        %   Tab shortcut key in undocking mode
        %   Cmd-a / Ctrl-a shortcut key
        %
        %   During a mouseclick, rois should be selected. If any rois
        %   should be deselected, this should happen when the mouse is
        %   released.
            
            ch = obj.activeChannel;
            
            if nargin < 4; isMousePress = false; end

            if isnan(roiIndices)
                wasInRoi = false;
            else
                wasInRoi = true;
            end

            obj.unselectedRois = []; % Make sure this is empty.
            
            switch selectionType
                
                case 'normal' % RoiIndices should have length 1
                    
                    assert(numel(roiIndices)==1, 'Please report')
                    
                    % Reset selection of all unselected rois
                    deselectedRois = setdiff(obj.selectedRois, roiIndices);
                    
                    if any(obj.selectedRois == roiIndices)
                        if ~isempty(deselectedRois) 
                            if isMousePress
                                obj.unselectedRois = deselectedRois;
                            else
                                obj.deselectRois(deselectedRois)
                            end
                        else
                            obj.unselectedRois=[];
                        end
                    else
                        obj.deselectRois(deselectedRois)
                    end
                    
%                     obj.selectedRois=[];
                    
                    % Make roi white if it was newly selected
                    if wasInRoi && ~any(obj.selectedRois == roiIndices)
                        addNeuropilPatch(obj, roiIndices)
                        obj.RoiPlotHandles{ch}(roiIndices).Color = 'White';
                        obj.RoiTextHandles{ch}(roiIndices).Color = 'White';
                        if obj.settings.openRoiFigure && ~isempty(obj.sessionObj)
                            sid = obj.sessionObj.sessionID;
                            filepath = stackRoiImages(sid, 'ultimateRoiSummary', roiIndices, 'filepath');
                            filepath = cellfun(@(str) strrep(str, ' ', '\ '), filepath, 'uni', 0);
                            [status, ~] = unix(sprintf('open -a Preview ''%s'' --args ''%s''', filepath{1}, strjoin(filepath(2:end), ' ')));
                        end
                    end

                    % Plot signal of Roi if signal plot is open
                    if obj.uiButtons.ShowSignal.Value
                        if wasInRoi && any(obj.selectedRois == roiIndices)
                            if isequal(obj.RoiPlotHandles{ch}(roiIndices).Color, [1,1,1]) % White, meaning it is selected when signal plot is not open
                                obj.updateSignalPlot(roiIndices, 'overwrite');
                            else
                                % Do nothing
                            end
                        elseif wasInRoi && ~any(obj.selectedRois == roiIndices)
                            obj.updateSignalPlot(roiIndices, 'overwrite');
                        else
                            obj.resetSignalPlot()
                        end
                    end

                    % Update selected rois array and listbox 
                    if isnan(roiIndices); roiIndices = []; end
                    if isempty(obj.selectedRois); obj.selectedRois=[]; end %Prevent horzqqcat error in next line
                    obj.selectedRois = cat(2, obj.selectedRois, roiIndices);
                    obj.roiListBox.Value = obj.selectedRois;

                case 'extend'

                    % Add roi to list of selected rois
                    if wasInRoi %&& ~any(obj.selectedRois == roiIndices)
                        
                        newSelection = setdiff(roiIndices, obj.selectedRois);
                        set(obj.RoiPlotHandles{ch}(newSelection), {'color'}, repmat({'White'}, numel(newSelection), 1));
                        set(obj.RoiTextHandles{ch}(newSelection), {'color'}, repmat({'White'}, numel(newSelection), 1));                        
                        
                        % Patch neuropil region for each newly selected roi
                        for i = newSelection
                            if obj.settings.showNpMask
                                addNeuropilPatch(obj, i)
                            end
                        end
                        
                        % Plot signals for each newly selected roi
                        if obj.uiButtons.ShowSignal.Value && numel(newSelection) < 8
                            obj.updateSignalPlot(newSelection, 'append');
                        end

                        % Add newly selected rois to selected rois.
                        obj.selectedRois = horzcat(obj.selectedRois, newSelection);
                        obj.roiListBox.Value = horzcat(obj.roiListBox.Value, newSelection);
                        
                    end
                    
                case 'listbox'
                    if wasInRoi %&& ~any(obj.selectedRois == roiIndices)
                        for i = roiIndices

                            if obj.uiButtons.ShowSignal.Value
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
            
            if ~isempty(obj.selectedRois)
                obj.selectedRois = unique(obj.selectedRois); % The lazy way
                obj.updateCurrentRoiImage(obj.selectedRois);
            end
            obj.updateRoiInfoPanel()
            
            % Change rois in dataViewer
            if ~isempty(obj.dataViewer)
                if isvalid(obj.dataViewer)
                    obj.dataViewer.changeRoi(obj, [], obj.selectedRois)
                end
            end
            
            if wasInRoi && numel(obj.selectedRois)==1
                obj.zoomOnRoi(obj.selectedRois(end))
            end
                
        end
        
        
        function deselectRois(obj, roiIndices)
        % Deselect all selected rois. Remove lines, reset color of roi in
        % image and unselect from listbox.
            
        if isempty(roiIndices); return; end
        
            ch = obj.activeChannel;

            for i = roiIndices
                color = obj.getRoiColor(obj.roiArray{ch}(i));
                obj.RoiPlotHandles{ch}(i).LineWidth = 0.5;
                obj.RoiPlotHandles{ch}(i).Color = color;
                obj.RoiTextHandles{ch}(i).Color = color;
                obj.removeNeuropilPatch(i)
            end
            
            
            obj.selectedRois = setdiff(obj.selectedRois, roiIndices);
            obj.roiListBox.Value = obj.selectedRois;
            
%             toRemove = ismember(obj.selectedRois, roiIndices);
%             if ~isempty(toRemove)
%                 obj.selectedRois(toRemove) = [];
%                 obj.roiListBox.Value = obj.selectedRois;
%             end
            
            if obj.uiButtons.ShowSignal.Value
                obj.resetSignalPlot()
                replotInd = setdiff(obj.selectedRois, roiIndices);
                obj.updateSignalPlot(replotInd, 'overwrite')
                
            end

%             obj.editRoiLabel.String = '';
            
        end
        
        
        function multiSelectRois(obj)
            xData = get(obj.zoomRectPlotHandle, 'XData');
            yData = get(obj.zoomRectPlotHandle, 'YData');
            
            selectionLimitsX = round([min(xData), max(xData)]);
            selectionLimitsY = round([min(yData), max(yData)]);
            
            ch = obj.activeChannel;
            currentFig = gcf;
            switch get(currentFig, 'SelectionType')
                case 'normal'
                    obj.deselectRois(obj.selectedRois)
                    set(currentFig, 'SelectionType', 'extend')
            end
            
            markedRois = false(1, obj.roiCount{ch});
            
            for i = 1:numel(obj.roiArray{ch})
                [y, x] = find(obj.roiArray{ch}(i).mask);
                if any(selectionLimitsX(1) <= x) && any(x <= selectionLimitsX(2))
                    if any(selectionLimitsY(1) <= y) && any( y <= selectionLimitsY(2))
                        markedRois(i) = true;
                    end
                end
            end
            
            markedRois = find(markedRois);
            selectRois(obj, markedRois, 'extend');
            
        end
        
        
        function selectListBoxObj(obj, source, ~)
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
        

        function copyRoisToClipboard(obj)
            
           obj.clipboardRois = obj.roiArray{obj.activeChannel}(obj.selectedRois);
            
        end
        
        
        function pasteRoisFromClipboard(obj)
            if ~isempty(obj.clipboardRois)
                obj.addRois(obj.clipboardRois);
            end
        end
        
        
        function displayRoiContextMenu(obj, selectedRoi)
            if isnan(selectedRoi) || obj.logPosition==0
                return
            else
                
                if isequal(obj.actionLog(obj.logPosition).roiInd, selectedRoi)
                    disp('a')
                    
                    currentFig = gcf;
                    cmenu = findobj(currentFig, 'Type', 'UIContextMenu');
                    if isempty(cmenu)
                    	cmenu = uicontextmenu;
                    else
                        delete(cmenu.Children)
                    end
                    
                    if obj.actionLog(obj.logPosition).roiInd == selectedRoi
                        if isequal(obj.actionLog(obj.logPosition).action, 'reshape')
                            if obj.settings.synchRoisAcrossChannels
                                m1 = uimenu(cmenu, 'Label', 'Reshape Roi in All Channels');
                                m1.Callback = @obj.applyRoiActionToAllChannels;
                                cmenu.Position = currentFig.CurrentPoint;
                                cmenu.Visible = 'on';
                            end
                        end
                    end
                    
                    
                end
            end
        end

        
        function changeSelectedRoi(obj, prevOrNext)
            
            if numel(obj.selectedRois) ~= 1
                return
            end
            
            switch prevOrNext
                case 'previous'
                    if obj.settings.synchRoisAcrossChannels
                        if obj.activeChannel == 1 && obj.selectedRois == 1
                            return
                        elseif obj.activeChannel == 1
                            obj.selectRois(obj.selectedRois-1, 'normal');
                            newChannel = obj.loadedChannels{end};
                            obj.changeActiveChannel(struct('String', newChannel));
                        else
                            newChannel = obj.loadedChannels{obj.activeChannel-1};
                            obj.changeActiveChannel(struct('String', newChannel));
                        end
                    else
                        if obj.selectedRois == 1
                            return
                        else
                            obj.selectRois(obj.selectedRois-1, 'normal');
                        end
                    end
                    
                case 'next'
                    if obj.settings.synchRoisAcrossChannels
                        if obj.activeChannel == obj.nLoadedChannels && obj.selectedRois == obj.roiCount{obj.activeChannel}
                            return
                        elseif obj.activeChannel == obj.nLoadedChannels
                            obj.selectRois(obj.selectedRois+1, 'normal');
                            newChannel = obj.loadedChannels{1};
                            obj.changeActiveChannel(struct('String', newChannel));
                        else
                            newChannel = obj.loadedChannels{obj.activeChannel+1};
                            obj.changeActiveChannel(struct('String', newChannel));
                        end
                    else
                        if obj.selectedRois == obj.roiCount{obj.activeChannel}
                            return
                        else
                            obj.selectRois(obj.selectedRois+1, 'normal');
                        end
                    end
                    
                    
                    
                    
            end
               
            
            
        end
        
        
% % % % Methods for plotting rois and modifying the plots
        
        function plotRoi(obj, roiArray, ind, mode, ch)
        % Plot the roi in the ax.
        
        % Default mode is append. Alternative: insert.
        
        % Rois are only plotted if active channel = current channel. This
        % is relevant for when rois should be synched across channels.
        % Otherwise the roi line coordinates are added to a cell array.
        
            % Set default values of input arguments
            if nargin < 5; ch = obj.activeChannel; end
            if nargin < 4; mode = 'append'; end
            if nargin < 3
                ind = obj.roiCount{ch} - fliplr(1:numel(roiArray)) + 1;
            end
            
            % Initialize Plot/Text handles and position cell arrays
            if ch == obj.activeChannel && isempty(obj.RoiPlotHandles{ch})
                obj.RoiPlotHandles{ch} = gobjects(0);
                obj.RoiTextHandles{ch} = gobjects(0);
            elseif ch ~= obj.activeChannel &&  isempty(obj.RoiLinePos{ch})
                obj.RoiLinePos{ch} = cell(0, 2);
                obj.RoiTextPos{ch} = cell(0, 1);
            else
                % Do nothing
            end   
            
            
            % Preallocate some arrays
            nRois = numel(roiArray);
            colorCellArray = cell(nRois, 1);
            roiBoundaryCellArray = cell(2, nRois);
            centerPosArray = zeros(nRois, 3);

            % Find boundaries for all rois
            for roiNo = 1:numel(roiArray)
                colorCellArray{roiNo} = obj.getRoiColor(roiArray(roiNo));
                centerPosArray(roiNo, :) = [roiArray(roiNo).center, 0];

                boundary = roiArray(roiNo).boundary{1};
                roiBoundaryCellArray{1, roiNo} = boundary(:,2); 
                roiBoundaryCellArray{2, roiNo} = boundary(:,1);
            end
            
            % Plot to active channel or add to position cell array
            if ch == obj.activeChannel
            
                % Plot lines and add text objects for all rois
                hLine = plot(obj.uiaxes.imagedisplay, roiBoundaryCellArray{:}, 'LineStyle', '-', 'Marker', 'None');
                hText = text(obj.uiaxes.imagedisplay, centerPosArray(:, 1), centerPosArray(:, 2), '');

                set(hLine, {'color'}, colorCellArray)
                set(hLine, 'HitTest', 'off')
                set(hLine, 'PickableParts', 'none')
                set(hLine, 'Tag', 'RoI')
                
                set(hText, {'color'}, colorCellArray)
                set(hText, 'HitTest', 'off')
                set(hText, 'PickableParts', 'none')
                set(hText, 'HorizontalAlignment', 'center')
                set(hText, 'Tag', 'RoIlabel')
                
                % Set visibility of text based on button "Show/Hide Tags"
                if obj.settings.showTags
                    set(hText, 'Visible', 'on')
                else
                    set(hText, 'Visible', 'off')
                end
                
                
                % NB: Ind is a row vector, so plot handles become a row
                % vector as well. hLine and hText are column vectors, thats
                % why I transpose before inserting into array.

                % Add to the end
                switch mode
                    case {'append', 'initialize'}
                        obj.RoiPlotHandles{ch}(ind) = hLine;
                        obj.RoiTextHandles{ch}(ind) = hText;
                    case 'insert'
                        obj.RoiPlotHandles{ch} = utilities.insertIntoArray(obj.RoiPlotHandles{ch}, hLine', ind);
                        obj.RoiTextHandles{ch} = utilities.insertIntoArray(obj.RoiTextHandles{ch}, hText', ind);
                end
            end
            
            
            % Add positions to position arrays
            % NB: Have to transpose roiBoundaryCellArray here.
            centerPosArray = arrayfun(@(i) centerPosArray(i,:), 1:nRois, 'uni', 0);
            switch mode
                case {'append', 'initialize'}
                    obj.RoiLinePos{ch}(ind, :) = roiBoundaryCellArray';
                    obj.RoiTextPos{ch}(ind, 1) = centerPosArray;
                case 'insert'
                    obj.RoiLinePos{ch} = utilities.insertIntoArray(obj.RoiLinePos{ch}, roiBoundaryCellArray', ind, 1);
                    obj.RoiTextPos{ch} = utilities.insertIntoArray(obj.RoiTextPos{ch}, centerPosArray', ind, 1);
            end
             
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
                pObj(i) = patch(patchCoords{i}(:, 2), patchCoords{i}(:, 1), color, 'facealpha', 0.2, 'EdgeColor', 'None', 'Parent', obj.uiaxes.imagedisplay, 'Tag', tag);
            end
            
            set(pObj,'HitTest', 'off', 'PickableParts', 'none')

        end
        
        
        function updateRoiPlot(obj, roiInd, chInd)
        % Replot the roi at idx in roiArray
        
            if nargin < 3
                chInd = obj.activeChannel;
            end
            
            roi = obj.roiArray{chInd}(roiInd);
            
            for j = 1:length(roi.boundary)
                if j == 1
                    boundary = roi.boundary{j};
                else
                    boundary = cat(1, boundary, [nan,nan], roi.boundary{j});
                end
            end

            if chInd == obj.activeChannel
                obj.RoiPlotHandles{chInd}(roiInd).XData = boundary(:, 2);
                obj.RoiPlotHandles{chInd}(roiInd).YData = boundary(:, 1);
                % Move roi label/tag to new center position
                set(obj.RoiTextHandles{chInd}(roiInd), 'Position', [roi.center, 0])
            end
            
            obj.RoiLinePos{chInd}(roiInd, :) = {boundary(:, 2), boundary(:, 1)};
            % Move roi label/tag to new center position
            obj.RoiTextPos{chInd}(roiInd) = {[roi.center, 0]};
            
            if any(obj.selectedRois == roiInd)
                removeNeuropilPatch(obj, roiInd)
                addNeuropilPatch(obj, roiInd)
            end
            
            if any(obj.selectedRois == roiInd)
                obj.updateCurrentRoiImage(roiInd)
            end

        end
        
        
        function shiftRoiPlot(obj, shift)
        % Shift Roi plots according to a shift [x, y, 0]
            % Get active roi
            ch = obj.activeChannel;
            
            xData = {obj.RoiPlotHandles{ch}(obj.selectedRois).XData};
            yData = {obj.RoiPlotHandles{ch}(obj.selectedRois).YData};
            
            % Calculate and update position 
            xData = cellfun(@(x) x+shift(1), xData, 'uni', 0);
            yData = cellfun(@(y) y+shift(2), yData, 'uni', 0);
            set(obj.RoiPlotHandles{ch}(obj.selectedRois), {'XData'}, xData', {'YData'}, yData')

            % Shift text labels to new position, but only perform shift if 
            % they are visible. If not, they will be shifted when actual 
            % rois are moved.

            if obj.settings.showTags
                textpos = {obj.RoiTextHandles{ch}(obj.selectedRois).Position};
                textpos = cellfun(@(pos) pos + shift, textpos, 'uni', 0);
                set(obj.RoiTextHandles{ch}(obj.selectedRois), {'Position'}, textpos')
            end
            
%             drawnow;

            
% %             for i = obj.selectedRois
% % 
% %                 xData = get(obj.RoiPlotHandles{ch}(i), 'XData');
% %                 yData = get(obj.RoiPlotHandles{ch}(i), 'YData');
% %             
% %                 % Calculate and update position 
% %                 xData = xData + shift(1);
% %                 yData = yData + shift(2);
% %                 set(obj.RoiPlotHandles{ch}(i), 'XData', xData)
% %                 set(obj.RoiPlotHandles{ch}(i), 'YData', yData)
% %             
% %                 % Shift text to new position
% %                 textpos = get(obj.RoiTextHandles{ch}(i), 'Position');
% %                 textpos = textpos + shift;
% %                 set(obj.RoiTextHandles{ch}(i), 'Position', textpos);
% %             end
        end
        
        
        function addNeuropilPatch(obj, i)
        % Patch surrounding neuropil
        
        ch = obj.activeChannel;
        
            if obj.settings.showNpMask
                patchtag = sprintf('NpMask%03d', i);
                patches = findobj(obj.uiaxes.imagedisplay, 'Tag', patchtag);
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
                patches = findobj(obj.uiaxes.imagedisplay, '-regexp', 'Tag', patchtag);
                if ~isempty(patches)
                    delete(patches)
                end
            end
        end
        
        
        function setObjectVisibility(obj, src, ~)
            switch src.Label
                case 'Show Numbers'
                    set(obj.RoiTextHandles{obj.activeChannel}, 'Visible', 'on')
                    obj.settings.showTags = true;
                    src.Label = 'Hide Numbers';
                case 'Hide Numbers'
                    set(obj.RoiTextHandles{obj.activeChannel}, 'Visible', 'off')
                    obj.settings.showTags = false;
                    src.Label = 'Show Numbers';
                case 'Show Rois'
                    set(obj.RoiPlotHandles{obj.activeChannel}, 'Visible', 'on')
                    src.Label = 'Hide Rois';
                case 'Hide Rois'
                    set(obj.RoiPlotHandles{obj.activeChannel}, 'Visible', 'off')
                    src.Label = 'Show Rois';
                case 'Show Neuropil Mask'
                    obj.settings.showNpMask = true;
                    src.Label = 'Hide Neuropil Mask';
                case 'Hide Neuropil Mask'
                    obj.removeNeuropilPatch('all')
                    obj.settings.showNpMask = false;
                    src.Label = 'Show Neuropil Mask';
% %                 case 'Show Neuropil Signal'
% %                     obj.settings.showNpSignal = true;
% %                     src.Label = 'Hide Neuropil Signal';
% %                 case 'Hide Neuropil Signal'
% %                     obj.settings.showNpSignal = false;
% %                     src.Label = 'Show Neuropil Signal';
                case 'Show Roi Correlation Matrix'
                    chNo = obj.activeChannel;
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
                    [RHO, ~] = corr(signalData);
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

                case 'Open Roi Figure on Selection'
                    obj.settings.openRoiFigure = ~obj.settings.openRoiFigure;
                    
                    
                    

            end
            
        end
        
        
% % % % Methods for plotting other things

        function plotCircleTool(obj, coords)
            
            if nargin < 2 && ~obj.isCursorInsideAxes(obj.uiaxes.imagedisplay)
                if isempty(obj.circleToolCoords)
                    x = obj.roiTemplateCenter(1);
                    y = obj.roiTemplateCenter(2);
                    r = obj.roiOuterDiameter/2;
                    obj.circleToolCoords = [x, y, r];
                else
                    x = obj.circleToolCoords(1); y = obj.circleToolCoords(2); 
                    r = obj.circleToolCoords(3);
                end
            elseif nargin < 2 && obj.isCursorInsideAxes(obj.uiaxes.imagedisplay)
                point = obj.uiaxes.imagedisplay.CurrentPoint;
                x = point(1,1);
                y = point(1,2);
                if isempty(obj.circleToolCoords)
                    r = obj.roiOuterDiameter/2;
                else
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
            
            % Plot Line
            if isempty(obj.circleToolHandle)
                obj.circleToolHandle = plot(obj.uiaxes.imagedisplay, xData, yData, 'c');
            else
                set(obj.circleToolHandle, 'XData', xData, 'YData', yData)
            end
        end
        
        
        function plotCrosshair(obj, center)
%             drawnow limitrate
%             drawnow
            
            ps = 10 / obj.imWidth * range(obj.uiaxes.imagedisplay.XLim); 

            if nargin < 2 && ~obj.isCursorInsideAxes(obj.uiaxes.imagedisplay)
                y0 = obj.imHeight/2;
                x0 = obj.imWidth/2;
            elseif nargin < 2 && obj.isCursorInsideAxes(obj.uiaxes.imagedisplay)
                point = obj.uiaxes.imagedisplay.CurrentPoint;
                x0 = point(1,1);
                y0 = point(1,2);
            else
                x0 = center(1)+1*ps/10;
                y0 = center(2)+0;
            end
            
            xdata1 = [0, x0-ps, nan, x0+ps, obj.imWidth];
            ydata1 = ones(size(xdata1))*y0;
            
            ydata2 = [0, y0-ps, nan, y0+ps, obj.imHeight];
            xdata2 = ones(size(ydata2))*x0;
            
            % Plot Line
            if isempty(obj.crosshairHandle)
                obj.crosshairHandle = gobjects(4,1);
                obj.crosshairHandle(1) = plot(obj.uiaxes.imagedisplay, xdata1, ydata1);
                obj.crosshairHandle(2) = plot(obj.uiaxes.imagedisplay, xdata2, ydata2);
                obj.crosshairHandle(3) = plot(obj.uiaxes.imagedisplay, xdata1, ydata1);
                obj.crosshairHandle(4) = plot(obj.uiaxes.imagedisplay, xdata2, ydata2);
                set( obj.crosshairHandle(1:2), 'Color', [1,1,1])
                set( obj.crosshairHandle(1:2), 'LineWidth', 3)
                set( obj.crosshairHandle(3:4), 'Color', [0,0,0])
                set( obj.crosshairHandle(3:4), 'LineWidth', 1)
            else
                set(obj.crosshairHandle(1), 'XData', xdata1, 'YData', ydata1)
                set(obj.crosshairHandle(2), 'XData', xdata2, 'YData', ydata2)
                set(obj.crosshairHandle(3), 'XData', xdata1, 'YData', ydata1)
                set(obj.crosshairHandle(4), 'XData', xdata2, 'YData', ydata2)
            end
            
            
        end
            

        function plotRoiTemplate(obj)
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
                
                if isempty(obj.hlineRoiTemplate)
                    obj.hlineRoiTemplate = plot(obj.uiaxes.imagedisplay, xData, yData, 'yellow');
                else
                    set(obj.hlineRoiTemplate, 'XData', xData, 'YData', yData)
                end
            end
        end
        
       
% % % % Methods for loading and saving rois
        
        
        function loadRois(obj, src, ~)
        % Load rois from file. Keep rois which are in gui from before
        
        if ~isempty(obj.sessionObj) && ~obj.settings.useReferenceChannel && ~isa(src, 'matlab.ui.container.Menu')
                
% %                 sessionDir = getSessionFolder(obj.sessionObj.sessionID);
% %                 filePath = fullfile(sessionDir, 'roisignals');
% %                 roiListing = dir(fullfile(filePath, '*rois.mat'));
% %                 roiFileName = roiListing(1).name;
                
            loadpath = getFilePath(obj.sessionObj.sessionID, 'roi_arr', 1, 2);
            [filePath, roiFileName, ext] = fileparts(loadpath);
            roiFileName = strcat(roiFileName, ext);
            
            
        else
        
            % Open filebrowser in same location as imgTseries was loaded
            % from, unless the folder roisignals exist
            
            
            
            settingsPath = obj.signalExtractionSettings.savePath;
            roiPath = utilities.validatePathString(settingsPath, obj.initPath);
            
            if exist(roiPath, 'dir')
                initpath = roiPath;
            else
                initpath = obj.initPath;
            end

            [roiFileName, filePath, ~] = uigetfile({'*.mat', 'Mat Files (*.mat)'; ...
                                          '*', 'All Files (*.*)'}, ...
                                          'Find Roi File', ...
                                          initpath, 'MultiSelect', 'on');

            if isequal(roiFileName, 0) % User pressed cancel
                return
            end
            
        end

        if ischar(roiFileName) % Later sections work with cell of filenames
            roiFileName = {roiFileName};
        end
                        
        preLoadChannelNum = obj.activeChannel;
        
        fileChNames = regexp(roiFileName, [obj.fileSettings.chExpr, '\d*'], 'match');
        if ~isempty(fileChNames{1})
            fileChNames = cellfun(@(c) c{1}, fileChNames, 'uni', 0);
            fileChNames = strrep(fileChNames, obj.fileSettings.chExpr, '');
        else
            fileChNames{1} = '';
        end
        
        isRoiArrayLoaded = false(obj.nLoadedChannels, 1);
        
        roiSynchState = obj.settings.synchRoisAcrossChannels;
        
        %Need to turn this off when loading from files.
        obj.settings.synchRoisAcrossChannels = false;

        
        h = waitbar(0, 'Loading RoIs From File');

        % Determine channels and load rois to correct channel
        for f = 1:numel(roiFileName)
            
            filename = roiFileName{f};
            loadedChannel = fileChNames{f};
            
            % If roi file contains a channel number, change channel to load
            % rois to corresponding channel.
            if ~isempty(loadedChannel)
                if ~any(strcmp(obj.loadedChannels, loadedChannel))
                    warning('Channel number of roi file does not correspond with channel number of image file. Loading rois to current channel')
                    chInd = obj.activeChannel;
                else
                    % Change current channel to put rois in correct channel
                    if ~roiSynchState
                        obj.changeActiveChannel(struct('String', loadedChannel));
                    end
                    chInd = obj.activeChannel;
                end
            else
                chInd = obj.activeChannel;
            end
            
            % Load roi array from selected file path.
            if exist(fullfile(filePath, filename), 'file')
                S = load(fullfile(filePath, filename));
                field = fieldnames(S);
                fieldMatch = contains(field, {'roiArray', 'roi_arr'});
                if isempty(fieldMatch)
                    error('Did not find roi array in selected file')
                else
                    roi_arr = S.(field{fieldMatch});
                end
            else
                continue
            end
            
            % Go to next file if roi array is empty.
            if isempty(roi_arr)
                continue
            end
            
% % %             % Use rois from another session, and fill in missing. Easier if
% % %             % there are drifts over time.
% % %             if ~isempty(obj.sessionObj)
% % %                 [refRoiFile, folder, ~]  = uigetfile( {'*.mat', 'Mat Files (*.tif)'; ...
% % %                                                 '*', 'All Files (*.*)'}, ...
% % %                                                 'Find Rois', ...
% % %                                                 getSessionFolder(obj.sessionObj.sessionID), ...
% % %                                                 'MultiSelect', 'on');
% % %                 
% % %                 S = load(fullfile(folder, refRoiFile), 'roi_arr');
% % %                 roi_arr = S.roi_arr;
% % % %                 roiRef = S.roi_arr;
% % %                 
% % % %                 synched = utilities.synchRoiArrays({roiRef, roi_arr});
% % % %                 roi_arr = synched{1};
% % %                 
% % %             end
% % %                 
            
            
            
            
            
            % Determine mode of loading new rois.
            if ~isempty(obj.roiArray{chInd})
                % Remove old rois when loading new rois.
                if isequal(obj.roiArray{chInd}, roi_arr)
                    continue
                else
                    mode = questdlg('Should new rois replace current rois?', ...
                    'Load Options', ...
                    'Replace', 'Append', 'Append');
                    mode = lower(mode);
                end
            else
                mode = 'initialize';
            end
            
            % If rois should be replaced, remove current rois 
            switch mode
                case 'replace'
                    roiInd = 1:numel(obj.roiArray{chInd});
                    obj.removeRois(roiInd, chInd);
                    initializeSignalArray(obj, chInd)
                case 'initialize'
                    initializeSignalArray(obj, chInd)

            end
                
            if ~assertImageSize(roi_arr, [obj.imHeight, obj.imWidth])
                for i = 1:numel(roi_arr)
                    roi_arr(i).imagesize = [obj.imHeight, obj.imWidth];
                end
            end
            
%             loadedRois = checkRoiSizes(roi_arr, [obj.imHeight, obj.imWidth]);
                        
            % Add rois to manager
            obj.addRois(roi_arr, [], mode, chInd);
            isRoiArrayLoaded(chInd) = true;
            
            waitbar(f/numel(roiFileName), h)
        end
        
        close(h)
        

        if roiSynchState
            obj.roiArray = utilities.synchRoiArrays(obj.roiArray);
        end

        % Synchronize rois across channels.
        if roiSynchState && any(~isRoiArrayLoaded)
            
            roi_arr = utilities.roiarray2struct(roi_arr);
                        
            chInd = find(~isRoiArrayLoaded);
            
            switch mode
                case 'replace'               
                    roiInd = 1:numel(obj.roiArray{obj.activeChannel});
                    obj.removeRois(roiInd, chInd);
                    obj.initializeSignalArray(chInd)
            end
            
            obj.addRois(roi_arr, 1:numel(roi_arr), 'initialize', chInd);

        end
        
        % Reset roi synchronization state
        obj.settings.synchRoisAcrossChannels = roiSynchState;
        
        % Change to what was active channel before loading rois
        preLoadChannelName = obj.loadedChannels(preLoadChannelNum);
        obj.changeActiveChannel(struct('String', preLoadChannelName));
        
        % Initialize action log because this way of loading
        % rois was not compatible with the way the log works.
        initializeActionLog(obj)
        
        end
           
        
        function saveRois(obj, source, ~, saveMode)
        % Export rois to file. Save to sessionfolder if available
                   
            % Set save mode if it is not given as input
            if nargin < 4
                saveMode = 'Standard';
            end
            
            if ~isempty(obj.sessionObj) && ~obj.settings.useReferenceChannel
                saveMode = 'session';
            end
        
            % Get path for saving depending on which saveMode is used.
            switch lower(saveMode)
                case 'open browser'
                    
                    % Open filebrowser in same location as imTSeries was loaded from
                    initpath = obj.initPath;

                    [roiFilenm, savePath] = uiputfile(initpath);

                    if isequal(savePath, 0) % User pressed cancel
                        return
                    end
                    
                case 'session'
% %                     fullpath = getFilePath(obj.sessionObj.sessionID, 'roi_arr', 1, 2);
% %                     [savePath, fileName, ext] = fileparts(fullpath);
                    
                    savePath = obj.initPath;
                    settingsPath = obj.signalExtractionSettings.savePath;
                    savePath = utilities.validatePathString(settingsPath, savePath);
                    roiFilenm = strcat(obj.sessionObj.sessionID, '_rois.mat');

                otherwise
                    savePath = obj.initPath;
                    settingsPath = obj.signalExtractionSettings.savePath;
                    savePath = utilities.validatePathString(settingsPath, savePath);
            end
            
            if ~exist(savePath, 'dir'); mkdir(savePath); end

            % Loop through each channel and save roi arrays 
            for ch = 1:obj.nLoadedChannels
                
                if isempty(obj.roiArray{ch})
                    continue
                end
                
                if obj.settings.useReferenceChannel && ch == 1
                    continue
                end
                
                % Add channel suffix to filename
                switch lower(saveMode)
                    case 'open browser'
                    
                    case 'session'
                        
                    otherwise
                        roiFilenm = strcat( obj.loadedFileName{ch}, '_rois.mat' );
                end
                
                % Create enhanced roi image for all rois to be saved
                enhancedImageSize = [52,52]; % pixels * pixels

                if obj.settings.saveEnhancedRoiImages
                    for currRoi = 1:size(obj.roiArray{ch}, 2)
                        
                        % Create enhanced image if it is not already made
                        if isempty(obj.roiArray{ch}(currRoi).enhancedImage)
                            obj.roiArray{ch}(currRoi).enhancedImage = createRoiImage(obj,currRoi);
                        end
                        
                        % Resize enhancedImages to fixed size
                        if obj.settings.saveSquareEnhancedRoiImages
                            obj.roiArray{ch}(currRoi).enhancedImage = imresize(obj.roiArray{ch}(currRoi).enhancedImage,enhancedImageSize);
                        end
                    end
                end
                
                % Todo: Should save it as a struct array in the future... 
                roi_arr = obj.roiArray{ch};
                
                % Check if there are any rois outside the image.
                isOutside = isOutsideImage(roi_arr);
                if any(isOutside)
                    answer = questdlg('Rois are present outside of the image. Do you want to remove these before saving?');
                    switch lower(answer)
                        case 'yes'
                            roi_arr(isOutside) = [];
                    end
                end
                
                if isa(roi_arr, 'struct')
                    roi_arr = utilities.struct2roiarray(roi_arr);
                end
                
                % Check if a file already exists. Ask user what to do...
                if exist(fullfile(savePath, roiFilenm), 'file')
                    answer = questdlg('File already exists, do you want to overwrite it?');
                    switch lower(answer)
                        case 'yes'
                            doSave = true;
                        otherwise
                            doSave = false;
                    end
                else
                    doSave = true;
                end
                
                % Save rois to file
                if doSave
                    save(fullfile(savePath, roiFilenm), 'roi_arr')
                    fprintf('Rois saved to %s \n', fullfile(savePath, roiFilenm));
                end

            end
        end
        
        
        function saveSignal(obj, ~, ~, mode)
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
                    savePath = utilities.validatePathString(settingsPath, savePath);
            end
            
            if ~exist(savePath, 'dir'); mkdir(savePath); end
        
            options = obj.signalExtractionSettings;
            options.savePath = savePath;
            
            options.fps = obj.signalExtractionSettings.fps; 
            options.neuropilExtractionMethod = options.neuropilExtractionMethod.Selection;
            options.deconvolutionMethod = options.deconvolutionMethod.Selection;
            options.type = options.deconvolutionType.Selection;
            options.tau_dr = [obj.sliderTauDecay.Value, obj.sliderTauRise.Value] ./ 1000 .* options.fps;
            options.spk_SNR = str2double(obj.editSpikeSNR.String); % 10; %Default = 0.99
            options.lam_pr = str2double(obj.editLambdaPr.String); %Default = 0.5

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
                
                rois = obj.roiArray{ch};
                if isa(rois, 'struct')
                    rois = utilities.struct2roiarray(rois);
                end
                
                % Add some more items to options
                options.filename = sprintf('%s_signals.mat', obj.loadedFileName{ch});
                
                if options.extractFromFiles
                    % Find image files
                    chPattern = strcat(obj.fileSettings.chExpr, obj.loadedChannels(ch));
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
                        {images, rois, options})
                    fprintf('Signals will be extracted on a separate worker to:\n %s\n', savePath)
                else
                    tic
                	signalExtraction.extractAndSaveSignals(images, rois, options)
                    toc
                    fprintf('Signals saved to %s \n', savePath);
                end
                
            end
            
        end
        
        
        function runSeudo(obj, ~, ~)
        % runSeudo Run seudo for source demixing and signal contamination
        
            if ~exist('seudo', 'class')
                errordlg('Seudo is not on the matlab path.')
                return
            end
        
            Y = obj.imgTseries{obj.activeChannel};
            P = cat(3, obj.roiArray{obj.activeChannel}(:).mask );
            se = seudo(Y,single(P));
            se.classifyTransients;
        end
        
        
        function runAutoSegmentation(obj, ~, ~)
        % Calls autodetection package from Pnevmatikakis et al (Paninski)
        % and adds detected rois to gui
                   
        Y = obj.imgTseries{obj.activeChannel};
        
        % Create moving average video.
%         Y = utilities.getMovingAverage(Y, 10);
        
        if ~isa(Y,'single'); Y = single(Y);  end    % convert to single
        roiDiameter = obj.roiOuterDiameter;
        
        mask = obj.imgAvg{obj.activeChannel} ~= 0;
        mask = imdilate(mask, strel('disk', 5));
        Y = cast(mask, 'like', Y) .* Y;

        disp('Starting the roi autodetection program')
        
        switch lower(obj.signalExtractionSettings.autoSegmentationMethod.Selection)

            case 'suite2p'
                if ~exist('get_svdForROI.m', 'file')
                    errordlg('Suite2P is not on the matlab path.')
                    return
                end
                
                foundRois = autosegment.suite2p.run(Y, roiDiameter);
            case 'caiman'
                if ~exist('CNMF', 'class')
                    errordlg('CaImAn is not on the matlab path.')
                    return
                end
                
                foundRois = autosegment.cnmf.run(Y, roiDiameter);
            case 'tenaspis'
                
            case 'able'
                if ~exist('ABLE_documentation.pdf', 'file')
                    errordlg('ABLE is not on the matlab path.')
                    return
                end                
                foundRois = autosegment.able.run(Y, roiDiameter);
        end
        
        % Check and remove rois that are close to the edge of the image.
        isBoundaryRoi = arrayfun(@(roi) roi.isOnBoundary, foundRois);
        
        foundRois = foundRois(~isBoundaryRoi);
        
% %         % % % Testing.
        mask = obj.imgAvg{obj.activeChannel} == 0;
        mask = imdilate(mask, strel('disk', 5));
        
        isOutside = foundRois.isOverlap(mask);
        foundRois = foundRois(~isOutside);

        obj.addRois(foundRois);

        end
        
        
        function updateCnmfData(obj, idx, mode)
            
            %Only supports append
                        
            switch mode
                
                case 'append'
                    rois = obj.roiArray{obj.activeChannel}(idx);
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
        
        function showStack(obj, ~, ~)
        % Shows current frame in image display
            obj.unFocusButton(obj.uiButtons.ShowCurrentFrame)
            set(obj.fsContainer, 'Visible', 'on');
            
            % Untoggle all other show buttons
            obj.switchToggleButton(obj.uiButtons.ShowAvg, false)

            obj.updateImageDisplay();
        end
        
        
        function showAvg(obj, source, ~)
        % Shows stack average projection in image display
            obj.unFocusButton(obj.uiButtons.ShowAvg)
            ch = obj.activeChannel;
            if ~isempty(obj.imgAvg{ch})
                
                % Untoggle all other show buttons
                obj.switchToggleButton(obj.uiButtons.ShowAvg)

                if source.Value
                    set(obj.fsContainer, 'Visible', 'off');
                    set( obj.textCurrentFrame, 'String', ...
                              'Current Frame: Avg Image' )
                end
                
%                 set(obj.brightnessSlider, 'Low', obj.brightnessDictionary.avg.min);
%                 set(obj.brightnessSlider, 'High', obj.brightnessDictionary.avg.max);
%                 obj.changeBrightness(obj.brightnessSlider, [])
                
                obj.updateImageDisplay();
            end
        end
        
        
        function showMax(obj, source, ~)
        % Shows stack average projection in image display
            obj.unFocusButton(obj.uiButtons.ShowMax)
            ch = obj.activeChannel;
            if ~isempty(obj.imgMax{ch})
                
                % Untoggle all other show buttons
                obj.switchToggleButton(obj.uiButtons.ShowMax);
                
                if source.Value
                    set(obj.fsContainer, 'Visible', 'off');
                    set( obj.textCurrentFrame, 'String', ...
                              'Current Frame: Max Image' )
                end
                                
                obj.updateImageDisplay();
            end
        end           

  
        function showMovingAvg(obj, source, ~)
        % Shows stack running average projection in image display
        
            if ~source.Value
                obj.unFocusButton(obj.uiButtons.ShowMovingAvg)
            end
            
            % Untoggle all other show buttons
            obj.switchToggleButton(source);
            
            obj.updateImageDisplay();
            
        end
        
        
        function showMovingStd(obj, source, ~)
        % Shows stack running standard deviation projection in image display
        
            if ~source.Value
                obj.unFocusButton(obj.uiButtons.ShowMovingStd)
            end
            
            % Untoggle all other show buttons
            obj.switchToggleButton(source);

            
            if isempty(obj.imgTseriesMedfilt{obj.activeChannel})
                obj.despeckleStack();
            end
            
            obj.updateImageDisplay();
            
        end
        
        
        function showMovingMax(obj, source, ~)
        % Shows stack running maximum projection in image display
        
            if ~source.Value
                obj.unFocusButton(obj.uiButtons.ShowMovingMax)
            end
        
            % Untoggle all other show buttons
            obj.switchToggleButton(source);

            if isempty(obj.imgTseriesMedfilt{obj.activeChannel})
                obj.despeckleStack();
            end
            
            obj.updateImageDisplay(); 
            
        end
        
        
        function showCorrelationImage(obj, src, ~)

            % Calculate the correlation image if it does not exist.
            if isempty(obj.imgCn{obj.activeChannel})
                %Credit: Eftychios A. Pnevmatikakis & Pengcheng Zhou
                cIm = utilities.correlation_image(single(obj.imgTseries{obj.activeChannel}));
                cIm = utilities.makeuint8(cIm);
                obj.imgCn{obj.activeChannel} = cIm;
                
                if strcmp(src.Text, 'Calculate Correlation Image')
                    src.Text = 'Show Correlation Image';
                end
            end 
            
            obj.updateImageDisplay('Correlation Image')
            obj.switchToggleButton(obj.uiButtons.ShowAvg, false)
        end     
        
        
        function showBoostedActivityImage(obj, src, ~)
            
            if isempty(obj.imgBa{obj.activeChannel})
                obj.imgBa{obj.activeChannel} = utilities.enhancedActivityImage(obj.imgTseries{obj.activeChannel});
                obj.imgBa{obj.activeChannel} = uint8(obj.imgBa{obj.activeChannel}*255);
                
                if strcmp(src.Text, 'Calculate Boosted Activity Image')
                    src.Text = 'Show Boosted Enhanced Image';
                end
            end
            
            obj.updateImageDisplay('Boosted Activity Image')
            obj.switchToggleButton(obj.uiButtons.ShowAvg, false)     
        end
        

% % % % Two functions for general button management 
        
        function switchToggleButton(obj, sourceBtn, newState)
        %switchToggleButton Set state of togglebuttons belonging to a group
        %
        % This function is used for programmatically setting the state of a
        % toggle button and making sure that all complementry togglebuttons
        % are switched off.
        %
        % See also findButtonGroup

            if nargin < 3 || isempty(newState)
                newState = sourceBtn.Value;
            end

            buttonGroup = obj.findButtonGroup(sourceBtn);
            
            for i = 1:numel(buttonGroup)
                if buttonGroup(i) == sourceBtn
                    set(buttonGroup(i), 'Value', newState)
                else
                    set(buttonGroup(i), 'Value', 0)
                end
            end
            
        end
        
        
        function buttonGroup = findButtonGroup(obj, sourceButton)
        %findButtonGroup Return buttongroup which sourceButton belong to
            
            showbuttons = [ obj.uiButtons.ShowMovingMax, ...
                            obj.uiButtons.ShowMovingStd, ...
                            obj.uiButtons.ShowMovingAvg, ...
                            obj.uiButtons.ShowAvg, ...
                            obj.uiButtons.ShowMax ];
                        
            if any(showbuttons == sourceButton)
                buttonGroup = showbuttons; return
            end
            
            editbuttons = [ obj.uiButtons.DrawRoi, ...
                            obj.uiButtons.TraceRoi, ...
                            obj.uiButtons.EditRoi, ...
                            obj.uiButtons.AutoDetect, ...
                            obj.uiButtons.CircleTool, ...
                            obj.uiButtons.Crosshair ];
                        
            if any(editbuttons == sourceButton)
                buttonGroup = editbuttons; return
            end
            
            playbackbuttons = [ obj.uiButtons.play2x, ...
                                obj.uiButtons.play4x, ...
                                obj.uiButtons.play8x ];
                            
            if any(playbackbuttons == sourceButton)
                buttonGroup = playbackbuttons; return
            end
            
            buttonGroup = sourceButton;
            
        end
        
        
% % % % Misc

        function menuCallback_SelectFrames(obj, ~, ~)
        % Add booleans where there is a signal leakthrough or artifact in the roi signal. 

            if ~isempty(obj.hpatchFrameSelection)    
                if strcmp(obj.hpatchFrameSelection.Visible, 'on')
                    if isempty(obj.selectedFrames)
                        obj.selectedFrames = zeros(obj.nFrames(obj.activeChannel), 1);
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

            obj.selectedFrames = zeros(obj.nFrames(obj.activeChannel), 1);
            obj.updateSelectedFramePatch('delete')
        
        end
        
        
        function selectFrames(obj, mode)
            switch mode
                case 'Start Selection'
                    obj.selectFrameMode = true;

                    frameNo = obj.currentFrameNo;

                    if isempty(obj.hlineCurrentFrame2) || ~isgraphics(obj.hlineCurrentFrame2) 
                        obj.hlineCurrentFrame2 = plot(obj.uiaxes.signalplot, [frameNo, frameNo], get(obj.uiaxes.signalplot, 'ylim'), '--r', 'Visible', 'off', 'HitTest', 'off');
                    else
                        set(obj.hlineCurrentFrame2, 'XData', [frameNo, frameNo]);
                    end
                    
                case 'Finish Selection'
                    obj.selectFrameMode = false;
                    set(obj.hlineCurrentFrame2, 'Visible', 'off')
            end
        end

        
        function displaySelectedFrames(obj)
            
            %todo when roi is changed. Should it disappear? Have to change ydata...
           if obj.selectFrameMode
                if strcmp(obj.hlineCurrentFrame2.Visible, 'off')
                    set(obj.hlineCurrentFrame2, 'Visible', 'on')
                    set(obj.hpatchFrameSelection, 'Visible', 'on')
                end
               
                prevFrame = get(obj.hlineCurrentFrame2, 'XData');
                prevFrame = prevFrame(1);
                xPatch = [prevFrame, obj.currentFrameNo, obj.currentFrameNo, prevFrame];
                ylim = get(obj.uiaxes.signalplot, 'ylim');
                set(obj.hlineCurrentFrame2, 'YData', ylim);
                yPatch = [ylim(1), ylim(1), ylim(2), ylim(2)];
                
                if isempty(obj.hpatchFrameSelection) || ~isgraphics(obj.hpatchFrameSelection)
                    obj.hpatchFrameSelection = patch(xPatch, yPatch, [0.2,0.2,0.8] ,'Parent', obj.uiaxes.signalplot, 'facealpha', 0.2,'edgecolor','none');
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
                    [xCoord, yCoord] = plotbox.getEventPatchCoordinates(obj.selectedFrames, obj.uiaxes.signalplot.YLim);

                    if ~isempty(xCoord)
                        patch = findobj(obj.uiaxes.signalplot, 'Tag', 'SelectedFramePatch');
                        if isempty(patch)
                            return
                        end
                        
                        % Update y vertices of patch so that it covers from bottom to top of plot.
                        yVertices = patch.Vertices(:,2);
                        yVertices(yVertices==min(yVertices)) = min(yCoord(:));
                        yVertices(yVertices==max(yVertices)) = max(yCoord(:));
                        patch.Vertices(:,2) = yVertices;
                    end
                    
                case 'overwrite'
                    patches = findobj(obj.uiaxes.signalplot, 'Tag', 'SelectedFramePatch');
                    delete(patches)
                    pobj = plotbox.patchEvents(obj.uiaxes.signalplot, obj.selectedFrames, 'blue');
                    pobj.Tag = 'SelectedFramePatch';
                    pobj.EdgeColor = 'None'; pobj.FaceAlpha = 0.3; 
                    pobj.HitTest = 'off'; pobj.PickableParts = 'none';
                case 'delete'
                    patches = findobj(obj.uiaxes.signalplot, 'Tag', 'SelectedFramePatch');
                    delete(patches)
            end
        end
        
        
        function menuCallback_RoiToWorkspace(obj, ~, ~)
            
            ch = obj.activeChannel;

% % %             if isempty(obj.selectedFrames) || sum(obj.selectedFrames) == 0
% % %                 frames = 1:obj.nFrames(obj.activeChannel);
% % %             else
% % %                 frames = find(obj.selectedFrames);
% % %             end
            
            
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
        
        function changeBinningSize(obj, source, ~)
        % Updates the binning size for moving averages. Forces new value to
        % be odd
            newBinningSize = str2double(source.String);
            if ~mod(newBinningSize, 2)
                newBinningSize = newBinningSize - 1;
            end
            obj.binningSize = newBinningSize;
            set(obj.inputSetBinningSize, 'String', num2str(obj.binningSize))
        
        end
        
        
        function setRoiTemplateSize(obj, source,  ~)
        % Callback for button to set the roi diameter to use for autodetection
        
            switch source.String
                case 'Set Autodetection Size'
                    set(obj.uiButtons.SetRoiTemplateSize, 'String', 'Ok')
                    obj.uiButtons.SetRoiTemplateSize.Position(1) = 0.8;
                    obj.uiButtons.SetRoiTemplateSize.Position(3) = 0.15;
                    set(obj.roiSizeSliderContainer, 'Visible', 'on')
                    set(obj.uiButtons.SetRoiTemplateSize, 'TooltipString', 'Move cursor to image and click to reposition the Roi Template')
                    obj.setMouseMode('Set Roi Diameter')
                    if isempty(obj.roiTemplateCenter)
                        xlim = get(obj.uiaxes.imagedisplay, 'Xlim');
                        ylim = get(obj.uiaxes.imagedisplay, 'Ylim');
                        obj.roiTemplateCenter = [xlim(1) + diff(xlim)/2, ylim(1) + diff(ylim)/2];
                        plotRoiTemplate(obj);
                    end
                    
                    set(obj.hlineRoiTemplate, 'Visible', 'on')
                    
                case 'Ok'
                    obj.uiButtons.SetRoiTemplateSize.Position(1) = 0.1;
                    obj.uiButtons.SetRoiTemplateSize.Position(3) = 0.8;
                    set(obj.uiButtons.SetRoiTemplateSize, 'String', 'Set Autodetection Size')
                    set(obj.roiSizeSliderContainer, 'Visible', 'off')
                    set(obj.uiButtons.SetRoiTemplateSize, 'TooltipString', '')
                    set(obj.hlineRoiTemplate, 'Visible', 'off')
                    obj.unFocusButton(obj.uiButtons.SetRoiTemplateSize)
                    obj.setMouseMode('Previous')
            end        
        
        end
        
        
        function setDeconvolutionImplementation(obj, src, ~)

            switch src.String{src.Value}
                case {'CaImAn', 'Suite2P'}
                    obj.signalExtractionSettings.deconvolutionMethod.Selection = src.String{src.Value};
                    obj.modifySignalArray(obj.selectedRois, 'reset')
                    obj.updateSignalPlot(obj.selectedRois, 'overwrite')
            end
            
            switch src.String{src.Value}
                case 'CaImAn'
                    obj.dropdownMethod.Enable = 'on';
                case 'Suite2P'
                    obj.dropdownMethod.Enable = 'off';
            end

        end
        
        
        function setDeconvolutionMethod(obj, src, ~)
            switch src.String{src.Value}
                case {'Ar1', 'Ar2', 'Exp2', 'AutoAr'}
                    obj.signalExtractionSettings.deconvolutionType.Selection = lower(src.String{src.Value});
                    obj.modifySignalArray(obj.selectedRois, 'reset')
                    obj.updateSignalPlot(obj.selectedRois, 'overwrite')
            end
        end
        

        function changeRoiSize(obj, slider, ~)
        % Callback function for value change of roi diameter slider 
            obj.roiInnerDiameter = slider.Low;
            obj.roiOuterDiameter = slider.High;
            plotRoiTemplate(obj);
            set(slider, 'tooltip', sprintf('%d px', obj.roiOuterDiameter))
        end
        
        
        function changeBrightness(obj, slider, ~)
        % Callback function for value change of brightness slider
            min_brightness = slider.Low;
            max_brightness = slider.High;
            switch obj.channelDisplayMode
                case {'single', 'correlation'}
                    set(obj.uiaxes.imagedisplay, 'CLim', [min_brightness, max_brightness])
                case 'multi'
                    obj.updateImageDisplay();
            end
            drawnow;
            
            if obj.uiButtons.ShowAvg.Value
                obj.brightnessDictionary.avg.min = min_brightness;
                obj.brightnessDictionary.avg.max = max_brightness;
            elseif obj.uiButtons.ShowMax.Value
                obj.brightnessDictionary.max.min = min_brightness;
                obj.brightnessDictionary.max.max = max_brightness;  
            else
                obj.brightnessDictionary.norm.min = min_brightness;
                obj.brightnessDictionary.norm.max = max_brightness;  
            end
            
        end
        
        
        function changeTau(obj, slider, ~)
            set(slider, 'tooltip', sprintf('%d ms', slider.Value))
%             obj.updateSignal([], [])
        end

        
        function changeRoiClass(obj, source, ~)
            % Change roiclass of roi if popupmenu is changed.
            if ~isempty(obj.selectedRois)
                for i = obj.selectedRois
                    obj.roiArray{obj.activeChannel}(i) = obj.editRoiProperties(i, source);
                    obj.updateListBox(i);
                end
            end
        end
        
        
        function tagRois(obj, src, ~, tag)
            
            ch = obj.activeChannel;
            roiInd = obj.selectedRois;
            
            switch lower(tag)
                case 'overfilled'
                    % Add tag to tags property of selected rois.
                    if src.Value
                        obj.roiArray{ch}(roiInd) = obj.roiArray{ch}(roiInd).addTag(tag);
                    else
                        obj.roiArray{ch}(roiInd) = obj.roiArray{ch}(roiInd).removeTag(tag);
                    end

                case 'unchecked'
                    obj.roiArray{ch}(roiInd) = obj.roiArray{ch}(roiInd).addTag('imported');
                    obj.updateListBox(obj.selectedRois)
            end
            
        end
        
        
        function changeChannelDisplayMode(obj, source, ~)
        % Button callback to change display between showing single or
        % multiple channels.
        
        % This function was modified when I added the correlation image. It
        % was a button callback, but now it is also called from the
        % menu selection 'Show correlation image'. In this case I dont want
        % to update the image display, because it is done elsewhere.
        
            switch source.String
                case {'Show Single Channel', 'Show Enhanced Contrast Image'}
                    set(obj.uiButtons.ShowSingleChannel, 'String', 'Show All Channels')
                    obj.channelDisplayMode = 'single';
                    colormap(obj.uiaxes.imagedisplay, gray(256))
                    min_brightness = obj.brightnessSlider.Low;
                    max_brightness = obj.brightnessSlider.High;
                    set(obj.uiaxes.imagedisplay, 'CLim', [min_brightness, max_brightness])
                    obj.updateImageDisplay();
                    
                case 'Show All Channels'
                    if obj.nLoadedChannels == 1; return; end
                    set(obj.uiButtons.ShowSingleChannel, 'String', 'Show Single Channel')
                    obj.channelDisplayMode = 'multi';
                    obj.updateImageDisplay();
                    
                case 'Show Correlation Image'
                    obj.channelDisplayMode = 'correlation';
%                     colormap(obj.uiaxes.imagedisplay, parula(256))
                    min_brightness = obj.brightnessSlider.Low;
                    max_brightness = obj.brightnessSlider.High;
                    set(obj.uiaxes.imagedisplay, 'CLim', [min_brightness, max_brightness])
                otherwise
                    return
            end
            
        end
        
        
        function changeActiveChannel(obj, source, ~)
        % Callback for changing the current channel by user
        %
        % Change channels names in gui
        % Set active channel
        % Make sure rois in active channel are roi objects.
        % Make sure rois of other channels are struct arrays
        % In synch mode: exchange plot x and y data with plot handles for
        % active channel.
            
            newChannelName = source.String;
            prevCh = obj.activeChannel;
        
            % Selected channel as logical array.
            isNewChannel = cellfun(@(str) strcmp(str, newChannelName), obj.loadedChannels);
            chNew = find(isNewChannel, 1);
            % Check that the selected channel is part of list of channels
            % and that 
            if isempty(chNew)
                error('Selected channel (%s) is not loaded', source.String)
            elseif obj.activeChannel == chNew
                return %error('Selected channel (%s) is already active', source.String)
            end
              
            % Cancel drawing or editing - Need to do before deselecting
            if ~isempty(obj.tmpRoiPosX)
                obj.cancelRoi();
            end
            
            % Reset selection of rois. Do before setting new channel
            if ~obj.settings.synchRoisAcrossChannels
                obj.deselectRois(obj.selectedRois);
            end
            
            % Set new active channel and update listbox
            obj.activeChannel = chNew;
            set(obj.channel, 'String', obj.loadedChannels{obj.activeChannel})

            if ~obj.settings.synchRoisAcrossChannels
                obj.resetListbox();
            end

            % Update image and filename
%             set(obj.textCurrentFileName, 'String',  obj.loadedFileName{obj.activeChannel})
            isRoiEmpty = isempty(obj.roiArray{obj.activeChannel}) && isempty(obj.roiArray{prevCh});
            
            if obj.settings.synchRoisAcrossChannels && ~isRoiEmpty
                
                nRois = numel(obj.roiArray{obj.activeChannel});
                
                % Store line and text coordinates
                obj.RoiLinePos{prevCh}(1:nRois,1) = {obj.RoiPlotHandles{prevCh}.XData};
                obj.RoiLinePos{prevCh}(1:nRois,2) = {obj.RoiPlotHandles{prevCh}.YData};
                obj.RoiTextPos{prevCh}(1:nRois,1)= {obj.RoiTextHandles{prevCh}.Position};
                
                % Move line and text handles to current channel cell array
                obj.RoiPlotHandles{obj.activeChannel} = obj.RoiPlotHandles{prevCh};
                obj.RoiTextHandles{obj.activeChannel} = obj.RoiTextHandles{prevCh};
                obj.RoiPlotHandles{prevCh} = gobjects(0);
                obj.RoiTextHandles{prevCh} = gobjects(0);
                
                % Set position of plot and text handles to position of current channel
                set(obj.RoiPlotHandles{obj.activeChannel}, {'XData'}, obj.RoiLinePos{obj.activeChannel}(:,1))
                set(obj.RoiPlotHandles{obj.activeChannel}, {'YData'}, obj.RoiLinePos{obj.activeChannel}(:,2))
                set(obj.RoiTextHandles{obj.activeChannel}, {'Position'}, obj.RoiTextPos{obj.activeChannel})
            elseif isRoiEmpty
                % Do nothing...
            else
                % Change visibility of rois and text label
                for i = 1:obj.nLoadedChannels
                    if i == obj.activeChannel
                        set(obj.RoiPlotHandles{i}, 'Visible', 'on')
                        if obj.settings.showTags
                            set(obj.RoiTextHandles{i}, 'Visible', 'on')
                        end
                    else
                        set(obj.RoiPlotHandles{i}, 'Visible', 'off')
                        set(obj.RoiTextHandles{i}, 'Visible', 'off')
                    end
                end
            end
            
            obj.resetSignalPlot();
            
            % Convert rois from current channel to RoiArray and previous
            % channel to struct.
            if obj.settings.synchRoisAcrossChannels && ~isempty(obj.roiArray{obj.activeChannel})
                obj.roiArray{prevCh} = utilities.roiarray2struct(obj.roiArray{prevCh});
                obj.roiArray{obj.activeChannel} = utilities.struct2roiarray(obj.roiArray{obj.activeChannel});
            end
            
            if obj.nFrames(obj.activeChannel) ~= obj.nFrames(prevCh)
                if obj.currentFrameNo > obj.nFrames(obj.activeChannel)
                    obj.changeFrame(struct('String', num2str(obj.nFrames(obj.activeChannel))), [], 'jumptoframe')
                end
                
                obj.textCurrentFrame.String = sprintf( 'Current Frame: %d/%d',  obj.currentFrameNo, obj.nFrames(obj.activeChannel) );
                set(obj.frameslider, 'maximum',  obj.nFrames(obj.activeChannel), 'VisibleAmount', 0.1);
                obj.uiaxes.signalplot.XLim = [1, obj.nFrames(obj.activeChannel)];
            end
            
            obj.updateImageDisplay();
            if ~obj.settings.synchRoisAcrossChannels
                obj.updateListBox();
            end
            
            obj.updateSignalPlot(obj.selectedRois, 'overwrite');

        end
        
                  
% % % %  Misc
        
        function validateRois(obj, src, event)
            
            ch = obj.activeChannel;
            
            roiData.roiArrayOld = obj.roiArray{obj.activeChannel};
            roiData.roiArrayNew = RoI.empty(1,0);
            roiData.roiImage = cell(numel(roiData.roiArrayOld), 1);
            roiData.ulCoords = zeros(numel(roiData.roiArrayOld), 2);
            
            h = waitbar(0, 'Please wait, creating roi images and improving estimates');
            
            for i = 1:numel(roiData.roiArrayOld)
                [roiData.roiImage{i}, roiData.ulCoords(i,:)] = createRoiImage(obj, i);
                
                frames = getActiveFrames(obj, i);
                
                x = obj.roiArray{ch}(i).center(1);
                y = obj.roiArray{ch}(i).center(2);
                
                mask = obj.autodetectDonut(x, y, frames);
                
                roiData.roiArrayNew(i) = obj.roiArray{ch}(i).reshape('Mask', mask);
                
                if mod(i, 10) == 0
                    waitbar(i/numel(roiData.roiArrayOld), h)
                end
            end
            
            close(h)
            
            roiValidator(roiData)

        end


        function applyRoisToOtherSessions(obj, ~, ~)
            % Note only works for active channel
           
            msg = [ 'Add reference images from other sessions here. Add ',...
                    'as many files as you want. These images will be ', ...
                    'aligned to the average image of the current channel, '...
                    'and then the shifts will be used to reposition the rois ', ...
                    'for each session. One file with rois will be saved for each ', ...
                    'reference image, in the same folder as the image is loaded from.'];

            imgFilePaths = utilities.fileFinder(msg, 'image', obj.initPath);
            
            if isempty(imgFilePaths); return; end
            
            % Get average image of active channel and use as reference
            ch = obj.activeChannel;
            ref = obj.imgAvg{ch};
            
            % Load reference images
            imCellArray = cellfun(@(pathstr) imread(pathstr), imgFilePaths, 'uni', 0);
            imArray = cat(3, ref, imCellArray{:});
            
            % Find fov shifts
            fovShifts = crossday.alignFovs(imArray);
            
            roiImArray = cell(numel(fovShifts)+1, 1);
            
            % Loop through sessions and create new rois.
            for i = 0:numel(fovShifts)
                
                if i == 0
                    roi_arr = obj.roiArray{ch};
                    pathstr = fileparts(obj.initPath(1:end-1)); % Stupid way to remove filesep... Will probably regret this..
                    fileName = obj.loadedFileName{obj.activeChannel};
                    pathstr = fullfile(pathstr, 'fov_image');
                    if ~exist(pathstr, 'dir'); mkdir(pathstr); end
                else
                    roi_arr = crossday.warpRois(obj.roiArray{ch}, fovShifts(i));
                    % Save rois
                    [pathstr, fileName, ~] = fileparts(imgFilePaths{i});
                    save(fullfile(pathstr, strcat(fileName, '_rois.mat')), 'roi_arr')
                end
                    

                
                % Create and save image with rois overlaid
                im = imArray(:,:,i+1);
                
                if isa(imArray, 'uint16')
                    im = utilities.makeuint8(im);
                end
                
                f = figure('visible', 'off', 'Position', [1,1,size(im)]); 
                ax = axes('Parent', f, 'Position', [0,0,1,1]);
                imshow(im, 'Parent', ax); hold on;
                hrois = plotbox.drawRoiOutlines(gca, roi_arr, true);
                set(hrois, 'LineWidth', 0.5, 'Color', 'r')
                frame = frame2im(getframe(f));
                savePath = fullfile(pathstr, strcat(fileName, '_rois_overlaid.png'));
                imwrite(frame, savePath, 'PNG' );
                roiImArray{i+1} = frame;
%                                 roiImArray{i} = imresize(frame, size(im));

                
                close(f)

            end
           
            % Open images in imviewer to see if they match
            imviewer(cat(4, roiImArray{:}))

        end


        function loadRoisFromOtherSessions(obj, ~, ~)
            msg = [ 'Find roi files to add to this session. All rois with ', ...
                    'with different uids will be compared with existing rois, ',...
                    'and will be added if they are not overlapping. Overlapping rois ', ...
                    'will inherit roi uids from the imported rois. Added rois will be ', ...
                    'green. Use enter to untag them.'];

            roiFilePaths = utilities.fileFinder(msg, 'mat', obj.initPath);
            
            if isempty(roiFilePaths); return; end
            
            for fnum = 1:numel(roiFilePaths)
            
                S = load(roiFilePaths{fnum});
                roiArray1 = S.roi_arr;
                roiArray2 = obj.roiArray{obj.activeChannel};

                % Get the rois which are not present in the current rois.
                % Rois are repositioned based on interpolation of the positions
                % of the intersection of rois between the 2 sessions.
                roiArrayDiffImported = utilities.interpolateRoiPositions(roiArray1, roiArray2);

                % Find those rois that have a large overlap. Only compare the
                % difference.
                roiArrayDiffCurrent = utilities.setdiffRois(roiArray2, roiArray1);

                centerImported = cat(1, roiArrayDiffImported.center);
                centerCurrent = cat(1, roiArrayDiffCurrent.center);

                % Merge highly overlapping rois.
                if ~isempty(roiArrayDiffCurrent)
                    [xPosI, xPosJ] = meshgrid(centerImported(:,1), centerCurrent(:,1));
                    [yPosI, yPosJ] = meshgrid(centerImported(:,2), centerCurrent(:,2));

                    distance = sqrt( (xPosI-xPosJ).^2 + (yPosI-yPosJ).^2 );
                    [j, i] = find(distance<10);

                    overlap = zeros(numel(j), 1);
                    for n = 1:numel(j)
                        overlap(n) = RoI.calculateOverlap(roiArrayDiffImported(i(n)), ...
                                        roiArrayDiffCurrent(j(n)));
                    end

                    isOverlapping = find(overlap>0.75)';

                    for n = isOverlapping
                        roiArrayDiffCurrent(j(n)).uid = roiArrayDiffImported(i(n)).uid;
                    end

                    roiArrayDiffImported(i(isOverlapping)) = [];
                end

                % Find rois with zero values in the mean...
                isOnEdge = false(numel(roiArrayDiffImported),1);
                for i = 1:numel(roiArrayDiffImported)
                    roiMask = roiArrayDiffImported(i).mask;
                    if any(any(obj.imgAvg{obj.activeChannel}(roiMask) == 0))
                        isOnEdge(i) = true;
                    end
                end

                roiArrayDiffImported(isOnEdge) = [];

                roiArrayDiffImported = roiArrayDiffImported.addTag('imported');
                obj.addRois(roiArrayDiffImported);
            end
            
        end
        
        
        function repositionRois(obj, src, ~)
            
            ch = obj.activeChannel;
            nCh = obj.nLoadedChannels;
            
            switch src.Label
                
                case 'Reposition Rois ...'

                    if numel(obj.roiArray) == nCh + 1
                        return
                    end
                    
                    % Select 10-15 random rois scattered across the fov and 
                    % color them a different color.
                    
                    randInd = randi([1,numel(obj.roiArray{ch})], 15, 1);
                    set(obj.RoiPlotHandles{ch}(randInd), 'Color', 'c')
                    
                    % Make a backup of the roi array. Put this in the
                    % channel after the last. (NB) This needs to be
                    % implemented in a better way if peple are working on
                    % multiple channels...
                    
                    obj.roiArray{nCh+1} = obj.roiArray{ch};
                    
                    msgbox('Move a subset of rois to their optimal position. A random selection is highlighted, but you can move any rois. When done, press shift+f and all the other rois will be shifted based on interpolation.')
                    
                case 'Finish Reposition'
                    % NB The following is much the same as the moveRoi
                    % method, with some differences, e.g. the moveRoi
                    % method does not shift the roi plot, and here that
                    % happens. Also here, the small roi inset image is not
                    % updated.
                    
                    if numel(obj.roiArray) == nCh
                        return
                    end
                    
                    % Get the original rois
                    roisOrig = obj.roiArray{nCh+1};
                    
                    % Find ind of rois that has changed positions.
                    centerCoordOrig = cat(1, roisOrig.center);
                    centerCoordNew = cat(1, obj.roiArray{ch}.center);
                    
                    [~, roiInd] = setdiff(centerCoordOrig, centerCoordNew, 'rows');

                    % Find the offsets (shifts) of these rois.
                    roiOffsets = centerCoordNew(roiInd,:) - centerCoordOrig(roiInd,:);

                    Fx = scatteredInterpolant(centerCoordOrig(roiInd,1),centerCoordOrig(roiInd,2), roiOffsets(:,1));
                    Fy = scatteredInterpolant(centerCoordOrig(roiInd,1),centerCoordOrig(roiInd,2), roiOffsets(:,2));

                    roiIndB = setdiff(1:numel(obj.roiArray{ch}), roiInd);
                                        
                    % Turn off signal plot
                    if obj.uiButtons.ShowSignal.Value
                        obj.showSignalPlot( struct('Value', 0), [])
                    end
                    
                    % Turn on the waitbar if many rois are being moved...
                    wb_on = false;
                    if numel(roiIndB) > 50
                        h = waitbar(0, 'Moving Roi Objects'); 
                        wb_on = true; c=0;
                    end
                    
                    obj.addToActionLog(ch, roiIndB, 'reshape')
                    obj.modifySignalArray(roiIndB, 'reset')

                    % Sort roiInds.
                    roiIndsSorted = [];
                    
                    yPos = centerCoordOrig(roiIndB, 2);
                    xPos = centerCoordOrig(:, 1);
                    
                    yPos = ceil(yPos ./ (obj.imHeight/4));
                    for i = 1:4
                        tmpInd = roiIndB(yPos == i);
                        [~, sortInd] = sort(xPos(tmpInd));
                        
                        roiIndsSorted = cat(2, roiIndsSorted, tmpInd(sortInd));
                    end
                    
                    for i = roiIndsSorted
                        roiShiftX = Fx(obj.roiArray{ch}(i).center);
                        roiShiftY = Fy(obj.roiArray{ch}(i).center);
                        
                        % NB: For simple coding, I just (mis)use the roimanager
                        % move method. Not optimal, should at some point
                        % make an extended roi class, for plottable roi
                        % objects...
                        obj.selectedRois = i;
                        
                        % For debugging / testing the method
                        set(obj.RoiPlotHandles{ch}(i), 'Color', 'g', 'LineWidth', 2)

%                         pause(0.2)
                        obj.shiftRoiPlot( [roiShiftX, roiShiftY, 0] );
                        obj.roiArray{ch}(i) = obj.roiArray{ch}(i).move([roiShiftX, roiShiftY]);
                        removeNeuropilPatch(obj, i)
                        addNeuropilPatch(obj, i)
                        
                        if wb_on; c=c+1; waitbar(c/numel(roiIndB), h); end
                        
                        set(obj.RoiPlotHandles{ch}(i), 'Color', 'r', 'LineWidth', 0.5)
                    end
                    
                    if wb_on; close(h); end
                    
                    answer = questdlg('Is this good enough?', '', 'Yes', 'No', 'Yes');
                    
                    switch answer
                        case 'Yes'
                            obj.roiArray(nCh+1) = [];
                        case 'No'
                            % Select some rois that are not good.
                            msgbox('Select a subset of rois that are not well positioned. Press shift-r, and then place these rois in the optimal positions and press shift-f to finish.')
                    end

                    if obj.uiButtons.ShowSignal.Value
                        obj.showSignalPlot( struct('Value', 1), [])
                    end
                    
                    
                case 'Undo Reposition and Continue'
                    
                    roiInds = obj.selectedRois;
                    
                    obj.traverseActionLog('up')
                    
                    obj.deselectRois(roiInds)
                    
                    set(obj.RoiPlotHandles{ch}(roiInds), 'Color', 'c', 'LineWidth', 1)
                    
            end
            
            
        end
        
        
        
        
        function despeckleStack(obj)
        % Create a stack which is median filtered (despeckled)
        
            h = waitbar(0, 'Please wait while performing median filtering');
            
            ch = obj.activeChannel;
            obj.imgTseriesMedfilt{ch} = zeros(obj.imHeight, obj.imWidth, obj.nFrames(ch), 'like', obj.imgTseries{ch});

            for f = 1:obj.nFrames(ch)
                obj.imgTseriesMedfilt{ch}(:,:,f) = medfilt2(obj.imgTseries{ch}(:, :, f));
                if mod(f,100)==0
                    waitbar(f/obj.nFrames(ch), h)
                end
            end

            close(h)
            
        end
       
        
        function filterImage(obj, ~, ~, type)
            ch = obj.activeChannel;
            switch type
                case 'okada'
                    obj.imgTseries{ch} = utilities.okada(obj.imgTseries{ch}, 3);
                    obj.updateImageDisplay()
           end
            
        end
        
        
        function openRoiFigure(obj)
        
        end
        
% % % % Methods for extracting and showing signal of RoIs


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
                case 'Show Deconvolved'
                    signalName = 'deconvolved';
                    
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
                
                if (isequal(signalName, 'denoised') || isequal(signalName, 'deconvolved')) && (obj.uiButtons.ShowDenoised.Value + obj.uiButtons.ShowSpikes.Value == 1)
                    showDeconvolutionOptions(obj, source) 
                end

            else
                obj.signal2display = setdiff(obj.signal2display, signalName);
                set( obj.hlineSignal.(signalName), 'Visible', 'off' )
                if isequal(signalName, 'denoised')
                    hNoiseThresh = findobj(obj.uiaxes.signalplot, 'Tag', 'spkSnr');
                    if ~isempty(hNoiseThresh); delete(hNoiseThresh); end
                end
                
                if (isequal(signalName, 'denoised') || isequal(signalName, 'deconvolved')) && ( obj.uiButtons.ShowDenoised.Value + obj.uiButtons.ShowSpikes.Value == 0)
                    hideDeconvolutionOptions(obj, source) 
                end
            end

            for i = 1:numel(obj.selectedRois)
                if i == 1
                    updateSignalPlot(obj, obj.selectedRois(i), 'overwrite');
                else
                    updateSignalPlot(obj, obj.selectedRois(i), 'append');
                end
            end
            
            if isequal(source.String, 'Show Deconvolved')
                source.String = 'Show Spikes';
                obj.changeSignalType(source, [])
            end
            
            if isequal(source.String, 'Show Spikes')
                source.String = 'Show Deconvolved';
            end
            
            
        end
        
        
        function changeSignalParameter(obj, src, ~)
        %changeSignalParameter Callback for deconvolution parameter update 
                        
            if isa(src, 'javahandle_withcallbacks.javax.swing.JSlider')
                parameter = src.Name;
                newValue = src.Value;
                
            elseif isa(src, 'matlab.ui.control.UIControl')
                parameter = src.Tag;
                newValue = str2double(src.String);
                if isnan(newValue)
                    errordlg('This is not a number')
                end
            else
               error('Unknown source for changing signal parameters') 
            end
            
            switch lower(parameter)
                
                case 'taurise'
                    
                    
                    obj.signalExtractionSettings.caimanParameters.tauDr(2) = newValue;
                case 'taudecay'
                    obj.signalExtractionSettings.caimanParameters.tauDr(1) = newValue;
                case 'spikesnr'
                    obj.signalExtractionSettings.caimanParameters.spkSnr = str2double(src.String);
                case 'lambdapr'
                    obj.signalExtractionSettings.caimanParameters.lamPr = str2double(src.String);
            end
            
            obj.modifySignalArray(obj.selectedRois, 'reset', [], {'deconvolved', 'denoised', 'spikes'}) % should only reset deconv, denoised and spikes.
            obj.updateSignalPlot(obj.selectedRois, 'overwrite')
            
            
%             for i = 1:numel(obj.selectedRois)
%                 if i == 1
%                     updateSignalPlot(obj, obj.selectedRois(i), 'overwrite');
%                 else
%                     updateSignalPlot(obj, obj.selectedRois(i), 'append');
%                 end
%             end
           
        end
            
            
        function [signal] = extractSignal(obj, roiInd, signalName)
        %extractSignal Extract roisignals for specified rois.
            
            signal = [];
        
            if obj.nFrames(obj.activeChannel) < 100
                return
            end
            
        
            ch = obj.activeChannel;
            if obj.settings.showWaitbar 
                h = waitbar(0, 'Please wait, extracting signals for Roi');
            end
            
            % Shorten name of extraction function to make lines shorter.
            extract = @signalExtraction.extractSignalFromImageData;

            % NB: Relevant for eivind because of circular cropping of images.
            imageMask = mean(obj.imgTseries{ch}, 3) ~= 0;
            imageMask = imclose(imageMask, ones(3,3));
            imageMask = imerode(imageMask, ones(3,3));
            
            
            % Choose signal extraction beased on selected method.
            switch signalName
                
            case 'roiMeanF'
            
                signal = extract(obj.imgTseries{ch}, obj.roiArray{ch}, 'raw', roiInd, imageMask);
                signal = squeeze(signal);
                                
            case 'dff'
                
                tmpSignal = extract(obj.imgTseries{ch}, obj.roiArray{ch}, 'standard', roiInd, imageMask);
%                 angles = obj.stagePos;
%                 roiBaseline = getRotationBaseline(tmpSignal(:, 1)', angles);
%                 npilBaseline = getRotationBaseline(tmpSignal(:, 2)', angles);
%     
%                 roisMeanF = tmpSignal(:,1,:)' - roiBaseline + mean(roiBaseline);
%                 npilMediF = tmpSignal(:,2,:)' - npilBaseline + mean(npilBaseline);
%                 signal1 = squeeze(signalExtraction.dff.dffRoiMinusDffNpil(roisMeanF, npilMediF));
                roiMeanF = squeeze(tmpSignal(:,1,:));
                pilMeanF = squeeze(tmpSignal(:,2,:));

                
                dffMethod = obj.signalExtractionSettings.dffMethod.Selection;
                dffFunction = str2func(sprintf('signalExtraction.dff.%s', dffMethod));
                signal = squeeze(dffFunction(roiMeanF, pilMeanF));
                
%                 signal = squeeze(signalExtraction.dff.dffRoiMinusDffNpil(roiMeanF, pilMeanF));
                
            case 'demixedMeanF'
                
                switch obj.signalExtractionSettings.neuropilExtractionMethod.Selection
                    case 'Standard'
                        signal = extract(obj.imgTseries{ch}, obj.roiArray{ch}, 'standard', roiInd);
                        signal = squeeze(signal(:, 1, :));
                    case 'Fissa'
                        extractedSignals = extract(obj.imgTseries{ch}, obj.roiArray{ch}, 'fissa', roiInd);
                        signal = signalExtraction.fissa.pythonWrapper(extractedSignals);
                end
                
            case {'denoised', 'deconvolved'}
                
                % Determine deconvolution method
                deconvolutionMethod = obj.signalExtractionSettings.deconvolutionMethod.Selection;
                dff = obj.signalArray(ch).dff(:, roiInd);
                
                % Check if any dffsignals are missing and extract if needed
                isMissingSignal = any(isnan(dff));
                if any(isMissingSignal)
                    tmpRoiInd = roiInd(isMissingSignal);
                    obj.extractSignal(tmpRoiInd, 'dff');
                    dff = obj.signalArray(ch).dff(:, roiInd);
                end
                
                % Set options
                opt.fps = obj.signalExtractionSettings.fps; %31;
                opt.type = obj.signalExtractionSettings.deconvolutionType.Selection;
                opt.spk_SNR = str2double(obj.editSpikeSNR.String); % 10; %Default = 0.99
                opt.lam_pr = str2double(obj.editLambdaPr.String); %Default = 0.5
                opt.tau_dr = [obj.sliderTauDecay.Value, obj.sliderTauRise.Value] ./ 1000 .* opt.fps;
                
                
                % Deconvolve dff. Have to transpose dff... :(
                switch deconvolutionMethod
                    case 'CaImAn'
                        [dec_df, den_df, param] = signalExtraction.CaImAn.deconvolve(dff', opt);
                        
                        % Calculate time constants in ms
                        tauRDms = signalExtraction.CaImAn.getArConstantsInMs(param{1}.pars,  opt.fps);

                    case 'Suite2P'
                        [dec_df, den_df] = signalExtraction.Suite2P.deconvolve(dff', opt.fps);
                        tauRDms = [nan, nan];
                end
                

                
                obj.editTauDecay.String = sprintf('%d', round(tauRDms(2)));
                obj.editTauRise.String = sprintf('%d', round(tauRDms(1)));
                
                % Transpose results back to obtain nT x nRois
                den_df = den_df'; dec_df = dec_df';

                % Add denoised and deconvolved signals to signalArray
                obj.signalArray(ch).denoised(:, roiInd) = den_df;
                obj.signalArray(ch).deconvolved(:, roiInd) = dec_df;
                
                % Assign output of funtion based on signal name
                switch signalName
                    case 'denoised'
                        signal = den_df;
                    case 'deconvolved'
                        signal = dec_df;
                end
           	
            case 'spikes'
                %todo: set spikethreshold manually or automatically based
                % on magnitudes of dff and the deconvolved trace.

                % Get deconvolved signals
                dec = obj.signalArray(ch).deconvolved(:, roiInd);
                
                % Extract deconvolved signals if any are missing
                isMissingSignal = any(isnan(dec));
                if any(isMissingSignal)
                    tmpRoiInd = roiInd(isMissingSignal);
                    obj.extractSignal(tmpRoiInd, 'deconvolved');
                end
                dec = obj.signalArray(ch).deconvolved(:, roiInd);
                
% % %                 % set/get spikethreshold (not implemented...)
% % %                 if isnan(obj.signalArray(ch).spikeThreshold(roiInd))
% % %                     opt.spikethreshold = 0.05;
% % %                     obj.signalArray(ch).spikeThreshold(roiInd) = opt.spikethreshold;
% % %                 else
% % %                     opt.spikethreshold = obj.signalArray(ch).spikeThreshold(roiInd);
% % %                 end
                
                % Set spike threshold based on deconvolution method
                switch obj.signalExtractionSettings.deconvolutionMethod.Selection
                    case 'CaImAn'
                        opt.spikethreshold = 0.1;
                    case 'Suite2P'
                        opt.spikethreshold = 0.1;                        
                end
                
                dff = obj.signalArray(ch).dff(:, roiInd);
                den = obj.signalArray(ch).denoised(:, roiInd);
                
% %                 spksnr = str2double(obj.editSpikeSNR.String);
% %                 spkmin = spksnr * GetSn(dff);
% %                 opt.nSpikes = 0.04 * round(sum(den>spkmin));
% %                 
% %                 obj.editSpikeThresh.String = num2str(opt.spikethreshold);
% % 
% %                 dec = dec'; % Transpose because integrateAndFire takes nRois x nT
% % %                 signal = signalExtraction.spikeEstimation.integrateAndFire(dec, opt);
% %                 signal = signal'; % Transpose back.

                signal = signalExtraction.spikeEstimation.discretizeDeconvolved(dec);

                
            otherwise
                fprintf('unknown signal, %s\n', signalName)
            end
            
            % Add extracted signals to signal array
            obj.signalArray(ch).(signalName)(:, roiInd) = signal;
            if obj.settings.showWaitbar; close(h); end
            
            % Clear output if not assigned in caller
            if ~nargout
                clear signal
            end
            
        end
        
        
        function showSignalPlot(obj, source, ~)
                            
            btnGroup = [obj.uiButtons.ShowRaw, obj.uiButtons.ShowDFF, ...
                        obj.uiButtons.ShowDemixed, obj.uiButtons.ShowDenoised, obj.uiButtons.ShowSpikes ];
                    
            signalNames = {'roiMeanF', 'npilMediF', 'demixedMeanF', 'dff', ...
                            'deconvolved', 'denoised', 'spikes'};                    
            
            if source.Value
                set(obj.uiaxes.signalplot, 'Visible', 'on')
                set(obj.uiaxes.signalplot.Children, 'Visible', 'on')
                for h = 1:numel(signalNames)
                    set(obj.hlineSignal.(signalNames{h}), 'Visible', 'on')
                end
                
                if ~isvalid(obj.hlineCurrentFrame)
                    obj.hlineCurrentFrame = [];
                    updateFrameMarker(obj)
                end
                
                set(obj.hlineCurrentFrame, 'Visible', 'on')
                if ~ strcmp(obj.uiButtons.UndockImage.String, 'Dock Image Window')
                    set(obj.uiaxes.imagedisplay, 'Position', [0.12, 0.2, 0.77, 0.77])
                end
                
                drawnow
                set(obj.himage, 'ButtonDownFcn', @obj.mousePress)
                set(btnGroup, 'Visible', 'on')
                
                if obj.uiButtons.ShowSpikes.Value || obj.uiButtons.ShowDenoised.Value 
                    showDeconvolutionOptions(obj, source)
                end

            else
                obj.resetSignalPlot();
                set(obj.uiaxes.signalplot, 'Visible', 'off')
                set(obj.uiaxes.signalplot.Children, 'Visible', 'off')

                for h = 1:numel(signalNames)
                    set(obj.hlineSignal.(signalNames{h}), 'Visible', 'off')
                end
                set(obj.hlineCurrentFrame, 'Visible', 'off')
                set(obj.uiaxes.imagedisplay, 'Position', [0.02, 0.01, 0.96, 0.96])
                set(btnGroup, 'Visible', 'off')
                                
                % Reset limits if the zoom was used. 
                set(obj.uiaxes.signalplot, 'XLim', [0.99, obj.nFrames(obj.activeChannel)])
                hideDeconvolutionOptions(obj, source)
            end
            
            
        end
        
        
        function showDeconvolutionOptions(obj, source)
%             set(obj.uiaxes.imagedisplay, 'Position', [0.145, 0.25, 0.71, 0.71])
            
            if isequal(source, obj.uiButtons.ShowSpikes) || ...
                    isequal(source, obj.uiButtons.ShowDenoised) 
                obj.uiaxes.signalplot.Position(4) = obj.uiaxes.signalplot.Position(4) - 0.04;
            end
            
            obj.dropdownImplementation.Visible = 'on';
            obj.dropdownMethod.Visible = 'on';
            set(obj.sliderTauRiseContainer, 'Visible', 'on')
            set(obj.sliderTauDecayContainer, 'Visible', 'on')
            obj.editSpikeSNR.Visible = 'on';
            obj.editLambdaPr.Visible = 'on';
%             obj.editSpikeSNR.UserData.Visible = 'on';
%             obj.editLambdaPr.UserData.Visible = 'on';
            set(obj.textannotations, 'Visible', 'on');
        end
        
        
        function hideDeconvolutionOptions(obj, source)
%             set(obj.uiaxes.imagedisplay, 'Position', [0.12, 0.2, 0.76, 0.76])
            
            if isequal(source, obj.uiButtons.ShowSpikes) || ...
                    isequal(source, obj.uiButtons.ShowDenoised) 
                obj.uiaxes.signalplot.Position(4) = obj.uiaxes.signalplot.Position(4) + 0.04;
            end
            
            obj.dropdownImplementation.Visible = 'off';
            obj.dropdownMethod.Visible = 'off';
            set(obj.sliderTauRiseContainer, 'Visible', 'off')
            set(obj.sliderTauDecayContainer, 'Visible', 'off')
            obj.editSpikeSNR.Visible = 'off';
            obj.editLambdaPr.Visible = 'off';
%             obj.editSpikeSNR.UserData.Visible = 'off';
%             obj.editLambdaPr.UserData.Visible = 'off';  
            set(obj.textannotations, 'Visible', 'off');
        end
        
        
        function updateSignal(obj, ~, ~)
            obj.modifySignalArray(obj.selectedRois, 'reset')
            obj.updateSignalPlot(obj.selectedRois, 'overwrite')
        end
        
        
        function updateSignalPlot(obj, roiInd, mode)
        % Update signal plot
        
            if ~obj.uiButtons.ShowSignal.Value || isempty(roiInd)
                return
            end
        
            if ~ishold(obj.uiaxes.signalplot)
               hold(obj.uiaxes.signalplot, 'on') 
            end
            
            yyaxis(obj.uiaxes.signalplot, 'left')
            
            fields = fieldnames(obj.signalArray);
            fields = setdiff(fields, {'spkThr', 'spkSnr', 'lamPr', 'spikeThreshold'}); % Not a line object
            
            % Overwrite is supposed to work for single and multiple rois
            if isequal(mode, 'overwrite')
                obj.uiaxes.signalplot.YLim = [0,1];
                obj.uiaxes.signalplot.YLim = [ min(0, obj.uiaxes.signalplot.YLim(1)), max(1, obj.uiaxes.signalplot.YLim(2)) ];
                for i = 1:numel(fields) % Reset data in line handle
                    if ~isempty(obj.hlineSignal.(fields{i}))
                        set(obj.hlineSignal.(fields{i})(:), 'YData', nan)
                    end
                end
            end
            
            %%% Why was this here?
%             pObj = findobj(obj.uiaxes.imagedisplay, 'Type', 'Patch');
%             delete(pObj)

            nRois = numel(roiInd);
            colorSelection = repmat({'Blues', 'Greens', 'Oranges', 'Reds', 'Purples'}, 1, ceil(nRois/5) );            
            colorSelection = colorSelection(randperm(numel(colorSelection), nRois));
            
            % Add different colors to a cell array
            plotColor = cellfun(@(cs) utilities.cbrewer('seq', cs, 15), colorSelection, 'uni', 0);
            plotColor = cellfun(@(pc) pc(5:end, :), plotColor, 'uni', 0);
            
            chNo = obj.activeChannel;
            
            % Color selected rois in different colors.  Choose 5th color (not too light)
            set(obj.RoiPlotHandles{chNo}(roiInd), {'Color'}, cellfun(@(pc) pc(5, :), plotColor, 'uni', 0)')
            set(obj.RoiPlotHandles{chNo}(roiInd), 'LineWidth', 1);
            
            for i = 1:numel(obj.signal2display)
                signalName = obj.signal2display{i};
                colorIdx = find(contains(fields, signalName)) + 2;
                colorCell = cellfun(@(pc) pc(colorIdx, :), plotColor, 'uni', 0)';
                
                % Get signaldata based on signal name to plot
                signalData = obj.signalArray(chNo).(signalName)(:, roiInd);
            
                % Check if any signals are missing and extract if needed
                isMissingSignal = any(isnan(signalData));
                if any(isMissingSignal)
                    roiIndTmp = roiInd(isMissingSignal);
                    obj.extractSignal(roiIndTmp, signalName);
                end
                signalData = obj.signalArray(chNo).(signalName)(:, roiInd);
                
                % All signals except spikes are plotted as lines.
                if ~isequal(signalName, 'spikes')
                    signalRange = range(signalData(:));
                    signalBounds = [min(signalData(:)), max(signalData(:))] + [-0.1*signalRange, 0.1*signalRange];
                    
                    % Change to left or right y axis depending on signal
                    switch signalName
                        case {'dff', 'denoised'}
                            yyaxis(obj.uiaxes.signalplot, 'right')
                        otherwise
                            yyaxis(obj.uiaxes.signalplot, 'left')
                    end
                    
                    % Update ylimits.
                    oldYlim = obj.uiaxes.signalplot.YLim;
                    newYlim = [0-0.05*signalRange, max([signalBounds(2), oldYlim(2)])];
                    obj.uiaxes.signalplot.YLim = newYlim;

                    
% %                     if isequal(signalName, 'deconvolved')
% %                     	signalData(signalData==0)=nan;
% %                     end
                    
                    % Plot or update plot data
                    if isempty(obj.hlineSignal.(signalName)) || isequal(mode, 'append')
%                         sgSmooth = sgolayfilt(signalData, 3, 7);
%                         signalData = cat(2, signalData, sgSmooth);
% %                         if isequal(signalName, 'deconvolved')
% %                             hTmp = stem(obj.uiaxes.signalplot, signalData);
% %                             set(hTmp, 'LineStyle', '-')
% %                             set(hTmp, 'Marker', 'o')
% %                         else
                        hTmp = plot(obj.uiaxes.signalplot, signalData);
                        set(hTmp, 'LineStyle', '-')
                        set(hTmp, 'Marker', 'None')
% %                         end

                        set(hTmp, 'LineWidth', 1)
                        set(hTmp, 'HitTest', 'off')
                        set(hTmp, {'Color'}, colorCell)
                        obj.hlineSignal.(signalName) = cat(1, obj.hlineSignal.(signalName), hTmp);
                        
                    elseif isequal(mode, 'overwrite')
                        % Reshape signaldata to cells of single roi signals and update ydata...
                        newYData = mat2cell(signalData, size(signalData,1), ones(size(signalData,2), 1));
                        set(obj.hlineSignal.(signalName)(:), {'YData'}, newYData', {'Color'}, colorCell)
                    else
                        error('Unknown error')
                    end
                    
                    if isequal(signalName, 'denoised') && nRois == 1
%                         spksnr = obj.signalExtractionSettings.caimanParameters.spkSnr;
                        
                        spksnr = str2double(obj.editSpikeSNR.String);
% %                         lam_pr = str2double(obj.editLambdaPr.String);
                        
%                         spkmin = signalExtraction.spikeEstimation.getSpikeCutoffThreshold(obj.signalArray(chNo).dff(:, roiInd));
                        spkmin = spksnr * GetSn(obj.signalArray(chNo).dff(:, roiInd));
%                             spkmin = spksnr * GetSn(signalData);
                        
                        hNoiseThresh = findobj(obj.uiaxes.signalplot, 'Tag', 'spkSnr');
                        if ~isempty(hNoiseThresh); delete(hNoiseThresh); end
                        hNoiseThresh = plot(obj.uiaxes.signalplot, obj.uiaxes.signalplot.XLim, [spkmin, spkmin], '--', 'Color', [0.4,0.4,0.4], 'Tag', 'spkSnr');
                        
% %                         fprintf('Area Denoised : %d\n', round(sum(signalData>spkmin)))
% %                     
% %                         decay_time=2;
% %                         fr = 31;
% %                         lam = choose_lambda(exp(-1/(fr*decay_time)), GetSn(obj.signalArray(chNo).dff(:, roiInd)), lam_pr);
% %                         
                    end
                    
            
                elseif isequal(signalName, 'spikes')
                    yyaxis(obj.uiaxes.signalplot, 'right')
                    
                    if obj.signalExtractionSettings.filterSpikesByNoiseLevel
                        dff = obj.signalArray(chNo).dff(:, roiInd);
                        den = obj.signalArray(chNo).denoised(:, roiInd);
                        samples2ignore = signalExtraction.spikeEstimation.getSpikeFilter(dff, den);
                        signalData(samples2ignore) = 0;
                    end
                    
%                     fprintf('Num Spikes : %d\n', round(sum(signalData)))
                    
                    % Plot spikes for each roi individually.
                    for rNo = 1:size(signalData, 2)
                    
                        [X, Y] = utilities.createscatterhistogram(signalData(:, rNo));
                        yLim = obj.uiaxes.signalplot.YLim;
                        rescaleSp = @(Y, b) ((Y-1) * range(yLim) * 0.01) + yLim(1) + (range(yLim) * b);
                        Y = rescaleSp(Y, 0.9);
                    
                        if isempty(obj.hlineSignal.(signalName))
                            obj.hlineSignal.(signalName) = plot(obj.uiaxes.signalplot, X, Y, '.', 'HitTest', 'off', 'Color', plotColor{rNo}(colorIdx, :));
                        else
                            switch mode
                                case 'append'
                                    obj.hlineSignal.(signalName)(end+1) = plot(obj.uiaxes.signalplot, X, Y, '.', 'HitTest', 'off', 'Color', plotColor{rNo}(colorIdx, :));
                                case 'overwrite'
                                    set(obj.hlineSignal.(signalName)(end), 'XData', X, 'YData', Y, 'Color', plotColor{rNo}(colorIdx, :))
                            end
                        end
                    end
                end
            end
            
            % Set yticks and height of framemarker
            obj.uiaxes.signalplot.YTick = [0, floor(obj.uiaxes.signalplot.YLim(2))];
            yyaxis(obj.uiaxes.signalplot, 'right')
            obj.updateFrameMarker('update_y')
            updateSelectedFramePatch(obj, 'update_y')
            
        end
        

        function resetSignalPlot(obj)
            
            signalNames = {'roiMeanF', 'npilMediF', 'demixedMeanF', 'dff', ...
                            'deconvolved', 'denoised', 'spikes'};
            
            lines = findobj(obj.uiaxes.signalplot, 'Type', 'Line');
            if ~isempty(lines) && ~isa(lines, 'matlab.graphics.GraphicsPlaceholder')
                isFrameMarker = contains({lines.Tag}, 'FrameMarker');            
                delete(lines(~isFrameMarker))
            end
            
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
            
            % Reset Y limits
            yyaxis(obj.uiaxes.signalplot, 'left')
            obj.uiaxes.signalplot.YLim = [0,256];
            yyaxis(obj.uiaxes.signalplot, 'right')
            obj.uiaxes.signalplot.YLim = [0,1];
            
        end
        
        
        function resetRoi(obj, ~, ~)
            nChannels = obj.nLoadedChannels;
            % Set roiArray to cell array of roi arrays (one per channel)
            obj.roiArray = arrayfun(@(i) RoI.empty, 1:nChannels, 'uni', 0);
            obj.roiCount = arrayfun(@(i) 0, 1:nChannels, 'uni', 0);
            cellfun(@(h) delete(h), obj.RoiPlotHandles, 'uni', 0)
            cellfun(@(h) delete(h), obj.RoiTextHandles, 'uni', 0)
            obj.RoiPlotHandles = cell(nChannels, 1);
            obj.RoiTextHandles = cell(nChannels, 1);
            obj.RoiLinePos = arrayfun(@(i) cell(0, 2), 1:nChannels, 'uni', 0);
            obj.RoiTextPos = arrayfun(@(i) cell(0, 1), 1:nChannels, 'uni', 0);
            resetListbox(obj);
            initializeActionLog(obj)
            obj.logPosition = 0;
            obj.lastLogPosition = 0;
            
            obj.signalArray = struct;
            
            % Find roi plot handles: 
            roilines = findobj(obj.uiaxes.imagedisplay, 'Tag', 'RoI');
            delete(roilines)
            roiLabels = findobj(obj.uiaxes.imagedisplay, 'Tag', 'RoIlabel');
            delete(roiLabels)
            
            obj.selectedRois = [];
            obj.unselectedRois = [];
        end
        
        
        function roiCorrIm = showRoiCorrelationImage(obj, ~, ~)
            
            if isempty(obj.selectedRois); return; end
                    
            ch = obj.activeChannel;
            roiIdx = obj.selectedRois(end); % Dont want to do this for many rois.

            if isempty(obj.selectedFrames) || sum(obj.selectedFrames) == 0
                frames = 1:obj.nFrames(ch);
            else
                frames = find(obj.selectedFrames);
            end

            [y, x] = find(obj.roiArray{ch}(roiIdx).mask);
            minX = min(x); maxX = max(x);
            minY = min(y); maxY = max(y);
            minX = minX-5; minY=minY-5;maxX=maxX+5;maxY=maxY+5;

%             croppedMask = obj.roiArray{ch}(roiIdx).mask(minY:maxY, minX:maxX);
            pixelChunk = single(obj.imgTseries{ch}(minY:maxY, minX:maxX, :));

%             f0 = prctile(pixelChunk, 20, 3);
%             dff = (pixelChunk - f0) ./ f0;

            nFrames = numel(frames);
            
            pixelChunk = pixelChunk(:, :, frames);
            pixelChunk = filterImArray(pixelChunk, [], 'gauss');
            
            if ~nargout; makeFigure = true; else; makeFigure = false; end
%             makeFigure = false;
            if makeFigure 
                figPos = [ 400, 200, round([range(x)*10, range(y)*10]) ];
                tmpfig = figure('Position', figPos);
                tmpfig.MenuBar = 'none';
                s1 = axes('Position', [0.1,0.1,0.8,0.8], 'Parent', tmpfig);
                colormap(s1, 'parula');
            end
            
            % make a correlation image
            roiCn = correlation_image(pixelChunk);
            roiCn = uint8(roiCn*255);

            if makeFigure
                imagesc(s1, roiCn);
                s1.XAxis.Visible = 'off';
                s1.YAxis.Visible = 'off';
            end
            
            [sourceMask, sourceSignal] = signalExtraction.desourcery(obj);
            
            if makeFigure
            [imH, imW, nSources] = size(sourceMask);
            sourceMask = reshape(sourceMask, [], nSources);
            sourceMask = sourceMask .* (1:nSources);
            sourceMask = reshape(sourceMask, imH, imW, nSources);
            sourceMask = sum(sourceMask, 3);
            fig = figure();
            drawnow
            fig.Position = [-500,1500,500,140]; 
            ax1 = axes('Units', 'pixel', 'Position', [10,20,80,80]);
            ax2 = axes('Units', 'pixel', 'Position', [110,20,80,80]);
            ax3 = axes('Units', 'pixel', 'Position', [220,20,270,120]);
            imagesc(ax1, roiCn);
            ax1.XAxis.Visible = 'off'; ax1.YAxis.Visible = 'off';
            imagesc(ax2, sourceMask)
            ax2.XAxis.Visible = 'off'; ax2.YAxis.Visible = 'off';
            l = plot(ax3, sourceSignal);
            if ~nSources == 0
                ax3.YLim = [min(sourceSignal(:)), max(sourceSignal(:))];
            end
            colors = get(l, 'Color');
            if isa(colors, 'cell'); colors = cell2mat(colors); end
            colors = vertcat([1, 1, 1], colors);
            colormap(ax2, colors)
            legend(l, arrayfun(@(o) num2str(o), 1:nSources, 'uni', 0), 'Orientation', 'horizontal', 'location', 'northoutside')
            if nargout
                roiCorrIm = roiCn;
            end
            end
         

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

        
% % % % Methods for playing images as video
        
        function playVideo(obj, ~, ~)
            % Callback for play button. Plays calcium images as video
            
            if obj.uiButtons.PlayVideo.Value
                
                % AREE : loop when asked for play
                if obj.currentFrameNo >= obj.nFrames(obj.activeChannel) - (obj.playbackspeed+1)
                    src.Value = round(1-obj.currentFrameNo);
                    obj.changeFrame(src, [], 'playvideo');
                end
                
                while obj.currentFrameNo < obj.nFrames(obj.activeChannel) - (obj.playbackspeed+1)
                    t1 = tic;
                    
                    if obj.playbackspeed >= 1
                        src.Value = obj.playbackspeed;
                    else
                        src.Value = 1;
                    end
                    
                    obj.changeFrame(src, [], 'playvideo');
                    
                    if ~obj.uiButtons.PlayVideo.Value
                        break
                    end
                    
                    t2 = toc(t1);
                    
                    if obj.playbackspeed < 1
                        pause(0.033/obj.playbackspeed - t2)
                    else
                        pause(0.033 - t2)
                    end
                    
                    if obj.currentFrameNo >= obj.nFrames - (obj.playbackspeed+1)
                        obj.currentFrameNo = 0;
                    end
                    
                end
                
                obj.uiButtons.PlayVideo.Value = 0;
                
            end

        end
        
        
        function buttonCallback_SetPlaybackSpeed(obj, source, ~)

            switch source.String
                case '2x'
                    if source.Value
                        obj.playbackspeed = 2;
                    end
                case '4x'
                    if source.Value
                        obj.playbackspeed = 4;
                    end
                case '8x'
                    if source.Value
                        obj.playbackspeed = 8;
                    end
            end
            
            obj.switchToggleButton(source)
                        
            if ~obj.uiButtons.play2x.Value && ~obj.uiButtons.play4x.Value && ~obj.uiButtons.play8x.Value
                obj.playbackspeed = 1;
            end
            
            
        end
        
        
% % % % Color settings
        
        function color = getRoiColor(obj, roi)
        % Return a color for the roi based on which group it belongs to.

            groupmatch = cellfun(@(x) strcmp(x, roi.group), obj.roiClasses, 'uni', 0);
            if any(cell2mat(groupmatch))
                color = obj.roiColors{cell2mat(groupmatch)};
            else
                color = 'red';
            end
            
            
            % Check if roi was newly imported and still unresolved...
            if contains('imported', roi.tags)
                color = 'green';
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
                        newFrame(:,:,1) = newFrame(:,:,1) + caframe(:,:,i);
                    case 'green'
                        newFrame(:,:,2) = newFrame(:,:,2) + caframe(:,:,i);
                    case 'blue'
                        newFrame(:,:,3) = newFrame(:,:,3) + caframe(:,:,i);
                    case 'yellow'
                        newFrame(:,:,[1, 2]) = newFrame(:,:,[1, 2]) + repmat(caframe(:,:,i), 1,1,2).*0.5;
                end
                
            end
            
            % Quick way to scale image if colors are overlapped.
            maxVal = max(newFrame(:));
            if maxVal > 255; newFrame = newFrame / maxVal; end
        end
        
        
        function menuCallback_ChangeColormap(obj, src, ~)
            
            switch src.Label
                case 'Viridis'
                    cmap = colormaps.viridis;
                case 'Inferno'
                    cmap = colormaps.inferno;
                case 'Magma'
                    cmap = colormaps.magma;
                case 'Plasma'
                    cmap = colormaps.plasma;
                case 'Nissl'
                    cmap = fliplr(utilities.cbrewer('seq', 'BuPu', 256));
                case 'BuPu'
                    cmap = utilities.cbrewer('seq', 'BuPu', 256);
                case 'PuBuGn'
                    cmap = flipud(utilities.cbrewer('seq', src.Label, 256));
                case {'GnBu', 'Greens', 'YlOrRd'}
                    cmap = utilities.cbrewer('seq', src.Label, 256);
                case 'PuOr' 
                    cmap = flipud(utilities.cbrewer('div', src.Label, 256));
                case 'Gray'
                    cmap = gray(256);
                case {'thermal', 'haline', 'solar', 'ice', 'gray', 'oxy', 'deep', 'dense', ...
                'algae','matter','turbid','speed', 'amp','tempo'}
                    cmap = colormaps.cmocean(src.Label);
            end
            
%             cmap(1, :) = [0.7,0.7,0.7];%obj.fig.Color;
            colormap(obj.uiaxes.imagedisplay, cmap)

        end
            
     
% % % % Quit callback
        
        function quitRoimanager(obj, ~, ~)
        % Close figure callback. delete obj and close figure
        
            saveSettings(obj)
        
            % Close figure
            closereq
            
            % Delete obj
            delete(obj)
            
            warning('on', 'MATLAB:dispatcher:nameConflict')
        
        end
        
    
    end
   
    
    
    methods (Static)
                
        
        function tf = isOpen()
            openFigures = findall(0, 'Type', 'Figure');
            if isempty(openFigures)
                tf = false;
            else
                figMatch = contains({openFigures.Name}, 'Roimanager');
                if any(figMatch)
                    figure(openFigures(figMatch))
                    tf = true;
                else
                    tf = false;
                end
            end
        end
        
        
        function signalSettings = loadSignalSettings()
            path = mfilename('fullpath');
            settingsPath = strcat(path, '_settings.mat');

            if exist(settingsPath, 'file') % Load settings from file
                S = load(settingsPath, 'signalExtractionSettings');
                signalSettings = S.signalExtractionSettings;
            end
            
        end
        
        
        function unFocusButton(btnHandle)
%         	set(btnHandle, 'Enable', 'off');
            drawnow;
%             set(btnHandle, 'Enable', 'on');
        end
       
        
        function centerAlignHandle(handle, centerPos)
            
           currentPos = handle.Position(2);
           currentH = handle.Position(4);
           
           currentCenter = currentPos + currentH/2;
           handle.Position(2) = handle.Position(2) + (centerPos-currentCenter);            
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
        
        
        function showHelp()
            % Create a figure for showing help text
            helpfig = figure('Position', [100,200,500,500]);
            helpfig.Resize = 'off';
            helpfig.Color = [0.2,0.2,0.2];
            helpfig.MenuBar = 'none';
            helpfig.NumberTitle = 'off';
            helpfig.Name = 'Help for roimanager';

            % Close help window if it loses focus
            jframe = fmutilities.getjframe(helpfig);
            set(jframe, 'WindowDeactivatedCallback', @(s, e) delete(helpfig))

            % Create an axes to plot text in
            ax = axes('Parent', helpfig, 'Position', [0,0,1,1]);
            ax.Visible = 'off';
            hold on

            % Specify messages. \b is custom formatting for bold text
            messages = {...
                '\bGet Started', ...
                [char(1161), '   Load images'], ...
                [char(1161), '   Mark roi positions'], ...
                [char(1161), '   Save Rois'], ...
                [char(1161), '   Extract Signals'], ...
                ...
                '\n\bKey Shortcuts', ...
                'q : Toggle zoom in tool', ...
                'w : Toggle zoom out tool', ...
                'shift + 1/2/3/4 : Zoom in to 1 of the 4 quadrants of the image', ...
                'cmd/ctrl + z : Undo action. Works for actions on rois', ...
                'cmd/ctrl + shift + z : Redo undone action. Works for actions on rois', ...
                'm : toggle mouse tool for multiselection of rois', ...
                'arrowkeys : work in progress', ...
                ...
                ['\nThere are many more shortcuts, some buttons and menu items are labeled\n', ...
                'and others are only found if you explore the roimanager/keyPress method.'], ...
                ...
                };


            % Plot messages from bottom top. split messages by colon and
            % put in different xpositions.
            hTxt = gobjects(0, 1);
            y = 0.1;
            x1 = 0.05;
            x2 = 0.3;

            for i = numel(messages):-1:1
                nLines = numel(strfind(messages{i}, '\n'));
                y = y + nLines*0.03;

                makeBold = contains(messages{i}, '\b');
                messages{i} = strrep(messages{i}, '\b', ''); 

                if contains(messages{i}, ':')
                    msgSplit = strsplit(messages{i}, ':');
                    hTxt(end+1) = text(x1, y, sprintf(msgSplit{1}));
                    hTxt(end+1) = text(x2, y, sprintf([': ', msgSplit{2}]));
                else
                    hTxt(end+1) = text(0.05, y, sprintf(messages{i}));
                end

                if makeBold; hTxt(end).FontWeight = 'bold'; end

                y = y + 0.05;
            end

            set(hTxt, 'FontSize', 14, 'Color', [0.8,0.8,0.8], 'VerticalAlignment', 'top')


            hTxt(end).ButtonDownFcn = @(s,e) fovmanager.openWiki;

            % Adjust size of figure to wrap around text.
            % txtUnits = get(hTxt(1), 'Units');
            set(hTxt, 'Units', 'pixel')
            extent = cell2mat(get(hTxt, 'Extent'));
            % set(hTxt, 'Units', txtUnits)

            maxWidth = max(sum(extent(:, [1,3]),2));
            helpfig.Position(3) = maxWidth./0.9; %helpfig.Position(3)*0.1 + maxWidth;
            helpfig.Position(4) = helpfig.Position(4) - (1-y)*helpfig.Position(4);
        end

        
    end

    
 end
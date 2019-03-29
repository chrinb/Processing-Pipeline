classdef sessionBrowser < handle
%sessionBrowser A GUI for browsing through sessionData.


% Todo

% Show block average?

% Update ylim of framemarkers if ylimits of axes change

% Write better documentation and comments.
% Panel independent margins.

properties
    
    % Figure and figure settings

    guiFigure               % GUI Figure Window
    caFigure            
    margins                 % Side margins within the GUI window
    padding                 % Padding between objects in the GUI window
    zoomFactor = 0.9        % Zoom factor for zooming the x-axis in plots.

    % Panels
    
    topPanel                % UI Panel for loading sessions and showing key information
    imagePanel              % UI Panel for showing calcium images
    pupilPanel              % UI Panel for showing pupil video
    bodyPanel               % UI Panel for showing body movement or video
    animationPanel          % UI Panel for showing arena animation
    signalPanel             % UI Panel for showing population and single roi signals
    
    % Video Axes
    
    axCalciumVideo          % Axes for showing calcium images
    axPupilVideo            % Axes for showing pupil video
    axOverviewVideo         % Axes for showing body movement video
    axArenaAnimation        % Axes for showing arena animation
    
    % Plot axes
    
    axPopulationResponse    % Axes for plotting
    axCellResponse          % Axes for showing roi signals
    axBodyMovementPlot      % Axes for showing body movement plot
    axPupilActivityPlot     % Axes for showing pupil plot
    axFrameMovementPlot     % Axes for showing frame movements/motion correction
    axLickResponses         % Axes for showing frame movements/motion correction
    
    % Images
    
    caImageObj              % Image object for current calcium image
    pupilImageObj           % Image object for current pupil image
    bodyImageObj            % Image object for current security camera image
    populationActivity      % Image object for current population activity image
    animationImObj          % Image object for current animation image
    
    % Lines
    
    roiPlotHandle           % Plot handle for the current ROI boundary
    pupilDiamLine           % Plot handle for pupil diameter
    pupilMovmLine           % Plot handle for pupil movement
    bodyMovmLine            % Plot handle for body movement
    frameMovmLine           % Plot handle for frame movement
    lickLine                % Line handle for licking
    waterLine               % Line handle for water
    roiGreenSignalLine      % Plot handle for green ROI signal
    roiRedSignalLine        % Plot handle for red ROI signal
    
    % Frame Markers
    
    pupilFrameMarker        % Plot handle for line indicator of current frame in pupil plot
    bodyFrameMarker         % Plot handle for line indicator of current frame in body movement plot
    popAframeMarker         % Plot handle for line indicator of current frame in population plot
    roiFrameMarker          % Plot handle for line indicator of current frame in roi signal plot
    fmFrameMarker           %
    lickresponseFrameMarker
    
    
    % Buttons/booleans
    
    roiGreenChVisibility    % Cell array of 'on'/'off' per block. Used to set visibility of lines
    roiRedChVisibility      % Cell array of 'on'/'off' per block. Used to set visibility of lines
    btnShowGreen            % Button to show/hide the green signal from the roi plot
    btnShowRed              % Button to show/hide the red signal from the roi plot
    btnShowRawSignal        % Button to toggle between raw signal and delta F over F
    btnShowAllBlocks        % Button to toggle between showing current block or all blocks
    calciumVideoIsLoaded    % True/false to indicate if calcium video is loaded into gui
    pupilVideoIsLoaded      % True/false to indicate if pupil video is loaded into gui
    bodyVideoIsLoaded       % True/false to indicate if body video is loaded into gui
    btnLoadCalciumVideo     % Button to load calcium video
    btnLoadPupilVideo       % Button to load puil video
    btnLoadBodyVideo        % Button to load security video
    btnExportVideo          % Button to export video of session (not active)
    btnChangeGuiMode        % Button to transform GUI to "Plots only" or "Plots + videos" 
    btnShowVideo
    
    % Inventories
    mouseInv                % Mouse database
    expInv                  % Experiment database
    tiffStacks
    
    % States
    currentBlock
    currentRoi
    currentFrame
    currentBlockIndicator
    currentFrameIndicator
    currentRoiIndicator
    channels
    objectPositions = containers.Map
    plotMode = false
    
    % Data
    sessionData
    calciumImages
    pupilVideo
    pupilFrameTimes
    surveillanceVideo
    sessionID
    
    % UI controls
    frameslider
    blockslider
    blocksliderContainer
    lightIndicator
    mousepopup
    sessionpopup
    dcm_obj
    hoverCellText
    RoiMarker

    
end



methods (Access = 'private', Hidden = true)
    
    
    function browser = createTopPanel(browser, pos)
        % Create left side UI panel for image controls
        browser.topPanel = uipanel('Title','Session Controls', 'Parent', browser.guiFigure, ...
                          'FontSize', 11,... % 'FontUnits', 'normalized', ...
                          'units', 'normalized', 'Position', pos);
        browser.objectPositions('topPanel') = get(browser.topPanel, 'Position');

        % Create ui controls
        popupPos = [0.04, 0.75, 0.35, 0.15];
        browser.mousepopup = uicontrol('Parent', browser.topPanel, 'Style', 'popup', ...
                                  'String', vertcat({'Select mouse'}, browser.mouseInv(2:end, 1)), ...
                                  'Value', 1, ...
                                  'units', 'normalized', 'Position', popupPos, ...
                                  'Callback', @browser.changeMouse);
        browser.objectPositions('mousepopup') = get(browser.mousepopup, 'Position');

        popupPos(1) = popupPos(1) + popupPos(3) + 0.05; 
        popupPos(3) = 0.5;
        browser.sessionpopup = uicontrol('Parent', browser.topPanel, 'Style', 'popupmenu', ...
                                         'String', 'Select a mouse...', ...
                                         'units', 'normalized', 'Position', popupPos, ...
                                         'Callback', @browser.changeSession);
        browser.objectPositions('sessionpopup') = get(browser.sessionpopup, 'Position');

                                                               
        browser.currentBlockIndicator = uicontrol('Parent', browser.topPanel, 'Style', 'text', ...
                                                  'String', 'Current Block: N/A', ...
                                                  'HorizontalAlignment', 'left', ...
                                                  'units', 'normalized', 'Position', [0.05 0.45 0.5 0.1], ...
                                                  'FontSize', 12); 
        browser.objectPositions('currentBlockIndicator') = get(browser.currentBlockIndicator, 'Position');

                                     
%         browser.blockslider = uicontrol('Parent', browser.topPanel, 'Style', 'slider',...
%                               'Min', 1, 'Max', 1, 'Value', 1,...
%                               'units', 'normalized', 'Position',[0.4 0.45 0.05 0.2] ,...
%                               'Callback',  {@browser.changeBlock, 'slider'});
                          
        browser.currentFrameIndicator = uicontrol('Parent', browser.topPanel, 'Style', 'text', ...
                                                  'String', 'Current frame: N/A', ...
                                                  'HorizontalAlignment', 'left', ...
                                                  'FontSize', 12, ...
                                                  'units', 'normalized', 'Position', [0.05 0.03 0.5 0.2]);
        browser.objectPositions('currentFrameIndicator') = get(browser.currentFrameIndicator, 'Position');

        
        browser.btnChangeGuiMode = uicontrol('Parent', browser.topPanel, ...
            'Style', 'pushbutton', 'String', 'Show Plots Only', ...
            'units', 'normalized', 'Position', [0.64, 0.08, 0.3, 0.2], ...
            'Callback', @browser.changeGuiMode);
        browser.objectPositions('btnChangeGuiMode') = get(browser.btnChangeGuiMode, 'Position');
                              
        browser.btnShowVideo = uicontrol('Parent', browser.topPanel, ...
            'Style', 'togglebutton', 'String', 'Show Calcium Video', ...
            'units', 'normalized', 'Position', [0.64, 0.08, 0.3, 0.2], ...
            'Visible', 'off', 'Value', 1);
        
        
        
        jSlider = javax.swing.JSlider;
        
        [browser.blockslider, browser.blocksliderContainer] = javacomponent(jSlider);
        browser.blockslider = handle(browser.blockslider, 'CallbackProperties');
        set(browser.blockslider, 'StateChangedCallback', {@browser.changeBlock, 'slider'});
        set(browser.blocksliderContainer, 'Parent', browser.topPanel, 'units', 'normalized', 'Position', [0.46 0.4 0.48 0.2])
        set(browser.blocksliderContainer, 'Visible', 'off')
                                                 
    end
    
    
    function browser = createImagePanel(browser, pos)
    	browser.imagePanel = uipanel('Title', 'Calcium Images', 'Parent', browser.guiFigure, ...
                          'FontSize', 11, 'FontUnits', 'normalized', ...
                          'units', 'normalized', 'Position', pos);
                      
        %axSize = 360/figsize(3) * [1, aspectRatio]; % Calcium image = 512 * 0.7 = 360px
        browser.axCalciumVideo = axes('Parent', browser.imagePanel, ...
            'units', 'normalized', 'Position', [0.03, 0.03, 0.94, 0.94], ...
            'xtick', [], 'ytick', []);
        box( browser.axCalciumVideo, 'on')              
                      
        browser.btnLoadCalciumVideo = uicontrol('Parent', browser.imagePanel, 'Style', 'pushbutton', ...
                                         'String', 'Load Calcium Video', ...
                                         'units', 'normalized', 'Position', [0.70, 0.90, 0.25, 0.05], ...
                                         'Callback', @browser.loadCalciumVideo);
    end
    
    
    function browser = createPupilPanel(browser, pos)
        
        browser.pupilPanel = uipanel('Title', 'Pupil Data', 'Parent', browser.guiFigure, ...
                          'FontSize', 11, 'FontUnits', 'normalized', ...
                          'units', 'normalized', 'Position', pos);
        
        browser.axPupilVideo = axes('Parent', browser.pupilPanel, 'Position', [0.03, 0.28, 0.94, 0.69], 'xtick',[], 'ytick',[]);
        browser.axPupilActivityPlot = axes('Parent', browser.pupilPanel, 'Position', [0.03, 0.04, 0.94, 0.2], 'xtick',[], 'ytick',[]);
        browser.objectPositions('axPupilActivityPlot') = get(browser.axPupilActivityPlot, 'Position');

        box( browser.axPupilVideo, 'on')  
        
        browser.btnLoadPupilVideo = uicontrol('Parent', browser.pupilPanel, 'Style', 'pushbutton', ...
                                              'String', 'Load Pupil Video', ...
                                              'units', 'normalized', 'Position', [0.70, 0.88, 0.25, 0.06], ...
                                              'Callback', {@browser.loadLabviewVideo, 'pupil'});  
        
    end
    
    
    function browser = createBodyPanel(browser, pos)
        
        browser.bodyPanel = uipanel('Title', 'Body Data', 'Parent', browser.guiFigure, ...
                          'FontSize', 11, 'FontUnits', 'normalized', ...
                          'units', 'normalized', 'Position', pos);
        browser.axOverviewVideo = axes('Parent', browser.bodyPanel, 'Position', [0.03, 0.28, 0.94, 0.69], 'xtick',[], 'ytick',[]);
        browser.axBodyMovementPlot = axes('Parent', browser.bodyPanel, 'Position', [0.03, 0.04, 0.94, 0.2], 'xtick',[], 'ytick',[]);
        box( browser.axOverviewVideo, 'on')  
        browser.objectPositions('axBodyMovementPlot') = get(browser.axBodyMovementPlot, 'Position');

        
        browser.btnLoadBodyVideo = uicontrol('Parent', browser.bodyPanel, 'Style', 'pushbutton', ...
                                         'String', 'Load Body Video', ...
                                         'units', 'normalized', 'Position', [0.70, 0.88, 0.25, 0.06], ...
                                         'Callback', {@browser.loadLabviewVideo, 'body'});
        
    end
    
    
    function browser = createSignalPanel(browser, pos)
        browser.signalPanel = uipanel('Title', 'Signal Data', 'Parent', browser.guiFigure, ...
                          'FontSize', 11, 'FontUnits', 'normalized', ...
                          'units', 'normalized', 'Position', pos);
        
        axPopSize = [0.03, 1-0.03-0.6,  0.94, 0.6 ];
        browser.axPopulationResponse = axes('Parent', browser.signalPanel, 'Position', ...
                     axPopSize, 'xtick',[], 'ytick',[]);
        browser.objectPositions('axPopulationResponse') = get(browser.axPopulationResponse, 'Position');

        
        browser.RoiMarker = uicontrol('Parent', browser.signalPanel, 'style', 'text', ...
                                      'String', '<', ...
                                      'Units', 'Normalized', ...
                                      'HorizontalAlignment', 'left', ...
                                      'Position', [axPopSize(1)+axPopSize(3) + 0.004, axPopSize(2)+axPopSize(4)-0.02, 0.015, 0.04]);
        browser.objectPositions('RoiMarker') = get(browser.RoiMarker, 'Position');

                                  
        browser.axCellResponse = axes('Parent', browser.signalPanel, 'Position', ...
                     [0.03, 0.05,  0.94, 0.27 ]); 
        browser.objectPositions('axCellResponse') = get(browser.axCellResponse, 'Position');

                 
        browser.hoverCellText = text('Color', 'red', 'String', '', 'VerticalAlign', 'Bottom', ...
                'BackgroundColor', 'white', 'Parent', browser.axPopulationResponse );
                 
                 
    end

    
    function browser = createAnimationAx(browser, pos)
        
        aspectRatio = pos(3)/pos(4);
        axSize = pos(4) ./ [aspectRatio, 1];
        axPos = [(pos(3)-axSize(1))/2 + pos(1), pos(2), axSize];

        browser.axArenaAnimation = axes('units', 'normalized', 'Position', axPos, 'xtick',[], 'ytick',[]);
        
        % Make and show graphics for mouse and arena
        frame = browser.makeAnimationFrame();
        frame = cat(3, frame, frame, frame);

        browser.animationImObj = imshow(frame, 'Parent', browser.axArenaAnimation, 'InitialMagnification', 'fit');
        sessionBrowser.maskArenaAnimation(browser.axArenaAnimation)
        sessionBrowser.anglePatchLegend(browser.axArenaAnimation)
                
        
    end
         
    
    function browser = reorderGuiPlotsOnly(browser)
        browser.plotMode = true;
        sideMargin = 0.05;
        plotSize = [0.9, 0.1];
        bottomMargin = 0.05;
        
        % Ax 0 :  Show plot with frame to frame movement
        if isempty(browser.axFrameMovementPlot)
            browser.axFrameMovementPlot = axes('Position', ...
                [sideMargin, bottomMargin + (plotSize(2) + 0.03)*4 + 0.23, plotSize(1), 0.05 ], 'xtick',[], 'ytick',[]);
        else
            set(browser.axFrameMovementPlot, 'Visible', 'on')
            set(browser.axFrameMovementPlot.Children, 'Visible', 'on')
        end
        
        
        % Ax 1 : Show image of responses for all cells
        set(browser.axPopulationResponse, 'Parent', browser.guiFigure, ...
            'Position', [sideMargin, bottomMargin + (plotSize(2) + 0.03)*4, plotSize(1), 0.2 ] );
        
        % Ax 2 : Show plot of responses for selected roi
        set(browser.axCellResponse, 'Parent', browser.guiFigure, ...
            'Position', [sideMargin, bottomMargin + (plotSize(2) + 0.03)*3, plotSize]);
        
        % Ax 3 :  Show plot with licking data
        if isempty(browser.axLickResponses)
            browser.axLickResponses = axes('Position', ...
                [sideMargin, bottomMargin + (plotSize(2) + 0.03)*2, plotSize ], 'xtick',[], 'ytick',[]);
        else
            set(browser.axLickResponses, 'Visible', 'on')
            set(browser.axLickResponses.Children, 'Visible', 'on')
        end
                 
        % Ax 4 : Show plot of body movement         
        set(browser.axBodyMovementPlot, 'Parent', browser.guiFigure, ...
            'Position', [sideMargin, bottomMargin + (plotSize(2) + 0.03)*1, plotSize ] );
                 
        % Ax 5 : Show plot of pupil activity
        set(browser.axPupilActivityPlot, 'Parent', browser.guiFigure, ...
            'Position', [sideMargin, bottomMargin, plotSize ] );
        
        % Make extra figure for calcium images.
        browser.caFigure = figure('Position', [0,0,800,800]);
        set(browser.axCalciumVideo, 'Parent', browser.caFigure);
        
        % Make panels invisible
        set(browser.topPanel, 'Position', [sideMargin, 0.88, 0.9, 0.08]);
        set(browser.imagePanel, 'Visible', 'off')
        set(browser.pupilPanel, 'Visible', 'off')
        set(browser.bodyPanel, 'Visible', 'off')
        set(browser.animationPanel, 'Visible', 'off')
        set(browser.signalPanel, 'Visible', 'off')

        set(browser.guiFigure, 'SizeChangedFcn', '' );

        if ~isempty(browser.sessionID)
            % Remove ticks from plots
            set(browser.axBodyMovementPlot, 'XTick', [])
            set(browser.axFrameMovementPlot, 'XTick', [])
            set(browser.axCellResponse, 'XTick', [])
            set(browser.axLickResponses, 'XTick', [])
            browser.axPupilActivityPlot.XLabel.String = 'Time (s)';
        end
        
        % Relocate ui controls
        set(browser.mousepopup, 'Position', [0.01, 0.65, 0.09, 0.05] );
                              
        set(browser.sessionpopup, 'Position', [0.11, 0.65, 0.12, 0.05] );
                                  
        set(browser.currentBlockIndicator, 'Position', [0.25, 0.20, 0.12, 0.5] ); 
                                              
        set(browser.currentRoiIndicator, 'Position', [0.38, 0.20, 0.1, 0.5], ...
            'Parent', browser.topPanel, ...
            'FontSize', 12);%, ...
            %'BackgroundColor', 'white');
        
        set(browser.currentFrameIndicator, 'Position', [0.5, 0.20, 0.12, 0.5] );
      
        figsize = get(browser.guiFigure, 'Position');
        btnSize = [100, 20];
        nBtnSize = btnSize ./ figsize(3:4);                              
          
        set(browser.btnChangeGuiMode, 'Position', [0.65, 0.6, 0.10, 0.3])
        set(browser.btnShowVideo, 'Position', [0.65, 0.2, 0.10, 0.3], ...
            'Visible', 'on');
        
        set(browser.btnShowAllBlocks, 'Position', [0.8, 0.2, 0.08, 0.3], 'Parent', browser.topPanel );                             
        set(browser.btnShowGreen, 'Position', [0.9, 0.2, 0.08, 0.3], 'Parent', browser.topPanel ); 
        set(browser.btnShowRed, 'Position', [0.9, 0.6, 0.08, 0.3], 'Parent', browser.topPanel );  
        set(browser.btnShowRawSignal, 'Position', [0.8, 0.6, 0.08, 0.3], 'Parent', browser.topPanel ); 
                                         

        axPopSize = get(browser.axPopulationResponse, 'Position');
        
        set(browser.RoiMarker, 'Parent', browser.guiFigure, ...
            'Position', [axPopSize(1)+axPopSize(3) + 2/figsize(3), axPopSize(2)+axPopSize(4)-0.0075, 0.012, 0.015]);
        browser.updateRoiMarker();

        
        set(browser.axArenaAnimation, 'Visible', 'off')
        set(browser.animationImObj, 'Visible', 'off')
        
        % Remove Patches in animation plot
        patches = findobj(browser.axArenaAnimation, 'Type', 'patch');
        lines = findobj(browser.axArenaAnimation, 'Type', 'Line');
        delete(patches)
        delete(lines)
        clear patches lines
        
        set(browser.blocksliderContainer, 'Visible', 'off')
        
    end
    
    
    function browser = reorderGUI(browser)
        browser.plotMode = false;

        % Ax 0 : Show plot with frame to frame movement
        set(browser.axFrameMovementPlot, 'Visible', 'off')
        set(browser.axFrameMovementPlot.Children, 'Visible', 'off')

        
        % Ax 1 : Show image of responses for all cells
        set(browser.axPopulationResponse, 'Parent', browser.signalPanel, ...
            'Position', browser.objectPositions('axPopulationResponse') );
        
        % Ax 2 : Show plot of responses for selected roi
        set(browser.axCellResponse, 'Parent', browser.signalPanel, ...
            'Position', browser.objectPositions('axCellResponse') );
        
        % Ax 3 :  Show plot with licking data
        set(browser.axLickResponses, 'Visible', 'off');
        set(browser.axLickResponses.Children, 'Visible', 'off')
                 
        % Ax 4 : Show plot of body movement         
        set(browser.axBodyMovementPlot, 'Parent', browser.bodyPanel, ...
            'Position', browser.objectPositions('axBodyMovementPlot') );
                 
        % Ax 5 : Show plot of pupil activity
        set(browser.axPupilActivityPlot, 'Parent', browser.pupilPanel, ...
            'Position',  browser.objectPositions('axPupilActivityPlot') );
        
        set(browser.axBodyMovementPlot, 'XTick', 0:20:browser.sessionData.timePoints(end))
        set(browser.axFrameMovementPlot, 'XTick', 0:20:browser.sessionData.timePoints(end))
        set(browser.axCellResponse, 'XTick', 0:20:browser.sessionData.timePoints(end))
        browser.axPupilActivityPlot.XLabel.String = '';
        
        % Make extra figure for calcium images.
        set(browser.axCalciumVideo, 'Parent', browser.imagePanel);
        close(browser.caFigure)
        
        set(browser.topPanel, 'Position', browser.objectPositions('topPanel'));
        set(browser.imagePanel, 'Visible', 'on')
        set(browser.pupilPanel, 'Visible', 'on')
        set(browser.bodyPanel, 'Visible', 'on')
        set(browser.animationPanel, 'Visible', 'on')
        set(browser.signalPanel, 'Visible', 'on')

        set(browser.guiFigure, 'SizeChangedFcn', @browser.figsizeChanged );

        set(browser.btnShowVideo, 'Visible', 'off');
        
        % Create ui controls
        set(browser.mousepopup, 'Position', browser.objectPositions('mousepopup'))              
        set(browser.sessionpopup, 'Position', browser.objectPositions('sessionpopup') );
                                  
        set(browser.currentBlockIndicator, 'Position', browser.objectPositions('currentBlockIndicator')); 
                                              
        set(browser.currentRoiIndicator, 'Position', browser.objectPositions('currentRoiIndicator'), ...            'Parent', browser.guiFigure, ...
            'Parent', browser.guiFigure, ...
            'FontSize', 14);%, ...
            %'BackgroundColor', 'white');
        
        set(browser.currentFrameIndicator, 'Position', browser.objectPositions('currentFrameIndicator') );
          
        set(browser.btnChangeGuiMode, 'Position', browser.objectPositions('btnChangeGuiMode'))
                
        set(browser.btnShowAllBlocks, 'Position', browser.objectPositions('btnShowAllBlocks'), 'Parent', browser.guiFigure );                             
        set(browser.btnShowGreen, 'Position', browser.objectPositions('btnShowGreen'), 'Parent', browser.guiFigure ); 
        set(browser.btnShowRed, 'Position', browser.objectPositions('btnShowRed'), 'Parent', browser.guiFigure );  
        set(browser.btnShowRawSignal, 'Position', browser.objectPositions('btnShowRawSignal'), 'Parent', browser.guiFigure ); 

        axPopSize = get(browser.axPopulationResponse, 'Position');
        set(browser.RoiMarker, 'Parent', browser.signalPanel, ...
            'Position', [axPopSize(1)+axPopSize(3) + 0.004, axPopSize(2)+axPopSize(4)-0.02, 0.015, 0.04]);
        browser.updateRoiMarker();

        set(browser.axArenaAnimation, 'Visible', 'on')
        set(browser.animationImObj, 'Visible', 'on')
        
        % Add Patches in animation plot
        sessionBrowser.anglePatchLegend(browser.axArenaAnimation)

        set(browser.blocksliderContainer, 'Visible', 'on')
    end
    
    
end



methods
    
    
    function browser = sessionBrowser
        % Initialize the browser GUI for looking through experimental data
        
        % Set up figure. Default is to cover the whole screen
        screenSize = get(0, 'Screensize');
        
        browser.guiFigure = figure(...
                      'Name', 'Session Browser', ...
                      'NumberTitle', 'off', ...
                      'Visible','off', ...
                      'Position', screenSize, ...
                      'WindowButtonMotionFcn', {@browser.mouseOver, 'display roi'}, ...
                      'WindowButtonDownFcn', {@browser.mouseOver, 'select roi'},...
                      'KeyPressFcn', @browser.keyPress);
        
        % Make figure visible to get the correct figure size for placing
        % things
        browser.guiFigure.Visible = 'On';
        set(browser.guiFigure, 'menubar', 'none');
        pause(0.5)
        
        figsize = get(browser.guiFigure, 'Position');
        aspectRatio = figsize(3)/figsize(4);
        
        % Load mouse and experiment inventory
        browser.mouseInv = loadMouseInv();
        browser.expInv = loadExpInv();

        % Specify obj.margins (for figure window) and obj.padding (space between objects)
        browser.margins = 0.02 * [1, aspectRatio];  %sides, top/bottom
        browser.padding = 0.03 * [1, aspectRatio];  %sides, top/bottom
        
        % Create Panels. Starting on right side (fixed sizes)...
        pupilPanelSize = [0.33, 0.45];
        pupilPanelPos = [1 - browser.margins(1) - pupilPanelSize(1), 1-browser.margins(2) - pupilPanelSize(2), pupilPanelSize];
        browser.createPupilPanel(pupilPanelPos);
        
        bodyPanelSize = [0.33, 0.45];
        bodyPanelPos = [1 - browser.margins(1) - bodyPanelSize(1), browser.margins(2), bodyPanelSize];
        browser.createBodyPanel(bodyPanelPos);

        imPanelSize = 0.5 ./ [aspectRatio, 1];
        imPanelPos = [pupilPanelPos(1) - browser.padding(1) - imPanelSize(1), 1-browser.margins(2) - imPanelSize(2), imPanelSize];
        browser.createImagePanel(imPanelPos);
        
        signalPanelSize = [1 - 2 * browser.margins(1) - browser.padding(1) - pupilPanelSize(1), ...
                           1 - 2 * browser.margins(2) - browser.padding(2) - imPanelSize(2)];
        signalPanelPos = [browser.margins(1), browser.margins(2), signalPanelSize];
        browser.createSignalPanel(signalPanelPos);
        
        topPanelSize = [imPanelPos(1) - browser.margins(1) - browser.padding(1), 0.2]; % This panel determines the rest.
        topPanelPos = [browser.margins(1), 1 - browser.margins(2) - topPanelSize(2), topPanelSize];
        browser.createTopPanel(topPanelPos);
        
        animationPanelSize = [topPanelSize(1), imPanelSize(2) - topPanelSize(2) - browser.padding(2)/2];
        animationPanelPos = [browser.margins(1), topPanelPos(2) - browser.padding(2)/2 - animationPanelSize(2), animationPanelSize ];
        browser.createAnimationAx(animationPanelPos);
        
        % Create two invisible axes
        sideMargin = 0.05;
        plotSize = [0.9, 0.1];
        bottomMargin = 0.05;
        browser.axFrameMovementPlot = axes('Position', ...
                [sideMargin, bottomMargin + (plotSize(2) + 0.03)*4 + 0.23, plotSize(1), 0.05 ], 'xtick',[], 'ytick',[], ...
                'Visible', 'off');
        browser.axLickResponses = axes('Position', ...
                [sideMargin, bottomMargin + (plotSize(2) + 0.03)*2, plotSize ], 'xtick',[], 'ytick',[], ...
                'Visible', 'off');
        
        % Activate callback function for resizing panels when figure changes size
        set(browser.guiFigure, 'SizeChangedFcn', @browser.figsizeChanged );
       
        % Create buttons above signal panel
        figBtnSize = [0.07, 0.03];
        figBtnPos = [signalPanelPos(1)+signalPanelPos(3), signalPanelPos(2)+signalPanelPos(4), figBtnSize];
        figBtnPos(1) = figBtnPos(1) - figBtnPos(3);                           
        browser.btnShowAllBlocks = uicontrol('Style', 'togglebutton', ...
                                             'String', 'Show All Blocks', ...
                                             'Units', 'Normalized', ...
                                             'Position', figBtnPos, ...
                                             'Callback', @browser.updateSignalPlot, ...
                                             'KeyPressFcn', @browser.keyPress);
        browser.objectPositions('btnShowAllBlocks') = get(browser.btnShowAllBlocks, 'Position');

                                         
        figBtnPos(1) = figBtnPos(1) - figBtnPos(3) - 0.01;                           
        browser.btnShowRed = uicontrol('Style', 'togglebutton', ...
                                         'String', 'Show Red Ch', ...
                                         'Units', 'Normalized', ...
                                         'Position', figBtnPos, ...
                                         'Callback', @browser.updateSignalPlot, ...
                                         'KeyPressFcn', @browser.keyPress); 
        browser.objectPositions('btnShowRed') = get(browser.btnShowRed, 'Position');
                                         
        figBtnPos(1) = figBtnPos(1) - figBtnPos(3) - 0.01;                           
        browser.btnShowGreen = uicontrol('Style', 'togglebutton', ...
                                         'String', 'Show Green Ch', ...
                                         'Units', 'Normalized', ...
                                         'Position', figBtnPos, ...
                                         'Callback', @browser.updateSignalPlot, ...
                                         'KeyPressFcn', @browser.keyPress); 
        browser.objectPositions('btnShowGreen') = get(browser.btnShowGreen, 'Position');
                             
        figBtnPos(1) = figBtnPos(1) - figBtnPos(3) - 0.01;                           
        browser.btnShowRawSignal = uicontrol('Style', 'pushbutton', ...
                                         'String', 'Show Raw Signal', ...
                                         'Units', 'Normalized', ...
                                         'Position', figBtnPos, ...
                                         'Callback', @browser.updateSignalPlot, ...
                                         'KeyPressFcn', @browser.keyPress); 
        browser.objectPositions('btnShowRawSignal') = get(browser.btnShowRawSignal, 'Position');
                                     
        textSize = [0.1, 0.025];
        textPos = [figBtnPos(1) - textSize(1) - 0.01, figBtnPos(2), textSize];
        browser.currentRoiIndicator = uicontrol('Style', 'text', ...
                                                'String', 'Current Roi: N/A', ...
                                                'Units', 'Normalized', ...
                                                'Position', textPos, ... % 135 20
                                                'HorizontalAlignment', 'left', ...
                                                'FontSize', 14);
        browser.objectPositions('currentRoiIndicator') = get(browser.currentRoiIndicator, 'Position');
        
        
        browser.currentFrame = 1;
        browser.currentBlock = 1;
        browser.currentRoi = 1;

    end
    
    
    function browser = figsizeChanged(browser, ~, ~)
    % Callback function to resize/move ui panels if figure size is changed
        
        figsize = get(browser.guiFigure, 'Position');
        aspectRatio = figsize(3)/figsize(4);
            
        browser.margins = 0.02 * [1, aspectRatio];  %sides, top/bottom
        browser.padding = 0.03 * [1, aspectRatio];  %sides, top/bottom
        
        imPanelPos = get(browser.imagePanel, 'Position');
        newWidth = imPanelPos(4) / aspectRatio;
        imPanelPos(1) = imPanelPos(1) + (imPanelPos(3) - newWidth);
        imPanelPos(3) = newWidth;
        set(browser.imagePanel, 'Position', imPanelPos)
        
        topPanelPos = get(browser.topPanel, 'Position');
        topPanelPos(3) = imPanelPos(1) - browser.margins(1) - browser.padding(1); 
        set(browser.topPanel, 'Position', topPanelPos)      

        animationAxPos = get(browser.axArenaAnimation, 'Position');
        animationAxPos(1) = (topPanelPos(3) - animationAxPos(3))/2 + topPanelPos(1);
        set(browser.axArenaAnimation, 'Position', animationAxPos);
            
    end
    
    
    function browser = mouseOver(browser, ~, ~, action)
        % Perform action when hovering over a ROI in the populationactivity axes. 
        % Either show roi number, or select a roi on button click.
        
        currentFigPoint = get(browser.guiFigure, 'CurrentPoint');
        x_f = currentFigPoint(1);
        y_f = currentFigPoint(2);
        figPos = get(browser.guiFigure, 'Position');

        % Check if mouse is over imageObj
        if ~isempty(browser.caImageObj)
            panelPos = get(browser.imagePanel, 'Position');
            btnPos = get(browser.btnLoadCalciumVideo, 'Position');
            btnPos(1:2) = panelPos(1:2) .* figPos(3:4) + (btnPos(1:2) .* panelPos(3:4) .* figPos(3:4));
            btnPos(3:4) = btnPos(3:4) .* panelPos(3:4) .* figPos(3:4);
            
            if x_f > btnPos(1) && x_f < btnPos(1) + btnPos(3) && y_f+10 > btnPos(2) && y_f < btnPos(2) + btnPos(4)
                set(browser.btnLoadCalciumVideo, 'Visible', 'on');
            else
                set(browser.btnLoadCalciumVideo, 'Visible', 'off');
            end
        end   
            
        % Check if mouse is over pupil panel (button)
        if ~isempty(browser.pupilImageObj)
            panelPos = get(browser.pupilPanel, 'Position');
            btnPos = get(browser.btnLoadPupilVideo, 'Position');
            btnPos(1:2) = panelPos(1:2) .* figPos(3:4) + (btnPos(1:2) .* panelPos(3:4) .* figPos(3:4));
            btnPos(3:4) = btnPos(3:4) .* panelPos(3:4) .* figPos(3:4);
            
            if x_f > btnPos(1) && x_f < btnPos(1) + btnPos(3) && y_f+10 > btnPos(2) && y_f < btnPos(2) + btnPos(4)
                set(browser.btnLoadPupilVideo, 'Visible', 'on');
            else
                set(browser.btnLoadPupilVideo, 'Visible', 'off');
            end
        end 
        
        % Check if mouse is over body panel (button)
        if ~isempty(browser.bodyImageObj)
            panelPos = get(browser.bodyPanel, 'Position');
            btnPos = get(browser.btnLoadBodyVideo, 'Position');
            btnPos(1:2) = panelPos(1:2) .* figPos(3:4) + (btnPos(1:2) .* panelPos(3:4) .* figPos(3:4));
            btnPos(3:4) = btnPos(3:4) .* panelPos(3:4) .* figPos(3:4);
            
            if x_f > btnPos(1) && x_f < btnPos(1) + btnPos(3) && y_f+10 > btnPos(2) && y_f < btnPos(2) + btnPos(4)
                set(browser.btnLoadBodyVideo, 'Visible', 'on');
            else
                set(browser.btnLoadBodyVideo, 'Visible', 'off');
            end
        end 
        
        % Check if mouse is over Ax with population responses
        if ~isempty(browser.axPopulationResponse)
            xlim = get(browser.axPopulationResponse, 'XLim');
            ylim = ceil(get(browser.axPopulationResponse, 'YLim'));
            mousePoint = get(browser.axPopulationResponse, 'CurrentPoint');
            x = round(mousePoint(1,1));
            y = floor(mousePoint(1,2)-0.3); % Ad hoc correction

            if x > xlim(1) && x < xlim(2) && y >=ylim(1) && y <= ylim(2) - 0.5
                
                switch action
                    case 'display roi'
                        set(browser.hoverCellText, 'String', ...
                            ['Roi: ', num2str(y)], 'Position', [x+10, y]);
                    case 'select roi'
                        browser = changeRoi(browser, y, [], 'mouseclick');
                end
            else
                set(browser.hoverCellText, 'String', '')
            end
        end
        
        % Check if mouse is over Ax with cell response
        if ~isempty(browser.axCellResponse)
            xlim = get(browser.axCellResponse, 'XLim');
            ylim = ceil(get(browser.axCellResponse, 'YLim'));
            mousePoint = get(browser.axCellResponse, 'CurrentPoint');
            x = round(mousePoint(1,1));
            y = round(mousePoint(1,2));
            
            if x > xlim(1) && x < xlim(2) && y >=ylim(1) && y <= ylim(2)
                switch action
                    case 'select roi'
                        % Go to frame which was clicked on
                        [~, idx] = min(abs(browser.sessionData.timePoints - x));
                        source.Value = idx;
                        browser = changeFrame(browser, source, [], 'buttonclick');
                end
            end
        end

        
    end
    
    
    function browser = keyPress(browser, source, event)
        if ~isempty(browser.sessionData)
            switch event.Key
                case {'leftarrow', 'rightarrow'}
                    browser = changeBlock(browser, source, event, 'keypress');
                case {'uparrow', 'downarrow'}
                    browser = changeRoi(browser, source, event, 'keypress');
                case {'q'}
                    ylim = get(browser.axCellResponse, 'YLim');
                    ylim(2) = ylim(2) + 1;
                    set(browser.axCellResponse, 'YLim', ylim)
                case {'a'}
                    ylim = get(browser.axCellResponse, 'YLim');
                    if ylim(2) > 1; ylim(2) = ylim(2) - 1; end
                    set(browser.axCellResponse, 'YLim', ylim)
                case {'x', 'X'}
                    if browser.plotMode
                        if strcmp(event.Character, 'X')
                            zoom = 1/browser.zoomFactor;
                        else 
                            zoom = browser.zoomFactor;
                        end
                        browser.zoomPlot(zoom);
                    end
                case 'm'
                    xLim = get(browser.axPopulationResponse, 'XLim');
                    nFrames = diff(xLim);
                    newsource.Value = nFrames;
                    browser.changeFrame(newsource, [], 'keypress');
                    browser.scrollXaxis();
                    
                case 'n'
                    xLim = get(browser.axPopulationResponse, 'XLim');
                    nFrames = diff(xLim);
                    newsource.Value = -nFrames;
                    browser.changeFrame(newsource, [], 'keypress');
                    browser.scrollXaxis();
            end
        end
    end
    
    
    function zoomPlot(browser, zoom)
    % Zoom in along the xAxis of all plots in the gui.
    
        xLim = get(browser.axCellResponse, 'XLim');
        xLimNew = [0 zoom*diff(xLim)] + xLim(1) + (1-zoom)*diff(xLim)/2;
        
        shift = browser.sessionData.timePoints(browser.currentFrame) - (xLimNew(1) + diff(xLimNew)/2);
        xLimNew = xLimNew + shift;
        
        if diff(xLimNew) > browser.sessionData.timePoints(end)
            xLimNew = [0, browser.sessionData.timePoints(end)];
        elseif xLimNew(1) < 0
            xLimNew = xLimNew - xLimNew(1);
        elseif xLimNew(2) > browser.sessionData.timePoints(end)
            xLimNew = xLimNew - (xLimNew(2) - browser.sessionData.timePoints(end));
        end
        
        set(browser.axCellResponse,'XLim',xLimNew)
        set(browser.axBodyMovementPlot,'XLim',xLimNew)
        set(browser.axPupilActivityPlot,'XLim',xLimNew)
        set(browser.axFrameMovementPlot,'XLim',xLimNew)
        set(browser.axLickResponses, 'XLim', xLimNew)

        xLim = get(browser.axPopulationResponse, 'XLim');
        xLimNew = [0 zoom*diff(xLim)] + xLim(1) + (1-zoom)*diff(xLim)/2;

        shift = browser.currentFrame - (xLimNew(1) + diff(xLimNew)/2);
        xLimNew = xLimNew + shift;
        
        if diff(xLimNew) > browser.sessionData.nFrames(end)
            xLimNew = [0, browser.sessionData.nFrames(end)];
        elseif xLimNew(1) < 0
            xLimNew = xLimNew - xLimNew(1);
        elseif xLimNew(2) > browser.sessionData.nFrames(end)
            xLimNew = xLimNew - (xLimNew(2) - browser.sessionData.nFrames(end));
        end

        set(browser.axPopulationResponse, 'XLim', xLimNew)

        
    end
    
    
    function browser = loadSession(browser, sessionID)
        if ~isempty(sessionID)
            % Change Mouse
            mouse = strrep(sessionID(1:4), 'm', 'mouse');
            browser.mousepopup.Value = find(strcmp(browser.mousepopup.String, mouse));
            browser.changeMouse(browser.mousepopup, []);
            
            % Change Session
            browser.sessionpopup.Value = find(strcmp(browser.sessionpopup.String, sessionID));
            browser.changeSession(browser.sessionpopup, []);
        end
    end
    
    
    function browser = changeMouse(browser, source, ~)
        % Change current mouse based on selection in popupmenu
        
        mouseId = source.String{source.Value}; % Selected string from menu
        
        if strcmp(mouseId, 'Select mouse') % No selection
            set(browser.sessionpopup, 'Value', 1);
            set(browser.sessionpopup, 'String', 'Select a mouse...');  
            return
        end

        % Add sessions which are present for selected mouse
        mId = strrep(mouseId, 'ouse', ''); % shorten mouse001 to m001
        mouseSessions = find(strncmp( browser.expInv(2:end, 1), mId, 4 ));
        mouseSessions = arrayfun(@(x) browser.expInv(x+1, :), mouseSessions, 'un', 0);
        if isempty(mouseSessions); mouseSessions = {'No Sessions Available'}; end

        % Filter out sessions that are not analyzed.
        analyzedSessions = arrayfun(@(x) mouseSessions{x}{1,2}.isAnalyzed, ...
                                    1:length(mouseSessions), 'uni', 0);

        mouseSessions = arrayfun(@(x) mouseSessions{x}{1, 1}, find(cell2mat(analyzedSessions)), 'uni', 0);
        set(browser.sessionpopup, 'Value', 1);
        set(browser.sessionpopup, 'String', horzcat({'Select a session...'}, mouseSessions));
        %changeSession(browser, browser.sessionpopup) %Change automatically
        %when mouse is chosen  
    end
    
    
    function browser = changeSession(browser, source, ~)
        % Open session data based on selection in session popupmenu
        
        if isempty(browser.sessionID)
            set(browser.guiFigure, 'WindowScrollWheelFcn', {@browser.changeFrame, 'mousescroll'})
        end

        
        browser.sessionID = source.String{source.Value}; % Selected session from menu
        if strcmp(browser.sessionID, 'Select a session...') % No selection made
            browser.sessionID = [];
            return
        end
        
        % Find selected session in experiment Inventory
        n = find(strcmp( browser.expInv(2:end, 1), browser.sessionID));
        if ~isempty(n)
            s = browser.expInv{n+1, 2};
            if s.isAnalyzed
                browser.currentFrame = 1;
                browser.currentBlock = 1;
                browser.currentRoi = 1;
                
                browser.sessionData = getSessionData(browser.sessionID);
                %browser.sessionData = deltaFoverFcontinuous(browser.sessionData); NB
                %browser.sessionData = deltaFoverFstep(browser.sessionData);

                nFrames = browser.sessionData.nFrames;
                nBlocks = double(browser.sessionData.nBlocks);
%                 set(browser.blockslider, 'Max', nBlocks, ...
%                                          'Value', browser.currentBlock, ...
%                                          'SliderStep', [1/(nBlocks-1), 1])
                set(browser.blockslider, 'Minimum', 1, 'Maximum', nBlocks, 'Value', browser.currentBlock);
                if ~browser.plotMode
                    set(browser.blocksliderContainer, 'Visible', 'on')
                end
                
                set(browser.currentFrameIndicator, 'String', ['Current Frame: 1/' num2str(nFrames)] )

                delete(browser.populationActivity)
                hold(browser.axPopulationResponse, 'off')
                browser.populationActivity = [];
                browser.patchAnglesPlot('Unpatch Angles');
                browser = changeBlock(browser, [], [], 'newSession');
                browser = changeRoi(browser, 1, [], 'newSession');

            end
        end
    end
    
    
    function browser = changeBlock(browser, source, event, action)
    % Change current block, either by slider or by arrowkeys
    
        nBlocks = browser.sessionData.nBlocks;
        command.String = 'Change Block';
        switch action
            case 'slider'
                i = source.Value;
                browser.currentBlock = round(i);
                
            case 'keypress'
                switch event.Key
                    case 'rightarrow'
                        if browser.currentBlock < nBlocks
                            browser.currentBlock = browser.currentBlock + 1;
                        else
                            return
                        end
                    case 'leftarrow'
                        if browser.currentBlock > 1
                            browser.currentBlock = browser.currentBlock - 1;
                        else
                            return
                        end
                end
            case 'newSession'
                command.String = 'Change Session';
        end
        
        set( browser.currentBlockIndicator, 'String', ...
                  ['Current Block: ' num2str(browser.currentBlock) '/' num2str(nBlocks)] )
        set( browser.blockslider, 'Value', browser.currentBlock )
%         lightsOn = browser.sessionData.lights(browser.currentBlock);
%         if lightsOn 
%             set(browser.lightIndicator, 'String', 'Lights On') 
%         else
%             set(browser.lightIndicator, 'String', 'Lights Off')
%         end

        browser = updatePlots(browser);
        browser = updateSignalPlot(browser, command, []);
        
        browser.calciumImages = [];
        browser.pupilVideo = [];
        browser.surveillanceVideo = [];
        browser.calciumVideoIsLoaded = false;
        browser.pupilVideoIsLoaded = false;
        browser.bodyVideoIsLoaded = false;
        
%         delete(browser.caImageObj)
%         browser.caImageObj = [];
        
        browser = updateFrames(browser);
        browser = updateFrameMarkers(browser);

    end
    
    
    function browser = changeRoi(browser, newValue, event, action)
        
        switch action
            case 'keypress'
                switch event.Key
                    case 'downarrow'
                        if browser.currentRoi < browser.sessionData.nRois
                            browser.currentRoi = browser.currentRoi + 1;
                        end
                    case 'uparrow'
                        if browser.currentRoi > 1
                            browser.currentRoi = browser.currentRoi - 1;
                        end
                end
                
            case {'mouseclick', 'newSession'}
                browser.currentRoi = newValue;
                
        end
        
        browser.updateRoiMarker();
        
        set( browser.currentRoiIndicator, 'String', ...
                  ['Current Roi: ' num2str(browser.currentRoi) '/' num2str(browser.sessionData.nRois)] )
        if  ~isempty(browser.calciumImages) || ~isempty(browser.tiffStacks)
            browser.plotRoi()
        end

        command.String = 'Change Roi';
        browser = updateSignalPlot(browser, command, []); 
        
    end
    
    
    function browser = updateRoiMarker(browser)
    % Moves a tiny marker next to the population plot to indicate current roi.    
        if ~isempty(browser.populationActivity)
            figsize = get(browser.guiFigure, 'Position');

            axPopPos = get(browser.axPopulationResponse, 'Position');
            ylim = get(browser.axPopulationResponse, 'YLim');
            deltaRoi = axPopPos(4)/(diff(ylim));
            roiMarkerPos = get(browser.RoiMarker, 'Position');


            if browser.plotMode
                % Set pointer to current roi
                y_corr = 4.782 / figsize(4);
                roiMarkerPos(2) = axPopPos(2) + axPopPos(4)-y_corr-(deltaRoi*(browser.currentRoi-0.5));
            else
                % Set pointer to current roi
                roiMarkerPos(2) = axPopPos(2) + axPopPos(4)-0.02-(deltaRoi*(browser.currentRoi-0.5));
            end

            set(browser.RoiMarker, 'Position', roiMarkerPos)
        end

        
    end
    
    
    function browser = changeFrame(browser, source, event, action)
        % Change the current frame and update data.
        
        nFrames = browser.sessionData.nFrames;
        
        switch action
            case 'mousescroll'
                i = event.VerticalScrollCount;

            case {'slider', 'buttonclick'}
                newValue = source.Value;
                i = newValue -  browser.currentFrame;
                i = round(i);
                
            case {'jumptoframe'}
                i = str2double(source.String) - browser.currentFrame;
                i = round(i);
                
            case 'playvideo'
                i = 1;
                
            case 'keypress'
                i = source.Value;

        end

        % Check that new value is within range and update current frame/slider info
        if (browser.currentFrame + i) >=1  && (browser.currentFrame + i) <= nFrames
            browser.currentFrame = round(browser.currentFrame + i);
            set(browser.frameslider, 'Value', browser.currentFrame );
        end
        
        
        if nFrames > 1
            set( browser.currentFrameIndicator, 'String', ...
                  ['Current Frame: ' num2str(browser.currentFrame) '/' num2str(nFrames)] )
        end
        
        if ~isempty(browser.sessionData)
            browser = updateFrameMarkers(browser);
            browser = updateFrames(browser);
        end
        
        if strcmp(action, 'mousescroll')
            if browser.plotMode
                browser.scrollXaxis();
            end
        end
                
    end
    
    
    function browser = loadCalciumVideo(browser, ~, ~)
    % Load tiff stack of calcium images when images are split into chunks
        
        sessionFolder = getSessionFolder(browser.sessionID);
        
        % Load tiff stack of calcium images
        imageFolder = fullfile(sessionFolder, 'calcium_images_aligned');
        
        imFiles = dir(fullfile(imageFolder, 'calcium*'));
        
        nFiles = length(imFiles);
        browser.tiffStacks = cell(nFiles, 1);
        
        for i=1:nFiles
            imFile = fullfile(imageFolder, imFiles(i).name);
            browser.tiffStacks{i} = TIFFStack(imFile);
        end
        
        browser.calciumVideoIsLoaded = true;
        
        browser = updateFrames(browser);
    end
    
    
    function browser = loadCalciumVideo_old(browser, ~, ~)
    % Load tiff stack of calcium images
        
        sessionFolder = getSessionFolder(browser.sessionData.sessionID);
        block = browser.currentBlock;
        
        % Load tiff stack of calcium images
        imageFolder = fullfile(sessionFolder, 'calcium_images_aligned');
        
        imFile = dir(fullfile(imageFolder, 'calcium*'));
        imFile = fullfile(imageFolder, imFile(block).name);
        
%          %Try to open image stack as a TIFFStack object. If fail: load to array
%         try
%             browser.calciumImages = TIFFStack(imFile);
%             %obj.tiffClass = 'TIFFStack';
%         catch
             browser.calciumImages = stack2mat(imFile, true);
%             %obj.tiffClass = 'double';
%         end
        
        browser.calciumVideoIsLoaded = true;
        
        browser = updateFrames(browser);
        
    end
    
    
    function browser = loadLabviewVideo(browser, ~, ~, whichVideo)
        block = browser.currentBlock;
        
        % Load videos from labview folders
        h = waitbar(0, 'Please wait... Loading videofile...');

        sessionFolder = getSessionFolder(browser.sessionID);
        labviewFolder = fullfile(sessionFolder, 'labview_data');
        blockFolders = dir(fullfile(labviewFolder, '*Block*'));
        blockFolder = blockFolders(block).name;
        switch whichVideo
            case 'pupil'
                videoPath = dir(fullfile(labviewFolder, blockFolder, '*pupil_video.avi'));
                frameTimesPath = dir(fullfile(labviewFolder, blockFolder, '*pupil_frametimes.txt'));
            case 'body'
                videoPath = dir(fullfile(labviewFolder, blockFolder, '*security_video.avi'));
        end
        
        video = VideoReader(fullfile(labviewFolder, blockFolder, videoPath(1).name));
        
        tic
        nFrames = video.NumberOfFrames;
        frames = zeros(video.Height, video.Width, nFrames, 'uint8');
        for i = 1:nFrames
            im = read(video, i);
            frames(:,:,i) = im(:,:,1);
            if mod(i, 100) == 0
                waitbar(i/nFrames, h)
            end
        end
        toc
        
        switch whichVideo
            case 'pupil'
                browser.pupilVideo = frames;
                browser.pupilFrameTimes = load(fullfile(labviewFolder, blockFolder, frameTimesPath(1).name));
                browser.pupilFrameTimes = cumsum(browser.pupilFrameTimes(:,2));
                browser.pupilVideoIsLoaded = true;
            case 'body'
                browser.surveillanceVideo = frames;
                browser.bodyVideoIsLoaded = true;
        end
        
        waitbar(1, h, 'File loaded successfully')
        close(h)

        browser = updateFrames(browser);
        
    end        
    
    
    function plotRoi(browser)
    % Plot roi in image
        boundary = browser.sessionData.roiArray(1, browser.currentRoi).Boundary{1, 1};
        if isempty(browser.roiPlotHandle)
            browser.roiPlotHandle = plot(browser.axCalciumVideo, boundary(:,2), boundary(:,1), 'r');
        else
            set(browser.roiPlotHandle, 'XData', boundary(:,2), 'YData', boundary(:,1))
            set(browser.roiPlotHandle, 'color', 'red')
        end 
    end
        
    
    function browser = updateFrames(browser)
    % Updates videoaxes and frame indicators
    
        frameNo = browser.currentFrame;
        t = browser.sessionData.timePoints(frameNo);
        
        % Update axes with calcium images
        if browser.calciumVideoIsLoaded && browser.btnShowVideo.Value
        
            chunkSize = 5000;
            chunkNo = floor(frameNo/5001) + 1;
            chunkFrameNo = mod(frameNo, chunkSize);
            if chunkFrameNo == 0; chunkFrameNo = 5000; end
            
            caframe = browser.tiffStacks{chunkNo}(:,:,chunkFrameNo);
            
            %caframe = browser.calciumImages(:,:,frameNo);            
            
            if isempty(browser.caImageObj) % First time initialization. Create image object
               browser.caImageObj = imshow(caframe, [0, 255], 'Parent', browser.axCalciumVideo, 'InitialMagnification', 'fit');
               hold(browser.axCalciumVideo, 'on')
            else
               set(browser.caImageObj, 'cdata', caframe);
            end
            
            browser.plotRoi();

        end
        
        % Update axes with pupil video
        if browser.pupilVideoIsLoaded  && browser.btnShowVideo.Value
            pTimes = browser.pupilFrameTimes;
            deltaT = abs(pTimes - t);
            [~, idx] = min(deltaT);

            pframe = browser.pupilVideo(:, :, idx);
            
            if isempty(browser.pupilImageObj) % First time initialization. Create image object
               browser.pupilImageObj = imshow(pframe, [0, 255], 'Parent', browser.axPupilVideo, 'InitialMagnification', 'fit');
            else
               set(browser.pupilImageObj, 'cdata', pframe);
            end

        end

        % Update axes with security video
        if browser.bodyVideoIsLoaded  && browser.btnShowVideo.Value
            sTimes = browser.sessionData.sTimes;
            deltaT = abs(sTimes - t);
            [~, idx] = min(deltaT);

            bframe = browser.surveillanceVideo(:,:,idx);

            if isempty(browser.bodyImageObj) % First time initialization. Create image object
               browser.bodyImageObj = imshow(bframe, 'Parent', browser.axOverviewVideo, 'InitialMagnification', 'fit');
            else
               set(browser.bodyImageObj, 'cdata', bframe);
            end
        end
        
        % Make and show graphics for mouse and arena
        frame = browser.makeAnimationFrame();
        frame = cat(3, frame, frame, frame);
        
        if isempty(browser.animationImObj)
            browser.animationImObj = imshow(frame, [0, 255], 'Parent', browser.axArenaAnimation, 'InitialMagnification', 'fit');
            set(browser.axArenaAnimation, 'Visible', 'on')
            sessionBrowser.maskArenaAnimation(browser.axArenaAnimation)
            sessionBrowser.anglePatchLegend(browser.axArenaAnimation)
        else
           set(browser.animationImObj, 'cdata', frame);
        end
        
    end
    
    
    function browser = updatePlots(browser)
        
        block = browser.currentBlock;
        
        block_response = squeeze(browser.sessionData.deltaFoverFch2(block, :, :));
        block_response = block_response ./ max(max(block_response));
        
        % Make population plot
        if isempty(browser.populationActivity)
            browser.populationActivity = imagesc(block_response, 'Parent', browser.axPopulationResponse, 'AlphaData', 1 );
            browser.hoverCellText = text('Color', 'red', 'String', '', 'VerticalAlign', 'Bottom', ...
                     'BackgroundColor', 'white', 'Parent', browser.axPopulationResponse );
            set(browser.axPopulationResponse, 'CLim', [0,1])
            colormap(browser.axPopulationResponse, 'default')
            browser.axPopulationResponse.XTick = [];
            hold(browser.axPopulationResponse, 'on')
%             yPatch = [0, 0, size(block_response,1), size(block_response,1)];
%             xPatch = [1, 1+1, 1+1, 1 ];
%            browser.popAframeMarker = patch(xPatch, yPatch, 'r', 'Parent', browser.axPopulationResponse, 'edgecolor','none');
            browser.popAframeMarker = plot(browser.axPopulationResponse, [1, 1],  get(browser.axPopulationResponse, 'ylim'), 'r');


        else
            browser.populationActivity.CData = block_response;
        end
        
        
        t = browser.sessionData.timePoints;
        % Make/update plot for body movement
        if isempty(browser.bodyMovmLine)
            browser.bodyMovmLine = plot(browser.axBodyMovementPlot, browser.sessionData.sTimes, browser.sessionData.struggleFactor(block, :));
            hold(browser.axBodyMovementPlot, 'on')
            browser.axBodyMovementPlot.YLim = [-1, 1];
            browser.axBodyMovementPlot.YTick = [-1, 0, 1];
            browser.bodyFrameMarker = plot(browser.axBodyMovementPlot, [t(1), t(1)], get(browser.axBodyMovementPlot, 'ylim'), 'r');
        else
            browser.bodyMovmLine.XData = browser.sessionData.sTimes;
            browser.bodyMovmLine.YData = browser.sessionData.struggleFactor(block, :);

        end
        browser.axBodyMovementPlot.XLim = [t(1), t(end)];
        
        % Make/update plot for pupil displacement
        pupilDiameter = browser.sessionData.pupilDiameter(block,:);
        pupilDiameter(pupilDiameter > nanmean(pupilDiameter) + 2*nanstd(pupilDiameter)) = nan;
        pupilDisplacement = browser.sessionData.pupilDisplacement(block, :);
        pupilDisplacement(pupilDisplacement > nanmean(pupilDisplacement) + 2*nanstd(pupilDisplacement)) = nan;

        max_pupil_diameter = 140;
        max_pupil_displacement = 20;
        
        if isempty(browser.pupilDiamLine)
            browser.pupilDiamLine = plot(browser.axPupilActivityPlot, browser.sessionData.pupilTimes(block, :), pupilDiameter/max_pupil_diameter );
            hold(browser.axPupilActivityPlot, 'on')
            browser.pupilMovmLine = plot(browser.axPupilActivityPlot, browser.sessionData.pupilTimes(block, :), pupilDisplacement / max_pupil_displacement );
            browser.pupilFrameMarker = plot(browser.axPupilActivityPlot, [t(1), t(1)], get(browser.axPupilActivityPlot, 'ylim'), 'r');
            browser.axPupilActivityPlot.YLim = [0, 1];
            browser.axPupilActivityPlot.YTick = [0, 1];
            set(browser.axPupilActivityPlot, 'XLabel', xlabel(''))
        else
            browser.pupilDiamLine.XData = browser.sessionData.pupilTimes(block, :);
            browser.pupilDiamLine.YData = pupilDiameter / max_pupil_diameter;
            browser.pupilMovmLine.XData = browser.sessionData.pupilTimes(block, :);
            browser.pupilMovmLine.YData = pupilDisplacement / max_pupil_displacement;
        end
        
        browser.axPupilActivityPlot.XLim = [t(1), t(end)];
        
        % Make/update plot for frame movement
        if isempty(browser.frameMovmLine)
            browser.frameMovmLine = plot(browser.axFrameMovementPlot, t, browser.sessionData.frameMovement(block, :));
            hold(browser.axFrameMovementPlot, 'on')
            browser.axFrameMovementPlot.YLim = [min(browser.sessionData.frameMovement(block, :)), max(browser.sessionData.frameMovement(block, :))];
            browser.axFrameMovementPlot.YTick = [0, max(browser.sessionData.frameMovement(block, :))];
            browser.fmFrameMarker = plot(browser.axFrameMovementPlot, [t(1), t(1)], get(browser.axFrameMovementPlot, 'ylim'), 'r');
        else
            browser.frameMovmLine.XData = t;
            browser.frameMovmLine.YData = browser.sessionData.frameMovement(block, :);

        end
        browser.axFrameMovementPlot.XLim = [t(1), t(end)];
        if ~browser.plotMode
                set(browser.axFrameMovementPlot, 'Visible', 'off')
                set(browser.axFrameMovementPlot.Children, 'Visible', 'off')
        end
        
        % Make/update plot for licking data
        if isfield(browser.sessionData, 'lickResponses')
            if isempty(browser.lickLine)
                browser.lickLine = plot(browser.axLickResponses, t, browser.sessionData.lickResponses(block, :), 'y');
                hold(browser.axLickResponses, 'on')
                browser.waterLine = plot(browser.axLickResponses, t, browser.sessionData.waterRewards(block, :), 'g');
                browser.axLickResponses.YLim = [0, 1.2];
                browser.axLickResponses.YTick = [0, 1];
                browser.lickresponseFrameMarker = plot(browser.axLickResponses, [t(1), t(1)], get(browser.axLickResponses, 'ylim'), 'r');
            else
                browser.lickLine.XData = t;
                browser.lickLine.YData = browser.sessionData.lickResponses(block, :);
                browser.waterLine.XData = t;
                browser.waterLine.YData = browser.sessionData.waterRewards(block, :);
            end
            browser.axLickResponses.XLim = [t(1), t(end)];
            if ~browser.plotMode
                set(browser.axLickResponses, 'Visible', 'off')
                set(browser.axLickResponses.Children, 'Visible', 'off')
            end
        end
        % drawnow
        
    end
    
    
    function browser = updateSignalPlot(browser, source, ~)
        
        if isempty(source)
            command = 'None';
        else
            command = source.String;
        end

        roi = browser.currentRoi;
        t = browser.sessionData.timePoints;
        
        switch command   % Change button states
            case 'Show All Blocks'
                set(browser.btnShowAllBlocks, 'String', 'Show Current Block')
                set(browser.btnShowRed, 'Enable', 'Off')
                
            case 'Show Current Block'
                set(browser.btnShowAllBlocks, 'String', 'Show All Blocks')
                set(browser.btnShowRed, 'Enable', 'On')
                
            case 'Show Red Ch'
                if source.Value
                	set(browser.btnShowAllBlocks, 'Enable', 'off')
                else
                    set(browser.btnShowAllBlocks, 'Enable', 'on')
                end
            
            case 'Show Raw Signal'
                set(browser.btnShowRawSignal, 'String', 'Show Delta F over F')
                browser.axCellResponse.YLim = [0,1];
                
            case 'Show Delta F over F'
                set(browser.btnShowRawSignal, 'String', 'Show Raw Signal')
                browser.axCellResponse.YLim = [0,4];
            
            case 'Change Session'
                nBlocks = browser.sessionData.nBlocks;
                cla(browser.axCellResponse)
                hold(browser.axCellResponse, 'on')
                browser.btnShowGreen.Value = 1;
                browser.roiGreenSignalLine = cell(1, nBlocks);
                browser.roiRedSignalLine = cell(1, nBlocks);
                browser.roiGreenChVisibility = cell(1, nBlocks);
                browser.roiRedChVisibility = cell(1, nBlocks);
                browser.axCellResponse.YLim = [0, 4];
                browser.roiFrameMarker = plot(browser.axCellResponse, [t(1), t(1)], [0, 4], 'r');
                browser.axCellResponse.XLim = [t(1), t(end)];
                
        end
        
        browser.roiGreenChVisibility(:) = {'off'};
        browser.roiRedChVisibility(:) = {'off'};
        
        % Select all blocks or current block
        if get(browser.btnShowAllBlocks, 'Value')
            blocks = 1:browser.sessionData.nBlocks;
        else 
            blocks = browser.currentBlock;
        end
        

        % Sort channels so that green comes first. (Sort by colorname : green, red)
        metadata2P = loadImagingMetadata(browser.sessionID); %/todo: Should not load this, should be in sessiondata
        channelColor = metadata2P.channelColor;
        ch_unsorted = cat(1, channelColor, num2cell(browser.sessionData.channels));
        ch_sorted = sortrows(ch_unsorted.', 1)';

        if any(strcmp(channelColor, 'Red')) && strcmp(source.String, 'Change Session')
            set(browser.btnShowRed, 'Enable', 'On')
        else
            set(browser.btnShowRed, 'Enable', 'Off')
        end

        % Get raw signal or delta f over f
        signal = cell(browser.sessionData.nCh, 1);

        for i = 1:browser.sessionData.nCh
            ch = ch_sorted{2, i};       
        
            switch get(browser.btnShowRawSignal, 'String');
                case 'Show Delta F over F'
                    fieldName = ['signalCh', num2str(ch)];
                case 'Show Raw Signal'
                    fieldName = ['deltaFoverFch', num2str(ch)];
            end
            
            signal{i} = squeeze(browser.sessionData.(fieldName)(:, roi, :));
        end
        
        if browser.sessionData.nBlocks == 1
            signal{1} = signal{1}';
        end
        
        % Plot or update lines
        for b = blocks
            if get(browser.btnShowGreen, 'Value');
                browser.roiGreenChVisibility(b) = {'on'};     % Set visibility.
                if isempty(browser.roiGreenSignalLine{b})
                    browser.roiGreenSignalLine{b} = plot(browser.axCellResponse, t, squeeze(signal{1}(b, :)));
                else
                    browser.roiGreenSignalLine{b}.XData = t;
                    browser.roiGreenSignalLine{b}.YData = squeeze(signal{1}(b, :));
                end
            else
                browser.roiGreenChVisibility(b) = {'off'};
            end
            
            if get(browser.btnShowRed, 'Value')
                browser.roiRedChVisibility(b) = {'on'};
                if isempty(browser.roiRedSignalLine{b})
                    browser.roiRedSignalLine{b} = plot(browser.axCellResponse, t, squeeze(signal{2}(b, :)), 'r');
                else
                    browser.roiRedSignalLine{b}.XData = t;
                    browser.roiRedSignalLine{b}.YData = squeeze(signal{2}(b, :));
                end
            else 
            	browser.roiRedChVisibility(b) = {'off'};
            end
        end
        
        % Set visibility of lines
        arrayfun(@(x) set(browser.roiGreenSignalLine{x}, 'Visible', browser.roiGreenChVisibility{x}), ...
                 1:browser.sessionData.nBlocks, 'un', 0);
        
        arrayfun(@(x) set(browser.roiRedSignalLine{x}, 'Visible', browser.roiRedChVisibility{x}), ...
                 1:browser.sessionData.nBlocks, 'un', 0);

        if strcmp(source.String, 'Change Session')
        	browser.patchAnglesPlot('Patch Angles');
        end

             
    end
              
                 
    function browser = updateFrameMarkers(browser)
        frameNo = browser.currentFrame;
        t = browser.sessionData.timePoints;
        
        % Update population activity plot
        %ylim = get(browser.axPopulationResponse, 'ylim');
%         yPatch = [0, 0, ylim(2), ylim(2)];
%         xPatch = [frameNo, frameNo+2, frameNo+2, frameNo ];
%         browser.popAframeMarker.XData = xPatch;
%         browser.popAframeMarker.YData = yPatch;
        browser.popAframeMarker.XData = [frameNo, frameNo];
        % Update other plots
        browser.bodyFrameMarker.XData = [t(frameNo), t(frameNo)];
        browser.pupilFrameMarker.XData = [t(frameNo), t(frameNo)];
        browser.roiFrameMarker.XData = [t(frameNo), t(frameNo)];
        browser.fmFrameMarker.XData = [t(frameNo), t(frameNo)];
        browser.lickresponseFrameMarker.XData = [t(frameNo), t(frameNo)];
    end
    
    
    function browser = scrollXaxis(browser)
    % Controls scrolling along xAxis if the zoom is on.
        xLim = get(browser.axCellResponse, 'XLim');
        
        if browser.sessionData.timePoints(browser.currentFrame) < xLim(1)
            xLimNew = xLim + (browser.sessionData.timePoints(browser.currentFrame) - xLim(1));
        elseif browser.sessionData.timePoints(browser.currentFrame) > xLim(2)
            xLimNew = xLim + (browser.sessionData.timePoints(browser.currentFrame) - xLim(2));
        else
        	xLimNew = xLim;
        end
        
        if diff(xLimNew) > browser.sessionData.timePoints(end)
            xLimNew = [0, browser.sessionData.timePoints(end)];
        elseif xLimNew(1) < 0
            xLimNew = xLimNew - xLimNew(1);
        elseif xLimNew(2) > browser.sessionData.timePoints(end)
            xLimNew = xLimNew - (xLimNew(2) - browser.sessionData.timePoints(end));
        end
        
        set(browser.axCellResponse,'XLim',xLimNew)
        set(browser.axBodyMovementPlot,'XLim',xLimNew)
        set(browser.axPupilActivityPlot,'XLim',xLimNew)
        set(browser.axFrameMovementPlot,'XLim',xLimNew)
        set(browser.axFrameMovementPlot, 'XLim', xLimNew)  
        set(browser.axLickResponses, 'XLim', xLimNew)

        xLim = get(browser.axPopulationResponse, 'XLim');

        if browser.currentFrame < xLim(1)
            xLimNew = xLim + (browser.currentFrame - xLim(1));
        elseif browser.currentFrame > xLim(2)
            xLimNew = xLim + (browser.currentFrame - xLim(2));
        else
        	xLimNew = xLim;
        end
        
        if diff(xLimNew) > browser.sessionData.nFrames(end)
            xLimNew = [0, browser.sessionData.nFrames(end)];
        elseif xLimNew(1) < 0
            xLimNew = xLimNew - xLimNew(1);
        elseif xLimNew(2) > browser.sessionData.nFrames(end)
            xLimNew = xLimNew - (xLimNew(2) - browser.sessionData.nFrames(end));
        end

        set(browser.axPopulationResponse, 'XLim', xLimNew)
        
    end
    
    
    function [mouseOrientation] = makeAnimationFrame(browser)
        % Create a frame showing the mouses orientation within the arena
        frameNo = browser.currentFrame;
        blockNo = browser.currentBlock;
        
        imMouse = imread('image_mouse.tif');
        imArena = imread('image_arena.tif');
        
        if isempty(browser.sessionData)
            mouseAngle = 0;
        else 
            mouseAngle = browser.sessionData.stagePositions(blockNo, frameNo);
        end
        arenaAngle = 0;
        
        tmpMouse = imrotate(imMouse, mouseAngle, 'bilinear', 'crop');
        tmpArena = imrotate(imArena, arenaAngle, 'bilinear', 'crop');
        mouseOrientation = tmpMouse + tmpArena;
    end
    
    
    function patchAnglesPlot(browser, command)
        % Add patches to the plot with roi activity showing direction of
        % mouse. Command: 'Patch Angles' || 'Unpatch Angles'
        
        
        switch command
            case 'Patch Angles'
                ylim = get(browser.axCellResponse, 'YLim');
                set(browser.axCellResponse, 'YLim', [0,4])
                patches = sessionBrowser.patchAngles_v2(browser.axCellResponse, ...
                            browser.sessionData.anglesRW(browser.currentBlock, :), ...
                            browser.sessionData.rotating(browser.currentBlock, :));
                set(browser.axCellResponse, 'YLim', ylim)   
            case 'Unpatch Angles'
                patches = findobj(browser.axCellResponse, 'Type', 'patch');
                delete(patches)
                clear patches
%                 patches = findobj(browser.axArenaAnimation, 'Type', 'patch');
%                 lines = findobj(browser.axArenaAnimation, 'Type', 'Line');
%                 delete(patches)
%                 delete(lines)
%                 clear patches lines
                
        end      
    end

    
    function exportVideo(browser, ~, ~)
    % Export video. Currently not active.
        sessionFolder = getSessionFolder(browser .sessionID);
        videoName = ['SummaryVideo-' browser.sessionID '-Block' ...
                     num2str(browser.currentBlock, '%03d') '.avi'];
        %Todo: Hide Buttons and sliders
        %Todo: Show Title
                
        % Filepath to save the movie
        video = VideoWriter(fullfile(sessionFolder, videoName));

        video.FrameRate = 30;
        video.open();
        
        browser.currentFrame = 1;
        for i = 1 : 500%browser.sessionData.nFrames
            browser = updateFrames(browser);
            browser = updateFrameMarkers(browser);
            F = getframe(gcf);
            frame = frame2im(F);
            writeVideo(video, frame)
            browser.currentFrame = browser.currentFrame + 1;
        end
        set(browser.frameslider, 'Value', browser.currentFrame )
        video.close()
    end
        
    
    function browser = changeGuiMode(browser, source, ~)
    % Change between gui modes, showing plots only in one mode and plots plus videos in the other.    
        switch source.String
            case 'Show Plots Only'
                set(browser.btnChangeGuiMode, 'String', 'Show Plots And Videos')
                browser.reorderGuiPlotsOnly();
            case 'Show Plots And Videos'
                set(browser.btnChangeGuiMode, 'String', 'Show Plots Only')
                browser.reorderGUI();
        end
        
        
    end
    
    
    
end


methods (Static)
    maskArenaAnimation(ax)
    anglePatchLegend(ax)
    patchAngles(ax, polar, rotating, makeArrow, ax2)
    patches = patchAngles_v2(ax, polar, rotating)
end


end

classdef mouseBrowser < handle
%mouseBrowser A GUI for browsing through mouse metadata.
    %   mouseBrowser; opens a GUI for organizing and browsing mouse information
    %
    %   Usage:
    %       - Set up a path to save a mouse inventory in pipeline settings.
    %       - Open mousebrowser and add or edit information about mice.
    %
    %   Extra features:
    %       - open sessions in sessionBrowser.
    %
    %   Requirements:
    %       - mouse and session class definitions
    %       - loadExpInv, saveExpInv, loadMouseInv, saveMouseInv
    %
    %   See also mouse

% todo
% disable save and edit if mouse is not selected.

properties (Constant)
    % Select the properties of mouse metadata object to show up in the different panels of
    % the GUI.
    
    % Properties of the mouse class that will show up in the mouse information UI Panel
    mouseInfoProps = {'mouseNo', 'headbarID', 'age', 'mouseStrain', 'sex', 'dateofBirth'}
    
    % Properties of the mouse class that will show up in the animal facility information UI Panel
    animalFacilityInfoProps = {'animalNumber', 'cageNumber', 'cageRoom', 'cageLocation'}
    
    % Properties of the mouse class that will show up in the surgery information UI Panel
    surgeryInfoProps = {'experimenter', 'surgeryDay', 'surgeryProtocol', 'injectedVirus', ...
                     'nInjections', 'hemisphere', 'injectionAngle', 'injectionDepth', ...
                     'injectionVolumes'}
                 
    % Properties of the mouse class that will show up in the notebook UI Panel
    notebookProps = {'commentsSurgery', 'commentsHabituation', 'commentsImaging'}
    
end


properties
    
    % Figure and figure settings
        
    fig                             % GUI Figure Window
    
    % UI Panels
    
    imPanel                         % UI panel for showing image of brain surface
    mPanel                          % UI panel for showing information about mouse
    afPanel                         % UI panel for showing information about mouse from the animal facility
    surgeryPanel                    % UI panel for showing information about surgery
    
    % UI Controls
    
    mouseInfoFields                 % List of UI edit boxes (input fields) in mouse UI panel 
    animalFacilityInfoFields        % List of UI edit boxes (input fields) in animalFacility UI panel                     
    surgeryInfoFields               % List of UI edit boxes (input fields) in surgery UI panel 
    notebookFields                  % List of UI edit boxes (input fields) in notebook UI panel 
    mousepopup                      % Mouse popupmenu to select a mouse from the database.                 

    
    % Ax and image
    
    axBrainSurface                  % Axes to show the image of the brain surface
    imBrainSurface                  % Image object to hold the displayed brain surface image
    imageScaleFactor                % scaleFactor used to calculate image coordinates if image is resized.
    xPos                            % Real world x coordinate when mouse is over image
    yPos                            % Real world y coordinate when mouse is over image
    
    % Buttons
    
    btnShowImagingLocations         % Button to show or hide imaging locations in brain surface image
    btnShowInjectionSpots           % Button to show or hide virus injection spots in brain surface image
    btnAddNewMouse                  % Button to add a new mouse to database
    btnEditMouse                    % Button to edit selected mouse  and save to database
    btnCancel                       % Button to cancel editing or adding mouse
    btnEuthanize                    % Button to mark animal as dead
    btnSaveLabbook                  % Button to save info to a labbook in pdf (requires laTeX)
    btnSaveExcel                    % Button to save info to an excel file
    btnManageSessions               % Not implemented
    btnOpenSessionBrowser           % Button to open session in sessionBrowser
    
    % Experiment table
    
    expTable                        % Table showing information about sessions
    wrTable                         % Table showing information about water restriction
    tabgroup                        % Tabgroup panel to show notebooks from surgery/imaging/training
    
    % Mouse List
    
    mouseInv                        % Mouse database
    mouseObj                        % Current mouse metadata object
    expInv                          % Experiment database
        
    sessionID                       % SessionID which is currently selected in list of experiments
    sBrowser                        % Instance of the sessionBrowser GUI

end

    
properties (Access = 'private', Hidden = true)  
    
    % UI Panel Positions
    panelPositions = containers.Map;    % Dictionary with pixel positions of UI panels

    % Java controls
    jScrollers = containers.Map         % Dictionary with scrollers belonging to panels
    scrollLastValue = containers.Map    % Dictionary with last scroller value for panels
    
end


methods (Access = 'private', Hidden = true)
  
    
    function obj = initTopPanel( obj, panelSize, panelLoc )
        %initTopPanel Create the top panel of the gui and add relevant uicontrols.

        % Create the ui panel
        topPanel = uipanel('Title', 'Status & Controls', ...
                           'FontSize', 13, ...
                           'Position', [panelLoc, panelSize]);         

        % Create a popup for selecting mice.
        obj.mousepopup = uicontrol('Parent', topPanel, 'Style', 'popup', ...
                            'String', vertcat({'Select mouse'}, obj.mouseInv(2:end, 1)), ...
                            'Value', 1, ...
                            'units', 'normalized', 'Position', [0.01, 0.65, 0.1, 0.05], ...
                            'Callback', @obj.loadMouse);

        % Create a button for editing info. This button will change the state of
        % the gui to edit mode, where fields can be edited. 
        btnPos = [0.14, 0.25, 0.07, 0.5];
        obj.btnEditMouse = uicontrol('Parent', topPanel, 'Style', 'pushbutton', ...
                            'String', 'Edit Mouse Info', ...
                            'units', 'normalized', 'Position', btnPos, ...
                            'Callback', @obj.editMouse);

        % Create a button for adding a new mouse. This button will reset/clear all
        % fields and set the gui to edit mode.
        btnPos(1) = btnPos(1) + 0.09;
        obj.btnAddNewMouse = uicontrol('Parent', topPanel, 'Style', 'pushbutton', ...
                            'String', 'Add New Mouse', ...
                            'units', 'normalized', 'Position', btnPos, ...
                            'Callback', @obj.addMouse);

        % Create a button for saving changes. This button will reset gui to normal mode
        btnPos(1) = btnPos(1) + 0.09;
        obj.btnCancel = uicontrol('Parent', topPanel, 'Style', 'pushbutton', ...
                            'String', 'Cancel', ...
                            'units', 'normalized', 'Position', btnPos, ...
                            'Enable', 'off', 'Callback', @obj.cancel);

        btnPos(1) = btnPos(1) + 0.11;        
        obj.btnEuthanize = uicontrol('Parent', topPanel, 'Style', 'pushbutton', ...
                            'String', 'Kill Mouse', ...
                            'units', 'normalized', 'Position', btnPos, ...
                            'Callback', @obj.euthanize);
        
        btnPos(1) = btnPos(1) + 0.1;        
        obj.btnSaveLabbook = uicontrol('Parent', topPanel, 'Style', 'pushbutton', ...
                            'String', 'Update Labbook', ...
                            'units', 'normalized', 'Position', btnPos, ...
                            'Callback', @obj.updateLabbook);   
        
        btnPos(1) = btnPos(1) + 0.09;  
        obj.btnSaveExcel = uicontrol('Parent', topPanel, 'Style', 'pushbutton', ...
                            'String', 'Save to Excel Sheet', ...
                            'units', 'normalized', 'Position', btnPos, ...
                            'Callback', @xlwriteMouseInv);

        btnPos(1) = btnPos(1) + 0.19;
        obj.btnManageSessions = uicontrol('Parent', topPanel, 'Style', 'pushbutton', ...
                            'String', 'Manage Sessions', ...
                            'units', 'normalized', 'Position', btnPos, ...
                            'Enable', 'off', ...
                            'Callback', @obj.manageSessions);

        btnPos(1) = btnPos(1) + 0.09;
        obj.btnOpenSessionBrowser = uicontrol('Parent', topPanel, 'Style', 'pushbutton', ...
                            'String', 'Open in SessionBrowser', ...
                            'units', 'normalized', 'Position', btnPos, ...
                            'Enable', 'off', ...
                            'Callback', @obj.openSessionBrowser);

    end

    function obj = initImagePanel(obj, panelSize, panelLoc)
        %initImagePanel Create the image panel of the gui and add relevant axes and uicontrols.

        % Calculate panel aspect ratio to properly size panel objects
        figsize = get(obj.fig, 'Position');
        aspectRatio = figsize(3)/figsize(4);

        % Create uipanel
        obj.imPanel = uipanel('Title','Brain Surface', 'FontSize', 13, ...
                          'Position', [panelLoc, panelSize]);
        
        set(obj.imPanel, 'units', 'pixel')
        panelPos = get(obj.imPanel, 'Position');
        panelAR = (panelPos(3) / panelPos(4)) * 1.0268; % Dont know why I need this factor
        set(obj.imPanel, 'units', 'normalized')

        % Add ax to the image panel. Occupies 0.9 units of panel in height.
        obj.axBrainSurface = axes('Parent', obj.imPanel, ...
                               'Position', [0.05/panelAR, 0.05, 0.9/panelAR, 0.9], ...
                               'xtick',[], 'ytick',[]);

        % Example to convert px to ax size (if necessary):
        %axSize = 512/figsize(3) * [1, aspectRatio];

        % Add buttons to the image panel
        btnSize = [0.2, 0.06];
        btnLoc = [0.75, 0.95-btnSize(2)]; % Place buttons right of obj.imPanel and start from top

        % Button 1: Load Image
        btnPos = [btnLoc , btnSize];
        uicontrol('Parent', obj.imPanel, 'Style', 'pushbutton', ...
                  'String', 'Load Image...', ...
                  'units', 'normalized', 'Position', btnPos, ...
                  'Callback', @obj.loadImage);

        % Button 2: Add injection spots
        btnPos(2) = btnPos(2) - btnSize(2)*1.5;
        uicontrol('Parent', obj.imPanel, 'Style', 'pushbutton',  ...
                  'String', 'Add Injection Spots', ...
                  'units', 'normalized', 'Position', btnPos, ...
                  'Callback', @obj.addInjectionSpots);

        % Button 3: Show injection spots
        btnPos(2) = btnPos(2) - btnSize(2)*1.5;
        obj.btnShowInjectionSpots = uicontrol('Parent', obj.imPanel, 'Style', 'pushbutton', ...
                  'String', 'Show Injection Spots', ...
                  'units', 'normalized', 'Position', btnPos, ...
                  'Callback', @obj.showInjectionSpots);

        % Button 4: Add imaging locations                                  
        btnPos(2) = btnPos(2) - btnSize(2)*1.5;
        uicontrol('Parent', obj.imPanel, 'Style', 'pushbutton', ...
                  'String', 'Add Imaging Locations', ...
                  'units', 'normalized', 'Position', btnPos, ...
                  'Callback', @obj.addImagingLoc);

        % Button 5: Show imaging locations  
        btnPos(2) = btnPos(2) - btnSize(2)*1.5;
        obj.btnShowImagingLocations = uicontrol('Parent', obj.imPanel, 'Style', 'pushbutton', ...
                  'String', 'Show Imaging Locations', ...
                  'units', 'normalized', 'Position', btnPos, ...
                  'Callback', @obj.showImagingLoc);

        % Add subpanel for displaying injection info. 
        subPanel = uipanel('Parent', obj.imPanel, 'Title','Coordinates',...
                           'Position', [0.75, btnPos(2) - btnSize(2)*1.5 - 0.3, 0.2, 0.3]);

        obj.xPos = uicontrol('Parent', subPanel, 'Style', 'text', ...
                  'String', 'X:', 'FontSize', 12, ...
                  'units', 'normalized', 'Position', [0.2, 0.7, 0.6, 0.2], ...
                  'HorizontalAlignment', 'left' );

        obj.yPos = uicontrol('Parent', subPanel, 'Style', 'text', ...
                  'String', 'Y:', 'FontSize', 12, ...
                  'units', 'normalized', 'Position', [0.2, 0.4, 0.6, 0.2], ...
                  'HorizontalAlignment', 'left' );

    end

    function obj = initExperimentPanel(obj, panelSize, panelLoc)
    %initExperimentPanel Create the experiment panel of the gui and add relevant axes and uicontrols.

        % Calculate panel aspect ratio to properly size panel objects
        figsize = get(obj.fig, 'Position');
        aspectRatio = figsize(3)/figsize(4);
        panelAR = aspectRatio / panelSize(2) * panelSize(1); 

        % Create the uipanel
        expPanel = uipanel('Title','List of experiments',...
                                   'FontSize', 13, ...
                                   'Position', [panelLoc, panelSize]);

        % Create table for experiments
        obj.expTable = uitable('Parent', expPanel, ...
                               'units', 'normalized', ...
                               'Columnname', {'SessionID','Protocol','ImLoc','ImDepth'}, ...
                               'ColumnWidth', {150, 240, 'auto', 'auto'}, ...
                               'Position', [0.05, 0.1, 0.9, 0.8], ...
                               'CellSelectionCallback', @obj.sessionSelected);

    end

    function obj = initMousePanel(obj, panelSize, panelLoc)
    %initMousePanel Create the mouse panel of the gui and add relevant axes and uicontrols.

        % Create the uipanel
        obj.mPanel = uipanel('Title','Mouse Information',...
                                      'FontSize', 13,...
                                      'Position', [panelLoc, panelSize]);
        
        set(obj.mPanel, 'units', 'pixel')
        obj.panelPositions('mPanel') = get(obj.mPanel, 'Position');
        set(obj.mPanel, 'units', 'normalized')                          
                                  
        % Create input/display fields
        for i = 1:length(obj.mouseInfoProps)
            obj.mouseInfoFields{i} = obj.makeNewField(obj.mPanel, obj.mouseInfoProps{i} );
        end
        
        obj.createScrollBar('mPanel')
        
    end
    
    function obj = initWrPanel(obj, panelSize, panelLoc)
        %initWrPanel Create the Wr panel (water restriction info) of the gui and add relevant 
        % axes and uicontrols.

        % Create the uipanel
        wrPanel = uipanel('Title','Water Restriction',...
                                  'FontSize', 13,...
                                  'Position', [panelLoc, panelSize]);

        % Create table for water restricton info
        obj.wrTable = uitable('Parent', wrPanel, ...
                              'units', 'normalized', ...
                              'Columnname', {'date','weight','health score', 'ml given', 'training'}, ...
                              'ColumnWidth', {'auto', 72, 'auto', 'auto', 'auto'}, ...
                              'ColumnEditable', true, ...
                              'Data', cell(10,3),...
                              'Position', [0.05, 0.1, 0.9, 0.8]);

    end
    
    function obj = initTrPanel(obj, panelSize, panelLoc)
        %initTrPanel Create the Tr panel (training info) of the gui and add relevant axes/uicontrols.

        % Create the uipanel
        trPanel = uipanel('Title','Training Summary',...
                          'FontSize', 13,...
                          'Position', [panelLoc, panelSize]);

    end  
    
    function obj = initCmntPanel(obj, panelSize, panelLoc)
        %initCmntPanel Create the comment of the gui and add relevant axes/uicontrols.

        % Create the uipanel
        cmntPanel = uipanel('Title','Notebook',...
                                    'FontSize', 13,...
                                    'Position', [panelLoc, panelSize]);

        % Create table for water restricton info
        obj.tabgroup = uitabgroup('Parent', cmntPanel, 'Position', [0.05, 0.05, 0.9, 0.95]);

        for i = 1:numel(obj.notebookProps)
            tab = uitab('Parent', obj.tabgroup, 'Title', mouse.get(obj.notebookProps{i}, 'label'));
            obj.notebookFields{i} = uicontrol('Parent', tab, 'Style', 'edit', ...
                                'String', '', 'Max', 3, 'Min', 1, ...
                                'units', 'normalized', 'Position', [0,0,1,1], ...
                                'Fontsize', 12, 'HorizontalAlignment', 'left', ...
                                'Enable', 'inactive', ...
                                'BackgroundColor', [0.97,0.97,0.97]);
        end
%         tab1 = uitab('Parent', obj.tabgroup, 'Title', 'Surgery Notes');
%         obj.notebookFields{1} = uicontrol('Parent', tab1, 'Style', 'edit', ...
%                                 'String', '', 'Max', 3, 'Min', 1, ...
%                                 'units', 'normalized', 'Position', [0,0,1,1], ...
%                                 'Fontsize', 12, 'HorizontalAlignment', 'left', ...
%                                 'Enable', 'inactive', ...
%                                 'BackgroundColor', [0.97,0.97,0.97]);
% 
% 
%         tab2 = uitab('Parent', obj.tabgroup, 'Title', 'Training Notes');
%         obj.notebookFields{2} = uicontrol('Parent', tab2, 'Style', 'edit', ...
%                                 'String', '', 'Max', 3, 'Min', 1, ...
%                                 'units', 'normalized', 'Position', [0,0,1,1], ...
%                                 'Fontsize', 12, 'HorizontalAlignment', 'left', ...
%                                 'Enable', 'inactive', ...
%                                 'BackgroundColor', [0.97,0.97,0.97]);
% 
% 
%         tab3 = uitab('Parent', obj.tabgroup, 'Title', 'Imaging Notes');
%         obj.notebookFields{3} = uicontrol('Parent', tab3, 'Style', 'edit', ...
%                                 'String', '', 'Max', 3, 'Min', 1, ...
%                                 'units', 'normalized', 'Position', [0,0,1,1], ...
%                                 'Fontsize', 12, 'HorizontalAlignment', 'left', ...
%                                 'Enable', 'inactive', ...
%                                 'BackgroundColor', [0.97,0.97,0.97]);
    end

    function obj = initAfPanel(obj, panelSize, panelLoc)
    %initAFPanel Create the AF panel (animal facility info) of the gui and add relevant axes/uicontrols.

        % Create the panel
        obj.afPanel = uipanel('Title','Animal Facility Information',...
                          'FontSize', 13,...
                          'Position', [panelLoc, panelSize]);

        set(obj.afPanel, 'units', 'pixel')
        obj.panelPositions('afPanel') = get(obj.afPanel, 'Position');
        set(obj.afPanel, 'units', 'normalized')   
                      
        % Create input fields
        for i = 1:length(obj.animalFacilityInfoProps)
            obj.animalFacilityInfoFields{i} = obj.makeNewField(obj.afPanel, obj.animalFacilityInfoProps{i} );
        end
        
        obj.createScrollBar('afPanel')

    end
    
    function obj = initSurgeryPanel(obj, panelSize, panelLoc)
    %initSurgeryPanel Create the Surgery (info) panel of the gui and add relevant axes/uicontrols.

        % Create the uipanel
        obj.surgeryPanel = uipanel('Title','Surgery Information',...
                               'FontSize', 13,...
                               'Position', [panelLoc panelSize]);
        
        set(obj.surgeryPanel, 'units', 'pixel')
        obj.panelPositions('surgeryPanel') = get(obj.surgeryPanel, 'Position');
        set(obj.surgeryPanel, 'units', 'normalized')   
                      
        % Create input fields
        for i = 1:length(obj.surgeryInfoProps)
            obj.surgeryInfoFields{i} = obj.makeNewField(obj.surgeryPanel, obj.surgeryInfoProps{i} );
        end
        
        obj.createScrollBar('surgeryPanel')

    end
    
    function obj = createScrollBar(obj, panel)     
    % Creates a scrollbar on a panel if all the fields does not fit on the panel
    
        % Determine position of bottom most field
        fields = findobj(obj.(panel), 'Style', 'edit');
        fieldPos1 = get(fields(1), 'Position'); % Last field added is the first field in the list
        
        if fieldPos1(2) < 0
            % Calculate range and y-positions of scrollbar
            fieldPos2 = get(fields(2), 'Position');
            yPad = fieldPos2(2) - fieldPos1(4) - fieldPos1(2);
            panelHeight = 1 + yPad + abs(fieldPos1(2));
            fieldPosTop = get(fields(end), 'Position');
            topMargin = 1 - fieldPosTop(2) - fieldPosTop(4);
        
            % Add a java scrollbar
            jScrollbar = javaObjectEDT('javax.swing.JScrollBar');
            jScrollbar.setOrientation(jScrollbar.VERTICAL);                          
            [obj.jScrollers(panel), jScrollContainer] = javacomponent(jScrollbar);
            
            % Add a callback for value changes
            obj.jScrollers(panel) = handle(obj.jScrollers(panel), 'CallbackProperties');
            set(obj.jScrollers(panel), 'AdjustmentValueChangedCallback', {@obj.scrollValueChange, panel});
            
            % Set scrollbar range and positions
            set(obj.jScrollers(panel), 'maximum',  panelHeight * 100, 'VisibleAmount', 100);
            scrollPos = [0.95, yPad, 0.05, 1-topMargin-yPad]; %% need y coordinates...
            set(jScrollContainer, 'Parent', obj.(panel), 'units', 'normalized', 'Position', scrollPos)
            obj.scrollLastValue(panel) = get(obj.jScrollers(panel), 'value');
        end
        
    end 
    
    function obj = scrollValueChange(obj, scroller, ~, panel)        
    % Callback for value change on scroller belonging to panel. Scrolls up or down.
        
        delta = scroller.value - obj.scrollLastValue(panel);
        obj.scrollLastValue(panel) = scroller.value;
        
        % Get editboxes and texts of panel
        editfields = findobj(obj.(panel), 'Style', 'edit');
        textfields = findobj(obj.(panel), 'Style', 'text');
        
        % Move fields in panel.
        for i = 1:length(editfields)
            fieldPos = get(editfields(i), 'Position');
            fieldPos(2) = fieldPos(2) + (delta)/100;
            set(editfields(i), 'Position', fieldPos)
            fieldPos = get(textfields(i), 'Position');
            fieldPos(2) = fieldPos(2) + (delta)/100;
            set(textfields(i), 'Position', fieldPos)
        end
        
    end
    
end


methods
        
    
    function obj = mouseBrowser
    % GUI Constructor. Creates all panels, axes and uicontrols.
    
        % Set up figure. Default is to cover the whole screen
        screenSize = get(0, 'Screensize');
        
        obj.fig = figure(...
                      'Name', 'MouseBrowse', ...
                      'NumberTitle', 'off', ...
                      'Visible','off', ...
                      'Position', screenSize, ...
                      'WindowButtonMotionFcn', {@obj.mouseOver}, ...
                      'WindowScrollWheelFcn', @obj.scrollCallback);
                  
        % Make figure visible to get the right figure size when setting up.
        obj.fig.Visible = 'On';
        set(obj.fig, 'menubar', 'none');
        pause(0.5)
        
        % Activate callback function for resizing panels when figure changes size
        set(obj.fig, 'SizeChangedFcn', @obj.figsizeChanged );
        
        % Make cell arrays to keep fields (uicontrol editbox) in
        obj.mouseInfoFields = cell(size(obj.mouseInfoProps));
        obj.animalFacilityInfoFields = cell(size(obj.animalFacilityInfoProps));
        obj.surgeryInfoFields = cell(size(obj.surgeryInfoProps));
        obj.notebookFields = cell(size(obj.notebookProps));
        
        figsize = get(obj.fig, 'Position');
        aspectRatio = figsize(3)/figsize(4);
        
        % Specify margins (for figure window) and padding (between figure objects)
        margins = [0.04, 0.04, 0.05, 0.03];  %left, right, bottom, top
        padding = 0.025 * [1, aspectRatio];  %sides, top/bottom
        
        % Load mouse and experiment inventory
        obj.mouseInv = loadMouseInv();
        obj.expInv = loadExpInv();
      
        % Create top panel with buttons and controls. Spans the whole 
        % width of the gui. Height arbitrarily chosen to be 0.06.
        topPanelSize = [1 - margins(1) - margins(2), 0.06];
        topPanelLoc = [margins(1), 1 - margins(4) - topPanelSize(2)];
        obj.initTopPanel(topPanelSize, topPanelLoc);

        % Create a panel for image of brain surface
        imPanelSize = [0.38, 0.5]; % Arbitrary size
        imPanelLoc = [1 - margins(2) - imPanelSize(1), topPanelLoc(2) - padding(2) - imPanelSize(2)]; % Place rightmost and underneath top panel
        obj.initImagePanel(imPanelSize, imPanelLoc);
        
        % Create panel to list experiments
        expPanelSize = [imPanelSize(1), imPanelLoc(2) - padding(2) - margins(3)];
        expPanelLoc = [imPanelLoc(1), margins(3)];
        obj.initExperimentPanel(expPanelSize, expPanelLoc);

        % Create panel for mouse info
        mPanelSize = [.21 .242];
        mPanelLoc = [margins(1), topPanelLoc(2) - padding(2) - mPanelSize(2)];
        obj.initMousePanel(mPanelSize, mPanelLoc);
        
        % Create panel for water restriction data
        wrPanelSize = [expPanelLoc(1) - padding(1)*2 - mPanelSize(1) - margins(1), 0.2];
        wrPanelLoc = [mPanelLoc(1) + mPanelSize(1) + padding(1), topPanelLoc(2) - padding(2) - wrPanelSize(2)];
        obj.initWrPanel(wrPanelSize, wrPanelLoc);
        
        % Create panel for training/habituation
        trPanelSize = [expPanelLoc(1) - padding(1)*2 - mPanelSize(1) - margins(1), 0.3 ];
        trPanelLoc = [mPanelLoc(1) + mPanelSize(1) + padding(1), wrPanelLoc(2) - padding(2) - trPanelSize(2)];
        obj.initTrPanel(trPanelSize, trPanelLoc);
        
        % Create panel for comments
        cmntPanelSize = [expPanelLoc(1) - padding(1)*2 - mPanelSize(1) - margins(1), ...
        trPanelLoc(2) - padding(2) - margins(3)];
        cmntPanelLoc = [wrPanelLoc(1), margins(3)];
        obj.initCmntPanel(cmntPanelSize, cmntPanelLoc);
 
        % Create panel for animal facility information
        afPanelSize = [mPanelSize(1) .145];
        afPanelLoc = [margins(1), mPanelLoc(2) - padding(2) - afPanelSize(2)];
        obj.initAfPanel(afPanelSize, afPanelLoc);

        % Create panel for surgery information
        sPanelSize = [mPanelSize(1), afPanelLoc(2) - padding(2) - margins(3)];
        sPanelLoc = [margins(1), afPanelLoc(2) - padding(2) - sPanelSize(2)];
        obj.initSurgeryPanel(sPanelSize, sPanelLoc);
           
    end
    
    
    function obj = figsizeChanged(obj, ~, ~)
    % Resize position of image ax when figure size changes.
    
        % Relocate image axes
        set(obj.imPanel, 'units', 'pixels')
        imPanelPos = get(obj.imPanel, 'Position');
        set(obj.imPanel, 'units', 'normalized')

        axPos = get(obj.axBrainSurface, 'Position');
        axPos(2) = (imPanelPos(4) - axPos(4)) / 2;
        set(obj.axBrainSurface, 'Position', axPos)

    end
    
    
    function obj = scrollCallback(obj, ~, event)
    % Callback for mousescroll. Controls sliders in panels.
    
        i = event.VerticalScrollCount;
        mousePoint = get(obj.fig, 'CurrentPoint');
        x = mousePoint(1); y = mousePoint(2);
        
        for panel = {'mPanel', 'afPanel', 'surgeryPanel'}
            if isKey(obj.jScrollers, panel{:})
                panelPos = obj.panelPositions(panel{:});
                panelLim = [panelPos(1:2), panelPos(1:2) + panelPos(3:4)];
         
                if x > panelLim(1) &&  x < panelLim(3) && y > panelLim(2) &&  y < panelLim(4)
                        scrollvalue = get(obj.jScrollers(panel{:}), 'value');
                        set(obj.jScrollers(panel{:}), 'value', scrollvalue + i)
                end
            end
        end
        
        
    end
    
    
    function obj = loadMouse(obj, source, ~)
    % Load a mouse metadata object based on selection in popupmenu
    
        if ~isempty(source)
            mouseId = source.String{source.Value}; % Selected string from menu
            if source.Value == 1; return; end
            mouseNo = str2double(mouseId(end-2:end));
        else % Use number from input field
            fieldIdx = find(strcmp(obj.mouseInfoProps, 'mouseNo'));
            mouseNo = str2double(get(obj.mouseInfoFields{fieldIdx}, 'String'));
            mouseId = ['mouse', num2str(mouseNo, '%03d')];
        end

        obj.mouseObj = mouse(mouseNo);
        
        % Concatenate all mouse properties and corresponding ui control edit boxes.
        mouseProps = cat(2, obj.mouseInfoProps, obj.animalFacilityInfoProps, ...
                            obj.surgeryInfoProps, obj.notebookProps);
        infoFields = cat(2, obj.mouseInfoFields, obj.animalFacilityInfoFields, ...
                            obj.surgeryInfoFields, obj.notebookFields);

        % Add mouse properties from mouse metadata obj to edit boxes.
        for f = 1:length(mouseProps)
            set(infoFields{f}, 'String', obj.mouseObj.(mouseProps{f}));
        end
        
        % Load brain surface image
        obj.displaySurfaceImage();

        % Add sessions which are present for selected mouse
        mId = strrep(mouseId, 'ouse', ''); % shorten mouse001 to m001
        mouseSessions = find(strncmp( obj.expInv(2:end, 1), mId, 4 ));
        mouseSessions = arrayfun(@(x) obj.expInv(x+1, :), mouseSessions, 'un', 0);
        
        % Fill out experiment table
        obj.expTable.Data = {};
        if ~isempty(mouseSessions)

            % Filter out sessions that are not analyzed.
            analyzedSessions = arrayfun(@(x) mouseSessions{x}{1,2}.isAnalyzed, ...
                                        1:length(mouseSessions), 'uni', 0);

            mouseSessions = arrayfun(@(x) mouseSessions{x}{1, 1}, find(cell2mat(analyzedSessions)), 'uni', 0);

            for i = 1:length(mouseSessions)
                idx = find(strcmp(obj.expInv(2:end, 1), mouseSessions{i})) + 1;
                session = obj.expInv(idx, 2);
                obj.expTable.Data = vertcat(obj.expTable.Data, {session{1,1}.sessionID, session{1,1}.protocol, session{1,1}.imLocation, round(session{1,1}.imDepth)} );
            end
            
        end
        
        % Change buttons
        if strcmp(get(obj.btnShowInjectionSpots, 'String'), 'Hide Injection Spots')
            set(obj.btnShowInjectionSpots, 'String', 'Show Injection Spots')
        end
        
        if strcmp(get(obj.btnShowImagingLocations, 'String'), 'Hide Imaging Locations')
            set(obj.btnShowImagingLocations, 'String', 'Show Imaging Locations')
        end
        
    end
    
    
    function obj = updateMouseInfo(obj)
    % Change info of mouse object based on text in fields.
        
        % Concatenate all mouse properties (excluding age) and corresponding ui controls
        inputProps = cat(2, obj.mouseInfoProps(~strcmp(obj.mouseInfoProps, 'age')), ...
                obj.animalFacilityInfoProps, obj.surgeryInfoProps, obj.notebookProps);
        inputFields = cat(2, obj.mouseInfoFields(~strcmp(obj.mouseInfoProps, 'age')), ...
                obj.animalFacilityInfoFields, obj.surgeryInfoFields, obj.notebookFields);

        % Update mouse properties
        for f = 1:length(inputProps)
            obj.mouseObj.(inputProps{f}) = get(inputFields{f}, 'String');
        end
        
        % Save edited mouseobj to database
        savetoDB(obj.mouseObj);
        
        % necessary????
        % Reload mouseInv.
        obj.mouseInv = loadMouseInv();
        set(obj.mousepopup, 'String', vertcat({'Select mouse'}, obj.mouseInv(2:end, 1)), ...
            'Value', 1)
        % Todo: Set value to current mouse...

    end
    
    
    function obj = showImagingLoc(obj, source, ~)
    % Button callback to show/hide imaging location in brain surface image.
    
    % Todo, should plot it instead of drawing it into image.
    
    btnState = source.String;
        
        switch btnState
            case 'Show Imaging Locations'
                set(obj.btnShowImagingLocations, 'String', 'Hide Imaging Locations')
        
                if ~isempty(obj.imBrainSurface) && ~isempty(obj.mouseObj.nImagedLocations)
                    temp_im = obj.imBrainSurface.CData;
                    nLocations = obj.mouseObj.nImagedLocations;
                    if ischar(nLocations); nLocations = str2double(nLocations); end
                    for h = 1:nLocations
                        rect = obj.mouseObj.imagingLocations(h, :) * obj.imageScaleFactor;
                        textX = rect(1)+rect(3)+10;
                        textY = rect(2)+rect(4)/3;

                        temp_im = insertShape(temp_im, 'rectangle', rect, ...
                                                     'color', 'white');
                        temp_im = insertText(temp_im, [textX, textY], ...
                                                   [' Loc. ' num2str(h)], 'FontSize', 18,  ...
                                                   'TextColor', 'white', 'BoxOpacity', 0);
                    end
                    obj.imBrainSurface.CData = temp_im;

                end
                
                injlocBtnState = get(obj.btnShowInjectionSpots, 'String');
                if strcmp(injlocBtnState, 'Hide Injection Spots')
                    set(obj.btnShowInjectionSpots, 'String', 'Show Injection Spots')
                end
                
            case 'Hide Imaging Locations'
                set(obj.btnShowImagingLocations, 'String', 'Show Imaging Locations')
                
                if ~isempty(obj.mouseObj) && ~isempty(obj.imBrainSurface)
                    im = imresize(obj.mouseObj.brainSurface, obj.imageScaleFactor);
                    obj.imBrainSurface = imshow(im, 'Parent', obj.axBrainSurface, 'InitialMagnification', 'fit');
                end
        end
    end
    
    
    function obj = showInjectionSpots(obj, source, ~)
    % Button callback to show/hide virus injection spots in brain surface image.
    
        btnState = source.String;
        
        switch btnState
            case 'Show Injection Spots'
                set(obj.btnShowInjectionSpots, 'String', 'Hide Injection Spots')
        
                if ~isempty(obj.imBrainSurface) && ~isempty(obj.mouseObj.nInjections)
                    injections_im = obj.imBrainSurface.CData;
                    nInj = obj.mouseObj.nInjections;
                    if ischar(nInj); nInj = str2double(nInj); end
                    for h = 1:nInj
                        x = obj.mouseObj.injectionCoordsIM(h, 1) * obj.imageScaleFactor;
                        y = obj.mouseObj.injectionCoordsIM(h, 2) * obj.imageScaleFactor;

                        injections_im = insertMarker(injections_im, [x, y], 'x', 'size', 3, ...
                                                     'color', 'white');
                        injections_im = insertText(injections_im, [x+15, y-14], ...
                                                   [' Inj. ' num2str(h)], 'FontSize', 16,  ...
                                                   'TextColor', 'white', 'BoxOpacity', 0);
                    end
                    
                    obj.imBrainSurface.CData = injections_im;
                    %obj.mouseObj.showInjectionSpots()
                end
                
                imlocBtnState = get(obj.btnShowImagingLocations, 'String');
                if strcmp(imlocBtnState, 'Hide Imaging Locations')
                    set(obj.btnShowImagingLocations, 'String', 'Show Imaging Locations')
                end
                     
            case 'Hide Injection Spots'
                set(obj.btnShowInjectionSpots, 'String', 'Show Injection Spots')
                
                if ~isempty(obj.mouseObj) && ~isempty(obj.imBrainSurface)
                    im = imresize(obj.mouseObj.brainSurface, obj.imageScaleFactor);
                    obj.imBrainSurface = imshow(im, 'Parent', obj.axBrainSurface, 'InitialMagnification', 'fit');
                    %imshow(obj.mouseObj.brainSurface, 'Parent', obj.axBrainSurface, 'InitialMagnification', 'fit');
                end
        end
    end
    
    
    function obj = loadImage(obj, ~, ~)
    % Button callback to load brain surface image from disk and add it to mouse metadata.
        if ~isempty(obj.mouseObj)
            obj.mouseObj = obj.mouseObj.enterBrainSurfaceImage();
            obj.displaySurfaceImage();
            shg
        end
    end
    
    
    function obj = displaySurfaceImage(obj)
    % Show brain surface image on axes.
        
        if ~isempty(obj.mouseObj.brainSurface)
            imsize = max(size(obj.mouseObj.brainSurface));
             
            set(obj.axBrainSurface, 'units', 'pixel')
            axPos = get(obj.axBrainSurface, 'position');
            set(obj.axBrainSurface, 'units', 'pixel')
            obj.imageScaleFactor = axPos(3)/imsize;

            im = imresize(obj.mouseObj.brainSurface, obj.imageScaleFactor);
            obj.imBrainSurface = imshow(im, 'Parent', obj.axBrainSurface, 'InitialMagnification', 'fit');
        else
            delete(obj.imBrainSurface)
            obj.imBrainSurface = [];
        end
    end
    
    
    function obj = addInjectionSpots(obj, ~, ~)
    % Call a mouse object method to mark virus injection locations.
        obj.mouseObj = obj.mouseObj.markVirusInjections();
    end
    
    
    function obj = addImagingLoc(obj, ~, ~)
    % Call a mouse object method to mark imaging locations.
        obj.mouseObj = obj.mouseObj.addImagingLocations(1);
    end

    
    function obj = editMouse(obj, source, ~)
    % Button callback to edit information of current mouse
         
        btnState = source.String;
        
        switch btnState
            case 'Edit Mouse Info'
                set(obj.btnEditMouse, 'String', 'Save Mouse Info')
                set(obj.btnAddNewMouse, 'Enable', 'off')
                set(obj.btnCancel, 'Enable', 'on')
                % Activate all fields (fields on, color white)
                obj.setInputMode('on');
                fieldMouseNo = obj.mouseInfoFields{strcmp(obj.mouseInfoProps, 'mouseNo')};
                set(fieldMouseNo, 'Enable', 'inactive', ...
                                      'BackgroundColor', [0.97, 0.97, 0.97])
   
            case 'Save Mouse Info'
            	set(obj.btnEditMouse, 'String', 'Edit Mouse Info')
                set(obj.btnAddNewMouse, 'Enable', 'on')
                set(obj.btnCancel, 'Enable', 'off')
                % Write all fields To mouseObj, add mouseObj to inventory,
                % and save inventory.
                obj.updateMouseInfo();
                % Deactivate all fields (fields inactive, gray out)
                obj.setInputMode('off');        
        end
                
    end
    
    
    function obj = addMouse(obj, source, ~)
    % Button callback to add new mouse to database
        
        btnState = source.String;
        
        switch btnState
            case 'Add New Mouse' % Empty fields and allow input
                % Change button text and enable/disable other buttons.
                set(obj.btnAddNewMouse, 'String', 'Save Mouse to DB')
                set(obj.btnEditMouse, 'Enable', 'off')
                set(obj.btnCancel, 'String', 'Cancel', 'Enable', 'on')
                % Reset all fields.
                obj.resetFields();
                % Activate all fields (fields on, color white)
                obj.setInputMode('on');
                
            case 'Save Mouse to DB' % Save entered info to mouse db
                % Change button text and enable/disable other buttons.
                set(obj.btnAddNewMouse, 'String', 'Add New Mouse')
                set(obj.btnEditMouse, 'Enable', 'on')
                set(obj.btnCancel, 'Enable', 'off')
                % Create new mouse object:
                fieldMouseNo = obj.mouseInfoFields{strcmp(obj.mouseInfoProps, 'mouseNo')};
                if ~isempty(get(fieldMouseNo, 'String'))
                    obj.mouseObj = mouse(str2double(get(fieldMouseNo, 'String')));
                    % Write fields to the new mouse object (current object)
                    obj.updateMouseInfo();
                    % Deactivate all fields (fields inactive, gray out)
                end
                obj.setInputMode('off');
        end
            
    end
    
    
    function obj = cancel(obj, ~, ~)
    % Button callback to cancel editing of mouse info
        
        obj.setInputMode('off');
        
        % If user was adding new mouse: reset all fields to blank
        if strcmp(get(obj.btnAddNewMouse, 'String'), 'Save Mouse to DB')
            set(obj.btnAddNewMouse, 'String', 'Add New Mouse')
            set(obj.btnEditMouse, 'Enable', 'on')
            obj.resetFields();
        end
        
        % If user was editing mouse info: Reload mouseinfo from database
        if strcmp( get(obj.btnEditMouse, 'String'), 'Save Mouse Info' )
            set(obj.btnEditMouse, 'String', 'Edit Mouse Info')
            set(obj.btnAddNewMouse, 'Enable', 'on')
            obj.loadMouse([], []);
        end
        
        % Disable cancel button
        set(obj.btnCancel, 'String', 'Cancel', 'Enable', 'off')
        
    end
    
    
    function obj = setInputMode(obj, enable)
    % Enable or disable editing of input fields. enable: 'on' | 'off'
                
        inputFields = cat(2, obj.mouseInfoFields(~strcmp(obj.mouseInfoProps, 'age')), ...
                obj.animalFacilityInfoFields, obj.surgeryInfoFields, obj.notebookFields);
        
        switch enable
            case 'on'
                for f = 1:length(inputFields)
                    set(inputFields{f}, 'Enable', 'on', 'BackgroundColor', [1, 1, 1])
                end
                set(obj.mousepopup, 'Enable', 'off')
            case 'off'
                for f = 1:length(inputFields)
                    set(inputFields{f}, 'Enable', 'inactive', ...
                        'BackgroundColor', [0.97, 0.97, 0.97])
                end
                set(obj.mousepopup, 'Enable', 'on')
        end
    end
    
    
    function obj = resetFields(obj)
    % Reset all input fields to blank
        
        fields = cat(2, obj.mouseInfoFields, obj.animalFacilityInfoFields, ...
            obj.surgeryInfoFields, obj.notebookFields);

        for f = 1:length(fields)
            set(fields{f}, 'String', '')
        end
        obj.expTable.Data = {};
        delete(obj.imBrainSurface)
        obj.imBrainSurface = [];
    end
        
    
    function obj = euthanize(obj, ~, ~)
        answer = inputdlg('Enter date (yyyymmdd)');
        if ~isempty(answer) && ~isempty(obj.mouseObj)
            obj.mouseObj.dateSacrificed = answer;
            obj.mouseObj.savetoDB()
        end
    end
    
    
    function obj = mouseOver(obj, ~, ~)
    % Mouseover callback to show rw coordinates when mouse cursor is over brain image.
        
        % Check that image is in the ax.    axBrainSurface
        if ~isempty(obj.imBrainSurface)
            xlim = get(obj.axBrainSurface, 'XLim');
            ylim = ceil(get(obj.axBrainSurface, 'YLim'));
            mousePoint = get(obj.axBrainSurface, 'CurrentPoint');
            x = round(mousePoint(1,1));
            y = round(mousePoint(1,2));
            
            if x > xlim(1) && x < xlim(2) && y >=ylim(1) && y <= ylim(2)
            
                x = x / obj.imageScaleFactor;
                y = y / obj.imageScaleFactor;
                
                xRW = ( x - obj.mouseObj.refCoordsIM(1)) / obj.mouseObj.pxPermm ...
                                                + obj.mouseObj.refCoordsRW(1);

                yRW = - ( y - obj.mouseObj.refCoordsIM(2)) / obj.mouseObj.pxPermm ...
                                                + obj.mouseObj.refCoordsRW(2) ;

                set(obj.xPos, 'String', ['X: ', num2str(xRW, ' %.1f'), ' mm'])
                set(obj.yPos, 'String', ['Y: ', num2str(yRW, ' %.1f'), ' mm'])
            else 
                set(obj.xPos, 'String', 'X: ')
                set(obj.yPos, 'String', 'Y: ')
            end
            
        end

    end
    
    
    function obj = manageSessions(obj, ~, ~)
    % Something for the future?
        disp('hello world')
    end
 
    
    function obj = sessionSelected(obj, source, event)
    % Callback function is session is selected from list of experiments.

        if ~isempty(event.Indices)
            obj.sessionID = source.Data{event.Indices(1), event.Indices(2)};
            if strcmp(obj.btnOpenSessionBrowser.Enable, 'off')
                set(obj.btnOpenSessionBrowser, 'Enable', 'on')
            end
        end
    end
    
    
    function obj = openSessionBrowser(obj, ~, ~)
    % Button callback to open a session in sessionbrowser.
        if ~isempty(obj.sessionID)
            if isempty(obj.sBrowser)
                obj.sBrowser = sessionBrowser;
            end
            
            obj.sBrowser.loadSession(obj.sessionID)
            
        end
    end
    
    
end


methods (Static)
    
    function [ fieldHandle ] = makeNewField( panel, property, uiEditSizePx )
        %makeNewField Make input field with text string
        %   makeNewField( panel, text, uiEditSize )
        
        uiTextSizePx = [100, 20];

        if nargin < 3
            uiEditSizePx = [160, 20];
            % Set max - min > 1
        end

        set(panel, 'units', 'pixel')
        panelSize = get(panel, 'Position');
        set(panel, 'units', 'normalized')
        panelAR = panelSize(3)/panelSize(4);

        uiTextSize = uiTextSizePx ./ panelSize(3:4);
        uiEditSize = uiEditSizePx ./ panelSize(3:4);
        
        margins = 0.04 * [1, panelAR];  %sides, top/bottom
        padding = 0.019 * [1, panelAR];  %sides, top/bottom

        leftMarginText = margins(1);
        leftMarginEdit = leftMarginText + uiTextSize(1) + padding(1);

        fields = get(panel, 'Children');
        if isempty(fields) % Assume no previous fields; place this one on top.
            yPos = 1 - margins(2) - (uiEditSize(2));
        else
            fieldPos = get(fields(1), 'Position'); % Field 1 is the last one added, usually the edit uicontrol
            yPos = fieldPos(2) - (uiTextSize(2) + padding(2));
        end

        textlabel = mouse.get(property, 'label');
        tip = mouse.get(property, 'tip');

        uicontrol('Parent', panel, ...
                  'Style', 'text', ...
                  'String', textlabel, ...
                  'units', 'normalized', ...
                  'Position', [leftMarginText, yPos, uiTextSize], ...
                  'HorizontalAlignment', 'right',...
                  'Fontsize', 12, ...
                  'TooltipString', tip);
                  %'BackgroundColor', [0.5,0.5,0.5], ...

        fieldHandle = uicontrol('Parent', panel, ...
                                'Style', 'edit', ...
                                'units', 'normalized', ...
                                'Position', [leftMarginEdit, yPos, uiEditSize], ...
                                'HorizontalAlignment', 'left', ...
                                'Fontsize', 12,...
                                'Enable', 'inactive', ...
                                'BackgroundColor', [0.97,0.97,0.97]);

        if uiEditSizePx(2) > 20
            set(fieldHandle, 'Max', round(uiEditSizePx(2) / 20))
            set(fieldHandle, 'Min', 1)
            fieldPos = get(fieldHandle, 'Position');
            fieldPos(2) = fieldPos(2) - (uiEditSize(2) - (20/panelPos(4)));
            set(fieldHandle, 'Position', fieldPos);
        end

    end

    function updateLabbook(~, ~)
        makeLabBook()
    end
    
end


end
classdef mouse
%mouse Class with properties and methods for storing mouse metadata.
%   mInf = MOUSE(21) returns a metadata object for mouse with number 21. The 
%   metadata object is loaded from the database, or if it is not found for that 
%   mouse number, a new instance/object is created.
%   
%   Properties can be set directly, or by using the class methods. There are also 
%   methods for loading, saving or deleting the metadata object from a database. 
%   See <a href="matlab:doc mouse">doc mouse</a> for more information
%
%   See also mouse.enterInfo


%   Methods can be used for (1) entering and editing information about mouse
%   and (2) loading, adding or deleting mouse objects from a database which 
%   is stored as mouseInventory.mat on the Google Drive (nx2 cell array: 
%   {mouseID, mouseObject})


properties (Dependent)
	headbarID                   % Headbar identifier, e.g. #12 D-style
    age                         % Age of mouse
end


properties
    
    % Fields/properties of the mouse metadata object:
    
    mouseNo                     % Our number for mouse.
    mouseID                     % E.g. mouse020
    mousePortrait               % Picture of the mouse?
    
    % Properties with info about mouse and its location in the animal facility
   
    animalNumber                 % Animal Facility number for mouse
    mouseStrain                 % Strain of mouse          
    sex                         % Sex of mouse
    dateofBirth                 % When was mouse born
    cageNumber                  % Animal Facility cage number
    cageRoom                    % Room in animal faciltiy where mouse lives
    cageLocation                % Rack and rack location
    
    % Surgery information
    
    headbarNo                   % Number/mark on headbar
    headbarStyle                % Headbar style: D or O
    experimenter                % Who did surgeries
    surgeryDay                  % When was surgery made
    surgeryProtocol             % What surgery protocol was used
    injectedVirus               % What virues was injected
    nInjections                 % Number of injections
    injectionDepth              % Depth of injections
    injectionAngle              % Angle of injection pipette
    injectionVolumes            % Volume of injections
    hemisphere                  % Left or right hemisphere
    commentsSurgery             % Comments about surgery
    
    % Brain surface image and coordinates
    
    brainSurface                % Image of brain surface
    refCoordsIM                 % Coordinates in image of reference point to bregma
    refCoordsRW                 % Coordinates in real world of ref. point to bregma
    pxPermm                     % Pixels in image per real world millimeter
    injectionCoordsIM           % Coordinates of injections
    injectionCoordsRW           % Coordinates in real world of injections
    
    % Habituation information
    
    startDateHabit              % Date for start of habituation
    endDateHabit                % Date for end of habituation
    habituationProtocol         % Habituation protocol
    commentsHabituation         % Comments about habituation
    
    % Imaging information
    
    startDateImaging            % Date for start of imaging
    endDateImaging              % Date for end of imaging
    commentsImaging             % Comments about imaging
    nImagedLocations            % Number of imaged locations
    imagingLocations            % Coordinates of imaging locations in the image
    imagingLocRWmm              % Coordinates of imaging locations in real world
    
    % Euthanised
    dateSacrificed              % Date when mouse was sacrificed
    
    % Training information
    
    % Water Restriction
    waterTable
    
end


methods
    
    
    function mInf = mouse(N)
        % Initialize mouse object for mouse number N.
        %   mInf = mouse(N) creates an instance of mouse for mouse number N,
        %   either by loading it from the mouse inventory, or by creating a 
        %   new instance
        
        mInf.mouseNo = N;
        mInf.mouseID = num2str(N, 'mouse%04d');
        
        try     % Load from database if it exists 
            mInf = loadfromDB(mInf);
            disp(['Mouse ' num2str(N) ' loaded from mouseInventory'])
            
        catch   % Otherwise, create a new object
            %mInf = enterInfo(mInf);   
        end
        
    end
    
    
    function mInf = set.age(mInf, ~)
    end
   
    
    function age = get.age(mInf)
        if ~isempty(mInf.dateofBirth)
            t = datetime(mInf.dateofBirth, 'InputFormat', 'yyyy-MM-dd');
            %t = datetime(str2double(mInf.dateofBirth),'ConvertFrom','yyyymmdd');
            if isempty(mInf.dateSacrificed)
                mouse_age = date - t;
                mouse_age_weeks = days(mouse_age) / 7;
                age = num2str(round(mouse_age_weeks), '%d weeks');
            else
                age = 'dead';
            end
        else
            age = '';
        end
    end
    
    
    function mInf = set.dateofBirth(mInf, input)
        new_dob = '';
        for c = 1:length(input)
            if ~isnan(str2double(input(c)))
                new_dob = [new_dob, input(c)];
            end
        end
        mInf.dateofBirth = new_dob;
    end
   
    
    function mInf = set.surgeryDay(mInf, input)
        new_dos = '';
        for c = 1:length(input)
            if ~isnan(str2double(input(c)))
                new_dos = [new_dos, input(c)];
            end
        end
        mInf.surgeryDay = new_dos;
    end
    
    
    function dob = get.dateofBirth(mInf)
        if ~isempty(mInf.dateofBirth)
            t = datetime(str2double(mInf.dateofBirth),'ConvertFrom','yyyymmdd');
            dob = datestr(t, 'yyyy-mm-dd');
        else
            dob = '';
        end
    end
   
    
    function dob = get.surgeryDay(mInf)
        if ~isempty(mInf.surgeryDay)
            t = datetime(str2double(mInf.surgeryDay),'ConvertFrom','yyyymmdd');
            dob = datestr(t, 'yyyy-mm-dd');
        else
            dob = '';
        end
    end
           
    
    function mInf = set.headbarID(mInf, strInput)
        if ~isempty(strInput) && ~strcmp(strInput, mInf.headbarID)
            headbarID = strsplit(strInput, ',');
            mInf.headbarNo = headbarID{1};
            mInf.headbarStyle = headbarID{2};
        end
    end
    
    
    function headbarID = get.headbarID(mInf)
        if ~isempty(mInf.headbarNo) && ~isempty(mInf.headbarStyle)
            headbarID = ['#', mInf.headbarNo, ', ' mInf.headbarStyle, '-Style' ];   
        else
            headbarID = '';
        end
    end
    
    
    function mInf = enterInfo(mInf, context)
        % Enter info about mouse for a given context.
        %   mInf = mInf.enterInfo(context) lets you add information relevant to a
        %   given context by prompts on the command line. Possible choices of context: 
        %           's' : Surgery information
        %           'h' : Habituation information
        %           'i' : Imaging information
        %           'e' : Euthanasia information
        %           'b' : Brain surface information
        %           'p' : Picture of mouse for labbook
        
        if nargin < 2
            init_msg = [ 'Start adding or editing information. The following options ' ...
                         'are available: \n \n' ...
                         '  s : information about surgery \n' ...
                         '  h : information about habituation \n' ...
                         '  i : information about imaging \n' ...
                         '  e : information about euthanasia \n' ...
                         '  b : picture of the brain surface \n' ...
                         '  p : picture of the mouse \n \n' ...
                         'For all fields, entering space will leave the field empty ' ...
                         'for now, \nbut information can always be added later. \n'];

            fprintf(init_msg)
            context = input('Enter any option, or press c to cancel: ', 's');
        end
                        
        switch context
            case 's' % Surgery
                mInf = enterSurgeryInformation(mInf);
            case 'h' % Habituation
                mInf = enterHabituationInformation(mInf);
            case 'i' % Imaging
                mInf = enterImagingInformation(mInf);
            case 'e' % Euthanasia
                mInf = enterEuthanasiaInformation(mInf);
            case 'p' % Portrait for labbook
                mInf = enterMousePortrait(mInf);
            case 'b' % Image of Brain surface
                mInf = enterBrainSurfaceImage(mInf);
            case 'c'
                return
            otherwise
                error('Invalid input')
        end
                
    end
    
    
    function mInf = enterMousePortrait(mInf)
        % Add a picture of the mouse that can be used in labbook.
        %   mInf =  enterMousePortrait(mInf) opens a file dialog which lets 
        %   you navigate to the right file, which is added to the metadata object.
        
        disp('Locate file with image of the mouse')
        [fileName, pathName] = uigetfile({'tiff', 'Tiff Files (*.tiff)'; ...
                                          'tif', 'Tiff Files (*.tif)'; ...
                                          '*', 'All Files (*.*)'});
        try
            mInf.mousePortrait = imread(fullfile(pathName, fileName));
        catch
            mInf.mousePortrait = imread('mouse_illustration.jpg');
        end
        mInf.savetoDB()

    end
    
    
    function mInf = enterSurgeryInformation(mInf, mode)
        % Add surgery information based on command line input. 
        %   mouse = mouse.enterSurgeryInformation(mode) asks for 
        %   information based on selected mode: 
        %
        %       'a' - add missing information
        %       'o' - overwrite existing information

        if nargin < 2
            mode = 'a'; % Add missing information by default
        end
        
        surgeryProperties = cat(2, mouse.getPropertyGroup('mouseFields'), ...
                                   mouse.getPropertyGroup('surgeryFields'));

        % Loop through properties and set them using the setProperty method
        for i = 1:length(surgeryProperties)
            mInf = setProperty(mInf, surgeryProperties{i}, mode);
            mInf.savetoDB(false)
        end
        
        % Format headbar ID.
        mInf.headbarID = [mInf.headbarNo, ',', mInf.headbarStyle];
        % Change nInjections to number
        if ~isempty(mInf.nInjections); mInf.nInjections = str2double(mInf.nInjections); end

        % Enter brain surface image?
        if isempty(mInf.brainSurface)
            enter_brainsurface = input('Enter image of brainsurface (y/n)? ', 's');
        else
            enter_brainsurface = input('Re-enter image of brainsurface (y/n)? ', 's');
        end
        
        switch enter_brainsurface
            case 'y'
                mInf = mInf.enterBrainSurfaceImage();
            otherwise
                mInf.brainSurface = [];
        end
        
        % Mark virus injections
        switch mode
            case 'a'
                if isempty(mInf.injectionCoordsIM); mInf = mInf.markVirusInjections(); end
            case 'o'
                mInf = mInf.markVirusInjections();
        end
        mInf.savetoDB()
    end
    
    
    function mInf = enterBrainSurfaceImage(mInf)
        % Enter image of brain surface and set coordinates relative to bregma.
        % mInf = enterBrainSurfaceImage(mInf) lets you browse for the image
        % on disk and then guides you through some steps for adding a
        % reference point relative to bregma and transforming the coordinates
        % for the reference point to real world coordinates.
        
        % Get image of brain surface visible through window
        disp('Locate file with image of brain surface for this mouse')
        [fileName, pathName] = uigetfile({'tiff', 'Tiff Files (*.tiff)'; ...
                                          'tif', 'Tiff Files (*.tif)'; ...
                                          '*', 'All Files (*.*)'});
                                      
        if fileName == 0 % User pressed cancel
            return
        end
        
        mInf.brainSurface = imread(fullfile(pathName, fileName));

        % First, crop image if necessary
        crop_image = input('Crop image (y or n)? ', 's');

        switch crop_image
            case 'y'
                figure(); imshow(mInf.brainSurface)
                h = imrect(gca, [100,100,100,100]); % Make a square box
                setFixedAspectRatioMode(h,true)
                disp(['Resize and move square to mark the inner window ', ...
                      '(double click to finish)'])
                cropCoords = wait(h); close(gcf)
                
                mInf.brainSurface = imcrop(mInf.brainSurface, cropCoords);
            otherwise
                disp([ crop_image ' is a bad answer to a simple yes/no question'])
        end

        % Choose whether to use the center of the window as a reference
        % point, or to add another reference point
        set_refPoint = input(['Mark another location than centre of window to ' ...
                              'use for reference to bregma (y or n)? '], 's');
           
        switch set_refPoint % Create image-based reference coordinates to bregma 
            case 'y'
                figure(); imshow(mInf.brainSurface)
                disp(['Mark a reference point with a known distance to bregma ' ...
                      '(shift+enter to finish)'])
                [xref, yref] = getpts(gcf);
                mInf.refCoordsIM = [xref, yref];
                close(gcf)
            case 'n'
                mInf.refCoordsIM = fliplr(size(mInf.brainSurface)/2); % (size = y, x)
            otherwise
                disp([ set_refPoint ' is a bad answer to a simple yes/no question'])
        end

        % Enter real world distance to the specified reference point
        mInf.refCoordsRW = input(['Enter distance from reference point to bregma' ...
                                  ' in mm (as array: [x, y]): ']);

        % Ask to calibrate image. Otherwise assume image is 2.5 mm across.
        calibrate = input(['Do you want to calibrate the image (y/n)? If no, I '...
                           ' assume that the image is 2.5 mm across. '], 's');
                       
        switch calibrate
            case 'y'
                figure(); imshow(mInf.brainSurface)
                disp('Mark two points separated with a known distance (shift+enter to finish)')
                [xcal, ycal] = getpts(gcf); close(gcf)
                calibration_factor = input('Enter known distance in mm: ');

                distancePx = sqrt( abs(xcal(2)-xcal(1))^2 + abs(ycal(2)-ycal(1))^2 );
                lengthFactor = distancePx / calibration_factor; %(px/um)
                mInf.pxPermm = lengthFactor;
            case 'n'
                lengthFactor = size(mInf.brainSurface, 1) / 2.5;
                mInf.pxPermm = lengthFactor;
            otherwise
                disp('You entered something else than yes or no')
        end
        mInf.savetoDB()
        
    end
    
    
    function mInf = markVirusInjections(mInf)
        % Enter points of virus injections to brain surface image.
        
        if ~isempty(mInf.brainSurface) 
            figure(); imshow(mInf.brainSurface)
            fprintf(['Mark locations where virus was injected (backspace ' '\n'... 
                     'to delete previous point, shift+enter to finish) \n'])
            [x, y] = getpts(gcf); close(gcf)
            
            mInf.injectionCoordsIM = zeros(length(x), 2);
            mInf.injectionCoordsRW = zeros(length(x), 2);
            
            nInj  = mInf.nInjections;
            if ischar(nInj); nInj = str2double(nInj); end
            assert(nInj == length(x), 'Number of marked injections does not correspond with number of entered injections')
            
            for i = 1:nInj
                mInf.injectionCoordsIM(i, 1) = x(i); 
                mInf.injectionCoordsIM(i, 2) = y(i);
                mInf.injectionCoordsRW(i, 1) = (x(i)-mInf.refCoordsIM(1))/mInf.pxPermm ...
                                            + mInf.refCoordsRW(1);
                mInf.injectionCoordsRW(i, 2) = (y(i)-mInf.refCoordsIM(2))/mInf.pxPermm ...
                                            + mInf.refCoordsRW(2);
            end
            mInf.savetoDB()
        end
    end
    
    
    function mInf = enterHabituationInformation(mInf, mode)
        %Add habituation information based on command line input. 
        %   mouse = mouse.enterHabituationInformation(mode) asks for 
        %   information based on selected mode: 
        %
        %       'a' - add missing information
        %       'o' - overwrite existing information
                
        if nargin < 2
            mode = 'a';
        end
        
        habituationProperties = cat(2, mouse.getPropertyGroup('habituationFields'));
        % Loop through properties and set them using the setProperty method
        for i = 1:length(habituationProperties)
            mInf = setProperty(mInf, habituationProperties{i}, mode);
        end
        mInf.savetoDB()
    end
    
    
    function mInf = enterImagingInformation(mInf, mode)
        %Add imaging information based on command line input. 
        %   mouse = mouse.enterImagingInformation(mode) asks for 
        %   information based on selected mode: 
        %
        %       'a' - add missing information
        %       'o' - overwrite existing information
                
        if nargin < 2
            mode = 'a';
        end
        
        imagingProperties = cat(2, mouse.getPropertyGroup('imagingFields'));
        % Loop through properties and set them using the setProperty method
        for i = 1:length(imagingProperties)
            mInf = setProperty(mInf, imagingProperties{i}, mode);
        end
        
        mInf = mInf.enterNewImagingLocations();
        mInf.savetoDB()
    end
    
    
    function mInf = addImagingLocations(mInf, n)
        % Add new imaging locations to image of the brain surface.
        % mInf = enterNewImagingLocations(mInf, n) enters n new imaging
        % locations to the brain surface image and calculates the real
        % world coordinates of the center of each imaging location
    
        if isempty(mInf.brainSurface)
            disp('There is no image of the brain surface  to add imaging locations to')
            return
        end
        
        if nargin < 2
            n = input('Enter number of imaged locations: ');
        end
        
        if isempty(mInf.nImagedLocations);
            mInf.nImagedLocations = 0;
            mInf.imagingLocations = zeros(0,4);
            mInf.imagingLocRWmm = zeros(0,2);
        end
        
        mInf.nImagedLocations = mInf.nImagedLocations + n;

        newImagingLocations = zeros([n, 4]);
        newImagingLocRWmm = zeros([n, 2]);
        for loc = 1:n
            fov_size = input(['Enter length of FOV in um for imaging location ' num2str(loc)' ': ' ]);
            fov_size = fov_size / 1000 * mInf.pxPermm;
            figure(); imshow(mInf.brainSurface)
            h = imrect(gca, [100,100, fov_size, fov_size]); % - to select imaging location.
            setFixedAspectRatioMode(h,true)
            disp(['Change size and move square to mark imaging location ', ...
                  num2str(loc),  ' (double click to finish)'])
            newImagingLocations(loc, :) = wait(h);
            close(gcf)

            x_cntr = newImagingLocations(loc, 1) + newImagingLocations(loc, 3)/2;
            y_cntr = newImagingLocations(loc, 2) + newImagingLocations(loc, 4)/2;
            newImagingLocRWmm(loc, 1) = (x_cntr-mInf.refCoordsIM(1))/mInf.pxPermm + mInf.refCoordsRW(1);
            newImagingLocRWmm(loc, 2) = (y_cntr-mInf.refCoordsIM(2))/mInf.pxPermm + mInf.refCoordsRW(2);
        end
        
        mInf.imagingLocations = vertcat(mInf.imagingLocations, newImagingLocations);
        mInf.imagingLocRWmm = vertcat(mInf.imagingLocRWmm, newImagingLocRWmm);
        mInf.savetoDB()
    end
    
    
    function mInf = enterEuthanasiaInformation(mInf)
        % Enter date when mouse is euthanised.
        if nargin < 2
            mode = 'a';
        end
        mInf = setProperty(mInf, 'dateSacrificed', mode);
        mInf.savetoDB()
    end
    
    
    function mInf = loadfromDB(mInf)
        % Load mouse from mouse inventory.
        mouseInventory = loadMouseInv();
        
        % Search for mouseID and return mouse entry if it exists
        entry = find(strcmp(mInf.mouseID, mouseInventory(:,1)), 1);
        if isempty(entry)
            error('Cannot find mouse in mouse inventory')
        else
            mInf = mouseInventory{entry, 2};
        end
    
    end
    
    
    function saveChanges(mInf)
        % Save changes??
        save_changes = input('Save changes (y/n)? ', 's');
        switch save_changes
            case 'y'
                savetoDB(mInf)
            case 'n'
                return
        end
    end
    
    
    function savetoDB(mInf, vocal)
        % Add mouse object to a database sorted by mouseIDs.
        
        if nargin < 2
            vocal = true;
        end
        
        mouseInventory = loadMouseInv();
        
        % Make new entry or replace existing entry
        entry = find(strcmp(mInf.mouseID, mouseInventory(:,1)), 1);
        if isempty(entry)
            mouseInventory(end+1, :) = {mInf.mouseID, mInf};
            if vocal; disp(['Mouse ' num2str(mInf.mouseNo) ' added to mouseInventory']); end
        else
            mouseInventory(entry, :) = {mInf.mouseID, mInf};
            if vocal; disp(['Changes to Mouse ' num2str(mInf.mouseNo) ' is saved in mouseInventory']); end
        end
        
        saveMouseInv(mouseInventory)
        
    end
    

    function [injections_im] = drawInjectionSpots(mInf)
        % Add markers for injection spots to an image
        injections_im = mInf.brainSurface;
        for h = 1:mInf.nInjections
            x = mInf.injectionCoordsIM(h, 1);
            y = mInf.injectionCoordsIM(h, 2);

            injections_im = insertMarker(injections_im, [x, y], 'x', 'size', 3, ...
                                         'color', 'white');
            injections_im = insertText(injections_im, [x+15, y-14], ...
                                       [' Inj. ' num2str(h)], 'FontSize', 18,  ...
                                       'TextColor', 'white', 'BoxOpacity', 0);
        end
    end
    
    
    function [imagingLocationsImage] = drawImagingLocations(mInf)
        % Draw rectangular boxes on brainsurface image to illustrate imaging locations
        
        % todo - consider plotting instead...?
        
        temp_im = mInf.brainSurface;
        nLocations = mInf.nImagedLocations;
        if ischar(nLocations); nLocations = str2double(nLocations); end
        for h = 1:nLocations
            rect = mInf.imagingLocations(h, :);
            textX = rect(1)+rect(3)+10;
            textY = rect(2)+rect(4)/3;

            temp_im = insertShape(temp_im, 'rectangle', rect, ...
                                         'color', 'white');
            temp_im = insertText(temp_im, [textX, textY], ...
                                       [' Loc. ' num2str(h)], 'FontSize', 18,  ...
                                       'TextColor', 'white', 'BoxOpacity', 0);
        end
        imagingLocationsImage = temp_im;
        
    end
    
    
    function showImagingLocations(mInf)
        % Show imaged locations on brain surface image
        im = drawImagingLocations(mInf);
        imshow(im)
    end
    
    
    function showInjectionSpots(mInf)
        % Show injection locations on brain surface image
        im = drawInjectionSpots(mInf);
        imshow(im)
    end
    
    
    function mInf = formatPropsForTex(mInf)
        % Format fields to make them printable in tex.
        
        ignoreProps = {'mousePortrait', 'brainSurface', 'refCoordsIM', 'refCoordsRW', ...
                       'pxPermm', 'injectionCoordsIM', 'injectionCoordsRW',  ...
                       'imagingLocations', 'imagingLocRWmm'};
                   
        numProps = {'nImagedLocations', 'nInjections'};
        
        dateProps = {'dateofBirth', 'surgeryDay', 'startDateHabit', 'endDateHabit', ...
                     'startDateImaging', 'endDateImaging', 'dateSacrificed'};
        
        % Format dates
        formatDate = @(dob) strcat(dob(7:8), '.', dob(5:6), '.', dob(1:4));  
        for i = 1:length(dateProps)
            if ~isempty(mInf.(dateProps{i}))
                mInf.(dateProps{i}) = formatDate(mInf.(dateProps{i}));
            end
        end
        
        % Set num props to 0 if they are not entered
        for i = 1:length(numProps)
            if isempty(mInf.(numProps{i}))
                mInf.(numProps{i}) = 0;
            end
        end
        
        % Set to N/E (not entered) if property is empty
        allProps = properties(mInf);
        ignoreIdx = cell2mat(cellfun(@(x) sum(strcmp(x, ignoreProps)), allProps, 'un', 0));
        tmpProps = allProps(~ignoreIdx);
        
        for i = 1:length(tmpProps)
            if isempty(mInf.(tmpProps{i}))
                mInf.(tmpProps{i}) = 'N/E';
            end
        end
        
    end
    
    
end
    

methods (Access = 'private', Hidden = true)
    
    
    function mInf = setProperty(mInf, propName, mode)
        % Add a property. Overwrite, or add empty properties.
        switch mode
            case 'a' % Add a missing property
                if isempty(mInf.(propName))
                    mInf.(propName) = input(mouse.get(propName, 'tip'), 's');
                end
        
            case 'o' % Overwrite existing property
                mInf.(propName) = input(mouse.get(propName, 'tip'), 's');
        end
    end
    
    
end

    
methods (Static)
    
    
    function deletefromDB(mouseID)
        % Delete mouse given by mouseID from mouse inventory.
        mouseInventory = loadMouseInv();
        
        % Search for mouseID and delete mouse entry if it exists
        entry = find(strcmp(mouseID, mouseInventory(:,1)), 1);
        if isempty(entry)
            error('Cannot find specified mouse in mouse inventory')
        else
            mouseInventory(entry, :) = [];
        end
        
        saveMouseInv(mouseInventory)
    end
    
 
    function fields = getPropertyGroup(groupname)
    % getPropertyGroup This method returns a group of property names for the mouse class.
    %   FIELDS = getPropertyGroup(GROUPNAME) returns the fieldnames of properties 
    %   belonging to a group of properties specified by GROUPNAME.
    %
    %   Some class methods will apply to a group of properties, e.g. properties related to
    %   imaging. This method returns all the relevant fieldnames.
    %   
    %   If properties are added to the mouse class, consider if they should also be added 
    %   to one of these groups.
    
        switch groupname
            % Fields with info about mouse and its location in the animal facility
            case 'mouseFields' 
                fields = {'mouseStrain', 'sex', 'dateofBirth', 'animalNumber', ...
                          'cageNumber', 'cageRoom', 'cageLocation'};
                      
            % Fields with information about imaging          
            case 'imagingFields'    
                fields = {'startDateImaging', 'endDateImaging', 'commentsImaging'};

            % Fields with information about the surgery
            case 'surgeryFields'
                fields = {'headbarNo', 'headbarStyle', 'experimenter', 'surgeryDay', ...
                          'surgeryProtocol', 'injectedVirus', 'nInjections', ...
                          'injectionDepth', 'injectionAngle', 'injectionVolumes', ...
                          'hemisphere', 'commentsSurgery'};
    
            % Fields with information about habituation
            case 'habituationFields'
                fields = {'startDateHabit', 'endDateHabit', 'habituationProtocol', ...
                          'commentsHabituation'};
                
        end
    end
    
    
    function string = get(property, token)
   
    switch token
        case 'label'
        
            switch property

                case 'mouseNo';             string = 'Mouse Id';
                case 'headbarID';           string = 'Headbar Id';
                case 'age';                 string = 'Age';
                case 'animalNumber';        string = 'Mouse Number';
                case 'mouseStrain';         string = 'Mouse Strain';
                case 'sex';                 string = 'Sex';
                case 'dateofBirth';         string = 'Date of Birth';
                case 'cageNumber';          string = 'Cage Number';
                case 'cageRoom';            string = 'Cage Room';
                case 'cageLocation';        string = 'Cage Location';
                case 'experimenter';        string = 'Performed by';
                case 'surgeryDay';          string = 'Surgery Date';
                case 'surgeryProtocol';     string = 'Protocol followed';
                case 'injectedVirus';       string = 'Injected Virus';
                case 'nInjections';         string = '# Injections';
                case 'injectionDepth';      string = 'Injection depth';
                case 'injectionAngle';      string = 'Injection angle';
                case 'injectionVolumes';    string = 'Injection volume';
                case 'hemisphere';          string = 'Hemisphere';
                case 'commentsSurgery';     string = 'Surgery Notes';
                case 'startDateHabit';      string = 'Enter date when mouse habituation started: ';
                case 'endDateHabit';        string = 'Enter date when mouse habituation ended: ';
                case 'habituationProtocol'; string = 'Enter name of habituation protocol: ';
                case 'commentsHabituation'; string = 'Training Notes';
                case 'startDateImaging';    string = 'Enter date when mouse imaging started: ';
                case 'endDateImaging';      string = 'Enter date when mouse imaging ended: ';
                case 'commentsImaging';     string = 'Imaging Notes';
                case 'dateSacrificed';      string = 'Enter date when mouse was sacrificed: ';
                otherwise; error(['unknown property: ' property])
            end
            
        case 'tip'
            switch property
                case 'mouseNo';             string = 'Enter number of mouse as used by us';
                case 'headbarID';           string = 'Enter number and style of headbar, e.g. 13, O'; 
                case 'headbarNo';           string = 'Enter number on headbar: ';
                case 'headbarStyle';        string = 'Enter style of headbar (O or D): ';
                case 'mouseStrain';         string = 'Enter mouse strain (eg VIP-Cre, PV-Cre, SOM-Cre, 5HT3a-Cre, NPY-Cre) : ';
                case 'sex';                 string = 'Enter sex of mouse (M or F): ';
                case 'dateofBirth';         string = 'When was mouse born (yyyymmdd)? ';
                case 'animalNumber';        string = 'Enter the animal facility mouse number: ';
                case 'cageNumber';          string = 'Enter cage number where mouse is lodging: ';
                case 'cageRoom';            string = 'Enter room where cage belongs (e.g. CON-ROM1): ';
                case 'cageLocation';        string = 'Enter rack where cage belongs (e.g. Rack 923-D6): ';
                case 'experimenter';        string = 'Who did the surgery? ';
                case 'surgeryDay';          string = 'Enter date of surgery day (yyyymmdd): ';
                case 'surgeryProtocol';     string = 'Enter name of surgery protocol used: ';
                case 'injectedVirus';       string = 'Enter virus (e.g. hSyn-GCaMP6f): ';
                case 'nInjections';         string = 'Enter number of injections: ';
                case 'injectionDepth';      string = 'Enter injection depth(s) (in um): ';
                case 'injectionAngle';      string = 'Enter angle of injection pipette (in deg): ';
                case 'injectionVolumes';    string = 'Enter volume of injection per spot (in nl): ';
                case 'hemisphere';          string = 'Right or left hemisphere? ';
                case 'commentsSurgery';     string = 'Enter any comments: ';
                case 'startDateHabit';      string = 'Enter date when mouse habituation started: ';
                case 'endDateHabit';        string = 'Enter date when mouse habituation ended: ';
                case 'habituationProtocol'; string = 'Enter name of habituation protocol: ';
                case 'commentsHabituation'; string = 'Enter any comments: ';
                case 'startDateImaging';    string = 'Enter date when mouse imaging started: ';
                case 'endDateImaging';      string = 'Enter date when mouse imaging ended: ';
                case 'commentsImaging';     string = 'Enter any comments: ';
                case 'dateSacrificed';      string = 'Enter date when mouse was sacrificed: ';
                otherwise; string = '';
            end
            
    end

    end
    
end


end



classdef RoI < handle
% ROI Region of Interest object.
%   Holds information of the indices of a picture that is the actual
%   region of interest. The center is the mean of the index values and
%   not weighted. 
%   Subclass of handle so the object will be taken by reference. 

properties
    uid                         % Unique ID of RoI
    num                         % Number of RoI in list of RoIs. 
    shape                       % Polygon, Circle, Mask.
    coordinates                 % Corners, center and radius, mask (depends on shape)
    center                      % Mean center of RoI in image in pixel coordinates
    area                        % Area or number of pixels of RoI
    mask                        % Boolean mask of RoI
    boundary = cell(0)          % Boundary points of RoI
    connectedrois = cell(0)     % A list of uid of connected RoIs
    group                       % 
    celltype                    % Neuron, Astrocyte, other?
    structure                   % Axon, Dendrite, Endfoot, Vein, Artery, Capillary
    xyz                         % X, y and z coordinates relative to a reference point, e.g. bregma
    region = ''                 % Region of the brain where the RoI is drawn 
    layer = ''                  % Layer of cortex
    tags = cell(0)              % User defined tags. E.g 'overexpressing', 'excitatory', 'tuned' 
end


properties ( Hidden = true, Transient = true )
    ID = []  
    Tag
    Group
    CorticalLayer = 'n/a'
    Shape
    Center
    Channel = 0
    PixelsX = []
    PixelsY = []
    imPointsX
    imPointsY
    Selected
    Boundary = cell(0)
    Weights = []
    WeightType
    ImageDimX
    ImageDimY
    nFrames
    Mask
    ResX = 1
    ResY = 1
    Version = 'v1.0'
end


properties ( Dependent = true, Transient = true )
    tag
end


methods
    
    
    function obj = RoI(shape, coordinates, imdim)
        % RoI Constructor. Create a RoI object of specified shape.
        %   roi = RoI(SHAPE, COORDINATES, IMDIM) creates a RoI object of
        %   specifed SHAPE based on COORDINATES. IMDIM is the dimensions of
        %   the image where the roi is created, in nRows, nCols
        %
        %   SHAPE (str): 'Polygon' | 'Circle' | 'Mask'
        %   COORDINATES: Depends on the shape:
        %       'Polygon'   : nx2 vector of polygon corner coordinates
        %       'Circle'    : 1x3 vector of x_center, y_center, radius
        %       'Mask'      : nRow x nCol logical array 
        %   IMDIM (double): 1x2 vector ([nRows, nCols]) 

        if nargin < 1
            return
        end
        
        coordinates = obj.checkCoordinates(shape, coordinates);
        
        % Create a unique ID for the roi.
        obj.uid = rmUtil.make_guid();
        
        % Set shape and coordinates
        obj.shape = shape;
        obj.coordinates = coordinates;
        
        % Calculate other properties
        obj.createMask( imdim );
        obj.setBoundaries();
        obj.setCenter();
        obj.setArea();
        
    end
    
    
    function obj = move(obj, shift)
    %move Move RoI according according to specified shifts
        switch obj.shape
            case 'Polygon'
                obj.coordinates = obj.coordinates + shift;
            case 'Circle'
                obj.coordinates(1:2) = obj.coordinates(1:2) + shift;
            case 'Mask'
                obj.coordinates = circshift(obj.coordinates, round(fliplr(shift)));
        end
        
        % Update mask, boundary and center
        obj.createMask( size(obj.mask) );
        obj.setBoundaries();
        obj.setCenter();
        
    end
    
    
    function obj = reshape(obj, shape, coordinates, imdim)
    %reshape Reshape a RoI based on new input coordinates
        
        % Use old mask size if nothing is specified.
        if nargin < 4
            imdim = size(obj.mask);
        end
    
        coordinates = obj.checkCoordinates(shape, coordinates);

        obj.shape = shape;
        obj.coordinates = coordinates;
        
        % Update mask, boundary, center and area
        obj.createMask( imdim );
        obj.setBoundaries();
        obj.setCenter();
        obj.setArea();
    end
    
    
    function roiBabies = split(obj, nPieces)
        newRoiMasks = signalExtraction.fissa.splitneuropilmask(obj.mask, obj.mask, nPieces);
        
        roiBabies = RoI.empty;
        for i = 1:size(newRoiMasks, 3)
            roiBabies(i) = RoI('Mask', newRoiMasks(:,:,i), size(obj.mask));
            roiBabies(i).structure = obj.structure;
        end
    end
            

    
    
    function obj = grow(obj, npixels)
    %grow Grow a RoI by n pixels  
        switch obj.shape
            case 'Circle'
                obj.coordinates(3) = obj.coordinates(3) + npixels;
            case 'Polygon'
                theta = atan2(obj.coordinates(:, 2) - obj.center(2), obj.coordinates(:, 1) - obj.center(1));
                hypotenus = sqrt((obj.coordinates(:, 2)- obj.center(2)).^2 + (obj.coordinates(:, 1) - obj.center(1)).^2);
                hypotenus = hypotenus + npixels;
                obj.coordinates(:, 1) = obj.center(1) + cos(theta) .* hypotenus;
                obj.coordinates(:, 2) = obj.center(2) + sin(theta) .* hypotenus;
                
            case 'Mask'
                yCenter = round(obj.center(2));
                rad = round(sum(obj.mask(yCenter, :))/2);
                
                if mod(rad, 2) == 0 
                    % Imdilate 1 pixel in each direction: N, E, S, W.
                    nhood = [0,1,0;1,1,1;0,1,0];
                    obj.coordinates = imdilate(obj.coordinates, nhood);

                elseif mod(rad, 2) == 1
                    % Imdilate 1 pixel in each direction:  NE, SE, SW, NW
                    nhood = [1,0,1;0,1,0;1,0,1];
                    obj.coordinates = imdilate(obj.coordinates, nhood);
                end
        end
        
        % Calculate other properties
        obj.createMask( size(obj.mask) );
        obj.setBoundaries();
        obj.setCenter();
        obj.setArea();
        
    end
    
    
    function obj = shrink(obj, npixels)
    %shrink Shrink a RoI by n pixels 
        
        switch obj.shape
            case 'Circle'
                obj.coordinates(3) = obj.coordinates(3) - npixels;
                
            case 'Polygon'
                theta = atan2(obj.coordinates(:, 2) - obj.center(2), obj.coordinates(:, 1) - obj.center(1));
                hypotenus = sqrt((obj.coordinates(:, 2)- obj.center(2)).^2 + (obj.coordinates(:, 1) - obj.center(1)).^2);
                hypotenus = hypotenus - npixels;
                obj.coordinates(:, 1) = obj.center(1) + cos(theta) .* hypotenus;
                obj.coordinates(:, 2) = obj.center(2) + sin(theta) .* hypotenus;
                
            case 'Mask'
                yCenter = round(obj.center(2));
                rad = round(sum(obj.mask(yCenter, :))/2);
                
                if mod(rad, 2) == 0 
                    % Imdilate 1 pixel in each direction: N, E, S, W.
                    nhood = [0,1,0;1,1,1;0,1,0];
                    obj.coordinates = imerode(obj.coordinates, nhood);

                elseif mod(rad, 2) == 1
                    % Imdilate 1 pixel in each direction:  NE, SE, SW, NW
                    nhood = [1,0,1;0,1,0;1,0,1];
                    obj.coordinates = imerode(obj.coordinates, nhood);
                end
        end
        
        % Calculate other properties
        obj.createMask( size(obj.mask) );
        obj.setBoundaries();
        obj.setCenter();
        obj.setArea();
    end
    
    
    function obj = connect(obj, roi_uid_list)
    %connect Add connected RoIs to list of connected RoIs.
    %   obj.connect(roi_uid_list) add RoIs to list of connected RoIs. 
    %   roi_uid_list is a list of unique ids for RoIs to be connected.
        obj.connectedrois = cat(1, obj.connectedrois, roi_uid_list);
    end
    
    
    function addLabel(obj, label)
        
        if ~contains(label, obj.labels)
            obj.labels = cat(1, obj.labels, label);
        end
        
    end
    
    
    function twinRoi = copy(obj)
        twinRoi = RoI(obj.shape, obj.coordinates, size(obj.mask) );
        
        propertyList = {'uid', 'connectedrois', 'group', 'celltype', ...
                        'structure', 'xyz', 'layer', 'tags'};
        for i = 1:numel(propertyList)
            twinRoi.(propertyList{i}) = obj.(propertyList{i});
        end
        
    end
    
    
    function bool = isInRoi(obj, x, y)
    %isInRoi Check if the point (x,y) is a part of the roi.
    %   bool = isInRoi(roi, x, y) returns true if x and y is within the RoI
    %   and false otherwise
    %
    % roi       - Single RoI object.
    % x         - (int) Position in image as pixels.
    % y         - (int) Position in image as pixels.
    
        [szY, szX] = size(obj.mask);
        if x > szX || y > szY
            bool = false;
        elseif obj.mask(round(y), round(x))
            bool = true;
        else
            bool = false;
        end
    end
    
    
    function tag = get.tag(self)
        if ~isempty(self.celltype)
            tag = [self.celltype(1), self.structure(1)];
        else
            tag = self.structure(1:2);
        end
    end
    
    
% % Methods for getting old property values

    function group = get.Group(self)
        if isempty(self.Group)
            group = self.group;
        else
            group = self.Group;
        end
    end

    
    function PixelsX = get.PixelsX(self)
        [~, PixelsX] = find(self.Mask);
    end
    
    
    function PixelsY = get.PixelsY(self)
        [PixelsY, ~] = find(self.Mask);
    end
    

    function center = get.Center(self)
        if isempty(self.Center)
            center = self.center;
        else
            center = self.Center;
        end
    end

    
    function boundary = get.Boundary(self)
        if isempty(self.Boundary)
            boundary = self.boundary;
        else
            boundary = self.Boundary;
        end
    end
    
    
    function mask = get.Mask(self)
        if isempty(self.Mask)
            mask = self.mask;
        else
            mask = self.Mask;
        end
    end
    
    
    function tag = get.Tag(self)
        if ~isempty(self.celltype)
            tag = [self.celltype(1), self.structure(1)];
        else
            tag = self.structure(1:2);
        end
    end
    
end


% Following methods are only accessible to class and subclasses
methods (Access = protected)
    

    function obj = createMask(obj, imdim)
        % Calculate and set mask of RoI
        switch obj.shape
            case 'Polygon'
                x = obj.coordinates(:, 1);
                y = obj.coordinates(:, 2);
                obj.mask = poly2mask(x, y, imdim(1), imdim(2));
            case 'Circle'
                x = obj.coordinates(1);
                y = obj.coordinates(2);
                r = obj.coordinates(3);
                [xx, yy] = ndgrid((1:imdim(1)) - y, (1:imdim(2)) - x);
                obj.mask = (xx.^2 + yy.^2) < r^2;
            case 'Mask'
                obj.mask = obj.coordinates;
        end
    end
    
    
    function obj = setCenter(obj)
        % Find and set center of RoI
        [y,x] = find(obj.mask);
        obj.center = [mean(x), mean(y)];
    end
       
    
    function obj = setBoundaries(obj)
        % Find and set boundary of RoI
    	obj.boundary = bwboundaries(obj.mask);
    end
       
    
    function obj = setArea(obj)
        % Find and set area of RoI 
        obj.area = sum(obj.mask(:) == 1);
    end

    
end


methods(Static)
    
    
    function coordinates = checkCoordinates(shape, coordinates)
    %checkCoordinates check that coordinates are valid according to shape
        switch shape
            case 'Polygon'
                sizeCoord = size(coordinates);
                assert(numel(sizeCoord) == 2, 'Coordinates for polygon must be 2D')
                assert(any(sizeCoord==2), 'Coordinates for polygon must be have 2 rows or 2 columns')
                if sizeCoord(1)==2 % make it two column vectors...
                    coordinates = coordinates';
                end
            case 'Circle'
                msg = 'Circle is specified by a vector of 3 values; x, y and radius';
                assert( numel(coordinates) == 3, msg )
            case 'Mask'
                assert( numel(size(coordinates)) == 2, 'Mask must be 2D')
                assert( isa(coordinates, 'logical'), 'Coordinates for mask must be logicals')
        end
    end
    
    
    function overlap = calculateOverlap(roi1, roi2)
        % Find fraction of area overlap between two RoIs.
        area1 = roi1.area;
        area2 = roi2.area;
        overlappingArea = sum(roi1.mask & roi2.mask);
        overlap = overlappingArea / min(area1, area2);

    end
  
    
end

end

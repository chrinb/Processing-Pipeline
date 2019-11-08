classdef RoI < handle
    % ROI Region of Interest object.
    %   Holds information of the indices of a picture that is the actual
    %   region of interest. The center is the mean of the index values and
    %   not weighted. 
    %   Subclass of handle so the object will be taken by referance. 
    % ROI Properties:
    %   UID     - Unique identifier of the RoI.
    %   Label   - Name of the RoI.  
    
    properties
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
        signalArtifact = []
        Mask
        ResX = 1
        ResY = 1
        Version = 'v1.0'
    end
    
    methods
        function obj = RoI(mat)
            % Makes a RoI of non-zero values of mat. Can either be weighted
            % or binary. 
            if nargin == 0
                return
            end
            assert(length(size(mat)) == 2);
            obj.Mask = mat;
            [xDim, yDim] = size(mat);
            obj.ImageDimX = xDim;
            obj.ImageDimY = yDim;
            obj.setMask(mat);

            obj.findCenter();
            obj.findBoundaries();
                
            
            % Weights made some problems and are not actually needed at the
            % moment. So it is commented out.
            %obj.WeightType = 'binary';
%             if max(max(mat)) ~= 1
%                 obj.WeightType = 'float';
%                 obj.Weights = zeros(length(x),1);
%                 for i = 1:length(x)
%                     obj.Weights(i) = mat(y(i),x(i));
%                 end
%                 cx = mean(x);%.*obj.Weights);
%                 cy = mean(y);%.*obj.Weights);
%                 obj.Center = [cx, cy];
%             else
%                 obj.WeightType = 'binary';
%                 cx = mean(x);
%                 cy = mean(y);
%                 obj.Center = [cx, cy];
%             end
        end
        
        function assertPositions(self)
            for i = 1:length(self)
                a = isempty(self(i).ImageDimX);
                b = isempty(self(i).ImageDimY);
                if a
                    disp('Warning: ImageDimX not set');
                end
                if b
                    disp('Warning: ImageDimY not set');
                end
                if ~a && ~b
                    str = [self(i).Tag, ' is outside image dimensions.'];
                    c = false;          
                    c = c | (max(self(i).PixelsX) > self(i).ImageDimX);
                    c = c | (min(self(i).PixelsX) < 0);
                    c = c | (max(self(i).PixelsY) > self(i).ImageDimY);
                    c = c | (min(self(i).PixelsY) < 0);
                    if c
                        disp(['Warning: ', str]);
                    end
                end
            end
        end
        
        function findCenter(self)
            for i = 1:length(self)
                roi = self(i);
                cx = mean(roi.PixelsX);
                cy = mean(roi.PixelsY);
                roi.Center = [cx, cy];
            end
        end
        
        function findBoundaries(self)
            for i = 1:length(self)
                roi = self(i);
                roi.Boundary = bwboundaries(roi.getMask());
            end
        end
        
        function info = getInfo(self)
            info = cell(5,2);
            info{1,1} = 'Tag';
            info{2,1} = 'ID';
            info{3,1} = 'Group';
            info{4,1} = 'Area (um)';
%             info{5,1} = 'Shape';
%             info{6,1} = 'Weight';
            info{5,1} = 'Channel';
            
            info{1,2} = self.Tag;
            info{2,2} = num2str(self.ID);
            info{3,2} = self.Group;
            info{4,2} = num2str(length(self.PixelsX)*self.ResX*self.ResY);
%             info{5,2} = self.Shape;
%             info{6,2} = self.WeightType;  
            info{5,2} = num2str(self.Channel);
        end
        
        function area = getArea(self)
            area = length(self.PixelsX);
        end
        
        function img = getMask(self)
            % Creates a binary mask from the RoI. If it already exists it 
            % will be returned. 
            %   img = RoI.getMask();
            
            if isempty(self.Mask)
                img = zeros(self.ImageDimY,self.ImageDimX);
                for i = 1:length(self.PixelsX)
                    img(self.PixelsY(i), self.PixelsX(i)) = 1;
                end
            else 
                img = self.Mask;
            end
        end
        
        function obj = copy(self)
            obj = RoI;
            obj.ID = self.ID;
            obj.Tag = self.Tag;
            obj.Group = self.Group;
            obj.Shape = self.Shape;
            obj.Center = self.Center;
            obj.PixelsX = self.PixelsX;
            obj.PixelsY = self.PixelsY;
            obj.Boundary = self.Boundary;
            obj.Weights = self.Weights;
            obj.WeightType = self.WeightType;
            obj.ImageDimX = self.ImageDimX;
            obj.ImageDimY = self.ImageDimY;
            obj.Mask = self.Mask;
            obj.Channel = self.Channel;
        end
        
        function copyLabels(self, other)
            self.Tag = other.Tag;
            self.ID = other.ID;
            self.Shape = other.Shape;
            self.Group = other.Group;
            self.Channel = other.Channel;
        end
        
        function selected_rois = getSelected(self)
            
            % Assume self is an array of rois, should work even if it is
            % not. 
            selected_rois = RoI.empty;
            for i = 1:length(self)
                if self(i).Selected
                    selected_rois(end+1) = self(i);
                end
            end
        end
        
        function newRoi = merge(roiArr)
            % merge merges an array of RoIs into one RoI.
            % No overlap is needed.
            %   newRoi = merge(roiArr)
            %
            % roiArr        - Array of RoI object.
            mergedImg = roiArr(1).Mask;
            for i = 2:length(roiArr)
                mergedImg = mergedImg | roiArr(i).Mask;
            end
            newRoi = RoI(mergedImg);
            newRoi.copyLabels(roiArr(1));
        end
        
        function setMask(self,mask)
            self.Mask = mask;
            [y,x] = find(mask);
            self.PixelsX = x;
            self.PixelsY = y;
        end
        
        function saveToFile(self, file_path)
            % Save the array in the spesified location of file_apth. If
            % no path is given, the array will be saved in current
            % directory as 'roi_arr.mat'. 
            %
            %   roi_arr.saveToFile()
            %   roi_arr.savetoFile(file_path)
            %   roi.saveToFile()
            %   roi.saveToFile(file_path)
            if nargin < 2
                file_path = 'roi_arr.mat';
            end
            roi_arr = self;
            save(file_path,'roi_arr');
            disp(file_path);
        end
    end
        
    methods(Static)
        function overlap = calculateOverlap(roi1, roi2)
            
            % Get two binary images, one for each RoI.
            binaryImg1 = roi1.getMask();
            binaryImg2 = roi2.getMask();
            area1 = length(find(binaryImg1));
            area2 = length(find(binaryImg2));
            area = min(area1,area2);
            overlappingArea = length(find(binaryImg1 & binaryImg2));
            overlap = overlappingArea/area;
            
        end
        
        function roiArr = loadFromFile(fullFileName)
            s = load(fullFileName);
            % Assume the variable name is roi_arr.
            roiArr = s.roi_arr;
        end
    end
end


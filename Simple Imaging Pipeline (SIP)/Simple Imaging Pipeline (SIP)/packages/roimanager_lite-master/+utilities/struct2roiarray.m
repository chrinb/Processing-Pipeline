function roiArray = struct2roiarray(roiStruct)

nRois = numel(roiStruct);
roiArray(nRois, 1) = RoI;

fieldnames = {  'uid', 'shape', 'coordinates', 'imagesize', 'boundary', ...
                'area', 'center', 'connectedrois', 'group', 'celltype', ...
                'structure', 'layer', 'tags'};
for i = 1:nRois
    for f = 1:numel(fieldnames)
        roiArray(i).(fieldnames{f}) = roiStruct(i).(fieldnames{f});
    end
end

for i = 1:nRois
    roiArray(i) = RoI.loadobj(roiArray(i));
end

if iscolumn(roiArray)
    roiArray = roiArray';
end

end            
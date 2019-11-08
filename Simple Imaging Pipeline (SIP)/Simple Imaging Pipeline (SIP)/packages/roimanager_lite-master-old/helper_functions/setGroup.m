function rois = setGroup(rois, group)

    for i = 1:numel(rois)
        
        roi = rois(i);
        
        if nargin < 2
            group = roi.group;
        end

        roi.group = group;
        switch group
            case 'Neuronal Soma'
                roi.celltype = 'Neuron';
                roi.structure = 'Soma';
            case {'Neuronal Dendrite', 'Dendrite'}
                roi.celltype = 'Neuron';
                roi.structure = 'Dendrite';
            case {'Neuronal Axon', 'Axon'}
                roi.celltype = 'Neuron';
                roi.structure = 'Axon';
            case {'Neuropill', 'NeuroPil', 'Neuropil'}
                roi.celltype = 'Neuron';
                roi.structure = 'pil';
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
        
        rois(i) = roi;
       
    end
    
end
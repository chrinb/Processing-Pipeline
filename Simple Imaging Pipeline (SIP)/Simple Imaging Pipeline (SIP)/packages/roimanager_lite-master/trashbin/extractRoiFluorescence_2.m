function signals = extractRoiFluorescence_2(imArray, roiArray, roiIdx, method)

% Get the mask for the current RoI
roiMask = roiArray(roiIdx).mask;

switch method
    
    case 'raw'
%         roiMask = signalExtraction.fissa.splitneuropilmask(roiMask, roiMask, 4);
        signals = signalExtraction.extractRoiFluorescence(imArray, roiMask);
        
    case 'raw+neuropil' % Remove surrounding rois and extract neuropil too
        [roiMask, npMask] = signalExtraction.standard.getMasks(roiArray, roiIdx);
        signals = signalExtraction.extractRoiFluorescence(imArray, roiMask, npMask, 'median');
        
    case 'fissa'
        % Get the mask for the current RoI and surrounding neuropils
        npMask = signalExtraction.fissa.getMasks(roiMask, 4, 4);
    	signals = signalExtraction.extractRoiFluorescence(imArray, roiMask, npMask);

    otherwise
        fprintf('unknown method for signal extraction, ''%s''\n', method)
        
end



end
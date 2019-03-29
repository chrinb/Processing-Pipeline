function [signals, dFoF, normalized_signals] = extractSignalsFullSession(sessionFolder)
a = 1;
% fileFolder = uigetdir();
filesInFolder = dir([sessionFolder '\calcium_images_aligned'])

for x = 1:length(filesInFolder)
   
    if ~isempty(findstr(filesInFolder(x).name,'roi_arr'))
        roiFile = [filesInFolder(x).folder '\' filesInFolder(x).name];
        roiFileVar = load(roiFile);
        rois = roiFileVar.roi_arr;
    end
    
end



% roiFiles = dir(fullfile(sessionFolder, 'roi_arr*'));
% % Load ROI file
% roiFile = fullfile(pathName, roiFileName);
% roiFileVar = load(roiFile);
% rois = roiFileVar.roi_arr;

% Load imArray for each stack and extract signal

ch = 2;
signals = [];

for x = 1:length(filesInFolder)
   fprintf('Loading file %d of %d\n',x,length(filesInFolder));
    if ~isempty(findstr(filesInFolder(x).name,'tif'))
        
       partNum = str2num(filesInFolder(x).name(end-6:end-4));
       imFilePath = [filesInFolder(x).folder '\' filesInFolder(x).name];
       
       tiffStack = stack2mat(imFilePath,true);
       extractedSignal = extractSignal(tiffStack,rois);
       temp_signal = extractedSignal.Signal;
       signals = [signals; temp_signal];
         
    end
    
end
%sessionData.ROIsignals_raw = signals;
dFoF = deltaFoverFsimple(sessionData);
normalized_signals = zScoreNormalize(dFoF);




end
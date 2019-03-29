function [ sessionInfo ] = loadSessionInfo( sessionID )
%loadSessionInfo loads sessionInfo from labview Folder
%   sessionInfo = loadSessionInfo( sessionID )

sessionFolder = getSessionFolder(sessionID);

% Get session info from Labview
xmlFileLV = dir(fullfile(sessionFolder, 'labview_data', '*.xml'));
xmlFileLV = fullfile(sessionFolder, 'labview_data', xmlFileLV(1).name); 
sessionXML = parseLabviewXML(xmlFileLV);

sessionInfo = sessionXML.sessionInfo;

if isfield(sessionInfo, 'trialSpecifications');
    % Reshape labview array, the parser loads labview arrays with opposite dimensional order.
    sessionInfo.trialSpecifications = reshape(sessionInfo.trialSpecifications, ...
                             fliplr(size(sessionInfo.trialSpecifications))).';
end

% Find number of labview samples of stage positions and pupildiameter.                     
if ~isfield(sessionInfo, 'nSamples') && ~isfield(sessionInfo, 'nPupilSamples')
    nSamples = zeros(sessionInfo.nBlocks, 1);
    nPupilSamples = zeros(sessionInfo.nBlocks, 1);

    for block = 1:sessionInfo.nBlocks
        labviewData = loadLabviewData(sessionID, block, 'all');
        nSamples(block) = size(labviewData, 1);
        pupilData = loadPupilData(sessionID, block);
        nPupilSamples(block) = size(pupilData, 1);
    end

    sessionInfo.nSamples = nSamples;
    sessionInfo.nPupilSamples = nPupilSamples;
    
end

% look through all blocks and find number of frames in body video.
% /todo v2: record this in labview.

end


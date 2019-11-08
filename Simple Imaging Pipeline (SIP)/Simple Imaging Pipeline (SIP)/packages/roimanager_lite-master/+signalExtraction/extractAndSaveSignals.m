function extractAndSaveSignals(images, roiArray, options, angles)
% extractAndSaveSignals
%
%   extractAndSaveSignals(images, roiArray, options)
%
%   Input: 
%       images : Array of images or cell array of pathstrings to tiff-files
%                containing images 
%       roiArray : List (array) of RoIs
%       options : struct of options.
%             'extractNeuropil'             -
%             'neuropilExtractionMethod'    -
%             'deconvolveSignal'            -
%             'deconvolutionMethod'         -
%             'extractFromFiles'            -
%             'caimanParameters'            -
%             'filterSpikesByNoiseLevel'    -
%             'extractSignalsInBackground'  -
%             'savePath'                    -
%   Output:
%   
%       signaldata = nSamples x nRois;

% Todo: 
% V - create function to extract signals from image data
% V - fissa needs to deal with multiple rois. for loop in python...
% - create function for subtracting neuropil
% - create function for calculating delta f over f.
% - make options optional and use default options if options are missing.


if nargin < 4; angles = []; end


% % % First, determine if images have to be loaded.
if iscell(images)
    loadImages = true;
    nParts = numel(images);
    batchSize = nan;
    nFrames = 0;
elseif isnumeric(images)
    loadImages = false;
    nParts = 1;
    nFrames = size(images, 3);
elseif isa(images, 'memmapfile')
    loadImages = true;
    batchSize = 2000;
    nFrames = size(images.Data.yxt, 3);
    nParts = ceil(nFrames / batchSize);
else
    error('Images must be a numeric or a cell array')
end


% Load first batch of images.
if loadImages
    imArray = load.loadImagesFromFile(images, 1, batchSize);
else
    imArray = images;
end

imageMask = mean(imArray, 3) ~= 0;
imageMask = imclose(imageMask, ones(3,3));
imageMask = imerode(imageMask, ones(3,3));

% % % Make some preparations of variables.

% Todo: Make options optional and use default options if options are missing.
extractNeuropil = options.extractNeuropil;
npilMethod = options.neuropilExtractionMethod;

savedir = options.savePath;
if ~exist(savedir, 'dir'); mkdir(savedir); end

% Prepare mask for signal extraction based on neuropil extraction method
structArrayOfMasks = signalExtraction.prepareMasks(roiArray, npilMethod, [], imageMask);

% Function handle for creating filenames
filename = @(varName) sprintf('%s_%s.mat', options.filename, varName);

% % % Loop through parts and extract signals

% Shorten function name for extracting signals to avoid looong lines...
extract = @signalExtraction.extractSignalFromImageData;


% Set default version to v2. v1 is comparably slow for one roi and requires
% more memory because the imdata has to be double.
if ~isfield(options, 'version') || isempty(options.version)
    options.version = 'v2';
end

% Todo: streamline v1/v2 abit more...
switch options.version
    case 'v1'
        % Prepare masks: Each mask is weighted by lam (SUM TO 1)
        nRois = numel(structArrayOfMasks);

        cellMasks = cat(3, structArrayOfMasks(:).unique);
        cellMasks = reshape(cellMasks, [], size(cellMasks,3))';
        cellMasks = cellMasks ./ sum(cellMasks, 2);
        cellMasks = sparse(cellMasks);
        neuropMasks = cat(3, structArrayOfMasks(:).neuropil);
        neuropMasks = reshape(neuropMasks, [], size(neuropMasks,3))';
        neuropMasks = neuropMasks ./ sum(neuropMasks, 2);
        neuropMasks = sparse(neuropMasks);
end


% Preallocate signal arrays.

switch options.version
    case 'v1'
        [fRoi, fPil] = deal(NaN(nRois, nFrames, 'single'));
        
    case 'v2'
        % Initialize arrays for signals. Size unknown, so they are empty.
        fullRawSignal = [];             % nSamples x nRois
        fullSubSignal = [];             % nSamples x nSubregions x nRois
end


cnt = 0;

for i = 1:nParts

    if loadImages && i ~= 1
        imArray = load.loadImagesFromFile(images, i, batchSize);
    elseif loadImages && i == 1
        % skip. Images were loaded before creating masks
    else
        imArray = images;
    end

    switch options.version
        case 'v1'
            
            nT = size(imArray, 3);
            imArray = double(reshape(imArray, [], nT));
            
            % compute roi fluorescense
            fRoi(:, cnt + (1:nT)) = cellMasks * imArray;

            % compute neuropil fluorescence
            fPil(:, cnt + (1:nT)) = neuropMasks * imArray;
            cnt = cnt + nT;
        
        case 'v2'

            % Extract signals from current part and add to the full raw signal
            tempRawSignal = extract(imArray, structArrayOfMasks, 'raw');
            fullRawSignal = cat(1, fullRawSignal, tempRawSignal);

            % Extract "sub" signals from current part and add to the full signal.
            if extractNeuropil
                tempSubSignal = extract(imArray, structArrayOfMasks, npilMethod);
                fullSubSignal = cat(1, fullSubSignal, tempSubSignal);
            end

    end
end

switch options.version
    
    case 'v1'
        roisMeanF = fRoi;
        npilMediF = fPil;
        save(fullfile(savedir, filename('rois_meanf')), 'roisMeanF')
        save(fullfile(savedir, filename('npil_medif')), 'npilMediF')
    case 'v2' 
        roisMeanFRaw = squeeze(permute(fullRawSignal, [3, 2, 1]));% % Save extracted signals. Save as nRois x nSamples.
        save(fullfile(savedir, filename('rois_meanf_raw')), 'roisMeanFRaw')

        % % Save signal from neuropil and the unique roi.
        if extractNeuropil
            switch lower(npilMethod)
                case 'standard' % Save as nRois x nSamples
                    roisMeanF = squeeze(fullSubSignal(:, 1, :))';
                    npilMediF = squeeze(fullSubSignal(:, 2, :))';
                    save(fullfile(savedir, filename('rois_meanf')), 'roisMeanF')
                    save(fullfile(savedir, filename('npil_medif')), 'npilMediF')
                case 'fissa'
                    savepath = fullfile(savedir, filename('extracted_fissa'));
                    save(savepath, 'extractedSignals')
            end
        end
        
end


% % Demix Signals
if extractNeuropil
    switch npilMethod
        case 'Standard'
%             correctedSignal = signalExtraction.standard.subtractNeuropil(extractedSignals); % Todo make function
%             save(fullfile(savedir, filename('npil_subtracted')), 'correctedSignal')
        case 'Fissa'
            extractedSignalPath = fullfile(savedir, filename('extracted_fissa'));
            separatedSignalPath = fullfile(savedir, filename('separated_fissa'));
            
            % Call python script to run fissa separation
            path = mfilename('fullpath');
            [path, ~, ~] = fileparts(path);
            pyscript = fullfile(path, '+fissa/fissa_separation.py');
            
            [status, result] = system(sprintf('python %s %s %s', pyscript, ...
                                    extractedSignalPath, separatedSignalPath));
                                
            if status; error(result); end
            
            S = load(separatedSignalPath, 'matchedSignals');
            correctedSignal = S.matchedSignals;
            correctedSignal = squeeze(correctedSignal(:, 1, :));
    end
end


% % Calculate DeltaF over F

% if extractNeuropil
%     roiSignal = squeeze(correctedSignal); % nSamples x nRois
% else
%     roiSignal = extractedSignalsRaw;
% end
% 
% calculateDff = str2func(options.dffMethod);



dff = signalExtraction.dff.dffRoiMinusDffNpil(double(roisMeanF'), double(npilMediF'), false);
dff = dff';
save(fullfile(savedir, filename('dff')), 'dff')

% % Deconvolve signal
if ~isfield(options, 'fps')
    options.fps = 31;
end

if options.deconvolveSignal
    switch options.deconvolutionMethod
        case 'CaImAn'
            % Extract and save deconvolved activity
            [ciaDeconv, ciaDenois, ciaOptions] = signalExtraction.CaImAn.deconvolve(dff, options);
            save(fullfile(savedir, filename('cia_deconvolved')), 'ciaDeconv')
            save(fullfile(savedir, filename('cia_denoised')), 'ciaDenois')
            save(fullfile(savedir, filename('cia_options')), 'ciaOptions')

% %             % Estimate and save spiking activity
% %             ciaSpikeThreshold = ones(size(ciaDeconv, 1), 1) * 0.1;
% % %             save(fullfile(savedir, filename('cia_spikethreshold')), 'ciaSpikeThreshold')
% %             opt.spikethreshold = ciaSpikeThreshold;
% %             opt.nSpikes = cellfun(@(roiOpt) roiOpt.nSpikes, ciaOptions);
% %             
% %             [ciaSpikes] = signalExtraction.spikeEstimation.integrateAndFire(ciaDeconv, opt);
% %             save(fullfile(savedir, filename('cia_spikes')), 'ciaSpikes')
% % 
% %             % Remove spikes which cannot be distinguished from noise
% %             samplesToIgnore = signalExtraction.spikeEstimation.getSpikeFilter(dff', ciaDenois', 'median');
% %             ciaSpikes(samplesToIgnore') = 0;
% %             save(fullfile(savedir, filename('cia_spikes_v2')), 'ciaSpikes')

        case 'Suite2P'
            % Extract and save deconvolved activity
            fps = 1/options.dt;
            s2pDeconv = signalExtraction.Suite2P.deconvolve(dff, fps);
            save(fullfile(savedir, filename('s2p_deconvolved')), 's2pDeconv')

% %             % Estimate and save spiking activity
% %             s2pSpikeThreshold = ones(size(s2pDeconv, 1), 1) * 0.24;
% %             save(fullfile(savedir, filename('s2p_spikethreshold')), 's2pSpikeThreshold')
% %             opt.spikethreshold = s2pSpikeThreshold;
% %             [s2pSpikes] = signalExtraction.spikeEstimation.integrateAndFire(s2pDeconv, opt);
% %             save(fullfile(savedir, filename('s2p_spikes')), 's2pSpikes')

    end
end

save(fullfile(savedir, filename('signal_extraction_options')), 'options')

end
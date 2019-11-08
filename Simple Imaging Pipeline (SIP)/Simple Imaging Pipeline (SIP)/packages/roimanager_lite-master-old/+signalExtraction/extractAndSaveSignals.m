function extractAndSaveSignals(images, roiArray, options)
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



% % First, determine if images have to be loaded.
if iscell(images)
    loadImages = true;
    nParts = numel(images);
elseif isnumeric(images)
    loadImages = false;
    nParts = 1;
else
    error('Images must be a numeric or a cell array')
end

% % Function handle for creating filenames
% filename = @(varName) strrep(options.filename, '.mat', sprintf('_%s.mat', varName) );
filename = @(varName) sprintf('%s_%s.mat', options.filename, varName);


% Todo: make options optional and use default options if options are missing.
extractNeuropil = options.extractNeuropil;
npilMethod = options.neuropilExtractionMethod;


% % Loop through parts and extract signals
extractedSignalsRaw = [];                 % nSamples x nRois
extractedSignals = [];               % nSamples x nSubregions x nRois

for i = 1:nParts
    
    if loadImages
        imArray = rmUtil.stack2mat(images{i});
    else
        imArray = images;
    end
    
    extractedSignalsRaw = cat(1, extractedSignalsRaw, signalExtraction.extractSignalFromImageData(imArray, roiArray, 'raw'));
    if extractNeuropil
        extractedSignals = cat(1, extractedSignals, signalExtraction.extractSignalFromImageData(imArray, roiArray, npilMethod));
    end
       
end

% % Save extracted signals. Save as nRois x nSamples.
roisMeanFRaw = squeeze(permute(extractedSignalsRaw, [3, 2, 1]));

if ~exist(options.savePath, 'dir'); mkdir(options.savePath); end

save(fullfile(options.savePath, filename('rois_meanf_raw')), 'roisMeanFRaw')

if extractNeuropil
    switch lower(npilMethod)
        case 'standard' % Save as nRois x nSamples
            roisMeanF = squeeze(extractedSignals(:, 1, :))';
            npilMediF = squeeze(extractedSignals(:, 2, :))';
            save(fullfile(options.savePath, filename('rois_meanf')), 'roisMeanF')
            save(fullfile(options.savePath, filename('npil_medif')), 'npilMediF')
        case 'fissa'
            save(fullfile(options.savePath, filename('extracted_fissa')), 'extractedSignals')
    end
end


% % Demix Signals
if extractNeuropil
    switch npilMethod
        case 'Standard'
%             correctedSignal = signalExtraction.standard.subtractNeuropil(extractedSignals); % Todo make function
%             save(fullfile(options.savePath, filename('npil_subtracted')), 'correctedSignal')
        case 'Fissa'
            extractedSignalPath = fullfile(options.savePath, filename('extracted_fissa'));
            separatedSignalPath = fullfile(options.savePath, filename('separated_fissa'));
            
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

dff = signalExtraction.dff.dffRoiMinusDffNpil(roisMeanF', npilMediF');
dff=dff'; %save as nRois x nSamples
save(fullfile(options.savePath, filename('dff')), 'dff')

% % Deconvolve signal

if options.deconvolveSignal
    switch options.deconvolutionMethod
        case 'CaImAn'
            % Extract and save deconvolved activity
            [ciaDeconv, ciaDenois, ciaOptions] = signalExtraction.CaImAn.deconvolve(dff);
            save(fullfile(options.savePath, filename('cia_deconvolved')), 'ciaDeconv')
            save(fullfile(options.savePath, filename('cia_denoised')), 'ciaDenois')
            save(fullfile(options.savePath, filename('cia_options')), 'ciaOptions')

            % Estimate and save spiking activity
            ciaSpikeThreshold = ones(size(ciaDeconv, 1), 1) * 0.05;
            save(fullfile(options.savePath, filename('cia_spikethreshold')), 'ciaSpikeThreshold')
            opt.spikethreshold = ciaSpikeThreshold;
            [ciaSpikes] = signalExtraction.spikeEstimation.integrateAndFire(ciaDeconv, opt);
            save(fullfile(options.savePath, filename('cia_spikes')), 'ciaSpikes')
            
            % Remove spikes which cannot be distinguished from noise
            samplesToIgnore = signalExtraction.spikeEstimation.getSpikeFilter(dff', ciaDenois', 'median');
            ciaSpikes(samplesToIgnore') = 0;
            save(fullfile(options.savePath, filename('cia_spikes_v2')), 'ciaSpikes')
            
        case 'Suite2P'
            % Extract and save deconvolved activity
            fps = 1/options.dt;
            s2pDeconv = signalExtraction.Suite2P.deconvolve(dff, fps);
            save(fullfile(options.savePath, filename('s2p_deconvolved')), 's2pDeconv')
            
            % Estimate and save spiking activity
            s2pSpikeThreshold = ones(size(s2pDeconv, 1), 1) * 0.24;
            save(fullfile(options.savePath, filename('s2p_spikethreshold')), 's2pSpikeThreshold')
            opt.spikethreshold = s2pSpikeThreshold;
            [s2pSpikes] = signalExtraction.spikeEstimation.integrateAndFire(s2pDeconv, opt);
            save(fullfile(options.savePath, filename('s2p_spikes')), 's2pSpikes')
            
    end
end

save(fullfile(options.savePath, filename('signal_extraction_options')), 'options')

end
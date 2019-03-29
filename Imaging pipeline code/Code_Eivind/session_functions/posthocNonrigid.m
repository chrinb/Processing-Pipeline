function posthocNonrigid(sessionID)

sessionFolder = getSessionFolder(sessionID);
sessionInfo = loadSessionInfo(sessionID);

ch = 2;

for block = 1:sessionInfo.nBlocks

    imArray = loadRegisteredImages(sessionID, block, ch);

    Y1 = double(imArray);
    options_nonrigid = NoRMCorreSetParms('d1',size(Y1,1),'d2',size(Y1,2),...
                           'grid_size',[64,64],'mot_uf',4,'bin_width',43,...
                           'max_shift',15,'max_dev',12,'us_fac',50);

    [imArray, ~, ~] = normcorre_batch(Y1, options_nonrigid);
    
    saveFolder = fullfile(sessionFolder, 'calcium_images_aligned');
    filenm_id = [ sessionID, '_block', num2str(block, '%03d'), '_ch', num2str(ch), '_nonrigid' ];
    filenm = ['calcium_images_', filenm_id, '.tiff'];

    mat2stack(uint8(imArray), fullfile(saveFolder, filenm))

    % save max and average projection of stack
    avg_filenm = ['stackAVG_', filenm_id, '.tif'];
    max_filenm = ['stackMax_', filenm_id, '.tif'];

    imwrite(uint8(mean(imArray, 3)), fullfile(sessionFolder, 'preprocessed_data', avg_filenm), 'TIFF')
    % Despeckle before taking the max
    for f = 1:size(imArray, 3)
             imArray(:, :, f) = medfilt2(imArray(:, :, f));
    end

    imwrite(uint8(max(imArray, [], 3)), fullfile(sessionFolder, 'preprocessed_data', max_filenm), 'TIFF')

end
end
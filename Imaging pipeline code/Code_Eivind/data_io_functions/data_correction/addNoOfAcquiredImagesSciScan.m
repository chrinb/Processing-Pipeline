function addNoOfAcquiredImagesSciScan(sessionID)

sessionPath = getSessionFolder(sessionID);
sessionInfo = loadSessionInfo(sessionID);

nBlocks = sessionInfo.nBlocks;

rawImagePath = fullfile(sessionPath, 'calcium_images_raw_ss');
corImagePath = fullfile(sessionPath, 'calcium_images_aligned');

blockFolders = dir(fullfile(rawImagePath, '2017*' ));

ch = 2;

for block = 1:nBlocks

    filenm_id = [ sessionID, '_block', num2str(block, '%03d'), '_ch', num2str(ch) ];
    filenm = ['calcium_images_', filenm_id, '.tiff'];

    imInfo = imfinfo(fullfile(corImagePath, filenm));
    nFrames = length(imInfo);
    
    blockFolderPath = fullfile(rawImagePath, blockFolders(block).name);
    inifilename = dir(fullfile(blockFolderPath, '*.ini'));
    inifilePath = fullfile(blockFolderPath, inifilename(1).name);
    
    inistring=fileread(inifilePath);
    
    new_str = sprintf(['no..of.frames.acquired = ', num2str(nFrames, '%.12f'), '\n']);
    insertPoint = regexp([inistring ' '], 'x.correction');
    inistring = [inistring(1:insertPoint-1), new_str, inistring(insertPoint:end)];
        
    fid = fopen(inifilePath, 'w');
    fwrite(fid, inistring);
    fclose(fid);
    

end

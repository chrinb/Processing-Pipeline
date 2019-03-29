function applyRotationToAllChunks

angle = 1
dx = -100
dy = -40

for x = 1:chunks
   
    correctedImArray = zeros(size(imArray));
    
    for y = 1:numFrames
        
       correctedImArray(:,:,y) = rotateFramesInChunk(imArray(:,:,y),dx,dy,angle);
       
        
    end
    
    
    
end






end
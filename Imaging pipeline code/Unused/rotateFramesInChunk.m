function imArrayFinished = rotateFramesInChunk(imArray,x_padd,y_padd,angle)
% x_padd = 113;
% y_padd = 23;
% angle = 2;

% % Load stack
% imArray = stack2mat('D:\Data\mouse1004\session-m1004-20171002_1656_pretraining\calcium_images_aligned\calcium_images_m1004-20171002_1656_pretraining_block001_ch2_part001.tif',1);
% 
% %Subset image array for testing
% imArray = imArray(:,:,1:200);
%imArray = stack2mat('D:\Data\mouse1004\session-m1004-20171003_1454-001\stack_projections\stackAVG_m1004-20171003_1454-001_block001_ch2_part003.tif',1);
% figure(1);
% 
% subplot(2,2,1);
% image(imArray);
imArray = paddAroundStack(imArray,x_padd,y_padd);
% subplot(2,2,2);
% image(imArray);
nFrames = size(imArray,3);
angles = ones(nFrames,1)*angle;
imArrayCorr = applyFrameCorrections(imArray,angles,[],[]);
% subplot(2,2,3);
% image(imArrayCorr);

% Cut out original image size and remove padding

if x_padd>0
    imArrayFinished = imArrayCorr(:,1:end-abs(x_padd));
else
    imArrayFinished = imArrayCorr(:,abs(x_padd)+1:end);
end

if y_padd>0
    imArrayFinished = imArrayFinished(1:end-abs(y_padd),:);
else
    imArrayFinished = imArrayFinished(abs(y_padd)+1:end,:);
end
% subplot(2,2,4);
% image(imArrayFinished);



end
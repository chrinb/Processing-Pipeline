% Raster scanning.

fig = figure('Position', [200,200,500,500], 'Color', 'white');

imAx = axes('Position', [0.05, 0.05, 0.9, 0.9]);

caImage_orig = imread('/Users/eivinhen/Desktop/raster_test.tif');
[nRows, nCols] = size(caImage_orig);


%caImage_orig = ones(512,512);
caImage_anim = zeros(nRows, nCols);

line_segment_length = 64;
rows_length = 2;

imageObj = imshow(caImage_anim, [0,255]);
colormap gray

pause_time = 0.2:-0.01:0.05;
pause_counter = 1;
pause_time(end:end+50) = 0.05;

for row = 1:4:nRows;
    
    
    
     if row < 8
        for line_segment = 1:nCols
            caImage_anim(row:row+3, line_segment) = caImage_orig(row:row+3, line_segment);
            imageObj.CData = caImage_anim;
            pause(0.005)
        end
        
     elseif row < 12
        for line_segment = 1:nCols
            caImage_anim(row:row+3, line_segment) = caImage_orig(row:row+3, line_segment);
            imageObj.CData = caImage_anim;
            pause(0.004)
        end
     elseif row < 16
        for line_segment = 1:nCols
            caImage_anim(row:row+3, line_segment) = caImage_orig(row:row+3, line_segment);
            imageObj.CData = caImage_anim;
            pause(0.003)
        end
        
    
    elseif row < 20
        for line_segment = 1:nCols
            caImage_anim(row:row+3, line_segment) = caImage_orig(row:row+3, line_segment);
            imageObj.CData = caImage_anim;
            pause(0.001)
        end
    elseif row < 24
        for line_segment = 1:nCols
            caImage_anim(row:row+3, line_segment) = caImage_orig(row:row+3, line_segment);
            imageObj.CData = caImage_anim;
            pause(0.0005)
        end
    elseif row < 28
        for line_segment = 1:nCols
            caImage_anim(row:row+3, line_segment) = caImage_orig(row:row+3, line_segment);
            imageObj.CData = caImage_anim;
            pause(0.0001)
        end
    elseif row < 32
        for line_segment = 1:nCols
            caImage_anim(row:row+3, line_segment) = caImage_orig(row:row+3, line_segment);
            imageObj.CData = caImage_anim;
            pause(0.00001)
        end
    elseif row < 36
        for line_segment = 1:nCols
            caImage_anim(row:row+3, line_segment) = caImage_orig(row:row+3, line_segment);
            imageObj.CData = caImage_anim;
            pause(0.000001)
        end
    else
        caImage_anim(row:row+3, :) = caImage_orig(row:row+3, :);
        imageObj.CData = caImage_anim;
    end
    
    if row < 36
        continue
    else
        pause(pause_time(pause_counter))
        pause_counter = pause_counter+1;
    end

        
end
        
    





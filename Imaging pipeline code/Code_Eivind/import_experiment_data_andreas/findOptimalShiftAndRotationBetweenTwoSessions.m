function [dx, dy, angle] = findOptimalShiftAndRotationBetweenTwoSessions()

first_session_file = 'D:\Data\mouse1004\session-m1004-20171002_1656_pretraining\stack_projections\stackAVG_m1004-20171002_1656_pretraining_block001_ch2_part005.tif';
second_session_file = 'D:\Data\mouse1004\session-m1004-20171003_1454-001\stack_projections\stackAVG_m1004-20171003_1454-001_block001_ch2_part005.tif';

% [first_session_file, first_session_path] = uigetfile('Select first session');
% [second_session_file,second_session_path] = uigetfile('Select second session');

% first_session_file = [first_session_path first_session_file];
% second_session_file = [second_session_path second_session_file];

imArray_first = stack2mat(first_session_file,1);
imArray_second = stack2mat(second_session_file,1);
imArray_second_original = imArray_second;
% % 
% imArray_second(imArray_second<200) = 0;
% imArray_first(imArray_first<200) = 0;

count = 1;
correlationValues = [];

for dx = [[-100:-80]] %[[-105:-1:-135] [105:1:135]] %1:200
    disp(dx)
   for dy = [[10:40]] %1:100
      for angle = 0:0.2:2
          
          check_dx = dx;
          check_dy = dy;
          check_angle = angle;
          correctedImArray = rotateFramesInChunk(imArray_second,check_dx,check_dy,check_angle);
          R = corr2(imArray_first,correctedImArray);
          correlationValues(1,count) = R;
          correlationValues(2,count) = check_dx;
          correlationValues(3,count) = check_dy;
          correlationValues(4,count) = check_angle;
          count = count+1;
          
      end          
   end
end

indx = find(correlationValues(1,:) == max(correlationValues(1,:)));
parameters = [];
count = 1;
for x = indx
    parameters(count,:) = correlationValues(:,x);
    count = count + 1;
end

if (length(indx)>1)
    params = mean(parameters);
else
    params = parameters;
end

dx = round(params(2))
dy = round(params(3))
angle = round(params(4))

correctedImArray = rotateFramesInChunk(imArray_second_original,dx,dy,angle);

savePath = ['D:\Data\mouse1004\session-m1004-20171003_1454-001\' 'test_file_fixedcorr3.tiff'];
mat2stack(uint8(correctedImArray),savePath);



end
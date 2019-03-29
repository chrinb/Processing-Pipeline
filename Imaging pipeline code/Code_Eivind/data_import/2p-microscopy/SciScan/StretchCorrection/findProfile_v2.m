% Script to find a profile/lookup table to correct for resonance stretch

% Steps to make the profile

%   - Rotate a pollen slide 360 degrees under the microscope while making a resonance
%     recording
%   - Open stack in image J
%   - Create a mac projection
%   - Create elliptical rois and save to a roi file.
%   - Add path to this file and run script, or name according to path underneath and
%   - change zoom variable

zoom = 2;

path = ['/Users/eivinhen/PhD/Software/MATLAB/RotationExperiments/data_import/2p-microscopy/SciScan/StretchCorrection/RoiSet_zoom', num2str(zoom)];

roifiles = dir(fullfile(path, '*.roi'));

nRois = length(roifiles);

x_radius = zeros(1, nRois+1);
y_radius = zeros(1, nRois+1);

for roi = 1:nRois
    [sRoi] = ReadImageJROI(fullfile(path, roifiles(roi).name));
    x_radius(roi+1) = sRoi.vnRectBounds(4)-sRoi.vnRectBounds(2);
    y_radius(roi+1) = sRoi.vnRectBounds(3)-sRoi.vnRectBounds(1);
end

path = ['/Users/eivinhen/PhD/Software/MATLAB/RotationExperiments/data_import/2p-microscopy/SciScan/StretchCorrection/teststack_zoom', num2str(zoom), '.tif'];

%pollen_test = imread(path);

x_radius = x_radius / 2;
y_radius = y_radius / 2;

delta_r = x_radius - y_radius;

% Assuming symmetry of stretch effect around center:
y_radius = [ abs(256-fliplr(y_radius)), 256+y_radius(2:end)];
x_radius = [ abs(256-fliplr(x_radius)), 256+x_radius(2:end)];

delta_r = [fliplr(delta_r), delta_r(2:end)];

% Use a spline interpolation to fit a line to these points
delta_r_interp = interp1(x_radius, delta_r, 1:512, 'spline');

switch zoom
    case 1
        stretch_zoom1 = delta_r_interp;
    case 2
        stretch_zoom2 = delta_r_interp;
end

try
    save('/Users/eivinhen/PhD/Software/MATLAB/RotationExperiments/data_import/2p-microscopy/SciScan/spline_interp_stretch.mat', ['stretch_zoom', num2str(zoom)], '-append')
catch
    save('/Users/eivinhen/PhD/Software/MATLAB/RotationExperiments/data_import/2p-microscopy/SciScan/spline_interp_stretch.mat', ['stretch_zoom', num2str(zoom)])
end


% %Compare results
% figure(1)
% title('Spline interpolation and 3rd order polynomial fit')
% plot(1:512, delta_r_interp)
% hold on
% 
% plot(x_radius, delta_r, 'o' )
% xlabel('Image Width (px)')
% ylabel('x radius - y radius (px)')
% xlim([1,512])


% imArray = stack2mat(path);
% imArray = correctResonanceStretch(imArray, zoom);
% mat2stack(imArray, ['stretched_zoom',num2str(zoom), '.tif'])

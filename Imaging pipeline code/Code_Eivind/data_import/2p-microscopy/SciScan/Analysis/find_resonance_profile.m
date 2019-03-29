% Script to find a good sinusoidal function to correct for resonance
% stretch

% Values obtained from rotating a pollen slide 360 degrees.
% Recording Name: 20170522_17_56_42_Rotating-Pollen_XYT

% From this recording I made an average stack projection, where the pollen
% rotation paths were visible. Due to the resonance mirror, these paths are
% elliptical. I took 4 measurements of the x and y diameter:

% 1: x = 139, y = 133
% 2: x = 268, y = 245
% 3: x = 362, y = 318
% 4: x = 430, y = 366

% Fit sinusoid to these values. Going to shrink the image in the x-direction, so will
% keep y pixel coordinates and use the difference, x-y, as the sine
% values. Now, this will be the values around the top/bottom of the sine.
% After getting the sine function, this has to be differentiated and the
% resulting values used for scale in imresize. Apply it to e.g. 10 and 10
% columns. 

folder = '/Users/eivinhen/Desktop/2017_05_22 - Pollen rotation with different x-correction';
filenm = 'pollen_rotated3_xcorrect-0.20_175642.tif';

pollen_test = imread(fullfile(folder, filenm));

x_radius = [0, 139, 268, 362, 430] / 2;
y_radius = [0, 133, 245, 318, 366] / 2;

delta_r = x_radius - y_radius;

% Assuming symmetry of stretch effect around center:
y_radius = [ abs(256-fliplr(y_radius)), 256+y_radius(2:end)];
delta_r = [fliplr(delta_r), delta_r(2:end)];


% Use a spline interpolation to fit a line to these points
delta_r_interp = interp1(y_radius, delta_r, 1:512, 'spline');

% Fit a 3rd order polynomial to these points.
p = polyfit(y_radius, delta_r, 3);
pixels = 1:512;
delta_r_poly3 = polyval(p, pixels);

% Compare results
% figure(1)
% title('Spline interpolation and 3rd order polynomial fit')
% plot(1:512, x_interp)
% hold on
% plot(pixels, delta_r_poly3)


% Create a sinusoidal segment (parameters)
mirrorFreq = 8000;
lineFreq = mirrorFreq * 2;
lineDutyCycle = 0.66;
scale_factor = 110; % Found by trial and error

% Make half a cosine and mirror it around y-axis.
x = linspace(0, pi*lineDutyCycle/2, 256);
y = -scale_factor * cos(x) + scale_factor;
y = [fliplr(y), y];

plot(1:512, y)
hold on
plot(y_radius, delta_r, 'o' )
%plot(1:512, delta_r_interp)
%plot(1:512, delta_r_poly3)
warning('off', 'MATLAB:legend:IgnoringExtraEntries')
legend({'Sine Fit', 'Sample points', 'Spline', '3rd order polynom'})
warning('on', 'MATLAB:legend:IgnoringExtraEntries')

% Find the incremental change - used for correction
% differentiated = diff(y);
% differentiated = horzcat(differentiated(1), differentiated);
% 
% delta_r_poly3 = diff(delta_r_poly3);
% delta_r_poly3 = horzcat(delta_r_poly3(1), delta_r_poly3);

% Plot comparison of sampling points, sine and 3rd degree polynomial





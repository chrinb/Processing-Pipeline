function plotSessionOverview_old(data,trials)
start = 1;
stopp = 18000;
run_speed = data(7).daqdata.run_speed;
normSign = data(7).normalizedROIsignal;
gratingON = data(7).daqdata.photodiode_filtered;
% Normalize ROI signals
%normalizedSignals = normalizeROIsignals(sessionData.ROIsignal)

wheel_location = [];
wheel_circ = 2*pi*11;

for i = 1:length(data(7).daqdata.run_count)
   wheel_location(i) = rem(data(7).daqdata.run_count(i),wheel_circ);
    
end


for x = 21:50
    figure(1);
    title(x)
    hold on
    subplot(4,1,1)
    plot(normSign(start:stopp,x))
    subplot(4,1,2)
    plot(run_speed(start:stopp))
    subplot(4,1,3)
    plot(gratingON(start:stopp))
    subplot(4,1,4)
    plot(wheel_location(start:stopp))
    hold off
    pause;
    
end

end
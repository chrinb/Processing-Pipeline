function plotSessionOverview_notfunc(sessionData)

start = 1;
stop = 6000; %size(sessionData.normalized_signals,1);
sample_times = (1:stop)/30;

figure(10);
clf;
subplot(3,1,1);
%ROIsignal = sessionData.normalized_signals(1:length(sessionData.daqdata.run_speed),:)';
ROIsignal = sessionData.deltaFoverF';%normalized_signals';

numROIs = size(ROIsignal,1);
ROIsToPlot = 1:109;%numROIs;%[1:70, 130:165];

%--- imagesc
colormap('jet');
imagesc(normalizeROIsignals(ROIsignal(ROIsToPlot,start:stop)))
%--- calcium traces
% hold on
% for x = ROIsToPlot
%    
%     plot(ROIsignal(x,start:stop));
%     
% end
% hold off

xlim([1,length(sample_times)]);
xticks([]);

title('ROIs');
subplot(3,1,3);
hold on
title('Grating orientations')
dg_field_names = fieldnames(sessionData.daqdata.dgOnsetForEachDirection);
xlim([1,sample_times(end)]);
xlabel('Time (s)');
for x = 1:length(dg_field_names)
   plot(sample_times,sessionData.daqdata.dgOnsetForEachDirection.(dg_field_names{x})(start:stop));
    
end

subplot(3,1,2);
hold on
title('Running speed')
plot(sample_times,sessionData.daqdata.run_speed(start:stop));
ylabel('Speed cm/s');
xlim([1,sample_times(end)]);

end


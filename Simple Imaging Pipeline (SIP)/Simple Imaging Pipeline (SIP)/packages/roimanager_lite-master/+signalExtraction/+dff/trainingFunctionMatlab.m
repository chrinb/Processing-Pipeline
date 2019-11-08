function [correctedSignal] = trainingFunctionMatlab(roisMeanFRaw,npilMediF)

% Create function does that neuropil subtraction and calculate df/f
%Input1: Raw roi signal
%Input2: Neuropil
%Output: Neuropil subtracted df/f

f=5;
Path = get_path;
experiment = get_experiment_list([1 2 3 4 5 6 7 9 10 11 12 13]);

load(fullfile(Path.processed,filesep,'imaging',filesep,experiment(f).name,filesep,'roisignals', 'raw.mat'))
load(fullfile(Path.processed,filesep,'imaging',filesep,experiment(f).name,filesep,'roisignals', 'neuropil.mat'))

for i=1:size(roisMeanFRaw,1)
    correctedSignal(i,:)=(roisMeanFRaw(i,:)-mean(roisMeanFRaw(i,1:(300*31))))/mean(roisMeanFRaw(i,1:(300*31)));
end

imagesc(correctedSignal)
function sessionData = preprocess_downSampleAllChannels(sessionData,ds)
% Downsample session from 2500 hz to 500 hz (fex)

if nargin < 2
    ds = 5;
end

sessionData.daqdata.metadata.Sampling_rate_downsampled =  sessionData.daqdata.metadata.Sampling_rate_downsampled/ds;

if isfield(sessionData.daqdata,'run_speed')
    sessionData.daqdata.run_speed = downsample(sessionData.daqdata.run_speed,ds);
end

if isfield(sessionData.daqdata,'photodiode_filtered')
    sessionData.daqdata.photodiode_filtered = downsample(sessionData.daqdata.photodiode_filtered,ds);
end

if isfield(sessionData.daqdata,'shock_signal')
    sessionData.daqdata.shock_signal = downsample(sessionData.daqdata.shock_signal,ds);
end

if isfield(sessionData.daqdata,'optostimulation')
    sessionData.daqdata.optostimulation = downsample(sessionData.daqdata.optostimulation,ds);
end


end
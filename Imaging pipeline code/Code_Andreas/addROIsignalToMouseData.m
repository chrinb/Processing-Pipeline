function data = addROIsignalToMouseData(data)

[signals, sessionID] = quickExtractSignalsAllFiles;
signals = signals';

mouseID = sessionID(2:findstr(sessionID,'-')-1);
mouseName = ['mouse' num2str(mouseID)];
sessionNumber = sessionID(end-2:end);

if isfield(data,mouseName)
    
    for x = 1:length(data.(mouseName))
       
        if strcmp(data.(mouseName)(x).daqdata.metadata.session_num,sessionNumber)
                data.(mouseName)(x).ROIsignals_raw = signals;
                data.(mouseName)(x).ROIsignals_dFoverF = deltaFoverFsimple(signals);
                data.(mouseName)(x).ROIsignals_zScoreNormalized = zScoreNormalize(data.(mouseName)(x).ROIsignals_dFoverF);
        end
        
    end
    

    
else
   disp('Mouse not found in database!'); 
end





end
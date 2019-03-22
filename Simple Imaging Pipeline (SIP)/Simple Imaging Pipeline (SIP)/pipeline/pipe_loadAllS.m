function sData = pipe_loadAllS()
% PIPE_LOADALLS is used to extract all necessary data from a session into a
% struct. When the function is executed, the user chooses a folder
% containing all the session data, and both the DAQdata and ROI signals
% will be extracted. A preprocessing of the DAQdata will also be done. The
% function requires that the data is structured orderly. 
% If ROIs are not drawn, the function will only give out the DAQdata.

% Choose session
fileFolder = uigetdir(getPathToDir('datadrive'));

try % Get session data from DAQ file
    sData = pipe_loadSessionDataS(fileFolder);
    
    try % Preprocess session data
        sData = pipe_preprocessSessionDataS(sData);

        try % Extract signal from all ROIs
            sData = pipe_extractSignalsFromROIsS(sData,fileFolder);
        catch
            disp('Problem with extracting signals from ROIs!');

        end
    catch
        disp('Problem with preprocessing session data!');
    end
    
catch
    disp('Problem with loading session data!');
end




end
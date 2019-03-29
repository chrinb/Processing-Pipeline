function data = addNewSessionToDatabase(data,addAllSessions)

if (nargin < 2)
    addAllSessions = 0; % User will select a session to be added, else all sessions in folder will be loaded.
end
%------------------------ LOAD ALL SESSIONS FROM MOUSE FOLDER ------
if addAllSessions == 1
    %------ Find all session folders and grab sessionID from each.
    mouseFolder = 'D:\Data\mouse1004'; %uigetdir();
    nameIndx = findstr('\',mouseFolder);
    mouseName = mouseFolder(nameIndx(end)+1:end);
    
    if ~isfield(data,mouseName)
        data.(mouseName) = struct();
    end
    
    subFolders = dir(mouseFolder);
    allSessionIDs = struct();
    IDnum = 1;
    fprintf('Found sessions:\n')
    for x = 1:length(subFolders)-1
        if ~isempty(findstr(subFolders(x).name,'session'))
            allSessionIDs(IDnum).id = getSessionIDfromString([subFolders(x).folder '\' subFolders(x).name]);
            if strcmp(allSessionIDs(IDnum).id(end-2:end),'pre')
                allSessionIDs(IDnum).id = [allSessionIDs(IDnum).id 'training'];
            end
            
            if strcmp(allSessionIDs(IDnum).id(end-2:end),'pos')
                allSessionIDs(IDnum).id = [allSessionIDs(IDnum).id 'ttraining'];
            end
            
            fprintf('%s',allSessionIDs(IDnum).id);
            fprintf('\n');
            IDnum = IDnum+1;
        end
    end

    % Import metadata for each session
    for x = 1:length(allSessionIDs)
       data.(mouseName)(x).daqdata = loadLabViewSession(allSessionIDs(x).id);
       % Find the time onsets for each drifting grating direction:
%        [data.(mouseName)(x).daqdata.dg_onsets,data.(mouseName)(x).daqdata.dgOnsetForEachDirection] = setGratingDirectionAtPhotoDiodeMeasure(data.(mouseName)(x));
%        % Get a matrix containing the onset times (sample index) sorted for each
%        % grating direction:
%        data.(mouseName)(x).daqdata.gratingTypeOnsetTimes = findAllGratingDirectionWindows(data.(mouseName)(x));
    end


%------------------------ LOAD 1 SESSIONS FROM MOUSE FOLDER ------
else
    
    %------ Find all session folders and grab sessionID from each.
    sessionFolder = uigetdir();
    nameIndx = findstr('\',sessionFolder);
    mouseName = sessionFolder(nameIndx(end-1)+1:nameIndx(end)-1);
    sessionFolderName = sessionFolder(nameIndx(end)+1:end);
    
    sessionID = getSessionIDfromString(sessionFolderName);
    if strcmp(sessionID(end-2:end),'pre')
        sessionID = [sessionID 'training'];
    end
    if strcmp(sessionID(end-2:end),'pos')
    sessionID = [sessionID 'ttraining'];
    end


    %--- Import metadata for each session
    % If mouseName field does not exist, create it
    if ~isfield(data,mouseName)
        data.(mouseName) = struct();
    end

    %data.(mouseName)(end+1).daqdata = loadLabViewSession(sessionID);
    % Find the time onsets for each drifting grating direction:
    %        [data.(mouseName)(x).daqdata.dg_onsets,data.(mouseName)(x).daqdata.dgOnsetForEachDirection] = setGratingDirectionAtPhotoDiodeMeasure(data.(mouseName)(x));
    %        % Get a matrix containing the onset times (sample index) sorted for each
    %        % grating direction:
    %        data.(mouseName)(x).daqdata.gratingTypeOnsetTimes = findAllGratingDirectionWindows(data.(mouseName)(x));


    
    
end
    
    
    %-- Image registration
    %Use imregAllSessions(), select the mouse folder such that all sessions
    %will be image registrered. This is done using rigid-transformation. To
    %enable non-rigid transforms, change code in imregAllSessions.

    %-- Detect ROIs

%     %-- Get ROI signals
x= 1;

      [signals, dFoF, normalized_signals] = extractSignalsFullSession(sessionFolder);
      data.(mouseName)(x).ROIsignals_raw = signals;
      data.(mouseName)(x).deltaFoverF = dFoF;
      data.(mouseName)(x).normalizedROIsignal = normalized_signals;
%     data.(mouseName)(x).ROIsignals_raw = quickExtractSignalsAllFiles(data.(mouseName)(x));
% 
%     data.(mouseName)(x).nCh = 1; % set number of recording channels
%     data.(mouseName)(x).deltaFoverF = deltaFoverFsimple(data.(mouseName)(x));
%     data.(mouseName)(x).normalizedROIsignal = zScoreNormalize(data.(mouseName)(x));
% 

    %-- Plot running speeds across each drifting grating orientation to look
    %for any particular orientation that elicit more running behaviour.


end
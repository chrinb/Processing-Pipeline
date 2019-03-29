function data = pipelineAndreas()

%------ Find all session folders and grab sessionID from each.
mouseFolder = 'D:\Data\mouse1004'; %uigetdir();
nameIndx = findstr('\',mouseFolder);
data = struct();
mouseName = mouseFolder(nameIndx(end)+1:end);
data.(mouseName) = struct();
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
        fprintf('%s',allSessionIDs(IDnum).id);
        fprintf('\n');
        IDnum = IDnum+1;
    end
end

% Import metadata for each session
for x = 1:length(allSessionIDs)
   data.(mouseName)(x).daqdata = loadLabViewSession(allSessionIDs(x).id);
   % Find the time onsets for each drifting grating direction:
   [data.(mouseName)(x).daqdata.dg_onsets,data.(mouseName)(x).daqdata.dgOnsetForEachDirection] = setGratingDirectionAtPhotoDiodeMeasure(data.(mouseName)(x));
   % Get a matrix containing the onset times (sample index) sorted for each
   % grating direction:
   data.(mouseName)(x).daqdata.gratingTypeOnsetTimes = findAllGratingDirectionWindows(data.(mouseName)(x));
end

%-- Image registration
%Use imregAllSessions(), select the mouse folder such that all sessions
%will be image registrered. This is done using rigid-transformation. To
%enable non-rigid transforms, change code in imregAllSessions.

%-- Detect ROIs

%-- Get ROI signals
data.(mouseNum)(x).ROIsignals_raw = quickExtractSignalsAllFiles(data.(mouseNum)(x));

data.(mouseNum)(x).nCh = 1; % set number of recording channels
data.(mouseNum)(x).deltaFoverF = deltaFoverFsimple(data.(mouseNum)(x));
data.(mouseNum)(x).normalizedROIsignal = zScoreNormalize(data.(mouseNum)(x));


%-- Plot running speeds across each drifting grating orientation to look
%for any particular orientation that elicit more running behaviour.


end
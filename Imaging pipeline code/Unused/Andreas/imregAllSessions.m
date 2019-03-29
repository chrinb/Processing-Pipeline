function imregAllSessions()
% imregAllSessions lets the user select a folder containing all data from a
% mouse and all the sessions will be registrered. 

%----- Select registration methods
options = struct();
options.rigid = true;
options.nonrigid = true;

%------ Select folder to load sessions
mouseFolder = 'D:\Data\mouse1006'; %uigetdir();

%------ Find all session folders and grab sessionID from each.
subFolders = dir(mouseFolder);
allSessionIDs = struct();
IDnum = 1;
fprintf('Found sessions:\n')

for x = 1:length(subFolders)
    if ~isempty(findstr(subFolders(x).name,'session'))
        allSessionIDs(IDnum).id = getSessionIDfromString([subFolders(x).folder '\' subFolders(x).name]);
        fprintf('%s',allSessionIDs(IDnum).id);
        fprintf('\n');
        IDnum = IDnum+1;
    end
end

start_time = clock();
for i = [2] % This needs to be length(allSessionIDs) if you wish to loop through all sessions! Otherwise, select a subset of session numbers you wish to load. 
    curr_time = clock();
    sessionID = allSessionIDs(i).id;
    fprintf('----- Currently registrating from ID: %s -----\n',sessionID);
    fprintf('Session %d started at: %d:%d\n',i,curr_time(4:5));
    imregSessionSimple(sessionID,options)
end

fprintf('Started at: %d:%d\n',start_time(4:5))
end_time = clock();
fprintf('Ended at: %d:%d\n',end_time(4:5));

end
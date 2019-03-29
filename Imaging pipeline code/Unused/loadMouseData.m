function data = loadMouseData(mouseNumber)

% Select mouse

mouse_dir = ['D:\Data\mouse' num2str(mouseNumber)];
data = struct();

% Get all sessions
session_folders = dir(fullfile(mouse_dir, 'session*'));
for x = 1:length(session_folders)
   sessionID = getSessionIDfromPathString(session_folders(x).name);
   if strcmp(sessionID(end-2:end),'pre')
      sessionID = [sessionID 'training']; 
   end
   if strcmp(sessionID(end-2:end),'pos')
      sessionID = [sessionID 'ttraining']; 
   end
   
   fprintf('Loading session %i of %i\n',x,length(session_folders));
   data(x).sessionID = sessionID;
   data(x).daqdata = loadLabViewSession(sessionID);
   
   
  
end
end
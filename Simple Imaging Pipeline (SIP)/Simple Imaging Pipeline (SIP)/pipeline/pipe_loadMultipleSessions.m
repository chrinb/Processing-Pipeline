function mousedata = pipe_loadMultipleSessions(mousedata)
% Function not finished. Add the possibility to load multiple sessions at
% once.
fileFolder = uigetdir();

mousedata = pipe_loadSessionData(mousedata,fileFolder);
mousedata = pipe_extractSignalsFromROIs(mousedata,fileFolder);

end
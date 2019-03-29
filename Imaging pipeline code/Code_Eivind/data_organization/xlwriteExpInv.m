function [  ] = xlwriteExpInv(  )
%xlwriteExpInv Write experiment inventory to xls file
%   Requires xlWrite from matlab central

experimentInventory = loadExpInv( );

nSessionEntries = size(experimentInventory, 1);

% The xlWrite package downloaded from Matlab central requires the following lines:
xlWritePath = getPathToDir('xlwrite');

poiLibPath = fullfile(xlWritePath, 'poi_library');
addpath(xlWritePath)

javaaddpath(fullfile(poiLibPath, 'poi-3.8-20120326.jar'));
javaaddpath(fullfile(poiLibPath, 'poi-ooxml-3.8-20120326.jar'));
javaaddpath(fullfile(poiLibPath, 'poi-ooxml-schemas-3.8-20120326.jar'));
javaaddpath(fullfile(poiLibPath, 'xmlbeans-2.3.0.jar'));
javaaddpath(fullfile(poiLibPath, 'dom4j-1.6.1.jar'));

% Set path for excel file, and check if file already exists
expInventoryXl = fullfile(getPath('labbook'), 'experimentInventory_autogen.xlsx');
xlFileExists = exist(expInventoryXl, 'file');

%TODO: Load sessionData

xlCols = {'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O',...
          'P','Q','R','S','T','U','V','W','X','Y','Z'};                        

inclFields = {'dateOfExperiment', 'mouseNumber', 'sessionID', ...
              'mouseEnteredArena', 'mouseLeftArena', 'sessionProtocol', ...
              'nBlocks', 'nRois' };

%TODO: Add copied, processed, backup as fields.

% Write data to excel sheet.
lineCount = 3;

for s = 2:nSessionEntries
    sessionId = experimentInventory{s, 1};
    load(fullfile(getPath('labbook'), 'sessionData', strcat('session-', ...
                                                 sessionId, '-data.mat')));
    
    if s == 2 && ~xlFileExists
        xlwrite(expInventoryXl, inclFields, 'experimentInventory', ...
               'A2') ;
    end
    
    %loop through fields
    for f = 1:length(inclFields)
        xlwrite(expInventoryXl, {sessionData.(inclFields{f})}, 'experimentInventory', ...
               [xlCols{f}, num2str(lineCount) ':' xlCols{f}, num2str(lineCount)]) ;
    end
    
    lineCount = lineCount + 1; 
    
end

end


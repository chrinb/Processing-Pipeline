classdef session

%session object with properties listing key information about a session.
%   Methods can be used for loading, adding or deleting session objects
%   from a database which is stored as experimentInventory.mat on the 
%   Google Drive (nx2 cell array: {sessionID, sessionObject})
%
%   INPUT
%       sessionId (str) : sessionID, e.g. m002-20160901-1204

% Todo: Add average image of imaged population as a property here.


properties
    sessionID                   % Session ID ('m001-20170120-1800')
    date                        % Date of experiment
    time                        % Time of experiment
    storageRootPath             % Physical drive with data
    backupLocation              % Physical drive with backup of data
    protocol                    % Session Protocol
    isTransferedImData
    isTransferedLVData
    isBackedUp
    isRegistered                % Are calcium images registered?
    isAnalyzed                  % Are calcium images analysed?
    imLocation                  % Imaging location 
    imDepth                     % Imaging Depth.
end


methods
    
    
    function obj = session(sessionID)
        
        obj.sessionID = sessionID;
        
        try     % Load from database if it exists     
            obj = loadfromDB(obj);
            %disp(['Session ' sessionID ' loaded from experimentInventory'])
            
        catch   % Otherwise, create a new object
            obj.date = [obj.sessionID(12:13) '.' obj.sessionID(10:11) ...
                        '.' obj.sessionID(6:9)];
            obj.time = obj.sessionID(15:18);
            obj.imDepth = 'N/A';
            obj.isRegistered = false;
            obj.isAnalyzed = false;
            
         end
    end

    
    function obj = set.imLocation(obj, imLocation)
        obj.imLocation = imLocation;
    end

    
    function obj = set.imDepth(obj, imDepth)
        obj.imDepth = imDepth;
    end
    
    
    function obj = loadfromDB(obj)
        
        experimentInventory = loadExpInv();
        
        % Search for sessionID and return session entry if it exists
        entry = find(strcmp(obj.sessionID, experimentInventory(:,1)), 1);
        if isempty(entry)
            error('Cannot find session in experiment inventory')
        else
            obj = experimentInventory{entry, 2};
        end
    
    end
    
     
    function savetoDB(obj)
        % Add session object to a database sorted by sessionIDs

        experimentInventory = loadExpInv();
        
        % Make new entry or replace existing entry
        entry = find(strcmp(obj.sessionID, experimentInventory(:,1)), 1);
        if isempty(entry)
            experimentInventory(end+1, :) = {obj.sessionID, obj};
        else
            experimentInventory(entry, :) = {obj.sessionID, obj};
        end
        
        saveExpInv(experimentInventory)
        disp(['Session ' obj.sessionID ' saved to experimentInventory'])
        
    end
    
    
    function deletefromDB(sessionID)
        
        experimentInventory = loadExpInv();
        
        % Search for sessionID and delete session entry if it exists
        entry = find(strcmp(sessionID, experimentInventory(:,1)), 1);
        if isempty(entry)
            error('Cannot find specified session in experiment inventory')
        else
            experimentInventory(entry, :) = [];
        end
        
        saveExpInv(experimentInventory)
        
    end
    
    
    
end
end


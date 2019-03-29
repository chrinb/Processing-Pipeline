function [ ] = runPipeline( )
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here

microscope = 'SciScan';

% Update and load experiment inventory
updateExperimentInventory();
experimentInventory = loadExpInv();

% Find sessions which labview data is not transferred
sessions_istransfered = cellfun( @(s) s.isTransferedLVData, experimentInventory(2:end,2), 'uni', 0);
which_sessions = find(~cell2mat(sessions_istransfered)) + 1;

if ~isempty(which_sessions)
    for s = which_sessions
        try
            sessionID = experimentInventory{s,1};
            transferLabviewFiles(sessionID);
            %Set session raw path as property of session object.
            experimentInventory{s,2}.storageRootPath = getPathToDir('datadrive');
            experimentInventory{s,2}.isTransferedLVData = true;
        catch
            warning(['Labview files for session ', sessionIDs{s}, ' was not transfered'])
        end
    end
end


% Find sessions which imaging data is not transferred
sessions_istransfered = cellfun( @(s) s.isTransferedImData, experimentInventory(2:end,2), 'uni', 0);
which_sessions = find(~cell2mat(sessions_istransfered)) + 1;

for s = which_sessions
    
     try
        sessionID = experimentInventory{s,1};
        switch microscope
            case 'SciScan'
                transferSciScanFiles(sessionID);
            case 'PrairieView'
                transferPrairieViewFiles(sessionID); % /todo Finish function
        end
        experimentInventory{s,2}.isTransferedImData = true;
        
    catch
        warning(['Imaging files for session ', sessionID, ' was not transfered'])
    end
end

% Find sessions which data is transfered but which is not registered.
% Find value of all fields, negate imreg and add together, Pick those
% containing 3.
% or do boolean: 

% Backup Data.


end


function bool = bugcheckSession(sessionID, whichbug)
% This function checks the sessionID against a specified bug that has been
% present during acquisition. Returns true if there was a bug.
%
% Can be used by other functions to correct for that bug. 
%
% Known bugs that this function checks for
%   eyetrackingdata_longfile

switch whichbug
    case 'eyetrackingdata_longfile'
        bug_start_date = datetime(str2double('20170305'),'ConvertFrom','yyyymmdd');
        bug_end_date = datetime(str2double('20170705'),'ConvertFrom','yyyymmdd');
        session_date =  datetime(str2double(sessionID(6:13)),'ConvertFrom','yyyymmdd');
        
        if (bug_start_date < session_date) && (session_date < bug_end_date)
            bool = true;
        else
            bool = false;
        end
        
        otherSessionIDs = {'m029-20170219-1849', 'm029-20170219-1857', ...
            'm029-20170219-1902', 'm029-20170219-1909', 'm029-20170219-1919', ...
            'm029-20170219-1926'};
        
        if any(strcmp(otherSessionIDs, sessionID))
            bool = true;
        end
        
end
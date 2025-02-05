function [ sessionID ] = getSessionIDfromString( pathString )
%getSessionIDfromString return sessionID found in a pathString
% NB: This function does not directly allow block-folders in the experiment. 
%
% INPUT:
%   a string containing a sessionID
%
% Written by Eivind Hennestad. Modified by AL. 

strIdx = strfind(pathString, 'session-m');

% If the strIdx is empty, the session folder do not follow regular
% expression, use special case:
if isempty(strIdx)
    sessionID = ['ID-', pathString(4:end)];
    sessionID = strrep(sessionID,'\','+');
    
else % The path links to a typical session structure
    % Use the first match found. If sessionID also occurs later in the pathstr
    strIdx = strIdx(1);
    
    if isempty(strIdx)
        error('Did not find sessionID in input string')
    else
        strIdx = strIdx + 8; % exclude session-
    end
    
    % Select substring after match and cut off at next file separator.
    subString = pathString(strIdx:end);
    subStrings = strsplit(subString, filesep);
    
    sessionID = subString;
    
end

end


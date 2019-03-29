function [ sessionID ] = getSessionIDfromPathString( pathString )
%getSessionIDfromString return sessionID found in a pathString
%
% INPUT:
%   a string containing a sessionID
%
% NOTE: 
%   Assumes that pathString is a string containing name of sessionFolder


strIdx = strfind(pathString, 'session-m');

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

sessionID = subStrings{1};

if length(sessionID) > 22 % In case block folder is part of str..
    sessionID = sessionID(1:23);
end
    

end


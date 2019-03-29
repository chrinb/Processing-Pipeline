function mousedata = detect_missingMetadata(mousedata,sessionNumber)
%DETECT_MISSINGDATA Finds missing data points from the LabView file and
%allow the user to fill in these for a given session.

if nargin<2
   sessionNumber = inputdlg('Please provide the session number'); 
   sessionNumber = str2num(sessionNumber{1});
end

sessionData = mousedata(sessionNumber);

metadata = sessionData.daqdata.metadata;
fields = fieldnames(metadata);
for x = 1:length(fields)
    
    if isempty(metadata.(fields{x})) % Missing value
        msg = sprintf('Session number %i | Missing value for: %s.Update or type zero',sessionNumber,fields{x});
        inp = inputdlg(msg);
        metadata.(fields{x}) = str2num(inp{1});
    elseif (metadata.(fields{x}) == 0) % Value is zero
        msg = sprintf('Session number %i | Value is 0 for: %s. Update or type zero',sessionNumber,fields{x});
        inp = inputdlg(msg);
        metadata.(fields{x}) = str2num(inp{1});
    end
        
end
mousedata(sessionNumber).daqdata.metadata = metadata;


end
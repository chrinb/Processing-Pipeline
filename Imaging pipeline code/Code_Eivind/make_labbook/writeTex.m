function writeTex( fid, str )
%writeTex Write a str to a line of a tex file defined by fid.
    fprintf(fid, '%s \n', str);
end

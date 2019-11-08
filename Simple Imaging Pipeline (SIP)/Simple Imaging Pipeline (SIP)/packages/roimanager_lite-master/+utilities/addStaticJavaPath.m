function doneTF = addStaticJavaPath(javapath)

doneTF = false; 

savedir = prefdir;

filepath = fullfile(savedir, 'javaclasspath.txt');

if ~exist(filepath, 'file')
    fid = fopen(filepath, 'w', 'n', 'UTF-8');
else
    fid = fopen(filepath, 'a', 'n', 'UTF-8');
end
    
fprintf(fid, javapath);
status = fclose(fid);
if status == 0
    doneTF = true;
end

end
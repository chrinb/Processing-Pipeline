function varvalue=readVarIni(inistring,variablename);

ind1=regexp([inistring ' '],variablename);
ind2=regexp(inistring,'\n');
ind2(end+1) = numel(inistring);

varvalue=[];

if ~isempty(ind1)

    varline=inistring(ind1(1):(ind2(ind2>ind1(1))));
    
    
    s2=regexp(varline,'\=|\"','split');
    s2{2} = strrep(s2{2},',','.');
    for i=2:length(s2)
        if sum(size(strtrim(s2{i})))
            varvalue=str2num(s2{i});
            if ~isempty(varvalue)
                break
            else
                varvalue=s2{i};
                break
            end
        end
    end
    
  
end

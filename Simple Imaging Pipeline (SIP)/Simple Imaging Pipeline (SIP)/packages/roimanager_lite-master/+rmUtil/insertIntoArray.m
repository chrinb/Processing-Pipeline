function arrayOut = insertIntoArray(arrayIn, arrayToInsert, idx, dim)

    % Currently only supports 1 dimension.
    if nargin < 4; dim = 1; end
    
    if iscolumn(arrayIn)
        dim = 1;
    elseif isrow(arrayIn)
        dim = 2;
    else
        dim = 1;
    end
    
    arrayOut = arrayIn;
    cnt = 1;
    
    for i = sort(idx)
        firstPart = arrayOut(1:i-1);
        lastPart = arrayOut(i:end);
        
        if isempty(firstPart) && isempty(lastPart)
            arrayOut = arrayToInsert(cnt);
        elseif isempty(firstPart)
        	arrayOut = cat(dim, arrayToInsert(cnt), lastPart);
        elseif isempty(lastPart)
            arrayOut = cat(dim, firstPart, arrayToInsert(cnt));
        else
            arrayOut = cat(dim, firstPart, arrayToInsert(cnt), lastPart);
        end
                   
        cnt = cnt+1;
    end
    
end
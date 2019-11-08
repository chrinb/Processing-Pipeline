function arrayOut = insertIntoArray(arrayIn, arrayToInsert, ind, dim)

    % Currently only supports 2 dimension.
    if nargin < 4
        if iscolumn(arrayIn)
            dim = 1;
        elseif isrow(arrayIn)
            dim = 2;
        else
            dim = 1;
        end
    end
    
    if iscolumn(arrayIn) && isrow(arrayToInsert) && ~iscolumn(arrayToInsert)
        arrayToInsert = arrayToInsert';
        warning('Dimensions of inputs are not matching')
    end
    
    if isrow(arrayIn) && iscolumn(arrayToInsert) && ~isrow(arrayToInsert)
        arrayToInsert = arrayToInsert';
        warning('Dimensions of inputs are not matching')
    end
    
    nDim = numel(size(arrayIn));
    if nDim > 2; error('Not implemented for nd-arrays'); end
    
    [nRowsA, nColsA] = size(arrayIn);
    [nRowsB, nColsB] = size(arrayToInsert);
    
    if dim == 1
        arrayOut(nRowsA+nRowsB, nColsA) = arrayIn(1); % Preallocate
        colInd = 1:nColsB;
        rowIndNew = ind;
        rowIndOld = setdiff(1:nRowsA+nRowsB, rowIndNew);
        arrayOut(rowIndOld, colInd) = arrayIn;
        arrayOut(rowIndNew, colInd) = arrayToInsert;
    elseif dim == 2
        arrayOut(nRowsA, nColsA+nColsB) = arrayIn(1); % Preallocate
        rowInd = 1:nRowsB; 
        colIndNew = ind;
        colIndOld = setdiff(1:nColsA+nColsB, colIndNew);
        arrayOut(rowInd, colIndOld) = arrayIn;
        arrayOut(rowInd, colIndNew) = arrayToInsert;
    end
    

    
% %     for i = sort(ind)
% %         firstPart = arrayOut(1:i-1);
% %         lastPart = arrayOut(i:end);
% %         
% %         if isempty(firstPart) && isempty(lastPart)
% %             arrayOut = arrayToInsert(cnt);
% %         elseif isempty(firstPart)
% %         	arrayOut = cat(dim, arrayToInsert(cnt), lastPart);
% %         elseif isempty(lastPart)
% %             arrayOut = cat(dim, firstPart, arrayToInsert(cnt));
% %         else
% %             arrayOut = cat(dim, firstPart, arrayToInsert(cnt), lastPart);
% %         end
% %                    
% %         cnt = cnt+1;
% %     end
    
end
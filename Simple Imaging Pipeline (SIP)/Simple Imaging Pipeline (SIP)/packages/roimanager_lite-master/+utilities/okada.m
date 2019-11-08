function IMout = okada(IMin, dim)

h = waitbar(0, 'Please wait while applying okada');

IMin = cat(3, IMin(:,:,2), IMin, IMin(:,:,end-1));

IMout = single(IMin);

IMout = permute(IMout, [dim, setdiff(1:3, dim)]);

[imHeight, imWidth, nFrames] = size(IMout);

for j = 2:imHeight-1
    for i = 1:imWidth
        for t = 1:nFrames
            if (IMout(j,i,t) - IMout(j-1,i,t)) * (IMout(j,i,t) - IMout(j+1,i,t)) > 0
                IMout(j,i,t) = (IMout(j+1,i,t) + IMout(j-1,i,t)) ./ 2;
            end
        end
    end
    
    if mod(j,100)==0
        waitbar(j/imHeight, h)
    end
    
end

close(h)

% Permute back
if dim == 2
    IMout = permute(IMout, [dim, setdiff(1:3, dim)]);
elseif dim == 3
    IMout = permute(IMout, [2,3,1]);
end

IMout = cast(IMout, 'like', IMin);

IMout = IMout(:, :, 2:end-1);

end
function [ sTimes, struggleFactor ] = getBodyMovement( sessionID, blocks )
%getBodyMovement Get strugglefactor for blocks in session

struggleFactor = cell(length(blocks), 1);

for block = blocks
    [t, s] = bodyMovement(sessionID, block, 'auto');
    disp(['Adding strugglefactor for block ', num2str(block)])
    struggleFactor{block} = s;
end

nSamples = cell2mat( cellfun(@(x) length(x), struggleFactor, 'uni', 0) );
nSamples = min(nSamples);

% Add data to array
sfArray = zeros(length(blocks), nSamples);

for block = blocks
    sfArray(block, :) = struggleFactor{block}(1:nSamples);
end

sTimes = t(1:nSamples);
struggleFactor = sfArray;

end


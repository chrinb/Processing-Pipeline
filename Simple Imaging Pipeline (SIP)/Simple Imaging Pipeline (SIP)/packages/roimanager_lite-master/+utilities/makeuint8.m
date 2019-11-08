function imArray = makeuint8(imArray)

imArray = single(imArray); % Avoid edgeeffects if images are aligned.
sorted = sort(reshape(imArray(20:end-20, 20:end-20, :), [],1,1));
sorted(isnan(sorted)) = []; % Throw away black pixels. Usually present due to aligning...
sorted(sorted==0) = [];

nSamples = numel(sorted);

minVal = sorted(round(nSamples*0.0005));
maxVal = sorted(round(nSamples*0.9995));

imArray = uint8((imArray - minVal) ./ (maxVal-minVal) .* 255);

end

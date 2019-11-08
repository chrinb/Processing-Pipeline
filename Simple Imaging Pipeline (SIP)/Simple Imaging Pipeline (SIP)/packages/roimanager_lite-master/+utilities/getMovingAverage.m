function Y = getMovingAverage(Y, dsFactor)

if nargin < 2; dsFactor = 10; end

% Create moving average stack
nAvg = floor(size(Y, 3) / dsFactor);

[imHeight, imWidth, ~] = size(Y);
Y = reshape(Y(:,:,1:nAvg*dsFactor), imHeight, imWidth, dsFactor, nAvg);
Y = squeeze(mean(Y, 3));

end
function normalizedSignals = normalizeROIsignals(signals)

% Normalize ROI signals
normalizedSignals = zeros(size(signals));

for x = 1:size(signals,2)
   A = signals(:,x);
   normA = A - min(A(:));
   normA = normA ./ max(normA(:));
   normalizedSignals(:,x) = normA;
end

end
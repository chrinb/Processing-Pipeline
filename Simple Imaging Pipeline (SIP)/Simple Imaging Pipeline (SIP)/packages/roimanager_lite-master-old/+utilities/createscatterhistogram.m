function [X, Y] = createscatterhistogram(varargin)
%[X, Y] = createscatterhistogram(eventVector)

if numel(varargin) == 2
    bins = varargin{1};
    events = varargin{2};
elseif numel(varargin) == 1
    events = varargin{1};
    bins = 1:numel(events);
end

X = 1:sum(events);
Y = 1:sum(events);

fi = 1;

for i = 1:numel(events)
    
    n = double(events(i));
    if n==0 || isnan(n)
        continue
    end
    
    X(fi:fi+n-1) = bins(i);
    Y(fi:fi+n-1) = (1:n);
    
    fi = fi + n;
    
end

function [ age_weeks ] = age_weeks( str1, str2 )
%Calculate number of weeks between two dates given as str (dd.mm.yyyy)
% USAGE
%   Give last date as str 1 and first date as str 2.

% calculate age at surgery.
years = str2double(str1(7:10)) - str2double(str2(7:10));
months = str2double(str1(4:5)) - str2double(str2(4:5));
days = str2double(str1(1:2)) - str2double(str2(1:2));

% Take days from months
if days <= 0
    days = days + 30.4;
    months = months - 1;
end

% Take months from years
if months <= 0
    months = months + 12;
    years = years - 1;
end

age_weeks = round((years) * 52 + months * 4.35 + days / 7);

end


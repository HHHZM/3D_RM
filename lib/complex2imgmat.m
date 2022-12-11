function [m] = complex2imgmat(c)
% size(c) should equal to [complexnum,1]
m = [-imag(c),real(c)];
end

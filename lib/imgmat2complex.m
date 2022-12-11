function [c] = imgmat2complex(m)
% size(m) should equal to [complexnum,2]
c = m(:,2)-1i*m(:,1);
end
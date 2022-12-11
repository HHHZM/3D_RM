function [m,n] = rotation_axis(img_addr,mask,varargin)
% Get the coodinate of rotation axis in image coodinate system.
% input arg
%   img_addr: the path of 'rot_axis.jpg'.
%   mask: image mask, only need it in extract centerline method.
% output arg
%   m(n): coord in image coodinate system. 

% choose mode
if nargin == 2
    % extract centerline method
    [m,n] = cloudpoints_imgidx(img_addr,mask);
else
    % iteration method
    error('iteration method are under development')
end

end



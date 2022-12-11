function [x,y,z] = cloudpoints_3d_coord(points,theta,rot_axis)
% input arg
%   points: chechkerboard coordiantes
%   theta: current rotation angle
%   rot_axis: rot_axis struct
% output arg
%   x(y,z): coord in space rectangular coordinate system.

x_ck = points(:,1);
y_ck = points(:,2);

k = rot_axis.k;
b = rot_axis.b;
bottom = rot_axis.bottom;
x_b = bottom(1);
y_b = bottom(2);

intersec_x = (k.*y_ck+x_ck-k*b)/(k^2+1);
intersec_y = k.*intersec_x+b;

distance = ((x_ck-intersec_x).^2+(y_ck-intersec_y).^2).^(1/2);

x = distance.*cos(theta);
y = distance.*sin(theta);
z = ((x_b-intersec_x).^2+(y_b-intersec_y).^2).^(1/2);
    
end
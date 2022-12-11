clear all,close all

load('rot_axis.mat')
load('mask_mini_rotaxis.mat')
load('points_graph_c.mat')
board = imread('board.jpg');

k = rot_axis.k;
b = rot_axis.b;
bottom = rot_axis.bottom;

theta_delta = 2*pi/500;

filename = datestr(datetime);
filename(filename==':') = '_';
filename = [filename,'_accuracy'];
fp=fopen([filename,'.txt'],'a');
figure

for img_i = [2:250:252]
    
    [m,n] = centerline_barycenter(...
        ['calib_tiekuai\A',num2str(img_i),'.jpg'],mask_mini_rotaxis);
    % laser_idx = real_position([m,n],points_graph_c,board);
    laser_idx = real_position([m,n],points_graph_c);
    x = laser_idx(:,1);
    y = laser_idx(:,2);
    
    intersec_x = (k.*y+x-k*b)/(k^2+1);
    intersec_y = k.*intersec_x+b;
    distance = ((x-intersec_x).^2+(y-intersec_y).^2).^(1/2);
    
    coord_x = distance.*cos(theta_delta*img_i);
    coord_y = distance.*sin(theta_delta*img_i);
    coord_z = ((bottom(1)-intersec_x).^2+(bottom(2)-intersec_y).^2).^(1/2);
    
    scatter3(coord_x,coord_y,coord_z,1,[1,0,0],'filled')
    set(gca,'DataAspectRatio',[20,20,20])
    axis off
    hold on
    pause(0.01)
    
    file_temp = [coord_x,coord_y,coord_z];
    for file_i = 1:size(file_temp,1)
        fprintf(fp,'%f %f %f\r\n',file_temp(file_i,:));
    end

end
fclose(fp);
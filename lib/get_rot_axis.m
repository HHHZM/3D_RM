function rot_axis = get_rot_axis(nodes,mask,rot_axis_path,board_path)

[m,n] = rotation_axis(rot_axis_path,mask.mini);
rot_axis.img_idx = [m,n];

if nargin == 4
    board = imread(board_path);
    [x,y] = cloudpoints_boardidx([m,n],nodes,board);
else
    [x,y] = cloudpoints_boardidx([m,n],nodes);
end

rot_axis.real_idx = [x,y];
p = polyfit(x,y,1);
rot_axis.k = p(1);
rot_axis.b = p(2);
rot_axis.bottom = [x(1),y(1)];

end
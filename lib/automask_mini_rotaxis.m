function [mask_rotaxis] = automask_mini_rotaxis...
    (nodes,board_path,rot_axis)
board = imread(board_path);
board = rgb2gray(board);
[b_m,b_n] = size(board);

[n_m,n_n] = size(nodes.graph_c_nz);
node_ld = nodes.graph_c_nz(n_m-1,1+1);
node_rd = nodes.graph_c_nz(n_m-1,n_n-1);
node_lu = nodes.graph_c_nz(1+1,1+1);
node_ru = nodes.graph_c_nz(1+1,n_n-1);

node_ld = complex2imgmat(node_ld);
node_rd = complex2imgmat(node_rd);
node_lu = complex2imgmat(node_lu);
node_ru = complex2imgmat(node_ru);

line_top = polyfit([node_lu(1);node_ru(1)],[node_lu(2);node_ru(2)],1);
line_bot = polyfit([node_ld(1);node_rd(1)],[node_ld(2);node_rd(2)],1);
% [m,n]
p = polyfit(rot_axis(:,1),rot_axis(:,2),1);

K1 = [-line_top(1),1;-p(1),1];
B1 = [line_top(2);p(2)];
temp = K1^(-1)*B1;
% intersec1_m = temp(1);
% intersec1_n = temp(2);
intersec1 = [temp(1),temp(2)];

K2 = [-line_bot(1),1;-p(1),1];
B2 = [line_bot(2);p(2)];
temp = K2^(-1)*B2;
% intersec2_m = temp(1);
% intersec2_n = temp(2);
intersec2 = [temp(1),temp(2)];

x = [intersec2(2),node_rd(2),node_ru(2),intersec1(2)];
y = [intersec2(1),node_rd(1),node_ru(1),intersec1(1)];

mask_rotaxis = poly2mask(x,y,b_m,b_n);
% figure,imshow(mask_rotaxis)

figure,imshow(board,[])
hold on
for i = 1:length(x)
    rectangle('Position',[x(i)-26,y(i)-26,51,51],...
        'LineWidth', 3,'edgecolor','g','Curvature',[1 1])
end
x = [x,x(1)];
y = [y,y(1)];
line(x,y,'Color','red','LineWidth',2);
title('region of automask_mini_rotaxis','Interpreter','none')
end


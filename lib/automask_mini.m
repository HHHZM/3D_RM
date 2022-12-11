function [bw] = automask_mini(nodes,board_path)
board = imread(board_path);
board = rgb2gray(board);
[b_m,b_n] = size(board);

[n_m,n_n] = size(nodes.graph_c_nz);
node_ld = nodes.graph_c_nz(n_m-1,1+1);
node_rd = nodes.graph_c_nz(n_m-1,n_n-1);
node_lu = nodes.graph_c_nz(1+1,1+1);
node_ru = nodes.graph_c_nz(1+1,n_n-1);

node_mat = complex2imgmat([node_ld;node_rd;node_ru;node_lu]);
y = node_mat(:,1)';
x = node_mat(:,2)';
bw = poly2mask(x,y,b_m,b_n);
% figure,imshow(bw)

figure,imshow(board,[])
hold on
for i = [node_ld,node_rd,node_lu,node_ru]
    rectangle('Position',[real(i)-26,-imag(i)-26,51,51],...
        'LineWidth', 3,'edgecolor','g','Curvature',[1 1])
end
x = [x,x(1)];
y = [y,y(1)];
line(x,y,'Color','red','LineWidth',2);
title('region of automask_mini','Interpreter','none')
end
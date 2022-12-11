function nodes = get_nodes(board_path)

board = imread(board_path);
board_ori = board;
board = im2double(rgb2gray(board));

board = board.^2;
% imhist(board);pause

board = double(im2bw(board,0.4));
% figure,imshow(board);pause

% corr base
base_size = 60;
base = zeros(base_size)-1;
base(1:round(base_size/2),1:round(base_size/2)) = 1;
base(round(base_size/2)+1:end,round(base_size/2)+1:end) = 1;

img_nodes = imfilter(board,base,'conv','symmetric','same');

th = 0.6;
cor_min = min(img_nodes(:));
cor_max = max(img_nodes(:));
img_nodes(img_nodes<th*cor_max & img_nodes>th*cor_min) = 0;
img_nodes(img_nodes~=0) = 1;

single_points = img_nodes*0;
L = bwlabel(img_nodes);
count = tabulate(L(:));
count = count(2:end,:);

nodes_raw = zeros(size(count));
nodes_raw = nodes_raw(:,1:2);
for i = 1:size(count,1)
    if count(i,2) >= 10
        [m,n] = find(L==i);
        x = int32((max(n)+min(n))/2);
        y = int32((max(m)+min(m))/2);
        nodes_raw(i,:) = [y x];
        single_points(y,x) = 1;
    end
end
nodes_raw(all(nodes_raw==0,2),:) = [];

nodes_size = 17;
nodes_graph_c = get_node_graph(nodes_raw,nodes_size,board_ori);
nodes_graph_c_r = nodes_graph_c(nodes_graph_c~=0);
nodes_graph_c_nz = reshape(nodes_graph_c_r,[],nodes_size);
nodes_neib = get_node_neib(nodes_graph_c_r,nodes_graph_c_nz);

nodes.raw = nodes_raw;
nodes.size = nodes_size;
nodes.graph_c = nodes_graph_c;
nodes.graph_c_r = nodes_graph_c_r;
nodes.graph_c_nz = nodes_graph_c_nz;
nodes.neib = nodes_neib;

figure,imshow(board_ori)
for i = 1:size(nodes_raw,1)
    rectangle('Position',[nodes_raw(i,2)-16,nodes_raw(i,1)-16,31,31],...
        'edgecolor','g','Curvature',[1 1])
end
title('checkerboard nodes')
pause(0.1)

end

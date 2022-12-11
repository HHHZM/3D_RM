function [x,y] = cloudpoints_boardidx(points,nodes,board)
% transform image coord system into checkerboard coor system
% input arg
%   points: laserline points
%   nodes: checkerboard nodes struct
%   board: checkerboard image
% output arg
%   x(y): coord in checkerboard coord system

%% choose mode
if nargin == 1
    [x,y] = cloudpoints_boardidx_accelerate(points);
elseif nargin == 2
    [x,y] = cloudpoints_boardidx_default(points,nodes);
else
    % can show result in checkerboard image
    [x,y] = cloudpoints_boardidx_default(points,nodes,board);
end

end

function [result] = rot_angle(input,base)
% rotate rho-theta coord system
% input arg
%   input: angle of vector which will be rotated
%   base: zero vector in rotate result
% output arg
%   result: rotate result

input(input<0) = 2*pi + input(input<0);
result = mod(input - base,2*pi);
end

function [x,y] = cloudpoints_boardidx_accelerate(points)
% input arg
%   points: laserline points
% output arg
%   x(y): coord in checkerboard coord system

%% preprocess
global nodes
nodes_graph_c_r = nodes.graph_c_r;
nodes_graph_c_nz = nodes.graph_c_nz;
nodes_neib = nodes.neib;
nodes_num = size(nodes_graph_c_r,1);

points_c = imgmat2complex(points);
points_num = size(points,1);

%% get nearest node
delta = points_c*ones(1,nodes_num) - ones(points_num,1)*nodes_graph_c_r.';
distance = abs(delta);
[~,n_nodes_idx] = min(distance,[],2);
n_nodes_idx_uni = unique(n_nodes_idx);

% nearest node
n_nodes = nodes_graph_c_r(n_nodes_idx);
n_nodes_uni = nodes_graph_c_r(n_nodes_idx_uni);

%% neighbors of nearest node and orientation
n_nodes_neib8 = nodes_neib(n_nodes_idx,:);
n_nodes_neib8_uni = nodes_neib(n_nodes_idx_uni,:);
n_nodes_neib4_uni = n_nodes_neib8_uni(:,1:4);

n_nodes_neib4_uni_angl = angle(n_nodes_neib4_uni - n_nodes_uni);
n_nodes_neib4_uni_angl_rot = ...
    rot_angle(n_nodes_neib4_uni_angl,n_nodes_neib4_uni_angl(:,4));

n_nodes_bw = (n_nodes*ones(1,length(n_nodes_uni)) == n_nodes_uni.');

n_nodes_neib4_angl = n_nodes_bw * n_nodes_neib4_uni_angl;
n_nodes_neib4_angl_rot = n_nodes_bw * n_nodes_neib4_uni_angl_rot;

n_nodes_angl = angle(points_c - n_nodes);
n_nodes_angl_rot = rot_angle(n_nodes_angl,n_nodes_neib4_angl(:,4));

% get orientation of nearest node
% n_nodes_orient format:
% [lowerleft loweright upperight upperleft]
n_nodes_orient = false(points_num,4);
% lowerleft
n_nodes_orient(:,1) = n_nodes_angl_rot<n_nodes_neib4_angl_rot(:,1);
% loweright
n_nodes_orient(:,2) = n_nodes_angl_rot<n_nodes_neib4_angl_rot(:,3)&...
    n_nodes_angl_rot>=n_nodes_neib4_angl_rot(:,1);
% upperight
n_nodes_orient(:,3) = n_nodes_angl_rot<n_nodes_neib4_angl_rot(:,2)&...
    n_nodes_angl_rot>=n_nodes_neib4_angl_rot(:,3);
% upperleft
n_nodes_orient(:,4) = 1 - sum(n_nodes_orient(:,1:3),2);

%% nodes quadrangle where points in
% loweright node in neighbor quadrangle
p_rec_neib = zeros(points_num,1);
% nearest node in loweright corner
p_rec_neib(n_nodes_orient(:,2)) = n_nodes(n_nodes_orient(:,2));
% lowerleft 
p_rec_neib(n_nodes_orient(:,1)) = n_nodes_neib8(n_nodes_orient(:,1),4);
% upperight
p_rec_neib(n_nodes_orient(:,3)) = n_nodes_neib8(n_nodes_orient(:,3),2);
% upperleft
p_rec_neib(n_nodes_orient(:,4)) = n_nodes_neib8(n_nodes_orient(:,4),6);

p_rec_neib_uni = unique(p_rec_neib);

% as for loweright node, the order is:
% [self upper leftupper left]
p_loweright_idx = (1:nodes_num)*...
    (nodes_graph_c_r*ones(1,length(p_rec_neib_uni))==p_rec_neib_uni.');
orient_bw = logical([1,0,1,0,1,0,0,0]);
p_rec_neib_uni = [p_rec_neib_uni,nodes_neib(p_loweright_idx,orient_bw)];
% change order
p_rec_neib_uni(:,[4,3]) = p_rec_neib_uni(:,[3,4]);

%% projective transform
real_idx = zeros(points_num,2);
% loweright upperight upperleft lowerleft
A = [0,0;0,1;-1,1;-1,0];
for tf_i = 1:size(p_rec_neib_uni,1)
    loweright_bw = (p_rec_neib==p_rec_neib_uni(tf_i,1));
    cur_points = complex2imgmat(points_c(loweright_bw));

    B = complex2imgmat(p_rec_neib_uni(tf_i,:).');
    tform = fitgeotrans(B,A,'projective');
    d_xy = transformPointsForward(tform,cur_points);

    [node_y,node_x] = find(nodes_graph_c_nz==p_rec_neib_uni(tf_i,1));
    real_idx(loweright_bw,:) = [node_x,node_y] + d_xy*diag([1,-1]);
end

x = real_idx(:,1);
y = real_idx(:,2);

end

function [x,y] = cloudpoints_boardidx_default(points,nodes,board)
% input arg
%   points: laserline points
%   nodes: checkerboard nodes struct
%   board: checkerboard image
% output arg
%   x(y): coord in checkerboard coord system

%% preprocess
% nodes
nodes_graph_c_r = nodes.graph_c_r;
nodes_graph_c_nz = nodes.graph_c_nz;
nodes_neib = nodes.neib;
nodes_num = size(nodes_graph_c_r,1);
% points
points_c = imgmat2complex(points);
points_num = size(points,1);

%% plot scatter
if nargin == 3
    node = complex2imgmat(nodes_graph_c_r);
    figure,imshow(board)
    hold on
    scatter(node(:,2),node(:,1),'filled')
    scatter(points(:,2),points(:,1),'filled')
    pause(0.01)
end

%% get nearest node
delta = points_c*ones(1,nodes_num) - ones(points_num,1)*nodes_graph_c_r.';
distance = abs(delta);
[~,n_nodes_idx] = min(distance,[],2);
n_nodes_idx_uni = unique(n_nodes_idx);
% nearest node
n_nodes = nodes_graph_c_r(n_nodes_idx);
n_nodes_uni = nodes_graph_c_r(n_nodes_idx_uni);

%% neighbors of nearest node and orientation
% 8 neighbors of nearest node
n_nodes_neib8 = nodes_neib(n_nodes_idx,:);
n_nodes_neib8_uni = nodes_neib(n_nodes_idx_uni,:);
n_nodes_neib4_uni = n_nodes_neib8_uni(:,1:4);

n_nodes_neib4_uni_angl = angle(n_nodes_neib4_uni - n_nodes_uni);
n_nodes_neib4_uni_angl_rot = ...
    rot_angle(n_nodes_neib4_uni_angl,n_nodes_neib4_uni_angl(:,4));

n_nodes_bw = (n_nodes*ones(1,length(n_nodes_uni)) == n_nodes_uni.');

n_nodes_neib4_angl = n_nodes_bw * n_nodes_neib4_uni_angl;
n_nodes_neib4_angl_rot = n_nodes_bw * n_nodes_neib4_uni_angl_rot;

n_nodes_angl = angle(points_c - n_nodes);
n_nodes_angl_rot = rot_angle(n_nodes_angl,n_nodes_neib4_angl(:,4));

% get orientation of nearest node
% n_nodes_orient format:
% [lowerleft loweright upperight upperleft]
n_nodes_orient = false(points_num,4);
% lowerleft
n_nodes_orient(:,1) = n_nodes_angl_rot<n_nodes_neib4_angl_rot(:,1);
% loweright
n_nodes_orient(:,2) = n_nodes_angl_rot<n_nodes_neib4_angl_rot(:,3)&...
    n_nodes_angl_rot>=n_nodes_neib4_angl_rot(:,1);
% upperight
n_nodes_orient(:,3) = n_nodes_angl_rot<n_nodes_neib4_angl_rot(:,2)&...
    n_nodes_angl_rot>=n_nodes_neib4_angl_rot(:,3);
% upperleft
n_nodes_orient(:,4) = 1 - sum(n_nodes_orient(:,1:3),2);


%% nodes quadrangle where points in
% loweright node in neighbor quadrangle
p_rec_neib = zeros(points_num,1);
% nearest node in loweright corner
p_rec_neib(n_nodes_orient(:,2)) = n_nodes(n_nodes_orient(:,2));
% lowerleft 
p_rec_neib(n_nodes_orient(:,1)) = n_nodes_neib8(n_nodes_orient(:,1),4);
% upperight
p_rec_neib(n_nodes_orient(:,3)) = n_nodes_neib8(n_nodes_orient(:,3),2);
% upperleft
p_rec_neib(n_nodes_orient(:,4)) = n_nodes_neib8(n_nodes_orient(:,4),6);

% as for loweright node, the order is:
% [self upper leftupper left]
p_rec_neib_uni = unique(p_rec_neib(:,1));
p_loweright_idx = (1:nodes_num)*...
    (nodes_graph_c_r*ones(1,length(p_rec_neib_uni))==p_rec_neib_uni.');
orient_bw = logical([1,0,1,0,1,0,0,0]);
p_rec_neib_uni = [p_rec_neib_uni,nodes_neib(p_loweright_idx,orient_bw)];
% change order
p_rec_neib_uni(:,[4,3]) = p_rec_neib_uni(:,[3,4]);

%% projective transform
real_idx = zeros(points_num,2);
% loweright upperight upperleft lowerleft
A = [0,0;0,1;-1,1;-1,0];
for tf_i = 1:size(p_rec_neib_uni,1)
    loweright_bw = (p_rec_neib==p_rec_neib_uni(tf_i,1));
    cur_points = complex2imgmat(points_c(loweright_bw));

    B = complex2imgmat(p_rec_neib_uni(tf_i,:).');
    tform = fitgeotrans(B,A,'projective');
    d_xy = transformPointsForward(tform,cur_points);
    
    [node_y,node_x] = find(nodes_graph_c_nz==p_rec_neib_uni(tf_i,1));
    real_idx(loweright_bw,:) = [node_x,node_y] + d_xy*diag([1,-1]);
end

x = real_idx(:,1);
y = real_idx(:,2);

%% display projection transform result
if nargin == 3
    figure
    scatter(real_idx(:,1),real_idx(:,2),1,[1,0,0],'filled')
    axis on
    axis([0,17,0,17])
end

end
function [nodes_graph_c] = get_node_graph(nodes_raw,node_size,board)
% search method:
% set the lower right corner node as the starting node
% and then, search from right to left, bottom to top

% preprocess
nodes_graph_c = zeros(node_size,node_size);
nodes_raw = fliplr(nodes_raw);
nodes_raw = nodes_raw(:,1)-1i.*nodes_raw(:,2);
nodes_raw_ = nodes_raw;

% the lower right corner node
img_rightbottom = size(board,2)-1i.*size(board,1);
distance = abs(nodes_raw-img_rightbottom);
[~,idx] = min(distance);
nodes_graph_c(node_size,node_size) = nodes_raw(idx);

% sequence: left leftupper upper
base_m = [0,-1,-1];
base_n = [-1,-1,0];

% figure,imshow(board)
% hold on
for row = node_size:-1:1
    for col = node_size:-1:1
        cur_p = nodes_graph_c(row,col);
        
        % rectangle('Position',[real(cur_p)-16,-imag(cur_p)-16,31,31],...
        %     'edgecolor','g','Curvature',[1 1])
        
        nodes_raw_(nodes_raw_==cur_p) = [];
        
        delta = nodes_raw_ - cur_p;
        delta_ang = angle(delta);
        delta_ang(delta_ang<0) = 2*pi + delta_ang(delta_ang<0);
        
        % angle constraint, subject to left nodes
        ang_range = pi.*[7/6,3/4];
        ang_constraint_idx = ...
            delta_ang<ang_range(1) & delta_ang>ang_range(2);
        % num
        % disp(sum(ang_constraint_idx))
        if sum(ang_constraint_idx) == 0
            continue
        end
        index_constraint = nodes_raw_.*ang_constraint_idx;
        index_constraint(index_constraint==0) = [];
        delta_constraint = index_constraint - cur_p;
        % distance ascent
        [~,d_ix] = sort(abs(delta_constraint));
        nodes_graph_c(row+base_m(1),col+base_n(1)) = ...
            index_constraint(d_ix(1));
        
        % pause(0.1)
    end
    
    % row_start
    cur_p = nodes_graph_c(row,node_size);
    delta = nodes_raw_ - cur_p;
    delta_ang = angle(delta);
    delta_ang(delta_ang<0) = 2*pi + delta_ang(delta_ang<0);
    % constraint to up nodes
    ang_range = pi.*[3/4,1/4];
    ang_constraint_idx = ...
        delta_ang<ang_range(1) & delta_ang>ang_range(2);
    % num
    % disp(sum(ang_constraint_idx))
    if sum(ang_constraint_idx) == 0
        break
    end
    index_constraint = nodes_raw_.*ang_constraint_idx;
    index_constraint(index_constraint==0) = [];
    delta_constraint = index_constraint - cur_p;
    % distance ascent
    [~,d_ix] = sort(abs(delta_constraint));
    nodes_graph_c(row+base_m(3),17+base_n(3)) = ...
        index_constraint(d_ix(1));
end

end


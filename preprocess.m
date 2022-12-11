function preprocess(varargin)
% If you want to do default preprocessing, you do not need to 
% input any argument.
% If you want to do some specific preprocessing, you can use 
% preprocess(_,Name,Value) to specifies preprocessing properties 
% using one or more Name,Value pair arguments.
% Properties include 'board_path', 'rot_axis_path', 'filter_s'.
% For instance, you can use preprocess('filter_s',[1,1],[2,2])
% to specific a self-defined filter_s.

if nargin == 0
    % file path
    board_path = fullfile(pwd,'board.jpg');
    rot_axis_path = fullfile(pwd,'rot_axis.jpg');
    
    % get nodes struct of checkermboard
    nodes = get_nodes(board_path);
    save('nodes.mat','nodes')
    
    % get mask struct
    mask = get_mask(nodes,board_path,rot_axis_path);
    save('mask.mat','mask')
    
    % get axis of rotation struct
    rot_axis = get_rot_axis(nodes,mask,rot_axis_path);
    save('rot_axis.mat','rot_axis')
    
    % get filter struct
    filter_s = get_filter_s();
    save('filter_s.mat','filter_s')

else
    % board_path
    if sum(strcmp(varargin,'board_path')) == 1
        board_path_idx = find(strcmp(varargin,'board_path'));
        board_path = varargin{board_path_idx+1};
    else
        board_path = fullfile(pwd,'board.jpg');
    end
    
    % rot_axis_path
    if sum(strcmp(varargin,'rot_axis_path')) == 1
        rot_axis_path_idx = find(strcmp(varargin,'rot_axis_path'));
        rot_axis_path = varargin{rot_axis_path_idx+1};
    else
        rot_axis_path = fullfile(pwd,'rot_axis.jpg');
    end
    
    % size of filter_s
    if sum(strcmp(varargin,'filter_s')) == 1
        filter_s_idx = find(strcmp(varargin,'filter_s'));
        filter_s_var1 = varargin{filter_s_idx+1};
        filter_s_var2 = varargin{filter_s_idx+2};
        filter_s = get_filter_s(filter_s_var1,filter_s_var2);
        save('filter_s.mat','filter_s')
    end

end
end
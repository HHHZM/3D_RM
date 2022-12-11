function main(varargin)
% Before run this function, you should check four .mat file:
%   nodes.mat mask.mat rot_axis.mat and filter_s.mat 
% whether exist in current directory.
% If not,you should run 'preprocess' in command line first.  
clear global

%% configure basic parameters
global config
% whether write cloudpoints data into txt
% format(each row): [x_idx y_idx z_idx]
config.write_into_txt = false;
% realtime display 3d cloudpoints result
config.realtime_disp = true;
% read all images into memory previous
config.read_img_prev = true;
% dynamic adjust size of ROI mask (can speed up)
config.mask_dynamc_adj = true;
% choose laserline extraction algorithm
config.laser_algorithm = 'basic';
% whether laser extract result
config.save_laser = false;
% timing
config.timing = true;
% about image name
config.imgfold = fullfile(pwd,'demodata');
config.imgstr = 'A';
config.imgnum = 0:499;
% save laser extract result in following fold
config.laser_fold = fullfile(pwd,'result_laser');
% count
config.count = 0;
disp('configuration is as follows:')
disp(config)

%% other global var
global nodes mask filter_s 
board = imread('board.jpg');
nodes = load('nodes.mat');nodes = nodes.nodes;
mask = load('mask.mat');mask = mask.mask;
filter_s = load('filter_s.mat');filter_s = filter_s.filter_s;
rot_axis = load('rot_axis.mat');rot_axis = rot_axis.rot_axis;
theta_delta = 2*pi/length(config.imgnum);

%% follow config to set related parameter
if config.mask_dynamc_adj == true
    mask.dy_adj = true;
end

if config.write_into_txt == true
    filename = datestr(datetime);
    filename(filename==':') = '_';
    fp=fopen([filename,'.txt'],'a');
end

if config.save_laser == true
    if ~exist(config.laser_fold,'dir')
        mkdir(config.laser_fold);
    end
    cd(config.laser_fold)
    delete *
    cd ..
end

if config.read_img_prev == true
    % estimate memory for feasibility
    mem_img = numel(board)/size(board,3);
    mem_need = length(config.imgnum) * mem_img;
    disp(['All images will take up ',num2str(mem_need/2^30),...
        'GBytes of memory space']);
    if ispc
        meminfo = memory;
        mem_avi = meminfo.MemAvailableAllArrays;
        if mem_need + 2^30 > mem_avi
            error([...
                'Avilable memory is not enough to read all images in.',...
                ' Please change the option ''config.readallimgprev'' ',...
                'to ''false''']);
        end
        % init global big images mat
        global_img_mat('init',size(board,1),size(board,2),...
            length(config.imgnum),'uint8');
    else
        try
            % init global big images mat
            global_img_mat('init',size(board,1),size(board,2),...
                length(config.imgnum),'uint8');
        catch
            error([...
                'Avilable memory is not enough to read all images in.',...
                ' Please change the option ''config.readallimgprev'' ',...
                'to ''false''']);
        end
    end
    disp('start reading images...')
    start_readimg_time = clock;
    % write into global big images mat
    for img_i = 1:length(config.imgnum)
        if mod(img_i,50) == 0
            disp([num2str(img_i/length(config.imgnum)*100),'%'])
        end
        img_name = fullfile(config.imgfold,[config.imgstr,...
            num2str(config.imgnum(img_i)),'.jpg']);
        global_img_mat('set',img_i,img_name);
    end
    total_readimg_time = etime(clock,start_readimg_time);
    disp(['total time:',num2str(total_readimg_time),'s']);
    disp(['average time:',...
        num2str(total_readimg_time/length(config.imgnum)),'s']);
end

if config.realtime_disp == true
    figure
end

if config.timing == true
    time_start = clock;
end

%% main loop
disp('start processing...')
for img_i = 1:length(config.imgnum)    
    % whether read_img_prev
    if config.read_img_prev == true
        img_name = img_i;
    else
        img_name = fullfile(config.imgfold,[config.imgstr,...
            num2str(config.imgnum(img_i)),'.jpg']);
    end
    
    % step 1:
    % based on barycenter method to get centerline's index in image
    [x_img,y_img] = cloudpoints_imgidx(img_name);
    
    % step 2:
    % according to centerline's index and chechkerboard nodes' index, 
    % calculate centerline's coordinate in chechkerboard coordinate system.
    [x_ck,y_ck] = cloudpoints_boardidx([x_img,y_img]);
    
    % step 3:
    % according to chechkerboard coord and rotation axis, calculate the
    % final coordinate of cloudpoints in space rectangular coordinate 
    % system.
    theta = theta_delta*img_i;
    [x,y,z] = cloudpoints_3d_coord([x_ck,y_ck],theta,rot_axis);
    
    % realtime_disp
    if config.realtime_disp == true
        scatter3(x,y,z,1,[1,0,0],'filled')
        set(gca,'DataAspectRatio',[20,20,20]),axis off,hold on
        pause(0.01)
    end
    
    % write_into_txt
    if config.write_into_txt == true
        file_temp = [x,y,z];
        for file_i = 1:size(file_temp,1)
            fprintf(fp,'%f %f %f\r\n',file_temp(file_i,:));
        end
    end
    
    % count and display
    if mod(img_i,50) == 0
        disp([num2str(img_i/length(config.imgnum)*100),'%'])
    end
    config.count = config.count + 1;
end

% timing
if config.timing == true
    total_time = etime(clock,time_start);
    aver_time = total_time/length(config.imgnum);
    disp(['total time: ',num2str(total_time),'s'])
    disp(['average time: ',num2str(aver_time),'s'])
end

% finally, close file
if config.write_into_txt == true
    fclose(fp);
end

end
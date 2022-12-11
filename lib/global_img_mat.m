function outputArg1 = global_img_mat(mode,inputArg2,inputArg3,...
    inputArg4,inputArg5)
% This function specific for global big matrix 'img_mat', which include 
% all pending images.
switch mode
    case 'init'
        % initial the global variable 'img_mat'
        init_global_img_mat(inputArg2,inputArg3,inputArg4,inputArg5);
    case 'set'
        % set value of the global variable 'img_mat'
        set_global_img_mat(inputArg2,inputArg3);
    case 'get'
        % get value of the global variable 'img_mat'
        outputArg1 = get_global_img_mat(inputArg2);
end

end

function init_global_img_mat(s1,s2,s3,mtype)
global img_mat
img_mat = zeros(s1,s2,s3,mtype);
end

function set_global_img_mat(img_num,img_addr)
global img_mat
img_mat(:,:,img_num) = rgb2gray(imread(img_addr));
end

function img = get_global_img_mat(img_num)
global img_mat
img = img_mat(:,:,img_num);
end

function [m,n] = cloudpoints_imgidx(img_name,mask,h1_s,h2_s)
% input arg
%   img_name: 
%       img_address (read image for disk in each loop) or 
%       img_number (real all images in memory previous)
%   mask: ROI mask
%   h1_s: size of first filter (mean filter)
%   h2_s: size of second filter (intensity filter)
% output arg
%   m(n): subpixel result, which size is [points number,row(col) idx]

%% choose mode
if nargin == 1
    [m,n] = cloudpoints_imgidx_accelerate(img_name);
elseif nargin == 2
    [m,n] = cloudpoints_imgidx_default(img_name,mask);
else
    [m,n] = cloudpoints_imgidx_default(img_name,mask,h1_s,h2_s);
end

end

function [m,n] = cloudpoints_imgidx_accelerate(img_name)
% input arg
%   img_name: img_number (real all images in memory previous)
% output arg
%   m(n): subpixel result, which size is [points number,row(col) idx]

%% get and crop image
global mask filter_s config

if isnumeric(img_name)
    img = global_img_mat('get',img_name);
else
    img = rgb2gray(imread(img_name));
end

img_crop = img(mask.r_min:mask.r_max,mask.c_min:mask.c_max);
img_crop = im2double(img_crop);
img_crop = img_crop.*mask.mask_crop;

%% DIY base-2 fft
s1 = 2.^ceil(log(size(img_crop,1)+filter_s.h_s(1)-1)/log(2));
s2 = 2.^ceil(log(size(img_crop,2)+filter_s.h_s(2)-1)/log(2));
if s1 ~= filter_s.fft_s1_old || s2 ~= filter_s.fft_s2_old
    filter_s.h_fft = fftn(filter_s.h,[s1,s2]);
    filter_s.fft_s1_old = s1;
    filter_s.fft_s2_old = s2;
end
img_crop_f = fftn(img_crop,[s1,s2]).*filter_s.h_fft;
img_crop_f = ifftn(img_crop_f,[s1,s2]);
img_crop = img_crop_f(filter_s.h_center_idx(1):...
    filter_s.h_center_idx(1)+size(img_crop,1)-1,...
    filter_s.h_center_idx(2):filter_s.h_center_idx(2)+size(img_crop,2)-1);

%% search points based on barycenter method
if config.save_laser == true
    [tempimg,m,n] = choose_algorithm(img_crop,config.laser_algorithm);
    name_laser = fullfile(config.laser_fold,[num2str(config.count),...
        '_laser.jpg']);
    name_inten = fullfile(config.laser_fold,[num2str(config.count),...
        '_inten.jpg']);
    imwrite(tempimg,name_laser);
    imwrite(img_crop,name_inten);
else
    [~,m,n] = choose_algorithm(img_crop,config.laser_algorithm);
end

% coord transform
m = m + mask.r_min;
n = n + mask.c_min;

%% adjust size of ROI mask
if mask.dy_adj
    mask.r_min = round(min(m));
    mask.mask_crop = ...
        mask.main_mask(mask.r_min:mask.r_max,mask.c_min:mask.c_max);
    mask.dy_adj = false;
end

end

function [img,m,n] = choose_algorithm(img_crop,algorithm)
switch algorithm
    case 'basic'
        img_crop(img_crop < 0.1*max(img_crop(:))) = -1;
        [img,m,n] = search_points(img_crop,'basic');
    case 'bidirect'
        img_crop(img_crop < 0.1*max(img_crop(:))) = -1;
        [img,m,n] = search_points(img_crop,'bidirect');
    case 'bidirect advance 1'
        img_crop(img_crop < 0.1*max(img_crop(:))) = -1;
        [img,m,n] = search_points(img_crop,'bidirect advance 1');
    case 'bidirect advance 2'
        img_crop(img_crop < 0.1*max(img_crop(:))) = -1;
        % img_crop(img_crop < 0.1*max(img_crop(:))) = 0;
        [img,m,n] = search_points(img_crop,'bidirect advance 2');
    case 'bidirect advance 3'
        img_crop(img_crop < 0.1*max(img_crop(:))) = -1;
        [img,m,n] = search_points(img_crop,'bidirect advance 3');
    case 'multi connected domain'
        img_crop(img_crop < 0.2*max(img_crop(:))) = 0;
        [domain_label,domain_num] = bwlabel(img_crop);
        m = [];n = [];
        img = zeros(size(img_crop));
        for domain_i = 1:domain_num
            idx_bw = domain_label==domain_i;
            domain_size = sum(idx_bw(:));
            % idx_bw_sumrow = sum(idx_bw,2);
            % idx_bw_sumcol = sum(idx_bw,1);
            if domain_size < 1000
                continue;
            end
            negative_base = zeros(size(img_crop)) - 1;
            negative_base(idx_bw) = img_crop(idx_bw);
            [img_temp,m_temp,n_temp] = ...
                search_points(negative_base,'bidirect advance 2');
            % figure
            % subplot(1,2,1),imshow(img_temp,[]);
            % subplot(1,2,2),imshow(negative_base,[]);
            m = [m;m_temp];
            n = [n;n_temp];
            img = img + img_temp;
        end
end
end

function [m,n] = cloudpoints_imgidx_default...
    (img_name,mask,h1_s,h2_s)
% input arg
%   img_name: img_address (read image for disk in each loop)
%   mask: ROI mask
%   h1_s: size of first filter (mean filter)
%   h2_s: size of second filter (intensity filter)
% output arg
%   m(n): subpixel result, which size is [points number,row(col) idx]

%% crop image
img = im2double(rgb2gray(imread(img_name))).*mask;

col = find(sum(mask==1,1));
row = find(sum(mask==1,2));
c_min = min(col);
c_max = max(col);
r_min = min(row);
r_max = max(row);
img_crop = img(r_min:r_max,c_min:c_max);

%% define two level filter and filter image
% filter size
if nargin < 3
    h1_s = [11,11];
    h2_s = [21,21];
end

% level 1: mean filter
h1 = fspecial('average',h1_s);
% level 2: intensity filter
h2 = -1/(h2_s(1)*h2_s(2)).*ones(h2_s(1),h2_s(2));
h2((h2_s(1)+1)/2,(h2_s(2)+1)/2) = 1;

% filter image
img_crop = imfilter(img_crop,h1,'conv','symmetric','same');
img_crop = imfilter(img_crop,h2,'conv','symmetric','same');

%% search points based on barycenter method
img_crop(img_crop < 0.1*max(img_crop(:))) = -1;
[~,m,n] = search_points(img_crop,'basic');
m = m + r_min;
n = n + c_min;

end

function mask = get_mask(nodes,board_path,rot_axis_path)

mask.normal = automask_normal(nodes,board_path);
mask.mini = automask_mini(nodes,board_path);

[m,n] = rotation_axis(rot_axis_path,mask.mini);
mask.mini_rotaxis = automask_mini_rotaxis(nodes,board_path,[m,n]);

% use mini_rotaxis as mini_rotaxis
mask.main_mask = mask.mini_rotaxis;

mask.col = find(sum(mask.main_mask==1,1));
mask.row = find(sum(mask.main_mask==1,2));
mask.c_min = min(mask.col);
mask.c_max = max(mask.col);
mask.r_min = min(mask.row);
mask.r_max = max(mask.row);
mask.mask_crop = mask.main_mask...
    (mask.r_min:mask.r_max,mask.c_min:mask.c_max);
mask.dy_adj = false;

end
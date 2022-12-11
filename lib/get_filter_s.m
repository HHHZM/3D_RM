function filter_s = get_filter_s(h1_s,h2_s)
if nargin == 0
    h1_s = [17,17];
    h2_s = [31,31];
end
filter_s.h1_s = h1_s;
filter_s.h2_s = h2_s;
filter_s.h1 = fspecial('average',filter_s.h1_s);
filter_s.h2 = -1/(filter_s.h2_s(1)*filter_s.h2_s(2))...
    .*ones(filter_s.h2_s(1),filter_s.h2_s(2));
filter_s.h2((filter_s.h2_s(1)+1)/2,(filter_s.h2_s(2)+1)/2) = 1;
filter_s.h = conv2(filter_s.h1,filter_s.h2);
filter_s.h_s = size(filter_s.h);
filter_s.h_center_idx = (filter_s.h_s+1)/2;
filter_s.fft_s1_old = -1;
filter_s.fft_s2_old = -1;
filter_s.h_fft = [];
end
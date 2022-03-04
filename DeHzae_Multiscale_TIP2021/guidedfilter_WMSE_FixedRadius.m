function q = guidedfilter_WMSE_FixedRadius(I, p, r, eps)
%   GUIDEDFILTER   O(1) time implementation of guided filter.
%
%   - guidance image: I (should be a gray-scale/single channel image)
%   - filtering input image: p (should be a gray-scale/single channel image)
%   - local window radius: r
%   - regularization parameter: eps


[hei, wid] = size(I);
N = boxfilter(ones(hei, wid), r); % the size of each local patch; N=(2r+1)^2 except for boundary pixels.
mean_I = boxfilter(I, r);
mean_p = boxfilter(p, r);
mean_Ip = boxfilter(I.*p, r);
cov_Ip = mean_Ip - mean_I .* mean_p./N; % this is the covariance of (I, p) in each local patch.
clear mean_Ip;
mean_II = boxfilter(I.*I, r);
var_I = mean_II - mean_I .* mean_I./N;
clear mean_II;
var_I_mean = mean(mean(var_I(:,:)));
eps = eps*var_I_mean;
cov_Ip = cov_Ip.*var_I;
var_I = var_I.*var_I;
% a = C.*cov_Ip./(C.*var_I+N.*eps);
a = cov_Ip./(var_I+N.*eps);
clear cov_Ip;
clear var_I;
%a = cov_Ip./(var_I+N.*eps);
b = (mean_p-a.*mean_I)./N;
clear mean_p;
clear mean_I;
mean_a = boxfilter(a, r);
clear a;
mean_b = boxfilter(b, r);
clear b;
q = (mean_a .* I + mean_b)./N;
clear mean_a;
clear mean_b;
clear N;
end

function [transmission_estimation] = DDAP_non_local_dehazing(img_hazy, air_light, gamma, t0, type)
%The core implementation is based on "Non-Local Image Dehazing", CVPR 2016
% 
% The details of the algorithm are described in our paper: 
% Non-Local Image Dehazing. Berman, D. and Treibitz, T. and Avidan S., CVPR2016,
% which can be found at:
% www.eng.tau.ac.il/~berman/NonLocalDehazing/NonLocalDehazing_CVPR2016.pdf
% If you use this code, please cite the paper.
%
%   Input arguments:
%   ----------------
%	img_hazy     - A hazy image in the range [0,255], type: uint8
%	air_light    - As estimated by prior methods, normalized to the range [0,1]
%	gamma        - Radiometric correction. If empty, 1 is assumed
%   t0           - initial transmission map by the DDAP
%   Output arguments:
%   ----------------
%   transmission - Transmission map of the scene, in the range [0,1]
%
% under the attached LICENSE.md


%% Validate input
[h,w,n_colors] = size(img_hazy);
if (n_colors ~= 3) % input verification
    error(['Non-Local Dehazing reuires an RGB image, while input ',...
        'has only ',num2str(n_colors),' dimensions']);
end

if ~exist('air_light','var') || isempty(air_light) || (numel(air_light)~=3)
    error('Dehazing on sphere requires an RGB airlight');
end

if ~exist('gamma','var') || isempty(gamma), gamma = 1; end

img_hazy = im2double(img_hazy);
img_hazy_corrected = img_hazy.^gamma; % radiometric correction


%% Find Haze-lines
% Translate the coordinate system to be air_light-centric (Eq. (3))
dist_from_airlight = double(zeros(h,w,n_colors));
for color_idx=1:n_colors
    dist_from_airlight(:,:,color_idx) = img_hazy_corrected(:,:,color_idx) - air_light(:,:,color_idx);
end

% Calculate radius (Eq. (5))
radius = sqrt( dist_from_airlight(:,:,1).^2 + dist_from_airlight(:,:,2).^2 +dist_from_airlight(:,:,3).^2 );

% Cluster the pixels to haze-lines
% Use a KD-tree impementation for fast clustering according to their angles
dist_unit_radius = reshape(dist_from_airlight,[h*w,n_colors]);
dist_norm = sqrt(sum(dist_unit_radius.^2,2));
dist_unit_radius = bsxfun(@rdivide, dist_unit_radius, dist_norm);
n_points = 1000;
% load pre-calculated uniform tesselation of the unit-sphere
fid = fopen(['TR',num2str(n_points),'.txt']);
points = cell2mat(textscan(fid,'%f %f %f')) ;
fclose(fid);
mdl = KDTreeSearcher(points);
ind = knnsearch(mdl, dist_unit_radius);


%% Estimating Initial Transmission

% Estimate radius as the maximal radius in each haze-line (Eq. (11))
% K = accumarray(ind,radius(:),[n_points,1],@max);

K = accumarray(ind,radius(:),[n_points,1]); %@sum is the default function; 

radius_sum = reshape(K(ind), h, w);

T = accumarray(ind,t0(:),[n_points,1]); %@sum is the default function; 

trans_sum = reshape(T(ind), h, w);

    
% Estimate transmission using the non-local averaging over the haze line
transmission_estimation = radius.*trans_sum./radius_sum;

% Limit the transmission to the range [trans_min, 1] for numerical stability
trans_min = 0.1;
transmission_estimation = min(max(transmission_estimation, trans_min),1);

if type==1
% Solve optimization problem (Eq. (15))
% find bin counts for reliability - small bins (#pixels<50) do not comply with 
% the model assumptions and should be disregarded
    bin_count       = accumarray(ind,1,[n_points,1]);
    bin_count_map   = reshape(bin_count(ind),h,w);
    bin_eval_fun    = @(x) min(1, x/50);

% Calculate std - this is the data-term weight of Eq. (15)
%%The following might be relaxed.
    K_std = accumarray(ind,radius(:),[n_points,1],@std);
    radius_std = reshape( K_std(ind), h, w);
    radius_eval_fun = @(r) min(1, 3*max(0.001, r-0.1));
    radius_reliability = radius_eval_fun(radius_std./max(radius_std(:)));
    data_term_weight   = bin_eval_fun(bin_count_map).*radius_reliability;
    lambda = 0.1;
    transmission_estimation = wls_optimization(transmission_estimation, data_term_weight, img_hazy, lambda);  
end

end % function non_local_dehazing

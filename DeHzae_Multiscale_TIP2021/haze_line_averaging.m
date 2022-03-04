function [transmission_estimation] = haze_line_averaging(img_hazy, air_light, t_0)


[h,w,n_colors] = size(img_hazy);

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

% Estimate the maximal radius in each haze-line using the DDAP
eps = 1/255^2;
K = accumarray(ind,t_0(:)./max(radius(:),eps),[n_points,1],@mean); %%%all weights are 1's
radius_new = reshape( K(ind), h, w);
    
% Estimate transmission as radii ratio (Eq. (12))
transmission_estimation = radius.*radius_new;
end
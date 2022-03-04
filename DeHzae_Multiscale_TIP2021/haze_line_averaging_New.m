function [t_0] = haze_line_averaging_New(img_hazy, air_light, t_0)

gamma = 1.25;
[h,w,n_colors] = size(img_hazy);

img_hazy_corrected = im2double(img_hazy).^gamma;
% img_hazy_corrected = img_hazy.^gamma; % radiometric correction


%% Find Haze-lines
% Translate the coordinate system to be air_light-centric (Eq. (3))
dist_from_airlight = double(zeros(h,w,n_colors));
for color_idx=1:n_colors
    dist_from_airlight(:,:,color_idx) = img_hazy_corrected(:,:,color_idx) - air_light(:,:,color_idx);
end

%%%Convert to spherical coordinate
% Calculate radius (Eq. (5))
r_L = 1/256;
radius = sqrt( dist_from_airlight(:,:,1).^2 + dist_from_airlight(:,:,2).^2 +dist_from_airlight(:,:,3).^2 );

radius = max(radius, r_L);

theta = acos(dist_from_airlight(:,:,3)./radius(:,:)); %%%[0, pi]


psi = atan2(dist_from_airlight(:,:,2), dist_from_airlight(:,:,1))+pi; %%%[0, 2*pi]

%%%Histograms of theta and psi
Ns1 = 720;%720; %%%used to define  the number of bins for the historgram
Ns2 = 200; %%%the size of each sub-bin  %%%200 is better on 27/5/2021
Step = pi/Ns1;
X_step = 2*Ns1;
Dim = (X_step+1)*(Ns1+1);
Host_1 = zeros(Dim,1);
Host_2 = ones(Dim,1);
Pixel_H = zeros(h,w);
Pixel_W = zeros(h,w);
for i=1:h
    for j=1:w
        kk = X_step*floor(theta(i,j)/Step)+floor(psi(i,j)/Step)+1;
        Pixel_H(i,j) = kk; %%%define the kkth bin
        Host_1(kk) = Host_1(kk)+1;
        if Host_1(kk)==  Host_2(kk)*Ns2
            Host_2(kk) = Host_2(kk)+1;
        end
        Pixel_W(i,j) = Host_2(kk); %%%define the sub-bin index
    end
end

clear theta;
clear psi;
% Host_3 = zeros(Dim, 1);
Host_3 = zeros(Dim, 1); %%%determine the 1st sub-bin index in the kth bin
B_sum = 0; %%%total number of sub-bins
BS_LOW = 0;
for k=1:Dim
    if Host_1(k)>BS_LOW
        Host_3(k) = B_sum;
        B_sum = B_sum+Host_2(k);
    end
end
clear Host_2;
T1 = zeros(B_sum, 1);
T2 = zeros(B_sum, 1);
METHOD = 1;
if METHOD==1
    for i=1:h
        for j=1:w
            kk = Pixel_H(i,j);
            if Host_1(kk)>BS_LOW
                xx = Host_3(kk)+Pixel_W(i,j); %%%compute the current sub-bin index
                T1(xx) = T1(xx)+t_0(i,j); %%%compute the sum of t0  in the current sub-bin
                T2(xx) = T2(xx)+radius(i,j); %%%compute the sum of weight in the current sub-bin
            end
        end
    end    
    for i=1:h
        for j=1:w
            kk = Pixel_H(i,j);
            if Host_1(kk)>BS_LOW
                xx = Host_3(kk)+Pixel_W(i,j); %%%compute the current sub-bin index
                t_0(i,j) = radius(i,j)*T1(xx)/T2(xx); %%%compute the average t0
            end
        end
    end
else
    for i=1:h
        for j=1:w
            kk = Pixel_H(i,j);
            if Host_1(kk)>BS_LOW
                xx = Host_3(kk)+Pixel_W(i,j); %%%compute the current sub-bin index
                T1(xx) = T1(xx)+ radius(i,j)/t_0(i,j);
                T2(xx) = T2(xx)+ 1; %%%compute the sum of pixels in the current sub-bin
            end
        end
    end
    for i=1:h
        for j=1:w
            kk = Pixel_H(i,j);
            if Host_1(kk)>BS_LOW
                xx = Host_3(kk)+Pixel_W(i,j); %%%compute the current sub-bin index
                t_0(i,j) = radius(i,j)*T2(xx)/T1(xx);
            end
        end
    end    
end

clear Pixel_H;
clear Pixel_W;
clear T1;
clear T2;
clear Host_1;
clear Host_3;
end
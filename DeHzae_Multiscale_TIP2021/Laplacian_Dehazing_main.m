
clear all;
close all;
%%%Read a hazy image
haze_I = double(imread('E:\A_Paper_DeHaze_TIP\Test_Data_79\4.jpg'));

nlev = 2;%2; %%%number of levels in the pyramids

tic
CVPR = 3; %%%1: CVPR 2016; 2: IEEE TIP 2015; 3: IEEE TIP 2022; 4: ICIP 2021; 
%%% ( 1 ) Construct the Laplacian pyramid of hazy image
if nlev>1
    [pyr_haze, haze_I_E_0] = laplacian_pyramid(haze_I,nlev);
else
    haze_I_E_0 = haze_I;
end

%%%  ( 2 ) Estimate the atmospheric light using haze_I_E_0 which includes less
A = reshape( Global_Airlight_Estimation(haze_I_E_0), 1,1,3);
Ave = floor(mean(A(:))+0.5);
for ii=1:3
    A(ii) = (3*A(ii)+Ave)/4;
end

%%%  ( 3 )  Estimate the transmission map t using haze_I_E_0
if CVPR==1
    gamma = 1.25;
    [t] = non_local_dehazing(uint8(haze_I), A./255.0, gamma);
elseif CVPR==2
%%%Estimate the initial transmission map using the DDAP
    [t_0, G] = Simplified_Dark_Channel(haze_I_E_0,A);
%%%Remove morphological artifacts by using the WGIF with a large radius
    rad = 60;
    eps = 1/1000;
    t = guidedfilter_WMSE_FixedRadius(G, t_0,  rad, eps);    
elseif CVPR==3
%%%Estimate the initial transmission map using the DDAP
    [t_0, G] = Simplified_Dark_Channel(haze_I_E_0,A);
   % imwrite(t_0,ouput_file_1,'png');
%%%Reduce morphological artifacts using part of haze line
    t_1 = haze_line_averaging_New(uint8(haze_I), A./255.0, t_0); %%%result can be improved by using haze_I om 25/5/2021
   % imwrite(t_1,ouput_file_2,'png');
%%%Remove the remaining morphological artifacts using the WGIF with a small radius so as to preserve fine structure.
    rad = 19;%60;%19
    eps = 1/1000;
    t = guidedfilter_WMSE_FixedRadius(G, t_1,  rad, eps);
else
    [t_0, G] = Simplified_Dark_Channel(haze_I_E_0,A);
 %   imwrite(t_0,ouput_file_1,'png');
%%%First reduce morphological artifacts using the whole haze line,
%%%then using the WLS
     t = DDAP_non_local_dehazing(uint8(haze_I), A./255.0, gamma, t_0, 1);
    imwrite(t,ouput_file_3,'png');    
end


%%%at the coarstest level
eta = 1.0/4.0;%1.0/4.0 for normal haze; 1.0/8.0 for heavy haze.
if nlev>1
%%%Construct the Gaussian pyramid of transmission map
    pyr_transmission = gaussian_pyramid(t,nlev);
    pyr_dehaze = gaussian_pyramid(zeros(size(haze_I)),nlev);
   %%%Remove haze and reduce noise at different level of the pyramid     
    leave_haze = 1.0; %17.0/16.0;
    pyr_dehaze{nlev} = (pyr_haze{nlev}- repmat(A, size(pyr_haze{nlev}, 1), size(pyr_haze{nlev}, 2)))./repmat(max(pyr_transmission{nlev},eta), [1 1 3])+repmat(leave_haze*A, size(pyr_haze{nlev}, 1), size(pyr_haze{nlev}, 2));

    %%%at the lth level
    for l = 1:nlev-1
         pyr_dehaze{l} = pyr_haze{l}./repmat(max(pyr_transmission{l},eta), [1 1 3]) + (pyr_haze{l}-pyr_haze{l}./repmat(max(pyr_transmission{l},eta), [1 1 3]))./((1+exp(32.0*(repmat(pyr_transmission{l}, [1 1 3])/eta-1.0)))*2^(l-1));
    end

    % reconstruct a dehazed image by collapsing the pyramid pyr
    img_dehazed = reconstruct_laplacian_pyramid(pyr_dehaze)./255.0;
    
    % % Limit each pixel value to the range [0, 1] (avoid numerical problems)
    img_dehazed(img_dehazed>1) = 1;
    img_dehazed(img_dehazed<0) = 0;

    % % For display, we perform a global linear contrast stretch on the output, 
    % % clipping 0.5% of the pixel values both in the shadows and in the highlights 
    adj_percent = [0.005, 0.995];
    img_dehazed = adjust(img_dehazed,adj_percent);
    img_dehazed = im2uint8(img_dehazed);
else
    [height,width,color] = size(haze_I_E_0);
    img_dehazed = zeros(height,width,color);
    for i = 1:height
        for j = 1:width
            for k = 1:color
                 img_dehazed(i,j,k) = ((haze_I_E_0(i,j,k)-A(k))/max(t(i,j),eta)+A(k))/255.0;  
            end
        end
    end
end
time = toc 
%%%output
figure; imshow(img_dehazed);




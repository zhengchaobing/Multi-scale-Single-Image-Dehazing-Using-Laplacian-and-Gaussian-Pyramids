
function [A_rgb] = Global_Airlight_Estimation(haze_I)
        [height, width, color] = size(  haze_I  );
        quad_size = 32;
        iter = floor(  log2( max( height, width ) / quad_size  ) );
        topleft = [1,1];  % the star of hierachy
        pix_mean = zeros(3,1);
        sigma       = zeros(3,1); 
        for k = 1 : iter    
            hh  =  floor( height / 2^k ); 
            ww =  floor( width / 2^k );    
            score = -10000;        
            x_p = 0;        
            y_p = 0;
            for i = 1 : 2
                for j = 1 : 2            
                     xx = topleft(1) + (i-1) * hh;
                     yy = topleft(2) + (j-1) * ww; 
                     for ll=1 : 3
                           pix_mean(ll) = 0;
                           sigma(ll)    = 0;
                     end
                     for m = 1 : hh
                             for n = 1 : ww
                                     for ll = 1 : 3                       
                                            pix_mean(ll)  = pix_mean(ll)  +  haze_I(xx+m-1,yy+n-1,ll);
                                            sigma(ll) = sigma(ll) + haze_I(xx+m-1,yy+n-1,ll)*haze_I(xx+m-1,yy+n-1,ll);
                                     end
                             end %for n = 1:ww
                     end %for m = 1:hh             
                     pix_mean = pix_mean ./ (hh * ww);  
                     sigma = (sigma./( hh * ww )-pix_mean.^2).^0.5;
                     temp = mean(pix_mean-sigma);
                     if (temp > score)
                             score = temp;
                             x_p = xx; 
                             y_p = yy;
                     end            
                end %for j = 1:2
            end %for i = 1:2    
            topleft(1) = x_p; 
            topleft(2) = y_p;
        end
        
        xx  =  topleft(1);
        yy  =  topleft(2);
        DD = 10000000;
        A_rgb = zeros(3,1);
        
        for m = 1:hh
            for n = 1:ww        
                SS = sum((255-haze_I(xx+m-1,yy+n-1,:)).^2);
                if (SS<DD)
                    DD = SS;
                    A_rgb(:) = haze_I(xx+m-1,yy+n-1,:);
                end
            end %for n = 1:ww
        end %for m = 1:hh
end

function  Zinit = Fast_Edge_Preserving_Smoothing(Zinit, VFx,VFy, THETA, GAMMA)

[H, W] = size(Zinit);
T = 3; % Iteration number
UPSILON = 1.625;%1.625;
lambda = zeros(T,1);
for t=1:T
    lambda(t) = 1.5* 4^(T-t)/(4^T-1)*THETA;
end
%%%parametera long x direction
row = zeros(1,W);
a = zeros(1,W);
b = zeros(1,W);
c = zeros(1,W);
d = zeros(1,W);
%%%parameter along y direction
col = zeros(1,H);
aa = zeros(1,H);
bb = zeros(1,H);
cc = zeros(1,H);
dd = zeros(1,H);
    
for t=1:T %iteration for separable optimization
    for h = 1: H % for each row, A is a matrix of WxW     
 %%%%Definition of matrix coefficients
        bc_tmp = lambda(t)/(abs(VFx(h,1))^UPSILON+1/GAMMA);
        b(1) = 1+bc_tmp;
        c(1) = 0-bc_tmp;
        d(1) = Zinit(h, 1);
        for i = 2:W-1
            ab_tmp = lambda(t)/(abs(VFx(h,i-1))^UPSILON+1/GAMMA);
            bc_tmp = lambda(t)/(abs(VFx(h,i))^UPSILON+1/GAMMA);
            a(i-1) = 0-ab_tmp;
            b(i) = 1+ab_tmp+bc_tmp;
            c(i) = 0-bc_tmp;
            d(i) = Zinit(h, i);            
        end
        ab_tmp = lambda(t)/(abs(VFx(h,W-1))^UPSILON+1/GAMMA); 
        b(W) = 1+ab_tmp;
        a(W-1) = 0-ab_tmp;
        d(W) = Zinit(h, W);
  %%%%1D solver along x direction                        
        row(1) = d(1)/b(1);                    
  %%%%setting values to '\tilde b'
        for i = 2:W
            b(i) = b(i) - a(i-1)*c(i-1)/b(i-1);
            row(i) = (d(i) - a(i-1)*row(i-1))/b(i);
        end
            
        for i=(W-1):-1:1
            row(i) = row(i) - c(i)*row(i+1)/b(i);
        end
            
        Zinit(h,:) = row(:);
    end

      
    for w = 1:W % for each col, A is a matrix is HxH 
  %%%%Definition of matrix coefficients       
        bc_tmp = lambda(t)/(abs(VFy(1,w))^UPSILON+1/GAMMA);
        bb(1) = 1+bc_tmp;
        cc(1) = 0-bc_tmp;
        dd(1) = Zinit(1,w);
        for i = 2:H-1
            ab_tmp = lambda(t)/(abs(VFy(i-1,w))^UPSILON+1/GAMMA);
            bc_tmp = lambda(t)/(abs(VFy(i,w))^UPSILON+1/GAMMA);
            aa(i-1) = 0-ab_tmp;
            bb(i) = 1+ab_tmp+bc_tmp;
            cc(i) = 0-bc_tmp;
            dd(i) = Zinit(i,w);            
        end
        ab_tmp = lambda(t)/(abs(VFy(H-1,w))^UPSILON+1/GAMMA); 
        bb(H) = 1+ab_tmp;
        aa(H-1) = 0-ab_tmp;
        dd(H) = Zinit(H, w);         
  %%%%1D solver along x direction                        
        col(1) = dd(1)/bb(1);               
 %setting values to '\tilde b'
        for i = 2:H
            bb(i) = bb(i) - aa(i-1)*cc(i-1)/bb(i-1);
            col(i) = (dd(i) - aa(i-1)*col(i-1))/bb(i);
        end
            
        for i=(H-1):-1:1
            col(i) = col(i) - cc(i)*col(i+1)/bb(i);
        end
           
        Zinit(:,w) = col(:);
    end        
end        
end




function [min_array]=LocalMinValue_Search(input_array, N, k)

%%% a: input array
%%% N: the length of input array
%%% k: the window size. it must be odd number.
%%% min_array: the length of output array is times of window size, it may bo longer than input array.


sub_array = ceil(N/k);

g = zeros(sub_array*k,1);
h = zeros(sub_array*k,1);

MAXMAX = 10000; %%patching array;

if sub_array == N/k
    a = input_array;
else
    a = zeros(sub_array*k,1);
    
    for i = 1:N
        a(i) = input_array(i);
    end
    
    for i = N+1:sub_array*k
        a(i) = MAXMAX;
    end
end
    
for i = 1:sub_array
    
    xx = (i-1)*k;
    
    g(xx+1) = a(xx+1);
    h(xx+k) = a(xx+k);

    for m = 2:k-1
        
        if a(xx+m)<g(xx+m-1)
            g(xx+m) = a(xx+m);
        else
            g(xx+m) = g(xx+m-1);
        end
        
        n = k-m+1;
        
        if a(xx+n)<h(xx+n+1)
            h(xx+n) = a(xx+n);
        else
            h(xx+n) = h(xx+n+1);
        end
        
    end %for m = 2:k-1
    
    if a(xx+k)<g(xx+k-1)
        g(xx+k) = a(xx+k);
    else
        g(xx+k) = g(xx+k-1);
    end
             
    if a(xx+1)<h(xx+1+1)
        h(xx+1) = a(xx+1);
    else
        h(xx+1) = h(xx+1+1);
    end
    
end %for i = 1:sub_array

min_array = zeros(N,1);
for i = 1:(k-1)/2
    min_array(i) = g(i+(k-1)/2);
end

for i = (k-1)/2+1:sub_array*k-(k-1)/2 
    if g(i+(k-1)/2)<h(i-(k-1)/2)
        min_array(i) = g(i+(k-1)/2);
    else
        min_array(i) = h(i-(k-1)/2);
    end
end
    
for i = sub_array*k-(k-1)/2+1:sub_array*k
    min_array(i) = h(i-(k-1)/2);
end



%disp(min_array)


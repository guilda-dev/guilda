function params = low_level_cascade(varargin)
    
    Kv_p = 20;  %0.52;
    Kv_i = 400; %232.2;
    
    Ki_p = 2;   %0.73; 
    Ki_i = 100; %0.0059;

    iac_max = inf; %1.2;

    params = table(Kv_p,Kv_i,Ki_p,Ki_i,iac_max);
end
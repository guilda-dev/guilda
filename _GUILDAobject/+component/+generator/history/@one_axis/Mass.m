function M = Mass(obj)
    para = obj.parameter.model;
    M    = para.M;
    Tdp  = para.Td_p;

    M = diag( [1,M,Tdp] );
end
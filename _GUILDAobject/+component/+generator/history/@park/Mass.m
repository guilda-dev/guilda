function M = Mass(obj)
    para = obj.parameter.model;
    M    = para.M;
    Tdp  = para.Td_p;
    Tqp  = para.Tq_p;
    Tdpp = para.Td_pp;
    Tqpp = para.Tq_pp;

    M = diag( [1,M,Tdp,Tqp,Tqpp,Tdpp] );
end
function M = Mass(obj)
    M = obj.parameter.model.M;
    M = diag( [1,M] );
end
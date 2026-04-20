function sys = get_sys(obj, x, V, u)
    arguments
        obj 
        x 
        V 
        u         
    end

    Ax = obj.JacobiA([], x, V, u);
    Bv = obj.JacobiB([], x, V, u);    
    Cx = obj.JacobiC([], x, V, u);
    Dv = obj.JacobiD([], x, V, u);

    nx = numel(obj.str_x);
    nu = numel(obj.str_u);

    switch obj.key
        case {'gen-park','gen-2axis','gen-1axis'}; Bu = [zeros(1,nu);eye(nu);zeros(numel(obj.str_x)-3,nu)];
        case 'gen-classical';                      Bu = [zeros(1,nu);1 0];
        case 'load-impedance';                     Bu =  eye(nu);
        case 'load-power';                         Bu =  eye(nu);
    end
    
end
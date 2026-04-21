function sys = get_sys(obj, x, V, u)
    arguments
        obj 
        x (:,1) double = obj.cv_Xequilibrium
        V (:,1) double = [real(obj.c_Vequilibrium); imag(obj.c_Vequilibrium)]
        u (:,1) double = obj.cv_Uequilibrium        
    end

    Ax = obj.JacobiA([], x, V, u);
    Bv = obj.JacobiB([], x, V, u);    
    Cx = obj.JacobiC([], x, V, u);
    Dv = obj.JacobiD([], x, V, u);

    nx = numel(obj.str_x);
    nu = numel(obj.str_u);

    Vre = V(1);
    Vim = V(2);
    Vsq = Vre^2*Vim^2;

    Bu = [];
    Du = zeros(nu,nu);
    switch obj.key
        case {'gen-park','gen-2axis','gen-1axis'}
            Bu = [zeros(1,nu);eye(nu);zeros(numel(obj.str_x)-3,nu)];            
        case  'gen-classical'
            Bu = [zeros(1,nu);1 0];            
        case  'load-impedance'            
            Du = [-Vre/Vsq, -Vim/Vsq; Vim/Vsq, -Vre/Vsq];
        case  'load-power'            
            Du = [ Vre/Vsq,  Vim/Vsq; Vim/Vsq, -Vre/Vsq];
    end


    x_Names = obj.attach_tag(obj.str_x);
    u_Names = obj.attach_tag(obj.str_u);
    v_Names = obj.attach_tag(["Vre";"Vim"]);
    i_Names = obj.attach_tag(["Ire";"Iim"]);

    A = Ax;
    B = [Bv, Bu];
    C = [eye(nx); Cx];
    D = [zeros(nx,2*nu); [Dv, Du]];
    

    sys = ss(A,B,C,D);

    sys.StateName  = x_Names;
    sys.InputName  = [v_Names;u_Names];
    sys.OutputName = [x_Names;i_Names];
end
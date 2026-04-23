function sys = get_sys(obj, x, V, u, opt)
    arguments
        obj 
        x        (:,1) double = obj.cv_Xequilibrium
        V        (:,1) double = [real(obj.c_Vequilibrium); imag(obj.c_Vequilibrium)]
        u        (:,1) double = obj.cv_Uequilibrium                        
        opt.port (1,1) {mustBeMember(opt.port, ["V2I", "I2V"])} = "V2I"
        opt.full (1,1) logical = true
    end

    Mass = obj.rm_odeMass([], x, V, u);
    Ax = obj.JacobiA([], x, V, u);
    Bv = obj.JacobiB([], x, V, u);    
    Cx = obj.JacobiC([], x, V, u);
    Dv = obj.JacobiD([], x, V, u);
    
    nu = numel(obj.str_u);

    Vre = V(1);
    Vim = V(2);
    Vsq = Vre^2*Vim^2;

    Bu = zeros(0,2);
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

    xNames = obj.attach_tag(obj.str_x);
    uNames = obj.attach_tag(obj.str_u);
    Vport  = obj.attach_tag(["Vre";"Vim"]);
    Iport  = obj.attach_tag(["Ire";"Iim"]);

    switch opt.port
        case "V2I"
            A =  Ax;            
            B = [Bv,Bu];

            nx = size(A,1);
            nu = size(B,2);

            C  = [  eye(opt.full*nx,nx); Cx];
            D  = [zeros(opt.full*nx,nu); [Dv, Du]];            

            InputNames  = [Vport; uNames];
            OutputNames = {Iport;[xNames; Iport]};

        case "I2V"
            inv_Dv = Dv^-1;

            inv_Ax =  Ax - Bv * inv_Dv * Cx;                       
            inv_Bv =  Bv * inv_Dv;
            inv_Bu =  Bu - Bv * inv_Dv * Du;
            inv_Cx = -inv_Dv * Cx;                        
            inv_Du = -inv_Dv * Du;                        

            A =  inv_Ax;
            B = [inv_Bv, inv_Bu];            

            nx = size(A,1);
            nu = size(B,2);

            C  = [  eye(opt.full*nx,nx); inv_Cx];
            D  = [zeros(opt.full*nx,nu); [inv_Dv, inv_Du]];            
                        
            InputNames  = [Iport; uNames];
            OutputNames = {Vport;[xNames; Vport]};
    end    

    sys = ss(Mass^-1 * A, Mass^-1 * B, C, D);

    sys.StateName  = xNames;
    sys.InputName  = InputNames;
    sys.OutputName = OutputNames{opt.full+1};    
end
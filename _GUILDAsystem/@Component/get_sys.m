function sys = get_sys(obj, x, V, u, opt)
    arguments
        obj 
        x        (:,1) double = obj.cv_Xequilibrium
        V        (:,1) double = [real(obj.c_Vequilibrium); imag(obj.c_Vequilibrium)]
        u        (:,1) double = obj.cv_Uequilibrium                        
        opt.port (1,1) {mustBeMember(opt.port, ["V2I", "I2V"])} = "V2I"
        opt.full (1,1) logical = true
    end

    xNames = obj.attach_tag(obj.str_x);
    uNames = obj.attach_tag(obj.str_u);    

    Vport  = obj.attach_tag(["Vre";"Vim"]);
    Iport  = obj.attach_tag(["Ire";"Iim"]);    

    Mass = obj.rm_odeMass([], x, V, u);

    Axx = obj.JacobiAxx([], x, V, u);
    Bxv = obj.JacobiBxv([], x, V, u);    
    Bxu = obj.JacobiBxu([], x, V, u);        

    Cix = obj.JacobiCix([], x, V, u);
    Div = obj.JacobiDiv([], x, V, u);
    Diu = obj.JacobiDiu([], x, V, u);              

    switch opt.port
        case "V2I"
            A =  Axx;            
            B = [Bxv,Bxu];

            nx = size(A,1);
            nu = size(B,2);

            C  = [  eye(opt.full*nx,nx); Cix];
            D  = [zeros(opt.full*nx,nu); [Div, Diu]];            

            InputNames  = [Vport; uNames];
            OutputNames = {Iport;[xNames; Iport]};

        case "I2V"
            inv_Div = Div^-1;

            inv_Axx =  Axx - Bxv * inv_Div * Cix;                       
            inv_Bxv =  Bxv * inv_Div;
            inv_Bxu =  Bxu - Bxv * inv_Div * Diu;
            inv_Cix = -inv_Div * Cix;                        
            inv_Diu = -inv_Div * Diu;                        

            A =  inv_Axx;
            B = [inv_Bxv, inv_Bxu];            

            nx = size(A,1);
            nu = size(B,2);

            C  = [  eye(opt.full*nx,nx); inv_Cix];
            D  = [zeros(opt.full*nx,nu); [inv_Div, inv_Diu]];            
                        
            InputNames  = [Iport; uNames];
            OutputNames = {Vport;[xNames; Vport]};
    end    

    sys = dss(A, B, C, D, Mass);

    sys.StateName  = xNames;
    sys.InputName  = InputNames;
    sys.OutputName = OutputNames{opt.full+1};        
end
function sys = get_sys(obj, x, V, u, opt)
    arguments
        obj 
        x 
        V 
        u 
        opt.full (1,1) logical = true         
    end

    Mass = obj.rm_odeMass(0, x, V, u);

    Axx = obj.JacobiAxx(0,x,V,u);
    Bxu = obj.JacobiBxu(0,x,V,u);
    Bxv = obj.JacobiBxv(0,x,V,u);

    Cyx = obj.JacobiCyx(0,x,V,u);
    Dyu = obj.JacobiDyu(0,x,V,u);
    Dyv = obj.JacobiDyv(0,x,V,u);

    xNames = obj.attach_tag(obj.str_x);
    uNames = obj.attach_tag(obj.str_u);
    yNames = obj.attach_tag(obj.str_y);

    Vport = obj.attach_tag(["Vre";"Vim"]);

    OutputNames = {yNames; [xNames;yNames]};

    A = Axx;
    B = [Bxv, Bxu];

    nx = size(A,1);
    nu = size(B,2);

    C =[eye(opt.full*nx,nx); Cyx];
    D =[zeros(opt.full*nx,nu); [Dyv, Dyu]];

    sys = dss(A, B, C, D, Mass);

    sys.StateName = xNames;
    sys.InputName = [Vport; uNames];
    sys.OutputName = OutputNames{opt.full+1};

end
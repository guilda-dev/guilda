function [A_dae, B_dae, C_dae, D_dae, E_dae] = get_DAE(obj,opt)                                     
    arguments
        obj 
        opt (1,1) string {mustBeMember(opt,["theta&V","theta&rho","Vre&Vim"])} = "theta&rho"%"theta&V"
    end

    bus = obj.odeNetwork.a_Bus;
    ssFromBus = tools.cellfun(@(bs) bs.get_sys("port", "V2I", "full", false), bus);    

    [input, output] = get_IO_port;

    Axx = tools.dcellfun(@(SS) SS.A         , ssFromBus);
    Axv = tools.dcellfun(@(SS) SS.B(:,1:2)  , ssFromBus);
    Avx = tools.dcellfun(@(SS) SS.C         , ssFromBus);
    Avv = tools.dcellfun(@(SS) SS.D(:,1:2)  , ssFromBus);
    Bxu = tools.dcellfun(@(SS) SS.B(:,3:end), ssFromBus);
    Bvu = tools.dcellfun(@(SS) SS.D(:,3:end), ssFromBus);

    Y = obj.odeNetwork.get_admittance_matrix;
    Ymat = tools.complex2matrix( Y.Variables );
    

    Ex = tools.dcellfun(@(SS) SS.E, ssFromBus);
    Ev = zeros(size(Avv));

    n_b = numel(bus);
    n_x = size(Axx,1);
    n_v = size(Avx,1);
    n_u = size(Bxu,2);

    A_temp = [Axx, Axv;  Avx, + Avv - Ymat];
    B_temp = [Bxu; Bvu];
    
    A_dae = A_temp([1:n_x,(n_x+1):2:end,(n_x+2):2:end],[1:n_x,(n_x+1):2:end,(n_x+2):2:end]);
    B_dae = B_temp([1:n_x,(n_x+1):2:end,(n_x+2):2:end],:);
    C_dae = [eye(n_x),zeros(n_x,n_v)];
    D_dae = zeros(n_x,n_u);
    E_dae = blkdiag(Ex, Ev);

    ir_x   = 1:n_x;
    ir_Vre = n_x + (1:n_b);
    ir_Vim = n_x + n_b + (1:n_b);

    A_dae = [ A_dae(ir_x  ,:);
             -A_dae(ir_Vim,:);
              A_dae(ir_Vre,:)];
    B_dae = [ B_dae(ir_x  ,:);
             -B_dae(ir_Vim,:);
              B_dae(ir_Vre,:)];

    Vc_st = tools.vcellfun(@(b) b.c_Vequilibrium, bus);
    Ic_st = tools.vcellfun(@(b) b.c_Iequilibrium, bus);
    S_st  = Vc_st .* conj(Ic_st);
    
    rm_P  = diag(real( S_st));
    rm_Q  = diag(imag( S_st));
    rm_Vr = diag(real(Vc_st));
    rm_Vi = diag(imag(Vc_st));
    rm_V  = diag(abs( Vc_st));


    switch opt
        case "theta&V" 
            % rm_S = [-rm_Q     , rm_P/rm_V;...
            %          rm_P/rm_V, rm_Q     ];

            filt_o = [-    rm_Vi,       rm_Vr ;
                       rm_V\rm_Vr, rm_V\rm_Vi];
            filt_i = [-    rm_Vi,  rm_V\rm_Vr ;
                           rm_Vr,  rm_V\rm_Vi];

            str_busvar = ["theta";"V"];
        case "theta&rho" 
            % rm_S = [-rm_Q, rm_P;...
            %          rm_P, rm_Q];

            filt_o = [-rm_Vi,  rm_Vr ; 
                       rm_Vr,  rm_Vi];
            filt_i = [-rm_Vi,  rm_Vr ; 
                       rm_Vr,  rm_Vi];
            
            str_busvar = ["theta";"rho"];
        case "Vre&Vim"
            % rm_S = zeros(n_v, n_v);

            filt_o = eye(n_v);
            filt_i = eye(n_v);

            str_busvar = ["Vre";"Vim"];
    end

    A_dae = blkdiag(eye(n_x),filt_o)      ...
            * A_dae                       ...
            * blkdiag(eye(n_x),filt_i);
    B_dae = blkdiag(eye(n_x),filt_o)      ...
            * B_dae;

    str_busvar = reshape(str_busvar+(1:n_b),2,[]);
    str_busvar = reshape(str_busvar',1,[]);

    G = real( Y.Variables );
    B = imag( Y.Variables );
    obj.Lvv = filt_o * [-B,-G;G,-B] * filt_i;
    obj.Kxx = A_dae( 1:n_x, 1:n_x);
    obj.Kxv = A_dae( 1:n_x, n_x+(1:n_v));
    obj.Kvx = A_dae( n_x+(1:n_v), 1:n_x);
    obj.Kvv = A_dae( n_x+(1:n_v), n_x+(1:n_v)) - obj.Lvv;


    sys = dss(A_dae, B_dae, C_dae, D_dae, E_dae);
    sys.InputName  = input;
    sys.StateName  = [output(:)',str_busvar];
    sys.OutputName = output;    

    obj.odeLinearSystem = sys;

    function [input, output] = get_IO_port()
        
        input  = cell(numel(bus),1);
        output = cell(numel(bus),1);
        for argi = 1:numel(bus)
            COMP = bus{argi}.a_Component;
                          
            str_x = cell2mat( cellfun(@(C) C.attach_tag(C.str_x), COMP, 'UniformOutput', false) );
            str_u = cell2mat( cellfun(@(C) C.attach_tag(C.str_u), COMP, 'UniformOutput', false) );                                                      

            input{argi}  = str_u;
            output{argi} = str_x;
        end

        input  = cell2mat(input);
        output = cell2mat(output);
   end

end

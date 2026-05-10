function [Ax_ode, Bx_ode, Cx_ode, Dx_ode, E_ode] = get_LTI_viaKron(obj)                                     

    bus = obj.odeNetwork.a_Bus;
    ssFromBus = tools.cellfun(@(bs) bs.get_sys("port", "V2I", "full", false), bus);    

    [input, output] = get_IO_port;

    Ax = tools.cellfun(@(SS) SS.A         , ssFromBus);
    Bv = tools.cellfun(@(SS) SS.B(:,1:2)  , ssFromBus);
    Bu = tools.cellfun(@(SS) SS.B(:,3:end), ssFromBus);
    Cx = tools.cellfun(@(SS) SS.C         , ssFromBus);
    Dv = tools.cellfun(@(SS) SS.D(:,1:2)  , ssFromBus);
    Du = tools.cellfun(@(SS) SS.D(:,3:end), ssFromBus);

    E = tools.cellfun(@(SS) SS.E, ssFromBus);

    Ymat = obj.odeNetwork.get_admittance_matrix;
    Ymat = tools.complex2matrix( Ymat.Variables );
           
    Ax_dae = blkdiag(Ax{:});
    Bv_dae = blkdiag(Bv{:}); 
    Bu_dae = blkdiag(Bu{:});
    Cx_dae = blkdiag(Cx{:});
    Du_dae = blkdiag(Du{:});
    Dv_dae = blkdiag(Dv{:}) - Ymat;
    
    mat_v2x = Bv_dae / Dv_dae;
    
    n_x = size(Ax_dae,1); 
    n_u = size(Bu_dae,2);

    Ax_ode = Ax_dae - mat_v2x * Cx_dae;
    Bx_ode = Bu_dae - mat_v2x * Du_dae;
    Cx_ode = eye(n_x);
    Dx_ode = zeros(n_x,n_u);
    E_ode  = blkdiag(E{:});


    sys = dss(Ax_ode, Bx_ode, Cx_ode, Dx_ode, E_ode);
    sys.InputName  = input;
    sys.StateName  = output;
    sys.OutputName = output;    

    obj.odeLinearSystem = sys;

    function [input, output] = get_IO_port()
        BUS = obj.odeNetwork.a_Bus;

        input  = cell(numel(BUS),1);
        output = cell(numel(BUS),1);
        for argi = 1:numel(BUS)
            COMP = BUS{argi}.a_Component;            
                          
            str_x = cell2mat( cellfun(@(C) C.attach_tag(C.str_x), COMP, 'UniformOutput', false) );
            str_u = cell2mat( cellfun(@(C) C.attach_tag(C.str_u), COMP, 'UniformOutput', false) );                                                      

            input{argi}  = str_u;
            output{argi} = str_x;
        end

        input  = cell2mat(input);
        output = cell2mat(output);
   end

end

function [Ax_ode, Bx_ode, Cx_ode, Dx_ode, E_ode] = get_LTI_viaKron(obj)                                     

    bus = obj.odeNetwork.a_Bus;
    ssFromBus = tools.cellfun(@(bs) bs.get_sys("port", "V2I", "full", false), bus);    

    busInames = cell2mat( tools.cellfun(@(bi) bi.attach_tag(["Ire";"Iim"]), bus) );
    busVnames = cell2mat( tools.cellfun(@(bi) bi.attach_tag(["Vre";"Vim"]), bus) );

    x = tools.cellfun(@(s) string(s.StateName),  ssFromBus);
    i = tools.cellfun(@(s) string(s.InputName),  ssFromBus);
    o = tools.cellfun(@(s) string(s.OutputName), ssFromBus);

    input  = vertcat(i{:});
    output = vertcat(o{:});

    lv_input  = ismember(input, busVnames);
    lv_output = ismember(output,busInames);

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
    sys.InputName  = input(~lv_input);
    sys.StateName  = vertcat(x{:});
    sys.OutputName = output(~lv_output);    

    obj.odeLinearSystem = sys;

end

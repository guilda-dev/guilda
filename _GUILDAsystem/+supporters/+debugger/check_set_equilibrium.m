function check_set_equilibrium(c)
    if ~isempty(c.connected_bus)
        Vst = tools.complex2vec(c.V_equilibrium);
        Ist = tools.complex2vec(c.I_equilibrium);
    else
        Vst = rand(2,1);
        Ist = rand(2,1);
    end
    v2c = @(c) tools.vec2complex(c);

    c.set_equilibrium(v2c(Vst),v2c(Ist));
    xst = c.x_equilibrium;
    ust = c.u_equilibrium;
    [ dx,con] = c.get_dx_constraint(0,xst,Vst,Ist,ust);

    disp(array2table(dx.','VariableNames',c.get_state_name))
    disp(array2table(con.','VariableNames',"con"+(1:numel(con))'))

    if all(abs(dx)<1e-6) && all(abs(con)<1e-6)
        disp('ok!!')
    else
        error('there are something mistakes')
    end
end
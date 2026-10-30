function DAEvec = get_dx_algebraic(obj, t, x, Vi, Ii, u, DAEvec) 
% Add the equations of the component and its local controllers to the DAE residual.
%
% Called by odeSimulator at each evaluation of the network DAE: the state derivatives,
% the input equations and the current injected into the bus are added to the entries
% of `DAEvec` that belong to the component (iv_odeX, iv_odeU) and its bus.
%
% Outputs:
%
% - `DAEvec` — Updated DAE residual of the network.
%
% See also odeSimulator, Component.fcn_dx, Component.fcn_I

    rv_x = obj.iv_odeX;
    rv_u = obj.iv_odeU;

    rv_v = obj.a_Bus.iv_odeX;

    x_comp = x(rv_x);
    u_comp = x(rv_u);    
    
    if obj.l_hasController
        % The controller reads the outputs and the states of the component by name,
        % and its outputs replace the inputs of the same name
        obs.y = obj.f_Y(t,x_comp,Vi,Ii,u_comp);
        obs.x = x_comp;
        a_LC = obj.a_LocalController{1};
        [DAEvec, y_LC, y_name] = get_dx_algebraic(a_LC, t, x, Vi, Ii, obs, DAEvec);
        [lv_U2Y, iv_Y] = ismember(obj.sv_u, y_name);
        u(lv_U2Y) = y_LC(iv_Y(lv_U2Y));
    end
    
    X = obj.f_dx(t,x_comp,Vi,Ii,u_comp);
    I = obj.l_isConnect * obj.f_I(t,x_comp,Vi,Ii,u_comp);       

    DAEvec([rv_x; rv_u; rv_v]) = DAEvec([rv_x; rv_u; rv_v]) + [X; u_comp-u; -[real(I); imag(I)]];        

end
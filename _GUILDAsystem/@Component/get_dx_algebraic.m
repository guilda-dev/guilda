function DAEvec = get_dx_algebraic(obj, t, x, Vi, Ii, u, DAEvec) 
% Add the equations of the component and its local controllers to the DAE residual.
%
% Called by ODEsolver at each evaluation of the network DAE: the state derivatives,
% the input equations and the current injected into the bus are added to the entries
% of `DAEvec` that belong to the component (iv_odeX, iv_odeU) and its bus.
%
% Outputs:
%
% - `DAEvec` — Updated DAE residual of the network.
%
% See also ODEsolver, Component.fcn_dx, Component.fcn_I

    % Called directly, the handles may not be built yet. Only the own state is read here:
    % in a simulation, the solver has already brought every layer up to date.
    if obj.s_edit.str_odefcn ~= "updated"
        obj.check_edit();
    end

    rv_x = obj.iv_odeX;
    rv_u = obj.iv_odeU;

    rv_v = obj.a_Bus.iv_odeX;

    x_comp = x(rv_x);
    u_comp = x(rv_u);    
    
    if obj.l_hasController
        % The controller reads the outputs and the states of the component by name,
        % and its outputs drive the inputs of the same name. An input event or a global
        % controller on such an input adds to the output, as in get_sys
        obs.y = obj.f_Y(t,x_comp,Vi,Ii,u_comp);
        obs.x = x_comp;
        a_LC = obj.a_LocalController{1};
        [DAEvec, y_LC] = get_dx_algebraic(a_LC, t, x, Vi, Ii, obs, DAEvec);
        lv_U2Y = obj.lv_odeUfromLC;
        u(lv_U2Y) = y_LC(obj.iv_odeYtoU(lv_U2Y)) + u(lv_U2Y) - obj.rv_Uequilibrium(lv_U2Y);
    end
    
    X = obj.f_dx(t,x_comp,Vi,Ii,u_comp);
    I = obj.l_isConnect * obj.f_I(t,x_comp,Vi,Ii,u_comp);       

    DAEvec([rv_x; rv_u; rv_v]) = DAEvec([rv_x; rv_u; rv_v]) + [X; u_comp-u; -[real(I); imag(I)]];        

end
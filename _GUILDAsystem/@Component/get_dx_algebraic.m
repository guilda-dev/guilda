function DAEvec = get_dx_algebraic(obj, t, x, Vi, Ii, u, DAEvec) 
% Add the equations of the component and its local controllers to the DAE residual.
%
% Called by SolverODE at each evaluation of the network DAE: the state derivatives,
% the input equations and the current injected into the bus are added to the entries
% of `DAEvec` that belong to the component (iv_odeX, iv_odeU) and its bus.
%
% See also SolverODE, Component.fcn_dx, Component.fcn_I
%
% <@Group> Called by analyses
    arguments
        obj
        t      (1,1) double  % [s] Time.
        x      (:,1) double  % Variables of the network DAE (states, inputs, bus voltages and currents).
        Vi     (2,1) double  % [pu] Bus voltage [real; imag].
        Ii     (2,1) double  % [pu] Bus current [real; imag].
        u      (:,1) double  % Input values of the component: equilibrium, input events and global controllers.
        DAEvec (:,1) double  % DAE residual of the network so far.
    end
    arguments (Output)
        DAEvec (:,1) double  % Updated DAE residual of the network.
    end

    % Called directly, the handles may not be built yet. Only the own state is read here:
    % in a simulation, the solver has already brought every layer up to date.
    if obj.sct_edit.str_odefcn ~= "updated"
        obj.check_edit();
    end

    rv_x = obj.iv_odeX;
    rv_u = obj.iv_odeU;

    rv_v = obj.a_Bus.iv_odeX;

    x_comp = x(rv_x);
    u_comp = x(rv_u);    
    
    if obj.l_hasController
        % The controllers read the outputs and the states of the component by name,
        % and their outputs drive the inputs of the same name. An input event or a global
        % controller on such an input adds to the output, as in get_sys.
        % y_LC: the outputs of the top-level controllers, stacked in order (iv_odeYtoU)
        obs.y = obj.f_Y(t,x_comp,Vi,Ii,u_comp);
        obs.x = x_comp;
        a_LC = obj.a_LocalController;
        [DAEvec, y_LC] = get_dx_algebraic(a_LC{1}, t, x, Vi, Ii, obs, DAEvec);
        for k = 2:numel(a_LC)
            [DAEvec, y_k] = get_dx_algebraic(a_LC{k}, t, x, Vi, Ii, obs, DAEvec);
            y_LC = [y_LC; y_k]; %#ok<AGROW>
        end
        lv_U2Y = obj.lv_odeUfromLC;
        u(lv_U2Y) = y_LC(obj.iv_odeYtoU(lv_U2Y)) + u(lv_U2Y) - obj.rv_Uequilibrium(lv_U2Y);
    end
    
    X = obj.f_dx(t,x_comp,Vi,Ii,u_comp);
    I = obj.l_isConnect * obj.f_I(t,x_comp,Vi,Ii,u_comp);       

    DAEvec([rv_x; rv_u; rv_v]) = DAEvec([rv_x; rv_u; rv_v]) + [X; u_comp-u; -[real(I); imag(I)]];        

end
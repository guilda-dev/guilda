function set_powerflow(obj, net, opt)
% Set the bus voltages and component currents shown by the diagram.
%
% Uses Vbus and Icomp when both are given with one value per bus and per component;
% otherwise reads the equilibrium of net. Then the bus, component and branch powers are
% computed and the drawing is updated.
    arguments
        obj
        net      = [] % Network whose equilibrium is shown when Vbus or Icomp is not given.
        opt.Vbus  (:,1) double = []; % [pu] Bus voltage phasors, one per bus.
        opt.Icomp (:,1) double = []; % [pu] Component current phasors, one per component.
    end

    cv_Vb = opt.Vbus;
    cv_Ic = opt.Icomp;

    l_valid_Vbus  = isnumeric(cv_Vb) && numel(cv_Vb)==obj.n_bus;
    l_valid_Icomp = isnumeric(cv_Ic) && numel(cv_Ic)==obj.n_component;
    
    if ~l_valid_Vbus || ~l_valid_Icomp
        if isa(net,"PowerNetwork")
            get_Icomp = @(bus) tools.vcellfun(@(c) c.c_Iequilibrium, bus.a_Component);
            cv_Ic = tools.vcellfun(@(b) get_Icomp(b), net.a_Bus);
            cv_Vb = net.cv_Vequilibrium;
        else
            error("Either pass a PowerNetwork class to `net` or define `Vbus` and `Ibus` options.")
        end
    end

    obj.cv_Vbus = cv_Vb;
    obj.cv_Ibus = obj.cm_Ymat * cv_Vb;
    cv_Sbus     = cv_Vb .* conj(obj.cv_Ibus);
    obj.rv_Pbus = real(cv_Sbus);
    obj.rv_Qbus = imag(cv_Sbus);

    obj.cv_Vcomp = cv_Vb(obj.tab_component.bus);
    obj.cv_Icomp = cv_Ic;
    cv_Scomp     = obj.cv_Vcomp .* conj(cv_Ic);
    obj.rv_Pcomp = real(cv_Scomp);
    obj.rv_Qcomp = imag(cv_Scomp);

    obj.cm_Vbranch = reshape(obj.cm_Vbus2Vbranch * obj.cv_Vbus, 2, []);
    obj.cm_Ibranch = reshape(obj.cm_Vbus2Ibranch * obj.cv_Vbus, 2, []);
    cm_Sbranch = obj.cm_Vbranch .* conj(obj.cm_Ibranch);
    obj.rm_Pbranch = real(cm_Sbranch);
    obj.rm_Qbranch = imag(cm_Sbranch);

    obj.rehash
end
function set_powerflow(obj, cv_Vbus, cv_Icomp)
% Set the bus voltages and component currents shown, and update the drawing.
%
% The current injection of each bus is the sum of the currents of its components. The
% powers of the buses and components, and the end voltages, currents and powers of the
% branches follow from them.
    arguments (Input)
        obj
        cv_Vbus  (:,1) double % [pu] Bus voltage phasors, one per bus.
        cv_Icomp (:,1) double % [pu] Current phasors injected by the components, one per component.
    end
    obj.cv_Vbus = cv_Vbus;
    obj.cv_Ibus = accumarray(obj.tab_component.bus, cv_Icomp, [obj.n_bus, 1]);
    cv_Sbus     = cv_Vbus .* conj(obj.cv_Ibus);
    obj.rv_Pbus = real(cv_Sbus);
    obj.rv_Qbus = imag(cv_Sbus);

    obj.cv_Vcomp = cv_Vbus(obj.tab_component.bus);
    obj.cv_Icomp = cv_Icomp;
    cv_Scomp     = obj.cv_Vcomp .* conj(cv_Icomp);
    obj.rv_Pcomp = real(cv_Scomp);
    obj.rv_Qcomp = imag(cv_Scomp);

    obj.cm_Vbranch = reshape(obj.cm_Vbus2Vbranch * cv_Vbus, 2, []);
    obj.cm_Ibranch = reshape(obj.cm_Vbus2Ibranch * cv_Vbus, 2, []);
    cm_Sbranch     = obj.cm_Vbranch .* conj(obj.cm_Ibranch);
    obj.rm_Pbranch = real(cm_Sbranch);
    obj.rm_Qbranch = imag(cm_Sbranch);

    obj.rehash();
end

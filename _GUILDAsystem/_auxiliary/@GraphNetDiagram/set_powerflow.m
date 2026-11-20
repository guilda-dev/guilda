function set_powerflow(obj, cv_Vbus, cv_Icomp, cv_Ibranch)
% Set the bus voltages and component currents shown and compute the values that follow.
%
% The current injection of each bus is the sum of the currents of its components (NaN, a
% tripped unit, counts as 0). The powers of the buses and components, and the end
% voltages and powers of the branches follow from them and the branch currents.
    arguments (Input)
        obj
        cv_Vbus  (:,1) double  % [pu] Bus voltage phasors, one per bus.
        cv_Icomp (:,1) double  % [pu] Current phasors injected by the components, one per component.
        cv_Ibranch (:,1) double  % [pu] Currents into the branches at both ends: from, to of each branch (a column of sct_state.cm_Ibranch).
    end
    obj.cv_Vbus = cv_Vbus;
    cv_Iin = cv_Icomp;
    cv_Iin(isnan(cv_Iin)) = 0;                % a tripped unit (NaN) injects nothing
    obj.cv_Ibus = accumarray(obj.tab_component.bus, cv_Iin, [obj.n_bus, 1]);
    cv_Sbus     = cv_Vbus .* conj(obj.cv_Ibus);
    obj.rv_Pbus = real(cv_Sbus);
    obj.rv_Qbus = imag(cv_Sbus);

    obj.cv_Vcomp = cv_Vbus(obj.tab_component.bus);
    obj.cv_Icomp = cv_Icomp;
    cv_Scomp     = obj.cv_Vcomp .* conj(cv_Icomp);
    obj.rv_Pcomp = real(cv_Scomp);
    obj.rv_Qcomp = imag(cv_Scomp);

    obj.cm_Vbranch = reshape(obj.cm_Vbus2Vbranch * cv_Vbus, 2, []);
    obj.cm_Ibranch = reshape(cv_Ibranch, 2, []);
    cm_Sbranch     = obj.cm_Vbranch .* conj(obj.cm_Ibranch);
    obj.rm_Pbranch = real(cm_Sbranch);
    obj.rm_Qbranch = imag(cm_Sbranch);
end

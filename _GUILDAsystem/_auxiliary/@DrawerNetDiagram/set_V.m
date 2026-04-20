function set_V(obj, cv_V)
    arguments
        obj
        cv_V (:,1) double
    end

    obj.cv_Vbus = cv_V;
    obj.cv_Ibus = obj.cm_Ymat * obj.cv_Vbus;
    cv_Sbus = obj.cv_Vbus .* conj(obj.cv_Ibus);
    obj.rv_Pbus = real(cv_Sbus);
    obj.rv_Qbus = imag(cv_Sbus);

    obj.cm_Vbranch = reshape(obj.cm_Vbus2Vbranch * obj.cv_Vbus, 2, []);
    obj.cm_Ibranch = reshape(obj.cm_Vbus2Ibranch * obj.cv_Vbus, 2, []);
    cm_Sbranch = obj.cm_Vbranch .* conj(obj.cm_Ibranch);
    obj.rm_Pbranch = real(cm_Sbranch);
    obj.rm_Qbranch = imag(cm_Sbranch);

    tab_PQ  = obj.tab_component.powerflow{:,["P","Q"]};
    iv_isSlack = find( obj.tab_component.isSlack );
    i_slackbus = obj.tab_component.bus(iv_isSlack(1));
    tab_PQ(iv_isSlack(1),1) = obj.rv_Pbus(i_slackbus) - sum(tab_PQ(iv_isSlack,1));

    % For the reactive power of PV bus, distribute it based on baseMVA
    for i = 1:obj.n_bus
        iv_Comps = find( obj.tab_component.bus == i );
        if isempty(iv_Comps)
            continue
        end

        lv_nan  = isnan(tab_PQ(iv_Comps,2));
        if any(lv_nan)
            r_Qrest = obj.rv_Qbus(i) - sum(tab_PQ(iv_Comps(~lv_nan),2));
            iv_nan  = iv_Comps(lv_nan);
            if sum(lv_nan) == 1
                tab_PQ(iv_nan,2) = r_Qrest;
            else
                rv_Qrate = obj.tab_component.operation.baseMVA(iv_nan);
                tab_PQ(iv_nan,2) = (rv_Qrate/sum(rv_Qrate)) * r_Qrest;
            end
        end
    end

    obj.rv_Pcomp = tab_PQ(:,1);
    obj.rv_Qcomp = tab_PQ(:,2);
    obj.cv_Vcomp = cv_V(obj.tab_component.bus);
    obj.cv_Icomp = conj( tab_PQ * [1;1j] ./ obj.cv_Vcomp );

    rm_Varg = angle(obj.cm_Vbranch);
    obj.EdgeB2B_forward = (rm_Varg(1,:) - rm_Varg(2,:)) >= 0;

    if obj.NodeHeightMode ~= "none"
        obj.draw_graph_network();
    end
    obj.rehash
end
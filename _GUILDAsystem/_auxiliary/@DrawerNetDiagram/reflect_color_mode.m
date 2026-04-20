function reflect_color_mode(obj)
    color_mode = obj.ColorMode;

    n_edge   = obj.n_branch;
    n_comp   = obj.n_component;

    if color_mode == "none"
        obj.EdgeB2B_ColorVal = nan(n_edge, 1);
        obj.EdgeB2C_ColorVal = nan(n_comp, 1);
        return
    end

    rv_main = zeros(n_edge, 1);
    rv_Redge  = obj.tab_branch.dynamics.R;
    
    for i = 1:n_edge
        switch color_mode
            case "Loss"
                cv_Iedge1  = obj.cm_Ibranch(1,i); 
                rv_main(i) = real(rv_Redge(i) * cv_Iedge1 * conj(cv_Iedge1));
            case "I (current)"
                rv_main(i) = abs(obj.cm_Ibranch(1,i));
            case "P (active power)"
                rv_main(i) = mean(abs(obj.rm_Pbranch(:,i)), 'omitnan');
            case "Q (reactive power)"
                rv_main(i) = abs(sum(obj.rm_Qbranch(:,i), 'omitnan'));
            otherwise
                rv_main(i) = nan;
        end
    end
    obj.EdgeB2B_ColorVal = rv_main;

    rv_comp   = zeros(n_comp, 1);
    for i_comp = 1:obj.n_component
        switch color_mode
            case "Loss"
                rv_comp(i_comp) = nan;
            case "I (current)"
                rv_comp(i_comp) = abs(obj.cv_Icomp(i_comp));
            case "P (active power)"
                rv_comp(i_comp) = obj.rv_Pcomp(i_comp);
            case "Q (reactive power)"
                rv_comp(i_comp) = obj.rv_Qcomp(i_comp);
            otherwise
                rv_comp(i_comp) = nan;
        end
    end
    obj.EdgeB2C_ColorVal = rv_comp;
end
function [last_index, node, edge, Pset, Qset] = get_geometric(obj, last_index, tab_V, sct_comp)
    
    rm_X = sct_comp.X.Variables.';
    rm_U = sct_comp.U.Variables.';

    n_time = size(rm_X,2);

    rm_Vbus = tab_V{:,["Vreal","Vimag"]}.';

    fcn_I   = @(t) obj.fv_odeI( 0, rm_X(:,t), rm_Vbus(:,t), rm_U(:,t));
    cr_Ibus = tools.hcellfun(@(t) fcn_I(t), 1:n_time);
    cr_Vbus = [1,1j] * rm_Vbus;

    cr_Sbus = cr_Vbus .* conj(cr_Ibus);
    rr_Pbus = real(cr_Sbus);
    rr_Qbus = imag(cr_Sbus);

    Pset = real(cr_Sbus);
    Qset = imag(cr_Sbus);

    [node, edge] = obj.get_geometric_parts(rm_X, rm_U, cr_Vbus, cr_Ibus, rr_Pbus, rr_Qbus);
    edge = last_index + edge;
    last_index = last_index + numel(node);
end
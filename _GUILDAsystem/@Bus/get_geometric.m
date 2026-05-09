function [last_index, node, edge] = get_geometric(obj, last_index, tab_V, tab_PQ, sct_comp)
    
    a_Comp = obj.a_Component;

    rr_Pbus = tab_PQ.P.';
    rr_Qbus = tab_PQ.Q.';
    cr_Vbus = ( tab_V(:,["Vreal","Vimag"]) * [1;1j] ).';
    rr_Varg = angle(cr_Vbus);
    rr_Vabs = abs(  cr_Vbus);

    n_comp = numel(obj.a_Component);
    cell_node = cell(n_comp+1,1);
    
    rm_edge = cell(1,n_comp);
    i_bus = n_comp + 1;

    Pset = 0;
    Qset = 0;
    for i_comp = 1:n_comp
        [i_node, i_edge, i_Pset, i_Qset] = a_Comp{i_comp}.get_geometric(i_comp, tab_V, sct_comp(i_comp));
        cell_node{i_comp} = i_node;
        Pset = Pset + i_Pset;
        Qset = Qset + i_Qset;
        rm_edge{i_comp} = [ [i_bus;i_comp], i_edge];
    end

    tab_PFset = obj.get_pf_set;
    cell_node{n_comp+1} = struct( ...
                  'Color', [0,0,0,1], ...
                  'Label', [], ...
                  'Hover', obj.get_tag + "("+tab_PFset.Type+")", ...
                  'Pset' , Pset, ...
                  'Qset' , Qset, ...
                  'Pflow', rr_Pbus, ...
                  'Iflow', rr_Qbus./rr_Vabs, ...
                  'Varg' , rr_Varg, ...
                  'Vabs' , rr_Vabs );

    node = vertcat(cell_node{:});
    edge = horzcat(rm_edge{:}) + last_index;
    edge = reshape(edge,[],1);

    last_index = last_index + i_bus;
end
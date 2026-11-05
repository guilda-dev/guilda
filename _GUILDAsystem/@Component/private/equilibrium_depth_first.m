function x = equilibrium_depth_first(parent)
% States of parent and then of its local controllers, depth first (the order of get_variable_map)
    arguments (Input)
        parent   % Component or LocalController.
    end
    arguments (Output)
        x (:,1) double   % Stacked state equilibria.
    end
    x_con = tools.vcellfun(@equilibrium_depth_first, parent.a_LocalController);
    x     = [reshape(parent.rv_Xequilibrium, [], 1); x_con];
end

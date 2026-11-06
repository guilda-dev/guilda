function l_complete = restore_parameter_listeners(layer)
% Attach the class check and the listeners of Parameter.add_entry again on a layer and all
% layers below it. The class a parameter must keep is taken from its value.
% l_complete is false when a layer is still being loaded (the MAT file holds a variable
% below the network, which loads the network from inside that layer): its parameters are
% not available yet.
    arguments (Input)
        layer   % PowerNetwork, Bus, Branch, Component or controller.
    end
    arguments (Output)
        l_complete (1,1) logical   % False when a layer is still being loaded.
    end
    % Every layer has at least one container: none yet means it is still being loaded.
    l_complete = ~isempty(layer.a_Parameter);
    for i_para = 1:numel(layer.a_Parameter)
        para = layer.a_Parameter{i_para};
        if ~isa(para, "Parameter")
            l_complete = false;
            continue
        end
        for name = setdiff(string(properties(para)), string(properties("Parameter"))).'
            para.attach_callbacks(name, class(para.(name)));
        end
    end
    if isa(layer, "PowerNetwork")
        a_lower = [layer.a_Bus; layer.a_Branch; layer.a_GlobalController];
    elseif isa(layer, "Bus")
        a_lower = layer.a_Component;
    elseif isprop(layer, "a_LocalController")
        a_lower = layer.a_LocalController;
    else
        a_lower = {};
    end
    l_complete = all([l_complete, cellfun(@restore_parameter_listeners, a_lower(:).')]);
end

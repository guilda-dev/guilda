function delete_layers(c_layer)
% Delete removed model objects together with the objects under them.
%
% Called by the remove and replace methods after they take the objects out of their
% parent, so a handle the user still holds becomes invalid (isvalid is false). A bus
% takes its components, and a component or a local controller its local controllers.
%
% <@Examples>
% ```matlab
% tools.delete_layers({comp})   % in Bus.remove_component
% ```
    arguments (Input)
        c_layer cell   % Removed objects (Bus, Branch, Component, LocalController or GlobalController).
    end
    for k = 1:numel(c_layer)
        layer = c_layer{k};
        if isa(layer, "Bus")
            tools.delete_layers(layer.a_Component);
        elseif isa(layer, "Component") || isa(layer, "LocalController")
            tools.delete_layers(layer.a_LocalController);
        end
        delete(layer);
    end
end

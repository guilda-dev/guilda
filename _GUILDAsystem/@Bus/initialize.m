function initialize(obj)
% Bring the components of the bus up to date (PowerNetwork.initialize, after the power
% flow is written): Component.initialize of each.
%
% <@Group> Called by analyses
    arguments (Input)
        obj
    end
    for k = 1:numel(obj.a_Component)
        obj.a_Component{k}.initialize();
    end
end

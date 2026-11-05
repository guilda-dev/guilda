function remove_local_controller(obj)
% Detach the nested controller (Component.add_local_controller, when an AVR is replaced; Component.remove_local_controller)
%
% <@Group> Construction and attachment
    arguments (Input)
        obj
    end
    obj.a_LocalController = cell(0,1);
    obj.l_hasController = false;
end

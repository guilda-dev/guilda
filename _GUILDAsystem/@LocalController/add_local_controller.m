function add_local_controller(obj,a_Controller)
% Attach a nested controller (the PSS under an AVR; Component.add_local_controller).
%
% <@Group> Construction and attachment
    arguments (Input)
        obj
        a_Controller (1,1) LocalController   % Nested controller (the PSS).
    end
    obj.a_LocalController = {a_Controller};
    obj.l_hasController = true;
end

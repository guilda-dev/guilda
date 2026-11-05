function set_odefcn(obj)
% Build the f_* handle cache from the current parameters and network frequency.
% Layers that own handles (Component, LocalController, GlobalController)
% override this; other layers have nothing to build.
    arguments (Input)
        obj
    end
    obj.s_odefcn = "updated";
end

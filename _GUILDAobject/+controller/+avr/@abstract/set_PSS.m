function set_PSS(obj, cls)
% Attach a PSS to the AVR.
% The base implementation ignores `cls`; the concrete AVRs attach `cls`.
    arguments (Input)
        obj
        cls  % PSS object (a controller.pss.abstract subclass).
    end
    obj.a_LocalController{1} = controller.pss.base;
    obj.l_hasController = true;
end

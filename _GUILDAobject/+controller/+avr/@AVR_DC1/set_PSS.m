function set_PSS(obj, cls)
% Attach a PSS to the AVR.
    arguments (Input)
        obj
        cls  % PSS object (a controller.pss.abstract subclass).
    end
    obj.a_LocalController{1} = cls;
    obj.l_hasController = true;
end

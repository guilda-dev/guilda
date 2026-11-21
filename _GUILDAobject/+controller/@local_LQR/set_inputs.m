function set_inputs(obj, sv_name)
    arguments (Input)
        obj
        sv_name  % Names of the observed signals.
    end
    obj.sv_u = sv_name;
end

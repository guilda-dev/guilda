function set_inputs(obj, sv_name)
% The observed signals with "Xall" expanded: the states of the generator
    arguments (Input)
        obj
        sv_name  % Names of the observed signals.
    end
    obj.sv_u = sv_name;
end

function Hz = get_Hz(obj)
% Nominal frequency [Hz] of the network the model belongs to.
% net.tab_parameter.base.Hz; GUILDA.config("Model","Hz") when not attached to a
% network. This is the omega0 passed to the model functions (models multiply it by 2*pi).
    arguments (Input)
        obj
    end
    arguments (Output)
        Hz (1,1) double % [Hz] Nominal frequency.
    end
    p = obj;
    while isa(p,"PowerSystemModel") && ~isa(p,"PowerNetwork")
        p = p.parent;
    end
    if isa(p,"PowerNetwork")
        Hz = p.a_Parameter{cellfun(@(c) c.s_tag=="base", p.a_Parameter)}.Hz;
    else
        Hz = GUILDA.config("Model","Hz");
    end
end

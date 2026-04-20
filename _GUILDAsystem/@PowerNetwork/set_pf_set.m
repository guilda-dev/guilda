function set_pf_set(obj, name, para)
    arguments
        obj 
        name      (1,1) string = "NAN" 
        para.Varg (1,1) double = nan
        para.V    (1,1) double = nan
        para.P    (1,1) double = nan
        para.Q    (1,1) double = nan        
    end
    bc = ["b","c"];
    mx = blkdiag([1;1],[1;1]);
    switch bc( logical( ~isnan(struct2array(para))*mx ) )
        case "b"
            tag = cellfun(@(d) d.str_tag, obj.a_Bus);
            if ~any(ismember(name, tag))
                error("This bus is not registered within the system. Please review your settings.")
            end
            idx = find(name==tag);
            obj.a_Bus{idx}.para_powerflow.Varg = para.Varg;
            obj.a_Bus{idx}.para_powerflow.V    = para.V;

        case "c"
            tag = cellfun(@(d) string(d.a_Component), obj.a_Bus, 'UniformOutput', false);
            [nb, nc] = get_tag(name, tag);
            if isempty(nb) && isempty(nc)
                error("This component is not registered within the system. Please review your settings.")
            end        
            obj.a_Bus{nb}.a_Component{nc}.para_powerflow.P = para.P;
            obj.a_Bus{nb}.a_Component{nc}.para_powerflow.Q = para.Q;
    end        
end

function [nb, nc] = get_tag(name, tag)
    nb = []; nc = [];
    for i=1:numel(tag)
        eqs = name==tag{i};
        if any(eqs)
            nb = i;
            nc = find(eqs);
        end
    end
end

function l = odefcn_stale(obj)
% True when the f_* handles must be rebuilt: the stale tag odefcn is not empty, or the
% network frequency differs from the one bound into them.
    arguments (Input)
        obj
    end
    arguments (Output)
        l (1,1) logical  % True when build_odefcn is needed.
    end
    l = ~isempty(obj.sct_stale.odefcn) || ~isequal(obj.r_odefcnHz, obj.get_Hz());
end

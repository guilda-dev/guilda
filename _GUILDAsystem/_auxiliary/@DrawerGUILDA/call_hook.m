function call_hook(obj, s_hook, varargin)
% Call a hook of the active tab (f_show, f_click) when the tab has it.
    arguments (Input)
        obj
        s_hook (1,1) string  % Name of the hook.
    end
    arguments (Input, Repeating)
        varargin             % Arguments of the hook.
    end
    arguments (Output)
    end
    i_tab = find([obj.sct_tab.s_key] == obj.s_active, 1);
    if isempty(i_tab) || isempty(obj.sct_tab(i_tab).(s_hook))
        return
    end
    obj.sct_tab(i_tab).(s_hook)(varargin{:});
end

function refresh_controls(obj)
% Make the panel of controls show the values of the properties.
%
% Called after a control changed (also when the property refused the value, to put the
% widget back), by the PostSet listeners of the declared properties and by set_data. The
% EnableFcn of every control is evaluated again. Nothing happens without a panel.
    arguments (Input)
        obj
    end
    h_panel = obj.h_controls;
    if isempty(h_panel) || ~isgraphics(h_panel)
        return
    end
    sct = h_panel.UserData;
    for i = 1:numel(sct.sct_ctl)
        ctl = sct.sct_ctl(i);
        w   = sct.c_widget{i};
        val = obj.(ctl.Property);
        switch ctl.Widget
            case "dropdown"
                s_val = string(val);
                if ~ismember(s_val, string(w.Items))
                    w.Items = [string(w.Items), s_val];
                end
                w.Value = s_val;
            case {"checkbox", "toggle"}
                w.Value = logical(val);
            case "slider"
                w.Limits     = [min(ctl.Limits(1), val), max(ctl.Limits(2), val)];
                w.MajorTicks = w.Limits;
                w.Value      = val;
            case "spinner"
                w.Limits = [min(ctl.Limits(1), val), max(ctl.Limits(2), val)];
                w.Value  = val;
            case "range"
                if numel(w) == 3               % automatic (NaN): the values in use, Auto checked
                    w(3).Value = any(isnan(val));
                    if w(3).Value
                        val = ctl.Items(obj);
                    end
                end
                for j = 1:2
                    w(j).Limits = [min([ctl.Limits(1), val]), max([ctl.Limits(2), val])];
                    w(j).Value  = val(j);
                end
        end
        if ~isempty(ctl.EnableFcn)
            set(w, "Enable", matlab.lang.OnOffSwitchState(ctl.EnableFcn(obj)));
        end
    end
end

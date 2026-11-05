function check_assign(val)
% Accept only this view for comp.para_base = value.
%
% comp.para_base.Hz = x is forwarded by the view itself (it is a handle).
    arguments (Input)
        val  % Value assigned to comp.para_base.
    end
    if ~isa(val, "ComponentBaseView")
        error(msg("GUILDA:ComponentBaseView:ComponentBaseHz"));
    end
end

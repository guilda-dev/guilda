function opt = v3_bus_baseMVA(net, opt)
% Ignore the deprecated add_bus option baseMVA with a warning.
%
% v3 compatibility hook of PowerNetwork.add_bus: handles the removed baseMVA option.
% A given value is ignored with the warning GUILDA:Deprecated:BusBaseMVA, or
% GUILDA:Deprecated:BusBaseMVAMismatch when it differs from the system base
% net.tab_parameter.base.baseMVA. The field is removed from opt.
%
% Name-Value options:
%
% - `net` — Network the bus is added to.
% - `opt` — Options of add_bus.
%
% See also PowerNetwork.add_bus
    arguments (Output)
        opt   % opt without the baseMVA field.
    end
    if ~isfield(opt, "baseMVA")
        return
    end
    if ~isnan(opt.baseMVA)
        r_base = net.para_base.baseMVA;
        if opt.baseMVA == r_base
            Deprecated("BusBaseMVA", r_base);
        else
            Deprecated("BusBaseMVAMismatch", opt.baseMVA, r_base);
        end
    end
    opt = rmfield(opt, "baseMVA");
end

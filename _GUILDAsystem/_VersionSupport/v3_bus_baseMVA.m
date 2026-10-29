function opt = v3_bus_baseMVA(net, opt)
% <@Desc>
% v3 compatibility hook of PowerNetwork.add_bus: handles the removed baseMVA option.
% A given value is ignored with the warning GUILDA:Deprecated:BusBaseMVA, or
% GUILDA:Deprecated:BusBaseMVAMismatch when it differs from the system base
% net.tab_parameter.base.baseMVA. The field is removed from opt.
% <@Role> Compatibility
% <@Summary> Ignore the deprecated add_bus option baseMVA with a warning.
% <@Signatures>
% [
%   "opt = v3_bus_baseMVA(net, opt)"
% ]
% <@Parameters>
% [
%   {"Name": "net", "Type": "PowerNetwork", "Description": "Network the bus is added to.", "Required": true, "Default": "-"},
%   {"Name": "opt", "Type": "struct", "Description": "Options of add_bus.", "Required": true, "Default": "-"}
% ]
% <@Returns>
% [
%   {"Name": "opt", "Type": "struct", "Description": "opt without the baseMVA field."}
% ]
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

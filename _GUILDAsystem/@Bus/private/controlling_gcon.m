function str_gcon = controlling_gcon(obj, comp)
% Tag of the global controller of the network that controls this component ("" if none).
%
% Compares the objects: a replacing component usually keeps the tag of the old one.
    str_gcon = "";
    net = obj.a_PowerNetwork;
    if isempty(net)
        return
    end
    for i = 1:numel(net.a_GlobalController)
        gcon = net.a_GlobalController{i};
        if any(cellfun(@(unit) unit == comp, gcon.controlledUnits))
            str_gcon = gcon.str_tag;
            return
        end
    end
end

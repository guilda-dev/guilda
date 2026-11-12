function s_gcon = controlling_gcon(obj, comp)
% Tag of the global controller of the network that controls this component ("" if none).
%
% Compares the objects: a replacing component usually keeps the tag of the old one.
    arguments (Input)
        obj
        comp   % Component to look for in the controlledUnits of the global controllers.
    end
    arguments (Output)
        s_gcon   % Tag of the controlling global controller, or "" if none.
    end
    s_gcon = "";
    net = obj.a_PowerNetwork;
    for i = 1:numel(net.a_GlobalController)
        gcon = net.a_GlobalController{i};
        if any(cellfun(@(unit) unit == comp, gcon.controlledUnits))
            s_gcon = gcon.s_tag;
            return
        end
    end
end

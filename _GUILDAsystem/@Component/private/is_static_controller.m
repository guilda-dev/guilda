function l = is_static_controller(con)
% Whether con is a default Static controller of a synchronous generator ("avr-static", "gov-static").
    arguments (Input)
        con (1,1) LocalController  % Local controller.
    end
    arguments (Output)
        l (1,1) logical  % true for controller.avr.Static and controller.governor.Static.
    end
    l = ismember(con.key, ["avr-static", "gov-static"]);
end

function bus = add_bus(obj, opt)
% Add a bus to the network and return it.
%
% The bus tag is `Tag` followed by a three-digit number (the largest number in use + 1),
% e.g. "B001". The addition is logged as a "Topology" edit, so the equilibrium becomes
% stale until `net.initialize()` runs again.
%
% <@Examples>
% ```matlab
% net = PowerNetwork();
% b1  = net.add_bus(V=1.0, Varg=0);
% b2  = net.add_bus(Bshunt=0.1, Vmin=0.9, Vmax=1.1);
% ```
%
% See also PowerNetwork.remove_bus, PowerNetwork.add_branch, Bus
    arguments
        obj 
        opt.Varg              (1,1) double = 0 /180*pi;   % [rad] Voltage angle setting used when the bus is the slack bus.
        opt.V                 (1,1) double = 1;   % [pu] Voltage magnitude setting (slack or PV bus).
        opt.Gshunt            (1,1) double = 0;   % [pu] Shunt conductance.
        opt.Bshunt            (1,1) double = 0;   % [pu] Shunt susceptance.
        opt.Vmin              (1,1) double = 0.5;   % [pu] Lower voltage bound for the OPF.
        opt.Vmax              (1,1) double = 1.5;   % [pu] Upper voltage bound for the OPF.
        opt.baseKV            (1,1) double = 230;   % [kV] Base voltage.
        opt.baseMVA           (1,1) double = nan;   % [MVA] COMPAT(v3) Ignored; the system base is net.tab_parameter.base.baseMVA.
        opt.Varg0             (1,1) double = 0/180*pi;   % [rad] Initial voltage angle of the power-flow and OPF solvers.
        opt.V0                (1,1) double = 1;   % [pu] Initial voltage magnitude of the power-flow and OPF solvers.
        opt.Tag               (1,1) string = 'B';   % Prefix of the bus tag.
        opt.Xaxis             (1,1) double = nan;   % x coordinate in network diagrams (NaN = automatic layout).
        opt.Yaxis             (1,1) double = nan;   % y coordinate in network diagrams (NaN = automatic layout).
        opt.Marker            (1,1) string = "s";   % Marker of the bus in network diagrams.
    end
    arguments (Output)
        bus   % Added Bus object.
    end

    % largest number in use + 1 (after remove_bus, numel+1 may already be taken)
    str_Bus = opt.Tag+num2str(tools.next_tag_number(string(obj.a_Bus)),"%.3d");

    opt = v3_bus_baseMVA(obj, opt);                   % COMPAT(v3)
    opt = rmfield(opt,"Tag");
    bus = Bus(obj, str_Bus, opt);
    
    obj.a_Bus = [obj.a_Bus;{bus}];
    obj.log_edit(obj.str_tag+" <<-Add--- "+bus.str_tag,"Topology");
end
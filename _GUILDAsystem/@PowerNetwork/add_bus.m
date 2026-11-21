function bus = add_bus(obj, opt)
% Add a bus to the network and return it.
%
% The bus tag is `Tag` followed by a three-digit number (the largest number in use + 1),
% e.g. "B001". `FullTag` gives the complete tag instead, with no automatic number; a
% tag already used in the network is renamed with a number suffix, as for `s_tag`, and
% an Info line shows the change. The tag must be a valid variable name (isvarname, e.g.
% "Sub_7", not "Sub-7"); any other tag stops with GUILDA:LayerPackage:InvalidTag and no bus
% is added. The addition is a "Topology" edit, so the power flow is stale until
% `net.initialize()` runs again.
%
% <@Examples>
% ```matlab
% net = PowerNetwork();
% b1  = net.add_bus(V=1.0, Varg=0);
% b2  = net.add_bus(Bshunt=0.1, Vmin=0.9, Vmax=1.1);
% b3  = net.add_bus(FullTag="Sub7");
% b4  = net.add_bus(X=0.5, Y=0.2, Shape="hbar", Length=0.1);   % a bar in network diagrams
% ```
%
% The graph arguments (X to Color) are the layout of the bus in network diagrams; a bar
% ("hbar", "vbar") needs a positive Length. A wrong value stops before the bus is added.
%
% See also PowerNetwork.remove_bus, PowerNetwork.add_branch, Bus
%
% <@Group> Model building
    arguments (Input)
        obj 
        opt.Varg              (1,1) double = 0 /180*pi;  % [rad] Voltage angle setting used when the bus is the slack bus.
        opt.V                 (1,1) double = 1;          % [pu] Voltage magnitude setting (slack or PV bus).
        opt.Gshunt            (1,1) double = 0;          % [pu] Shunt conductance.
        opt.Bshunt            (1,1) double = 0;          % [pu] Shunt susceptance.
        opt.Vmin              (1,1) double = 0.5;        % [pu] Lower limit of the bus voltage magnitude (-Inf: none).
        opt.Vmax              (1,1) double = 1.5;        % [pu] Upper limit of the bus voltage magnitude (Inf: none).
        opt.baseKV            (1,1) double = 230;        % [kV] Base voltage; stored and exported to MATPOWER, used in no calculation.
        opt.baseMVA           (1,1) double = nan;        % [MVA] COMPAT(v3) Ignored; the system base is net.tab_parameter.base.baseMVA.
        opt.Tag               (1,1) string = 'B';        % Prefix of the bus tag.
        opt.FullTag           (1,1) string = "";         % Complete bus tag, used instead of Tag and the automatic number ("" = automatic).
        opt.X                 (1,1) double {mustBeReal} = nan;           % x coordinate of the bus center in network diagrams (NaN = automatic layout).
        opt.Y                 (1,1) double {mustBeReal} = nan;           % y coordinate of the bus center in network diagrams (NaN = automatic layout).
        opt.Shape             (1,1) string {mustBeMember(opt.Shape, ["hbar","vbar","circle","square","^","v","<",">","none"])} = "square";  % Shape in network diagrams: "hbar", "vbar" (bars, which need Length) or a marker.
        opt.Length            (1,1) double {mustBePositiveOrNaN} = nan;  % Length of a bar ("hbar", "vbar"); NaN for the other shapes.
        opt.MarkerSize        (1,1) double {mustBePositiveOrNaN} = nan;  % Marker size in network drawings (NaN = drawer default).
        opt.Color             (1,1) string = "";                         % Color in network drawings: a MATLAB color name or "#RRGGBB" ("" = drawer default).
    end
    arguments (Output)
        bus  % Added Bus object.
    end

    % largest number in use + 1 (after remove_bus, numel+1 may already be taken);
    % the tags are read in a loop: string(obj.a_Bus) calls string() on every bus, which
    % makes adding N buses slow (O(N^2) method calls)
    sv_Bus = strings(numel(obj.a_Bus), 1);
    for i = 1:numel(sv_Bus)
        sv_Bus(i) = obj.a_Bus{i}.s_tag;
    end
    s_Bus = opt.Tag+num2str(tools.next_tag_number(sv_Bus),"%.3d");
    if opt.FullTag ~= ""
        s_Bus = opt.FullTag;
    end

    opt = v3_bus_baseMVA(obj, opt);                   % COMPAT(v3)
    opt = rmfield(opt,["Tag","FullTag"]);
    bus = Bus(obj, s_Bus, opt);
    
    obj.a_Bus = [obj.a_Bus;{bus}];
    obj.log_edit(obj.s_tag+" <<-Add--- "+bus.s_tag,"Topology");
end
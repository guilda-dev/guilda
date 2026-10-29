function bus = add_bus(obj, opt)
    arguments
        obj 
        opt.Varg              (1,1) double = 0 /180*pi;
        opt.V                 (1,1) double = 1;
        opt.Gshunt            (1,1) double = 0;
        opt.Bshunt            (1,1) double = 0;
        opt.Vmin              (1,1) double = 0.5;
        opt.Vmax              (1,1) double = 1.5;
        opt.baseKV            (1,1) double = 230;
        opt.baseMVA           (1,1) double = nan;     % COMPAT(v3) deprecated and ignored (net.tab_parameter.base.baseMVA)
        opt.Varg0             (1,1) double = 0/180*pi;
        opt.V0                (1,1) double = 1;
        opt.Tag               (1,1) string = 'B';
        opt.Xaxis             (1,1) double = nan;
        opt.Yaxis             (1,1) double = nan;
        opt.Marker            (1,1) string = "s";
    end

    % largest number in use + 1 (after remove_bus, numel+1 may already be taken)
    str_Bus = opt.Tag+num2str(tools.next_tag_number(string(obj.a_Bus)),"%.3d");

    opt = v3_bus_baseMVA(obj, opt);                   % COMPAT(v3)
    opt = rmfield(opt,"Tag");
    bus = Bus(obj, str_Bus, opt);
    
    obj.a_Bus = [obj.a_Bus;{bus}];
    obj.log_edit(obj.str_tag+" <<-Add--- "+bus.str_tag,"Topology");
end
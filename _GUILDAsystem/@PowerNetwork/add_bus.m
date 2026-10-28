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
        opt.baseMVA           (1,1) double = nan;     % deprecated and ignored (net.tab_parameter.base.baseMVA)
        opt.Varg0             (1,1) double = 0/180*pi;
        opt.V0                (1,1) double = 1;
        opt.Tag               (1,1) string = 'B';
        opt.Xaxis             (1,1) double = nan;
        opt.Yaxis             (1,1) double = nan;
        opt.Marker            (1,1) string = "s";
    end

    % next number not used yet (after remove_bus, numel+1 may already be taken)
    n_Bus   = numel(obj.a_Bus);
    str_Bus = opt.Tag+num2str(n_Bus+1,"%.3d");
    while ismember(str_Bus, string(obj.a_Bus))
        n_Bus   = n_Bus + 1;
        str_Bus = opt.Tag+num2str(n_Bus+1,"%.3d");
    end

    if ~isnan(opt.baseMVA)
        r_base = obj.para_base.baseMVA;
        if opt.baseMVA == r_base
            Deprecated("BusBaseMVA", r_base);
        else
            Deprecated("BusBaseMVAMismatch", opt.baseMVA, r_base);
        end
    end
    opt = rmfield(opt,["Tag","baseMVA"]);
    bus = Bus(obj, str_Bus, opt);
    
    obj.a_Bus = [obj.a_Bus;{bus}];
    obj.log_edit(obj.str_tag+" <<-Add--- "+bus.str_tag,"Topology");
end
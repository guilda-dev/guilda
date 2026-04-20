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
        opt.baseMVA           (1,1) double = 100;
        opt.OPFinit_Varg0     (1,1) double = 0/180*pi;
        opt.OPFinit_V0        (1,1) double = 1;
        opt.Tag               (1,1) string = 'B';
        opt.Xaxis             (1,1) double = nan;
        opt.Yaxis             (1,1) double = nan;
        opt.Marker            (1,1) string = "s";
    end

    n_Bus   = numel(obj.a_Bus);
    str_Bus = opt.Tag+num2str(n_Bus+1,"%.3d");

    opt = rmfield(opt,"Tag");
    % opt = namedargs2cell(opt);
    % bus = Bus(str_Bus, opt{:});
    bus = Bus(str_Bus, opt);
    bus.set_network(obj)

    obj.a_Bus = [obj.a_Bus;{bus}];
    obj.log_edit(obj.str_tag+" <<-Add--- "+bus.str_tag,"Topology");
end
function replace_component(obj, str_tag, Type, parameter)

    arguments
        obj
        str_tag              (1,1) string
        Type                 (1,:) char {mustBeMember(Type,{'gen-classical','gen-1axis','gen-park','load-impedance','load-power'})} % Component type
        parameter             = nan;
    end

    str_tagComp = string(obj.a_Component);
    lv_rmcub = str_tagComp==str_tag;
    if ~any(lv_rmcub)
        error("No component with '"+str_tag+"' was found.")
    end

    comp_pre = obj.a_Component{lv_rmcub};
    tab_pre  = [comp_pre.para_powerflow.tab_parameter, ...
                comp_pre.para_operation.tab_parameter, ...
                comp_pre.para_graph.tab_parameter];
    opt      = table2struct(tab_pre);

    tab_opf  = comp_pre.para_OPF;
    opt.OPFinit_P0       = tab_opf.P0;
    opt.OPFinit_Q0       = tab_opf.Q0;
    opt.OPFcost_HP       = tab_opf.HP;
    opt.OPFcost_HQ       = tab_opf.HQ;
    opt.OPFcost_fP       = tab_opf.fP;
    opt.OPFcost_fQ       = tab_opf.fQ;
    opt.OPFcost_startup  = tab_opf.startup;
    opt.OPFcost_shutdown = tab_opf.shutdown;

    str_index = char(comp_pre.str_tag);
    str_index = string( str_index(1:end-3) );

    
    % get component function
    switch Type
        case 'gen-classical';  mkInst = @component.generator.classical;
        case 'gen-1axis';      mkInst = @component.generator.one_axis;
        case 'gen-park';       mkInst = @component.generator.park;
        case 'load-impedance'; mkInst = @component.load.impedance;
        case 'load-power';     mkInst = @component.load.power;

    end
    comp = mkInst(str_index, parameter, opt);

    % register
    comp.set_bus(obj)        

    Iequilibrium = obj.a_Component{lv_rmcub}.c_Iequilibrium;
    Vequilibrium = obj.c_Vequilibrium;

    omega0 = obj.parent.tab_parameter.base.Hz;
    
    obj.a_Component{lv_rmcub} = comp;   
    
    comp.get_equilibrium(Vequilibrium, Iequilibrium);
    comp.set_odefcn(omega0);
end
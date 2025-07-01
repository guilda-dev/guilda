function set_equilibrium(obj,dataSheet,mode)
    arguments
        obj 
        dataSheet (1,1) struct
        mode (1,1) string {mustBeMember(mode,["AC OPF","PF","manual"])} = "manual";
    end
    nbus = numel(obj.Buses);

    Vvec = tools.varrayfun(@(i) dataSheet.Bus(i).Vbus, 1:nbus);
    Ivec = tools.varrayfun(@(i) dataSheet.Bus(i).Ibus, 1:nbus);

    % validation
    Y = obj.get_admittance_matrix;
    valid =  Ivec - Y*Vvec;
    if (valid'*valid) > 1e-5
        warning(config.lang('潮流状態に誤りがある可能性があります．','There may be an error in the powerflow.'))
    end

    % set equilbrium
    for i = 1:nbus
        d = dataSheet.Bus(i);
        obj.Buses{i}.set_equilibrium(d.Vbus,d.Ibus,d.Pcomp,d.Qcomp);
    end
    tools.vcellfun(@(c) c.set_equilibrium(), obj.GlobalControllers);

    obj.methodPF = mode;
    obj.applyEdit;
end
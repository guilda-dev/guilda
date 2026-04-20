function set_equilibrium(obj,powerflow_bus,powerflow_cub)
    a_Bus = obj.a_Bus;
    for ibus = 1:numel(a_Bus)
        a_busi   = a_Bus{ibus};
        data_bus = powerflow_bus(ibus,:);
        str_cub  = string(a_busi.a_Cubicle);
        data_cub = powerflow_cub(str_cub,:);
        a_busi.set_equilibrium(data_bus,data_cub);
    end
end
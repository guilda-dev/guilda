function set_fault_option_table(app,option)
    temp = string(nan(20,1));
    fault_start = temp;
    fault_end   = temp;
    fault_bus   = temp;
    app.fault_set_table.Data = table(fault_start,fault_end,fault_bus);
    
    if nargin==2
        if isfield(option,'fault')
            for i = numel(option.fault)
                fault_time = option.fault{i}{1};
                fault_bus  = option.fault{i}{2};
                app.fault_set_table.Data{i,:} = ...
                    [num2str(fault_time(1)),num2str(fault_time(2)),mat2str(fault_bus)];
            end
        end
    end
end
function restore_working_data(net)
% Put the working data set during a run back to its initial values,
% also after an error, so that the analysis leaves the model unchanged.
    arguments (Input)
        net  % Network of the run.
    end
    SolverODE.set_gc_connect(net, strings(0,1));
    a_bus = net.a_Bus;
    for i = 1:numel(a_bus)
        a_bus{i}.l_isFault = false;
        a_Comp = a_bus{i}.a_Component;
        for j = 1:numel(a_Comp)
            a_Comp{j}.l_isConnect = true;
            a_Comp{j}.rv_Xoffset = [];
            a_Comp{j}.rv_Uoffset = [];
        end
    end
end

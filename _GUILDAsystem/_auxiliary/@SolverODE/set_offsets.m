function set_offsets(net, ph)
% State offsets and input functions of the phase on the components (Scenario.compile)
    arguments (Input)
        net  % Network of the run.
        ph   % Data of the phase (an element of the output of Scenario.compile).
    end
    c_comp = tools.cellfun(@(b) b.a_Component, net.a_Bus);
    c_comp = vertcat(cell(0,1), c_comp{:});
    for j = 1:numel(c_comp)
        c_comp{j}.rv_Xoffset = ph.c_Xoffset{j};
        c_comp{j}.rv_Uoffset = ph.c_Uoffset{j};
    end
end

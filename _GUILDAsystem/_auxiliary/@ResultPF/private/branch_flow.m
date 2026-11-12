function tab = branch_flow(sct_network, tab_bus)
% Power and current at both ends of each branch of the network snapshot (from = a_Bus{1},
% to = a_Bus{2}), from the solved bus voltages and the admittance of each branch
% (branch_admittance). A branch of an unknown class gets NaN flows.
    arguments (Input)
        sct_network struct  % Snapshot of the network (struct(net, false)).
        tab_bus     table   % Bus values of the solution (tab_bus of ResultPF).
    end
    arguments (Output)
        tab table           % Pfrom, Qfrom, Pto, Qto, Ifrom, Ito, Ploss, Qloss; row names = branch tags.
    end
    a_Branch = cell(0,1);
    if isfield(sct_network, "a_Branch")
        a_Branch = sct_network.a_Branch;
    end
    sv_bus = string(tab_bus.Properties.RowNames);
    n_br   = numel(a_Branch);
    cm_I   = zeros(n_br,2);
    cm_S   = zeros(n_br,2);
    sv_branch = strings(n_br,1);
    for k = 1:n_br
        br = a_Branch{k};
        sv_branch(k) = string(br.s_tag);
        iv_end = bus_index(br.a_Bus, sv_bus);
        cv_Vb  = tab_bus.Vphasor(iv_end);
        cv_Ib  = branch_admittance(br) * cv_Vb;
        cm_I(k,:) = cv_Ib.';
        cm_S(k,:) = (cv_Vb .* conj(cv_Ib)).';
    end
    tab = table(real(cm_S(:,1)), imag(cm_S(:,1)), real(cm_S(:,2)), imag(cm_S(:,2)), ...
                cm_I(:,1), cm_I(:,2), real(sum(cm_S,2)), imag(sum(cm_S,2)), ...
                'VariableNames', ["Pfrom","Qfrom","Pto","Qto","Ifrom","Ito","Ploss","Qloss"], ...
                'RowNames', sv_branch);
end

function tab = branch_flow(sct_network, tab_bus)
% End bus tags, power and current at both ends of each branch of the network snapshot
% (from = a_Bus{1}, to = a_Bus{2}), from the solved bus voltages and the admittance matrix of each branch
% in the snapshot (field cm_Y, added by Branch.struct; NaN flows without it).
    arguments (Input)
        sct_network struct  % Snapshot of the network (struct(net, false)).
        tab_bus     table   % Bus values of the solution (tab_bus of ResultPF).
    end
    arguments (Output)
        tab table  % From, To (bus tags), Pfrom, Qfrom, Pto, Qto, Ifrom, Ito, Ploss, Qloss; row names = branch tags.
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
    sm_end = strings(n_br,2);
    for k = 1:n_br
        br = a_Branch{k};
        sv_branch(k) = string(br.s_tag);
        iv_end = bus_index(br.a_Bus, sv_bus);
        sm_end(k,:) = sv_bus(iv_end).';
        cv_Vb  = tab_bus.Vphasor(iv_end);
        cm_Yb  = nan(2,2);                % a struct made without Branch.struct
        if isfield(br, "cm_Y")
            cm_Yb = br.cm_Y;
        end
        cv_Ib  = cm_Yb * cv_Vb;
        cm_I(k,:) = cv_Ib.';
        cm_S(k,:) = (cv_Vb .* conj(cv_Ib)).';
    end
    tab = table(sm_end(:,1), sm_end(:,2), real(cm_S(:,1)), imag(cm_S(:,1)), real(cm_S(:,2)), imag(cm_S(:,2)), ...
                cm_I(:,1), cm_I(:,2), real(sum(cm_S,2)), imag(sum(cm_S,2)), ...
                'VariableNames', ["From","To","Pfrom","Qfrom","Pto","Qto","Ifrom","Ito","Ploss","Qloss"], ...
                'RowNames', sv_branch);
end

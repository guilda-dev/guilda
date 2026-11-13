function sct_stop = stop_condition(net, sct_dae, r_angle)
% Stop condition of StopOnOutOfStep for SolverODE.solve (sct_dae.sct_stop).
%
% The units are the components with the state delta; the reference is the generator of
% the slack bus (the first component with delta on a slack bus, as the default of
% ResultODE.judge_out_of_step). The run stops when |delta_k - delta_ref| of a unit that is
% not tripped exceeds r_angle (no wrapping); while the reference is tripped it does not
% stop. Stops with GUILDA:PowerNetwork:StopNoRotorAngle when the network has no
% generator on the slack bus or no other component with delta.
    arguments (Input)
        net                       % Network of the run (slack buses).
        sct_dae (1,1) struct      % Data of the run (simulation_blocks).
        r_angle (1,1) double      % [deg] StopAngle.
    end
    arguments (Output)
        sct_stop (1,1) struct     % iv_angle, iv_angleComp, i_ref, i_refComp (rows of tab_variable, positions in c_comp), r_limit [rad], r_angle [deg].
    end
    tab  = sct_dae.tab_variable;
    iv_d = find(tab.Kind == "x" & tab.Name == "delta" & ismember(tab.Owner, sct_dae.sv_comp));
    lv_slack = cellfun(@(b) b.l_isSlack, net.a_Bus);
    sv_slack = sct_dae.sv_bus(lv_slack(:));
    i_ref = find(ismember(tab.Bus(iv_d), sv_slack), 1);
    if isempty(i_ref) || numel(iv_d) < 2
        sv_unit = tab.Owner(iv_d);
        if isempty(sv_unit)
            sv_unit = "none";
        end
        error(msg("GUILDA:PowerNetwork:StopNoRotorAngle", char(string(net.s_tag)), ...
                  char(join([sv_slack; strings(isempty(sv_slack),1) + "none"], ", ")), char(join(sv_unit, ", "))));
    end
    [~, iv_comp] = ismember(tab.Owner(iv_d), sct_dae.sv_comp);
    sct_stop = struct();
    sct_stop.iv_angle     = iv_d([1:i_ref-1, i_ref+1:end]);
    sct_stop.iv_angleComp = iv_comp([1:i_ref-1, i_ref+1:end]);
    sct_stop.i_ref        = iv_d(i_ref);
    sct_stop.i_refComp    = iv_comp(i_ref);
    sct_stop.r_limit      = r_angle*pi/180;
    sct_stop.r_angle      = r_angle;
end

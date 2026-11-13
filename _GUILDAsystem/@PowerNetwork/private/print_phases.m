function print_phases(tab_phase)
% Verbose: one line per integration phase with its active events
    arguments (Input)
        tab_phase table  % output.phases.
    end
    sr_evt = string(tab_phase.Properties.VariableNames(3:end));
    fprintf("Time simulation: %d phase(s)\n", height(tab_phase));
    for k = 1:height(tab_phase)
        sv = sr_evt(tab_phase{k,3:end});
        sv = sv(~contains(sv,"NoAction"));
        if isempty(sv)
            sv = "-";
        end
        fprintf("  phase %2d: t = [%g, %g]  events: %s\n", k, tab_phase{k,"t1"}, tab_phase{k,"t2"}, join(sv, ", "));
    end
end

function print_phases(tab_phase, sr_evt)
% Verbose: one line per integration phase with its active events
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

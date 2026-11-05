function set_gc_connect(net, sv_trip)
% Global controllers named in sv_trip are tripped (l_isConnect = false),
% the others connected. Components are set by initial_condition.
    arguments (Input)
        net      % Network of the run.
        sv_trip  % Tags of the tripped units.
    end
    a_GCs = net.a_GlobalController;
    for k = 1:numel(a_GCs)
        a_GCs{k}.l_isConnect = ~ismember(a_GCs{k}.s_tag, sv_trip);
    end
end

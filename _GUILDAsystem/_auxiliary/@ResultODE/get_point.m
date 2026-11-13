function rv = get_point(obj, t, tab_map, opt)
% Get the values of the variable map at a time of the simulation.
%
% Returns the values of the variables at time t, in the order of the rows of tab_map
% (by default the whole tab_variable, so rv is a point for net.get_sys(rv)).
% tab_map may be any part of tab_variable, e.g. the rows x, Vre, Vim, u of the variable
% map of a bus or component of the simulated network (bus.get_variable_map(),
% comp.get_variable_map()); its rows are found by Kind, Owner, Name and Bus. The other
% rows of a variable map (the controller inputs uc and the signals y, yc) are not in the
% result and stop with GUILDA:ResultODE:UnknownVariable.
%
% Between two output times the values are interpolated linearly. At a phase boundary,
% where the time appears twice in rv_t, Side chooses the value: "after" (default) the
% start of the later phase, i.e. the state after the event (an offset applied, a fault
% cleared), "before" the end of the earlier phase. At any other output time Side has no
% effect.
%
% <@Examples>
% ```matlab
% sc = net.add_scenario("fault");  sc.add_fault("B008", [1,1.05]);
% sim = net.simulate("fault", Time=[0,5]);
% x  = sim.get_point(2);                    % rows x, Vre, Vim, u of net.get_variable_map()
% x0 = sim.get_point(1.05, Side="before");  % end of the fault
% res = net.get_sys({sim, 2});            % same point as net.get_sys(x)
% ```
%
% See also PowerNetwork.get_variable_map, SolverLIN
    arguments (Input)
        obj
        t        (1,1) double {mustBeReal} % [s] Time within [rv_t(1), rv_t(end)].
        tab_map  table = obj.tab_variable % Rows to return (a variable map or a part of it).
        opt.Side (1,1) string {mustBeMember(opt.Side, ["after","before"])} = "after" % Value at a phase boundary: after or before the event.
    end
    arguments (Output)
        rv % Values in the order of the rows of tab_map (column).
    end
    iv_col = obj.columns_of(tab_map);

    tv = obj.rv_t;
    if isempty(tv) || ~(t >= tv(1) && t <= tv(end))
        if isempty(tv)
            tv = NaN;
        end
        error(msg("GUILDA:ResultODE:PointTime", sprintf("%g", t), sprintf("%g", tv(1)), sprintf("%g", tv(end))))
    end
    k = find(tv == t);
    if ~isempty(k)
        if opt.Side == "after"
            k = k(end);
        else
            k = k(1);
        end
        rv = obj.rm_variable(k, iv_col).';
        return
    end
    k = find(tv < t, 1, "last");
    w = (t - tv(k)) / (tv(k+1) - tv(k));
    rv = ((1-w) * obj.rm_variable(k, iv_col) + w * obj.rm_variable(k+1, iv_col)).';
end

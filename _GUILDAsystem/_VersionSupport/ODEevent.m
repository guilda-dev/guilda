function sc = ODEevent(tag, net, opt)
% Make a one-disturbance Scenario attached to net (the v3 event of net.simulate).
%
% v3 entry point of the simulation events (deprecated: warns GUILDA:Deprecated:ODEevent once
% per session). `ODEevent(tag, net, Name=Value)` takes the v3 Name-Value options (TimeSpan,
% FaultBus, TripUnit, OpenBranch, OffsetUnit, OffsetState, OffsetValue, InputUnit,
% InputName, InputValue) and returns a Scenario with the tag `tag` and one disturbance with
% the same tag, already added to `net` (net.a_Scenario). It runs as before:
% net.simulate(time, ev1, ev2, ...).
%
% Differences from v3:
%
% - The result is a Scenario: the v3 properties (ev.TimeSpan, ev.FaultBus, ...) are the
%   columns of ev.tab_disturbance and are not settable.
% - The checks of the tags, states and inputs run when the event is made, not when it is
%   simulated, and their messages are GUILDA:Scenario:*.
% - An earlier scenario made by ODEevent with the same tag in the same network is removed
%   from it (so that a loop does not pile up scenarios): it cannot be simulated with net any
%   more. A scenario added with net.add_scenario and the same tag is an error
%   (GUILDA:PowerNetwork:ScenarioTagInUse).
%
% <@Deprecated>
% Use sc = Scenario(tag); sc.add_disturbance(tag, Name=Value) (or add_fault, add_trip,
% add_open_branch, add_offset, add_input); net.add_scenario(sc).
%
% See also Scenario, PowerNetwork.add_scenario, PowerNetwork.simulate
    arguments (Input)
        tag (1,1) string % Tag of the event: of the scenario and of its disturbance.
        net {mustBeA(net, 'PowerNetwork')} % Network the event belongs to.
        opt.TimeSpan     % [s] [t_start, t_end], or t_start alone for an offset.
        opt.OffsetUnit   % Tag of the component whose initial states are offset.
        opt.OffsetState  % Names of the states to offset.
        opt.OffsetValue  % Offsets of OffsetState.
        opt.FaultBus     % Tags of the faulted buses.
        opt.TripUnit     % Tags of the tripped components or global controllers.
        opt.OpenBranch   % Tags of the opened branches.
        opt.InputUnit    % Tag of the component to which an input is added.
        opt.InputName    % Names of the inputs of InputUnit.
        opt.InputValue   % Values added to the inputs.
    end
    arguments (Output)
        sc % Scenario with one disturbance, added to net.
    end
    Deprecated("ODEevent");
    str_scenario = tag;
    if strlength(str_scenario) == 0
        str_scenario = "event";         % the disturbance tag "" stops below (ReservedTag)
    end
    sc = Scenario(str_scenario);
    sc.l_compat = true;
    c_opt = namedargs2cell(opt);

    lv_same = cellfun(@(s) s.str_tag == str_scenario, net.a_Scenario);
    if any(lv_same) && net.a_Scenario{lv_same}.l_compat
        net.remove_scenario(str_scenario);
    end
    % Added first, so that the disturbance is checked against net in the order of v3
    net.add_scenario(sc);
    try
        sc.add_disturbance(tag, c_opt{:});
    catch ME
        net.remove_scenario(str_scenario);
        rethrow(ME)
    end
end

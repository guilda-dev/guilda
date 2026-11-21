function sc = add_scenario(obj, s_tag, opt)
% Create a simulation scenario of the network and return it.
%
% The new scenario is a child of the network (net.a_Scenario, sc.a_PowerNetwork). Its tag
% (default "CASE") shares the name space of the buses, branches and global controllers: a
% tag in use gets a number suffix (case1 -> case1002, as for the other layers) and the new
% tag is shown as INFO; read it from sc.s_tag. Add the disturbances with the methods of the scenario.
%
% From=sc0 copies the events (with their tags), Time and Description of the scenario sc0
% (of this or another network); sc0 does not change. Event={ev1, ev2, ...} copies events
% made with their constructors (EventFault, EventTrip, EventOpenBranch, EventOffset,
% EventInput) after those of From; faults, trips and openings get new tags, offsets and
% inputs keep theirs. The events passed do not change. All events are checked against this
% network: when a check fails, no scenario is created. To move a scenario, copy it and
% remove the original: `net2.add_scenario(tag, From=sc); net1.remove_scenario(tag)`.
%
% Scenarios are not model data: the equilibrium does not become stale and nothing is
% logged as an edit.
%
% <@Examples>
% ```matlab
% sc = net.add_scenario("case1", Time=[0, 20]);
% sc.add_fault("B008", [0.10, 0.17]);
% sc.add_open_branch("EL003", 0.17);
% result = net.simulate("case1");
% other.add_scenario("case1", From=sc);     % a copy in another network
% sc3 = net.add_scenario(Time=[0, 5]);      % tag "CASE" (with a number when in use)
% sc2 = net.add_scenario("case2", Event={EventFault("B008", [0.1, 0.17]), EventOpenBranch("EL003", 0.17)});
% ```
%
% See also PowerNetwork.remove_scenario, PowerNetwork.simulate, Scenario
%
% <@Group> Model building
    arguments (Input)
        obj
        s_tag (1,1) string {mustBeNonzeroLengthText} = "CASE"  % Tag of the new scenario; a number is added when a child of the network has it.
        opt.Time (1,2) double {mustBeSimulationTime}  % [s] Simulation time [t0, tend]. Default: From.Time, else [0, 10].
        opt.Description (1,1) string                  % Free text. Default: From.Description, else "".
        opt.From Scenario {mustBeScalarOrEmpty} = Scenario.empty  % Scenario to copy the events, Time and Description from (of this or another network).
        opt.Event (1,:) cell = {}                     % Events to copy into the new scenario (EventFault, EventTrip, EventOpenBranch, EventOffset, EventInput), added after those of From.
    end
    arguments (Output)
        sc Scenario  % The new scenario, a child of the network.
    end
    for k = 1:numel(opt.Event)
        if ~(isa(opt.Event{k}, "EventBase") && isscalar(opt.Event{k}))
            error(msg("GUILDA:PowerNetwork:NotAnEvent", string(k), class(opt.Event{k})));
        end
    end
    sc = Scenario(obj, s_tag);
    obj.a_Scenario = [obj.a_Scenario; {sc}];
    try
        if ~isempty(opt.From)
            sc.Time        = opt.From.Time;
            sc.Description = opt.From.Description;
            for k = 1:numel(opt.From.a_Event)
                sc.insert_event(copy(opt.From.a_Event{k}), true);
            end
        end
        for k = 1:numel(opt.Event)
            sc.insert_event(copy(opt.Event{k}), false);
        end
        for s_name = intersect(["Time", "Description"], string(fieldnames(opt)).')
            sc.(s_name) = opt.(s_name);
        end
    catch ME
        obj.remove_scenario(sc.s_tag);
        rethrow(ME)
    end
end

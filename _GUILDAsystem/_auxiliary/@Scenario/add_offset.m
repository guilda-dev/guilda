function ev = add_offset(obj, unit, state, value, time, opt)
% Add an offset of the states of a component at one time.
%
% The values are added to the states at time (to the initial states when time is the
% start of the simulation). The offset is an EventOffset, returned: change it with ev.edit
% and remove it with remove_event(ev.s_tag). It gives one row in tab_offset.
%
% <@Examples>
% ```matlab
% sc.add_offset("B001SG1", ["delta"; "omega"], [0.1; 0], 0);
% ```
    arguments (Input)
        obj
        unit  (1,1) string         % Tag of the component.
        state (:,1) string         % Names of the states (e.g. "delta").
        value (:,1) double         % Offsets, one per state or one for all.
        time  (1,1) double = 0     % [s] Time of the offset.
        opt.Tag (1,1) string = ""  % Tag of the offset; "" for offset<n> (not Fault or Parallel followed by digits).
    end
    arguments (Output)
        ev EventOffset  % The added event (a handle: edit it with ev.edit).
    end
    ev = EventOffset(unit, state, value, time, Tag=opt.Tag);
    obj.insert_event(ev, false);
end

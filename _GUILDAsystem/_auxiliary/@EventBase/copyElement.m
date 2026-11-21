function cp = copyElement(obj)
% Copy of the event (copy(ev)): the same values and tag, not in a scenario (a_Scenario []).
    arguments (Input)
        obj
    end
    arguments (Output)
        cp  % The copy.
    end
    cp = copyElement@matlab.mixin.Copyable(obj);
    cp.a_Scenario = [];
end

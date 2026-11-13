function [tab_event, tab_offset, tab_input] = empty_disturbances()
% The three disturbance tables without rows
    arguments (Output)
        tab_event  table   % Tag, Target, Time, Status, Point.
        tab_offset table   % Tag, TimeSpan, OffsetUnit, OffsetState, OffsetValue.
        tab_input  table   % Tag, TimeSpan, InputUnit, InputName, InputValue, InputMethod.
    end
    tab_event  = table(strings(0,1), strings(0,1), zeros(0,1), strings(0,1), zeros(0,1), ...
                       'VariableNames', ["Tag","Target","Time","Status","Point"]);
    tab_offset = table(strings(0,1), zeros(0,1), strings(0,1), cell(0,1), cell(0,1), ...
                       'VariableNames', ["Tag","TimeSpan","OffsetUnit","OffsetState","OffsetValue"]);
    tab_input  = table(strings(0,1), zeros(0,2), strings(0,1), cell(0,1), cell(0,1), strings(0,1), ...
                       'VariableNames', ["Tag","TimeSpan","InputUnit","InputName","InputValue","InputMethod"]);
end

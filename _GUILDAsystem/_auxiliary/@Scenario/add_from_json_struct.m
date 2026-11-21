function add_from_json_struct(obj, sct)
% Set Time and Description and add the events read from scenario/<tag>.json.
%
% sct is the decoded file after the checks of PowerNetwork.import (Format, version 2, known
% fields; Event as a cell of structs Tag, Target, Time, Status, Point; Offset and Input as
% cells of structs, a tag at most once in each). The events keep their tags:
%
% - Event: the rows of one tag are one event. Each target of a fault has two rows, the
%   start and the end ("none"), and each target of a parallel event one row; all targets
%   have the same times, start Status and (a fault) Point; otherwise
%   GUILDA:Scenario:InvalidEventRows. Fault<n> is an EventFault; Parallel<n> is an
%   EventTrip when its Status is "open", else an EventOpenBranch (the Point of a parallel
%   event is not read).
% - Offset, Input: each row is an EventOffset or EventInput. A missing field is passed as
%   an empty value.
%
% Each event is checked as when added by hand; a failing one stops with the error of the
% check.
    arguments (Input)
        obj
        sct (1,1) struct  % Decoded content of the file (see to_json_struct).
    end
    if isfield(sct, "Time")
        obj.Time = reshape(double(sct.Time), 1, []);
    end
    if isfield(sct, "Description")
        obj.Description = string(sct.Description);
    end
    if isfield(sct, "Event") && ~isempty(sct.Event)
        tab = struct2table(vertcat(sct.Event{:}), "AsArray", true);
        for s_tag = reshape(unique(tab.Tag, "stable"), 1, [])
            tab_t = tab(tab.Tag == s_tag, :);
            sv_target = unique(tab_t.Target, "stable");
            l_fault = startsWith(s_tag, "Fault");
            rm_time = NaN(numel(sv_target), 1 + l_fault);
            for i = 1:numel(sv_target)
                iv = find(tab_t.Target == sv_target(i));
                if numel(iv) ~= 1 + l_fault || tab_t.Status(iv(1)) ~= tab_t.Status(1) ...
                        || (l_fault && (tab_t.Status(iv(end)) ~= "none" || ~isequaln(tab_t.Point(iv), tab_t.Point([1; 1]))))
                    error(msg("GUILDA:Scenario:InvalidEventRows", char(s_tag), char(obj.s_tag), char(sv_target(i)), ...
                              "the rows are not those of one event with the Status and Point of the other targets"));
                end
                rm_time(i, :) = tab_t.Time(iv).';
            end
            if any(rm_time ~= rm_time(1, :), "all")
                error(msg("GUILDA:Scenario:InvalidEventRows", char(s_tag), char(obj.s_tag), char(join(sv_target, ", ")), ...
                          "the targets have different times"));
            end
            if l_fault
                ev = EventFault(sv_target, rm_time(1, :), Status=tab_t.Status(1), Point=tab_t.Point(1));
            elseif tab_t.Status(1) == "open"
                ev = EventTrip(sv_target, rm_time(1));
            else
                ev = EventOpenBranch(sv_target, rm_time(1), Status=tab_t.Status(1));
            end
            ev.s_tag = s_tag;
            obj.insert_event(ev, true);
        end
    end
    for s_part = ["Offset", "Input"]
        if ~isfield(sct, s_part)
            continue
        end
        for e = reshape(sct.(s_part), 1, [])
            d = struct("TimeSpan", zeros(1,0), "OffsetUnit", "", "OffsetState", strings(0,1), "OffsetValue", zeros(0,1), ...
                       "InputUnit", "", "InputName", strings(0,1), "InputValue", zeros(0,1));
            for s_name = setdiff(string(fieldnames(e{1})).', ["Tag", "InputMethod"], "stable")
                d.(s_name) = e{1}.(s_name);
            end
            if isstruct(d.InputValue)
                rv_t = reshape(double(d.InputValue.Time), [], 1);
                rm_v = double(d.InputValue.Value);
                if size(rm_v, 1) ~= numel(rv_t) && isvector(rm_v)
                    rm_v = reshape(rm_v, numel(rv_t), []);   % one point: jsondecode gives a column
                end
                d.InputValue = [rv_t, rm_v];
            end
            ts = reshape(double(d.TimeSpan), 1, []);
            if s_part == "Offset"
                ev = EventOffset(string(d.OffsetUnit), reshape(string(d.OffsetState), [], 1), ...
                                 reshape(double(d.OffsetValue), [], 1), ts, Tag=string(e{1}.Tag));
            else
                c_opt = {};
                if isfield(e{1}, "InputMethod")
                    c_opt = {"Method", string(e{1}.InputMethod)};
                end
                ev = EventInput(string(d.InputUnit), reshape(string(d.InputName), [], 1), ...
                                reshape(double(d.InputValue), size(d.InputValue, 1), []), ts, c_opt{:}, Tag=string(e{1}.Tag));
            end
            obj.insert_event(ev, true);
        end
    end
end

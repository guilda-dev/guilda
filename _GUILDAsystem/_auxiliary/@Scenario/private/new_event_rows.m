function tab = new_event_rows(tab_event, s_kind, target, time, sr_status, point)
% Rows of one new event: the start and the end of each target, with the next tag of s_kind.
%
% The tag is s_kind and the largest number of the tags of s_kind in tab_event plus one
% (%03d: Fault001, Parallel012; numbers of removed tags are not used again).
    arguments (Input)
        tab_event table             % tab_event of the scenario.
        s_kind (1,1) string         % "Fault" or "Parallel".
        target (:,1) string         % Tags of the targets (repeated ones once).
        time   (1,2) double         % [s] [t_start, t_end].
        sr_status (1,2) string      % Status of the start and of the end.
        point  (1,1) double         % Point of both rows (NaN when unused).
    end
    arguments (Output)
        tab table                   % Rows with the columns of tab_event, two per target.
    end
    sv_num = extractAfter(tab_event.Tag(startsWith(tab_event.Tag, s_kind)), strlength(s_kind));
    rv_num = str2double(sv_num(matches(sv_num, digitsPattern)));
    s_tag  = s_kind + string(sprintf("%03d", max([0; rv_num(:)]) + 1));
    target = unique(target, "stable");
    n = numel(target);
    tab = table(repmat(s_tag, 2*n, 1), repelem(target, 2, 1), repmat(time(:), n, 1), ...
                repmat(sr_status(:), n, 1), repmat(point, 2*n, 1), ...
                'VariableNames', ["Tag","Target","Time","Status","Point"]);
end

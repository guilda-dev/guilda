function iv = bus_index(a_end, sv_bus)
% Row of each bus of a_end in sv_bus. In the snapshot a bus is the path where it was
% stored first ("net.a_Bus{3}"), or a struct when it was first reached here.
    arguments (Input)
        a_end  cell                % Buses of a branch or component in the snapshot.
        sv_bus (:,1) string        % Bus tags in tab_bus order.
    end
    arguments (Output)
        iv (:,1) double            % Row of each bus in sv_bus.
    end
    iv = zeros(numel(a_end),1);
    for k = 1:numel(a_end)
        x = a_end{k};
        if isstruct(x)
            iv(k) = find(sv_bus == string(x.s_tag), 1);
        else
            iv(k) = str2double(regexp(string(x), "a_Bus\{(\d+)\}$", "tokens", "once"));
        end
    end
end

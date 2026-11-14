function lim = limit_set(net, sv_limits, w, sv_load)
% Operating limits that Limits applies along the CPF path, one row per finite limit.
%
% - "Q": a PV bus (not the slack bus) with the sums of Qmin and Qmax over its generators
%   (w.c_lvFree), Class "Bus". The monitored value is the Q of these generators: the Q
%   injected into the network minus the Q of the other components of the bus.
% - "V": Vmin and Vmax of each bus, Class "Bus", on |V|.
% - "S": Smax of each branch, Class "Branch", on the larger |S| of its two ends.
% Inf and NaN limits are none.
    arguments (Input)
        net                        % Network of the CPF.
        sv_limits (1,:) string     % Kinds of limits: members of "Q", "V", "S".
        w         (1,1) struct     % Variable layout (output of build_layout).
        sv_load                    % Tags of the buses whose loads are scaled.
    end
    arguments (Output)
        lim       (1,1) struct     % sv_kind, iv_object, sv_class, sv_object, sv_limit, rv_bound,
                                   % rv_sign (1 upper, -1 lower); rv_Qother, rv_load (buses);
                                   % c_Ybranch, im_end (branches).
    end
    a_Bus  = net.a_Bus;
    n_bus  = numel(a_Bus);
    sv_bus = string(a_Bus(:));
    c_row  = cell(0, 6);       % {kind, object index, class, object, limit, bound}

    rv_Qother = zeros(n_bus, 1);
    for i = 1:n_bus
        bus    = a_Bus{i};
        a_Comp = bus.a_Component;
        for j = find(~w.c_lvFree{i}(:)).'
            rv_Qother(i) = rv_Qother(i) + imag(a_Comp{j}.c_Vequilibrium * conj(a_Comp{j}.c_Iequilibrium));
        end
        if ismember("Q", sv_limits) && bus.get_pf_condition().Type == "PV"
            a_gen = a_Comp(w.c_lvFree{i});
            r_min = sum(cellfun(@(c) group(c, "operation").Qmin, a_gen));
            r_max = sum(cellfun(@(c) group(c, "operation").Qmax, a_gen));
            c_row = add(c_row, "Q", i, "Bus", sv_bus(i), "Qmin", r_min);
            c_row = add(c_row, "Q", i, "Bus", sv_bus(i), "Qmax", r_max);
        end
        if ismember("V", sv_limits)
            ope = group(bus, "operation");
            c_row = add(c_row, "V", i, "Bus", sv_bus(i), "Vmin", ope.Vmin);
            c_row = add(c_row, "V", i, "Bus", sv_bus(i), "Vmax", ope.Vmax);
        end
    end

    a_Branch = net.a_Branch;
    n_br     = numel(a_Branch);
    lim.c_Ybranch = cell(n_br, 1);
    lim.im_end    = zeros(n_br, 2);
    if ismember("S", sv_limits)
        for k = 1:n_br
            br = a_Branch{k};
            [~, iv_end] = ismember(string(br.a_Bus), sv_bus);
            lim.im_end(k,:)  = iv_end(:).';
            lim.c_Ybranch{k} = br.get_admittance_matrix();
            c_row = add(c_row, "S", k, "Branch", string(br), "Smax", group(br, "operation").Smax);
        end
    end

    lim.sv_kind   = string(c_row(:,1));
    lim.iv_object = reshape(cell2mat(c_row(:,2)), [], 1);
    lim.sv_class  = string(c_row(:,3));
    lim.sv_object = string(c_row(:,4));
    lim.sv_limit  = string(c_row(:,5));
    lim.rv_bound  = reshape(cell2mat(c_row(:,6)), [], 1);
    lim.rv_sign   = 1 - 2 * endsWith(lim.sv_limit, "min");
    lim.rv_Qother = rv_Qother;
    lim.rv_load   = double(ismember(sv_bus, sv_load));
end


function c_row = add(c_row, s_kind, i_obj, s_class, s_obj, s_limit, r_bound)
% Adds a row for a finite limit (Inf and NaN: none)
    if isfinite(r_bound)
        c_row(end+1,:) = {s_kind, i_obj, s_class, s_obj, s_limit, r_bound};
    end
end


function tab = group(obj, s_group)
    tab = obj.a_Parameter{cellfun(@(p) p.s_tag==s_group, obj.a_Parameter)}.tab_parameter;
end

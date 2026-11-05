function resolve_observe(obj)
% Expand the reserved inputs "Xall" / "Yall" and find where each input is read on
% the observed component (iv_obsY / iv_obsX), for this controller and the
% controllers nested in it. An input name found in both sv_y and sv_x is read
% from sv_y. Without a component, the inputs stay as defined.
%
% <@Group> Construction and attachment
    arguments (Input)
        obj
    end
    if isempty(obj.sv_uRequest)
        obj.sv_uRequest = obj.sv_u;
    end
    if any(ismember(obj.sv_uRequest, ["X","Y"]))
        error(msg("GUILDA:LocalController:ReservedInputNames", class(obj)))
    end
    comp = obj.observed_component();
    if isempty(comp)
        sv_req = obj.sv_uRequest;
        if any(ismember(sv_req, obj.sr_reserved))
            obj.set_inputs(sv_req);
        end
        obj.iv_obsY = zeros(numel(obj.sv_u),1);
        obj.iv_obsX = zeros(numel(obj.sv_u),1);
    else
        obj.resolve_ports(comp);
        sv_name = strings(0,1);  sv_src = strings(0,1);
        for k = 1:numel(obj.sv_uRequest)
            switch obj.sv_uRequest(k)
                case "Xall"
                    sv_add = comp.sv_x;  s_src = "X";
                case "Yall"
                    sv_add = comp.sv_y;  s_src = "Y";
                otherwise
                    sv_add = obj.sv_uRequest(k);  s_src = "";
            end
            sv_name = [sv_name; sv_add(:)];                              %#ok<AGROW>
            sv_src  = [sv_src; repmat(s_src, numel(sv_add), 1)];       %#ok<AGROW>
        end
        if ~isequal(sv_name, obj.sv_u)
            obj.set_inputs(sv_name);
        end
        [~, iv_y] = ismember(sv_name, comp.sv_y);
        [~, iv_x] = ismember(sv_name, comp.sv_x);
        iv_y(sv_src == "X") = 0;
        iv_x(sv_src == "Y" | iv_y > 0) = 0;
        obj.iv_obsY = iv_y;
        obj.iv_obsX = iv_x;
    end
    cellfun(@(c) c.resolve_observe(), obj.a_LocalController);
end

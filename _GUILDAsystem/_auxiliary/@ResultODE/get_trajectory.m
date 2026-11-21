function tab = get_trajectory(obj, Quantity, opt)
% Get a trajectory of the buses or components as a table.
%
% Returns the values of one quantity against time, one column per owner: for the buses,
% the voltage magnitude (Vabs), the voltage angle (Vangle) or the power P / Q injected by
% the components; for the components, a state, an input or an output given by its name
% (e.g. omega, delta, Vfield), with one column per component of the selected buses that
% has it. plot_trajectory draws the same columns.
%
% The result is a table (not a timetable: at a phase boundary the time appears twice, see
% ResultODE) with the column t [s] first, then one column per owner named by its tag (the
% bus tag, or the full component tag), in the order of Bus and of the components of each
% bus. tab.Properties.Description names the quantity and VariableUnits holds the units.
%
% - Bus: the buses (for a component quantity, the buses of the components); "all" for
%   every bus.
% - Owner: the owners to keep, bus tags for a bus quantity or component tags for a
%   component quantity; "all" for every owner of the selected buses.
% - Reference="COI": the values relative to the center of inertia (the mean weighted by
%   the dynamics parameter M of the network snapshot), and a last column COI with the
%   center itself (tab.B001 + tab.COI is the value of B001). The states and inputs of a
%   tripped unit are NaN while it is tripped: at those times the unit is left out of the
%   center (the weights of the other units are renormalized) and its own column stays
%   NaN. COI is NaN at a time when every unit is NaN. For delta and Vangle the center is that of the rotor angles delta of
%   all the components with delta, as in judge_out_of_step(Reference="COI"), and Vangle
%   relative to it is wrapped to (-pi, pi]. For another component quantity it is the center
%   of that quantity over all the components that have it (each needs M). Vabs, P and Q
%   have no center. "none" (default) returns the values as simulated.
%
% <@Examples>
% ```matlab
% res = net.simulate("fault");
% tab = res.get_trajectory("omega");                    % t, B001SG1, B002SG1, ...
% plot(tab.t, tab{:, 2:end});
% tab = res.get_trajectory("delta", Reference="COI");   % angles from the center of inertia, and COI
% tab = res.get_trajectory("Vabs", Bus=["B004", "B005"]);
% tab = res.get_trajectory("Vfield", Owner="B001SG1");
% ```
%
% See also ResultODE.plot_trajectory, ResultODE.judge_out_of_step, ResultODE.get_point
    arguments (Input)
        obj
        Quantity (1,1) string = "Vabs"     % "Vabs", "Vangle", "P", "Q", or a state, input or output name of the components.
        opt.Bus       {mustBeText} = "all"  % Tags of the buses (for a component quantity: the buses of the components); "all" for every bus.
        opt.Owner     {mustBeText} = "all"  % Tags of the owners to keep (buses or components); "all" for every owner.
        opt.Reference (1,1) string {mustBeMember(opt.Reference, ["none","COI"])} = "none"  % "none": the values; "COI": relative to the center of inertia, with a column COI.
    end
    arguments (Output)
        tab table  % Column t [s], then one column per owner named by its tag (and COI with Reference="COI").
    end
    sv_bus = unique(string(opt.Bus(:)), "stable");
    if isequal(sv_bus, "all")
        sv_bus = obj.sv_bus;
    end
    [lv_found, iv_bus] = ismember(sv_bus, obj.sv_bus);
    if ~all(lv_found)
        error(msg("GUILDA:ResultODE:UnknownBus", char(join(sv_bus(~lv_found), ", "))));
    end

    s_q = Quantity;
    l_bus = ismember(s_q, ["Vabs","Vangle","P","Q"]);
    if l_bus
        tab_var = obj.tab_variable;
        rm_value = zeros(numel(obj.rv_t), numel(iv_bus));
        for k = 1:numel(iv_bus)
            i = iv_bus(k);
            cv_V = obj.rm_variable(:, tab_var.Kind == "Vre" & tab_var.Bus == obj.sv_bus(i)) ...
                 + 1j*obj.rm_variable(:, tab_var.Kind == "Vim" & tab_var.Bus == obj.sv_bus(i));
            cv_I = obj.rm_I(:, 2*i-1) + 1j*obj.rm_I(:, 2*i);      % injected current, P + jQ = V conj(I)
            switch s_q
                case "Vabs";    rm_value(:,k) = abs(cv_V);
                case "Vangle";  rm_value(:,k) = angle(cv_V);
                case "P";       rm_value(:,k) = real(cv_V).*real(cv_I) + imag(cv_V).*imag(cv_I);
                case "Q";       rm_value(:,k) = imag(cv_V).*real(cv_I) - real(cv_V).*imag(cv_I);
            end
        end
        sv_tag = obj.sv_bus(iv_bus);
        sv_unitBus = dictionary(["Vabs","Vangle","P","Q"], ["pu","rad","pu","pu"]);
        s_unit = sv_unitBus(s_q);
    else
        sv_comp = vertcat(strings(0,1), obj.c_component{iv_bus});
        [rm_value, sv_tag] = component_values(obj, s_q, sv_comp);
        s_unit = "";
    end
    if isempty(sv_tag)
        error(msg("GUILDA:ResultODE:UnknownQuantity", char(s_q)));
    end

    sv_owner = unique(string(opt.Owner(:)), "stable");
    if ~isequal(sv_owner, "all")
        lv_known = ismember(sv_owner, sv_tag);
        if ~all(lv_known)
            error(msg("GUILDA:ResultODE:UnknownOwner", char(join(sv_owner(~lv_known), ", ")), char(s_q), char(join(sv_tag, ", "))));
        end
        lv_keep  = ismember(sv_tag, sv_owner);
        rm_value = rm_value(:, lv_keep);
        sv_tag   = sv_tag(lv_keep);
    end

    s_description = s_q;
    if opt.Reference == "COI"
        if l_bus && s_q ~= "Vangle"
            error(msg("GUILDA:ResultODE:NoCenterOfInertia", char(s_q)));
        end
        if ismember(s_q, ["delta","Vangle"])
            s_center = "delta";
        else
            s_center = s_q;
        end
        sv_all = vertcat(strings(0,1), obj.c_component{:});
        [rm_all, sv_unit] = component_values(obj, s_center, sv_all);
        if isempty(sv_unit)
            error(msg("GUILDA:ResultODE:NoCenterOfInertia", char(s_q)));
        end
        rv_center = center_of_inertia(obj, rm_all, sv_unit, "GUILDA:ResultODE:TrajectoryNoInertia");
        rm_value = rm_value - rv_center;
        if s_q == "Vangle"
            rm_value = angle(exp(1j*rm_value));
        end
        rm_value = [rm_value, rv_center];
        sv_tag   = [sv_tag; "COI"];
        s_description = s_q + " relative to the center of inertia (COI: the center)";
    end

    tab = array2table([obj.rv_t, rm_value], "VariableNames", ["t"; sv_tag]);
    tab.Properties.Description   = s_description;
    tab.Properties.VariableUnits = ["s", repmat(s_unit, 1, numel(sv_tag))];
end


function [rm_value, sv_tag] = component_values(obj, s_q, sv_comp)
% The state, input or output s_q of the components sv_comp that have it (the first of x,
% u, y of the component's own rows; not of its controllers)
    tab = obj.tab_variable;
    tab_y = obj.tab_output;
    n_t = numel(obj.rv_t);
    rm_value = zeros(n_t, 0);
    sv_tag = strings(0,1);
    for k = 1:numel(sv_comp)
        i_col = find(ismember(tab.Kind, ["x","u"]) & tab.Owner == sv_comp(k) & tab.Name == s_q, 1);
        if ~isempty(i_col)
            rm_value(:, end+1) = obj.rm_variable(:, i_col);   %#ok<AGROW>
        else
            i_col = find(tab_y.Kind == "y" & tab_y.Owner == sv_comp(k) & tab_y.Name == s_q, 1);
            if isempty(i_col)
                continue
            end
            rm_value(:, end+1) = obj.rm_output(:, i_col);     %#ok<AGROW>
        end
        sv_tag(end+1, 1) = sv_comp(k);                        %#ok<AGROW>
    end
end

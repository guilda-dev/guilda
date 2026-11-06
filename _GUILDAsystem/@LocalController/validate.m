function flag = validate(obj, l_message)
% Check the model functions of the controller against the contract of LocalController.
%
% The controller must be attached to a component on a network, and the network must be
% initialized: the check is made at the equilibrium. A broken model does not stop the
% check: it is reported as FAIL in flag.contract and the values that cannot be computed
% are NaN. flag.inputs shows where each input is read, so a misspelled input name
% appears as "equilibrium (not connected)".
%
% <@Group> Queries and checks
    arguments (Input)
        obj
        l_message (1,1) logical = true   % Print the comparison.
    end
    arguments (Output)
        flag   % Struct of tables: dx (residual at the equilibrium), Axx, Bxu, ... (absolute differences of each Jacobian block), contract (PASS or FAIL of each check), inputs (connection source of each input).
    end

    comp = obj.observed_component();
    if isempty(comp) || isempty(comp.a_Bus) || isempty(comp.a_Bus.a_PowerNetwork)
        error(msg("GUILDA:LocalController:ValidateNotAttached", obj.s_tag))
    end
    net = comp.a_Bus.a_PowerNetwork;
    sv  = [net.sct_stale.powerflow; net.sct_stale.odefcn; obj.sct_stale.equilibrium; obj.sct_stale.odefcn];
    if ~isempty(sv)
        sv = unique(sv, "stable");
        s_reason = join(sv(1:min(end,3)), "; ");
        if numel(sv) > 3
            s_reason = s_reason + "; ...";
        end
        error(msg("GUILDA:LocalController:Stale", char(obj.s_tag), char(s_reason), "validate"))
    end

    % make variable (names read from a component may repeat, e.g. "Xall" with "Yall")
    sv_x  = unique_names(obj.sv_x);
    sv_u  = unique_names(obj.sv_u);
    sv_y  = unique_names(obj.sv_y);
    sv_v  = ["Vre"; "Vim"];
    nx = numel(sv_x);
    nu = numel(sv_u);
    ny = numel(sv_y);

    rv_x = obj.rv_Xequilibrium;
    rv_u = obj.rv_Uequilibrium;
    rv_V = [real(obj.c_Vequilibrium); imag(obj.c_Vequilibrium)];
    rv_I = [real(obj.c_Iequilibrium); imag(obj.c_Iequilibrium)];

    time  = 0;
    delta = 1e-5;
    contract = strings(0,3);

    % A wrong size is reported once here; the other checks run at a point of the right size
    l_size = numel(rv_x) == nx && numel(rv_u) == nu;
    contract = add_row(contract, "x, u sizes", l_size, ...
        sprintf("x %d (sv_x %d), u %d (sv_u %d)", numel(rv_x), nx, numel(rv_u), nu));
    rv_x = fit_size(rv_x, nx);
    rv_u = fit_size(rv_u, nu);

    fcn_dx = @(x,v,u) obj.f_dx(time, x, v, rv_I, u);
    fcn_Y  = @(x,v,u) obj.f_Y( time, x, v, rv_I, u);

    % validate dx=0 at the equilibrium point
    [dx_test, s_id] = eval_value(@() fcn_dx(rv_x,rv_V,rv_u));
    [l_ok, s_detail] = check_size(dx_test, s_id, nx);
    contract = add_row(contract, "fcn_dx size", l_ok, s_detail);
    if l_ok
        dx_test = reshape(dx_test, nx, 1);
    else
        dx_test = nan(nx,1);
    end

    [y_test, s_id] = eval_value(@() fcn_Y(rv_x,rv_V,rv_u));
    [l_ok, s_detail] = check_size(y_test, s_id, ny);
    contract = add_row(contract, "fcn_y size", l_ok, s_detail);

    % simulate reads the mass matrix without a point (tools.read_mass)
    [M_test, s_id] = eval_value(@() obj.f_Mass([],[],[],[],[]));
    l_ok = s_id == "" && (isequal(size(M_test),[nx,nx]) || (nx == 0 && isempty(M_test)));
    contract = add_row(contract, "fcn_Mass constant and square", l_ok, ...
        join_detail(s_id, "size " + join(string(size(M_test)),"x") + sprintf(" (sv_x %d)",nx)));

    % I is not a port of a controller: get_sys leaves its effect out of the linear model
    [r_dep, s_id] = current_dependence({@(I) obj.f_dx(time,rv_x,rv_V,I,rv_u), @(I) obj.f_Y(time,rv_x,rv_V,I,rv_u)}, rv_I);
    contract = add_row(contract, "no dependence on I", s_id == "" && r_dep < 1e-10, ...
        join_detail(s_id, sprintf("%.3g",r_dep)));

    sv_port = intersect(obj.sv_u, sv_v);
    contract = add_row(contract, "sv_u has no port names", isempty(sv_port), join(sv_port,", "));

    % make flag
    flag = struct("dx", mktab(abs(dx_test), sv_x, "diff"));

    % validate linearized matrix
    [flag, contract] = compare_jacobian(flag, contract, "Jacobi_dx", obj.f_JacobiDx, ...
        @() numeric_jacobian(fcn_dx, rv_x, rv_V, rv_u, nx, delta), {time,rv_x,rv_V,rv_I,rv_u}, ...
        ["Axx","Bxv","","Bxu"], sv_x, {sv_x,sv_v,sv_v,sv_u});
    [flag, contract] = compare_jacobian(flag, contract, "Jacobi_Y", obj.f_JacobiY, ...
        @() numeric_jacobian(fcn_Y, rv_x, rv_V, rv_u, ny, delta), {time,rv_x,rv_V,rv_I,rv_u}, ...
        ["Cyx","Dyv","","Dyu"], sv_y, {sv_x,sv_v,sv_v,sv_u});

    flag.contract = table(contract(:,2), contract(:,3), ...
        RowNames=contract(:,1), VariableNames=["status","detail"]);
    flag.inputs   = table(input_sources(obj, comp), RowNames=sv_u, VariableNames="source");

    % message
    if l_message
        sv_fn = string(fieldnames(flag))';
        disp(repmat('=',1,100))
        for fn = sv_fn
            disp(" ")
            if fn =="dx"
                disp(">> obj.f_dx(0,xst,Vst,ust)"+newline)
            elseif ismember(fn ,["Axx","Bxu","Bxv"])
                disp(">> obj.f_JacobiDx "+fn+" - (Numerical differentiation @obj.f_dx)"+newline)
            elseif ismember(fn ,["Cyx","Dyu","Dyv"])
                disp(">> obj.f_JacobiY "+fn+" - (Numerical differentiation @obj.f_Y)"+newline)
            elseif fn == "contract"
                disp(">> Contract of the model functions"+newline)
            elseif fn == "inputs"
                disp(">> Connection source of each input"+newline)
            end

            if isempty(flag.(fn))
                disp("   No Variables"+newline)
            else
                disp(flag.(fn))
            end
        end
        disp(repmat('=',1,100))
    end

end


function tab = mktab(flag, r, v)
    tab = array2table(flag, "RowNames", r, "VariableNames", v);
end

function sv = unique_names(sv)
    sv = matlab.lang.makeUniqueStrings(reshape(string(sv),[],1));
end

function contract = add_row(contract, s_check, l_ok, s_detail)
    if ismissing(s_detail)   % join of an empty list
        s_detail = "";
    end
    if l_ok
        contract = [contract; s_check, "PASS", s_detail];
    else
        contract = [contract; s_check, "FAIL", s_detail];
    end
end

function v = fit_size(v, n)
    v = reshape(v, [], 1);
    v = [v(1:min(end,n)); zeros(n-numel(v),1)];
end

function [val, s_id] = eval_value(f)
    val = [];
    s_id = "";
    try
        val = f();
    catch ME
        s_id = error_text(ME);
    end
end

function str = error_text(ME)
    % The identifier of the error, or its message when it has none (error(msg(...)) of GUILDA)
    str = string(ME.identifier);
    if str == ""
        str = string(ME.message);
    end
end

function [l_ok, s_detail] = check_size(val, s_id, n)
    l_ok = s_id == "" && numel(val) == n;
    s_detail = join_detail(s_id, "size " + join(string(size(val)),"x") + sprintf(" (expected %d)",n));
end

function str = join_detail(s_id, s_value)
    if s_id == ""
        str = s_value;
    else
        str = s_id;
    end
end

function [r_dep, s_id] = current_dependence(c_f, rv_I)
    % Largest slope of the model functions with respect to I (the error of the first failure)
    r_dep  = 0;
    s_id   = "";
    d = 1e-3;
    for k = 1:numel(c_f)
        for m = 1:2
            e = d * ((1:2)==m).';
            [r, id] = eval_value(@() max(abs(reshape(c_f{k}(rv_I+e) - c_f{k}(rv_I),[],1)))/d);
            if id ~= ""
                s_id = id;
            elseif ~isempty(r)
                r_dep = max(r_dep, r);
            end
        end
    end
end

function c = numeric_jacobian(fcn, rv_x, rv_V, rv_u, nr, delta)
    % Central differences of fcn(x,V,u): {d/dx, d/dV, [], d/du}
    c = {diff_arg(@(x) fcn(x,rv_V,rv_u), rv_x, nr, delta), ...
         diff_arg(@(v) fcn(rv_x,v,rv_u), rv_V, nr, delta), ...
         [], ...
         diff_arg(@(u) fcn(rv_x,rv_V,u), rv_u, nr, delta)};
end

function J = diff_arg(f, v, nr, delta)
    n = numel(v);
    J = zeros(nr,n);
    for i = 1:n
        e = delta/2 * ((1:n)==i).';
        J(:,i) = (f(v+e) - f(v-e)) / delta;
    end
end

function [flag, contract] = compare_jacobian(flag, contract, s_method, f_valid, f_num, point, sv_name, sv_row, c_col)
    % Compare the analytic blocks with the numerical ones; NaN for a block that cannot be
    % compared. An empty name skips the block of I, which is checked as a dependence on I.
    s_detail = "";
    c_num   = {};
    c_valid = cell(1,4);
    try
        c_num = f_num();
        [c_valid{:}] = f_valid(point{:});
    catch ME
        s_detail = error_text(ME);
    end
    for k = find(sv_name ~= "")
        nr = numel(sv_row);
        nc = numel(c_col{k});
        A = nan(nr,nc);
        if s_detail == ""
            V = c_valid{k};
            if isempty(V)              % Models may return [] for an empty or all-zero block (get_sys)
                A = abs(c_num{k});
            elseif numel(V) == nr*nc
                A = abs(c_num{k} - reshape(full(V),nr,nc));
            else
                s_detail = sv_name(k) + " size " + join(string(size(V)),"x") + sprintf(" (expected %dx%d)",nr,nc);
            end
        end
        flag.(sv_name(k)) = mktab(A, sv_row, c_col{k});
    end
    contract = add_row(contract, s_method+" sizes", s_detail == "", s_detail);
end

function sv_src = input_sources(obj, comp)
    % Where each input is read, as in get_dx_algebraic: on the observed component
    % (iv_obsY / iv_obsX), then replaced by the output of a nested controller of the same
    % name; the other inputs stay at the equilibrium.
    nu = numel(obj.sv_u);
    sv_src = repmat("equilibrium (not connected)", nu, 1);
    for k = 1:nu
        if obj.iv_obsY(k) > 0
            sv_src(k) = "output of " + comp.s_tag;
        elseif obj.iv_obsX(k) > 0
            sv_src(k) = "state of " + comp.s_tag;
        end
        for m = 1:numel(obj.a_LocalController)
            if any(obj.a_LocalController{m}.sv_y == obj.sv_u(k))
                sv_src(k) = "output of " + obj.a_LocalController{m}.s_tag;
            end
        end
    end
end

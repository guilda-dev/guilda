function flag = validate(obj, l_message)
% Check the model functions of the component against the contract of Component.
%
% Evaluates the model at the equilibrium, or at a random point of unit V and I when the
% equilibrium is not set. A broken model does not stop the check: it is reported as FAIL
% in flag.contract and the values that cannot be computed are NaN. Analytic Jacobians
% (Jacobi_*) are compared with finite differences of fcn_dx, fcn_I and fcn_Y; a component
% without them uses those same finite differences, so there is nothing to compare.
%
% get_equilibrium is called as the model requires it, so a model that stores values
% there (e.g. the loads) stores those of the evaluation point: run net.initialize after
% validating a component that has no equilibrium.
%
% <@Group> Queries and checks
    arguments
        obj
        l_message (1,1) logical = true   % Print the comparison.
    end
    arguments (Output)
        % Struct of tables: dx and I are the residuals at the point, Axx, Bxv, ... the
        % absolute differences of each Jacobian block, contract the status (PASS, FAIL
        % or INFO) of each check and inputs the connection source of each input.
        flag
    end

    % make variable
    sv_x  = obj.sv_x;
    sv_u  = obj.sv_u;
    sv_y  = obj.sv_y;
    sv_i  = ["Ire"; "Iim"];
    sv_v  = ["Vre"; "Vim"];
    nx = numel(sv_x);
    nu = numel(sv_u);
    ny = numel(sv_y);

    r_omega0 = obj.get_Hz();    % omega0 is the nominal frequency in Hz (models multiply by 2*pi)
    r_t      = 0;
    rr_param = obj.para_dynamics.tab_parameter{:,obj.sv_para};

    com2vec  = @(c) [real(c);imag(c)];
    contract = strings(0,3);

    % evaluation point
    if obj.s_edit.str_flag == "unset" || isempty(obj.c_Iequilibrium)
        rv_V = rand(2,1);
        rv_I = rand(2,1);
        rv_V = rv_V/norm(rv_V);
        rv_I = rv_I/norm(rv_I);
        c_V  = [1,1j]*rv_V;
        c_I  = [1,1j]*rv_I;
        try
            [rv_x,rv_u] = obj.get_equilibrium(c_V,c_I,real(c_V*conj(c_I)),imag(c_V*conj(c_I)));
        catch ME
            contract = add_row(contract, "get_equilibrium(V,I,P,Q)", false, error_text(ME));
            rv_x = nan(nx,1);
            rv_u = nan(nu,1);
        end
    else
        c_V = obj.c_Vequilibrium;
        c_I = obj.c_Iequilibrium;
        rv_V = com2vec(c_V);
        rv_I = com2vec(c_I);
        rv_x = obj.rv_Xequilibrium;
        rv_u = obj.rv_Uequilibrium;
    end

    % A wrong size is reported once here; the other checks run at a point of the right size
    l_size = numel(rv_x) == nx && numel(rv_u) == nu;
    contract = add_row(contract, "x, u sizes", l_size, ...
        sprintf("x %d (sv_x %d), u %d (sv_u %d)", numel(rv_x), nx, numel(rv_u), nu));
    rv_x = fit_size(rv_x, nx);
    rv_u = fit_size(rv_u, nu);

    f_dx = @(I) obj.fcn_dx(r_t,rv_x,rv_V,I,rv_u,rr_param,r_omega0);
    f_I  = @(I) obj.fcn_I( r_t,rv_x,rv_V,I,rv_u,rr_param,r_omega0);
    f_Y  = @(I) obj.fcn_Y( r_t,rv_x,rv_V,I,rv_u,rr_param,r_omega0);

    % validate dx=0 and I=Ist at the equilibrium point
    [dx_test, str_id] = eval_value(@() f_dx(rv_I));
    [l_ok, str_detail] = check_size(dx_test, str_id, nx);
    contract = add_row(contract, "fcn_dx size", l_ok, str_detail);
    if l_ok
        dx_test = reshape(dx_test, nx, 1);
    else
        dx_test = nan(nx,1);
    end

    [c_test, str_id] = eval_value(@() f_I(rv_I));
    [l_ok, str_detail] = check_size(c_test, str_id, 1);
    contract = add_row(contract, "fcn_I complex scalar", l_ok, str_detail);
    if l_ok
        I_test = com2vec(c_test) - rv_I;
    else
        I_test = nan(2,1);
    end

    [y_test, str_id] = eval_value(@() f_Y(rv_I));
    [l_ok, str_detail] = check_size(y_test, str_id, ny);
    contract = add_row(contract, "fcn_Y size", l_ok, str_detail);

    % simulate reads the mass matrix without a point (tools.read_mass)
    [M_test, str_id] = eval_value(@() obj.fcn_Mass([],[],[],[],[],rr_param,r_omega0));
    l_ok = str_id == "" && (isequal(size(M_test),[nx,nx]) || (nx == 0 && isempty(M_test)));
    contract = add_row(contract, "fcn_Mass constant and square", l_ok, ...
        join_detail(str_id, "size " + join(string(size(M_test)),"x") + sprintf(" (sv_x %d)",nx)));

    % get_sys stops with CurrentDependence
    [r_dep, str_id] = current_dependence({f_dx,f_I,f_Y}, rv_I);
    contract = add_row(contract, "no dependence on I", str_id == "" && r_dep < 1e-10, ...
        join_detail(str_id, sprintf("%.3g",r_dep)));

    sv_port = intersect(sv_u, [sv_v;sv_i]);
    contract = add_row(contract, "sv_u has no port names", isempty(sv_port), join(sv_port,", "));
    str_defined = "not defined";
    if ismethod(obj,"getCompPQ")
        str_defined = "defined";
    end
    contract = [contract; "getCompPQ (continuation power flow with UseInternalState)", "INFO", str_defined];

    % make flag
    flag = struct( ...
        "dx" , mktab(      abs(dx_test)      ,  sv_x, "diff" ),...
        "I"  , mktab(      abs( I_test)      ,  sv_i, "diff" )...
        );

    % validate linearized matrix
    point = {r_t,rv_x,rv_V,rv_I,rv_u,rr_param,r_omega0};
    if ismethod(obj,"Jacobi_dx")
        [flag, contract] = compare_jacobian(flag, contract, "Jacobi_dx", ...
            @() Jacobi_dx_num(obj,point{:}), @() obj.Jacobi_dx(point{:}), ...
            ["Axx","Bxv","Bxi","Bxu"], {sv_x,sv_x,sv_x,sv_x}, {sv_x,sv_v,sv_i,sv_u});
    end
    if ismethod(obj,"Jacobi_I")
        [flag, contract] = compare_jacobian(flag, contract, "Jacobi_I", ...
            @() Jacobi_I_num(obj,point{:}), @() obj.Jacobi_I(point{:}), ...
            ["Cix","Div","Dii","Diu"], {sv_i,sv_i,sv_i,sv_i}, {sv_x,sv_v,sv_i,sv_u});
    end
    if ismethod(obj,"Jacobi_Y")
        [flag, contract] = compare_jacobian(flag, contract, "Jacobi_Y", ...
            @() Jacobi_Y_num(obj,point{:}), @() obj.Jacobi_Y(point{:}), ...
            ["Cyx","Dyv","Dyi","Dyu"], {sv_y,sv_y,sv_y,sv_y}, {sv_x,sv_v,sv_i,sv_u});
    end

    flag.contract = table(contract(:,2), contract(:,3), ...
        RowNames=contract(:,1), VariableNames=["status","detail"]);
    flag.inputs   = table(input_sources(obj), RowNames=sv_u, VariableNames="source");

    % message
    if l_message
        sv_fn = string(fieldnames(flag))';
        disp(repmat('=',1,100))
        for fn = sv_fn
            disp(" ")
            if fn =="dx"
                disp(">> obj.f_dx(0,xst,Vst,ust)"+newline)
            elseif fn == "I"
                disp(">> Ist - obj.f_I(0,xst,Vst,ust)"+newline)
            elseif ismember(fn ,["Axx","Bxu","Bxv","Bxi"])
                disp(">> obj.Jacobi"+fn+"(0,xst,Vst,ust) - (Numerical differentiation @obj.f_dx)"+newline)
            elseif ismember(fn ,["Cix","Diu","Div","Dii"])
                disp(">> obj.Jacobi"+fn+"(0,xst,Vst,ust) - (Numerical differentiation @obj.f_I)"+newline)
            elseif ismember(fn ,["Cyx","Dyu","Dyv","Dyi"])
                disp(">> obj.Jacobi"+fn+"(0,xst,Vst,ust) - (Numerical differentiation @obj.f_Y)"+newline)
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

function contract = add_row(contract, str_check, l_ok, str_detail)
    if ismissing(str_detail)   % join of an empty list
        str_detail = "";
    end
    if l_ok
        contract = [contract; str_check, "PASS", str_detail];
    else
        contract = [contract; str_check, "FAIL", str_detail];
    end
end

function v = fit_size(v, n)
    v = reshape(v, [], 1);
    v = [v(1:min(end,n)); zeros(n-numel(v),1)];
end

function [val, str_id] = eval_value(f)
    val = [];
    str_id = "";
    try
        val = f();
    catch ME
        str_id = error_text(ME);
    end
end

function str = error_text(ME)
    % The identifier of the error, or its message when it has none (error(msg(...)) of GUILDA)
    str = string(ME.identifier);
    if str == ""
        str = string(ME.message);
    end
end

function [l_ok, str_detail] = check_size(val, str_id, n)
    l_ok = str_id == "" && numel(val) == n;
    str_detail = join_detail(str_id, "size " + join(string(size(val)),"x") + sprintf(" (expected %d)",n));
end

function str = join_detail(str_id, str_value)
    if str_id == ""
        str = str_value;
    else
        str = str_id;
    end
end

function [r_dep, str_id] = current_dependence(c_f, rv_I)
    % Largest slope of the model functions with respect to I (the error of the first failure)
    r_dep  = 0;
    str_id = "";
    d = 1e-3;
    for k = 1:numel(c_f)
        for m = 1:2
            e = d * ((1:2)==m).';
            [r, id] = eval_value(@() max(abs(reshape(c_f{k}(rv_I+e) - c_f{k}(rv_I),[],1)))/d);
            if id ~= ""
                str_id = id;
            elseif ~isempty(r)
                r_dep = max(r_dep, r);
            end
        end
    end
end

function [flag, contract] = compare_jacobian(flag, contract, str_method, f_num, f_valid, sv_name, c_row, c_col)
    % Compare the analytic blocks with the numerical ones; NaN for a block that cannot be compared
    str_detail = "";
    c_num   = cell(1,4);
    c_valid = cell(1,4);
    try
        [c_num{:}]   = f_num();
        [c_valid{:}] = f_valid();
    catch ME
        str_detail = error_text(ME);
    end
    for k = 1:4
        nr = numel(c_row{k});
        nc = numel(c_col{k});
        A = nan(nr,nc);
        if str_detail == ""
            V = c_valid{k};
            if isempty(V)              % Models may return [] for an empty or all-zero block (get_sys)
                A = abs(c_num{k});
            elseif numel(V) == nr*nc
                A = abs(c_num{k} - reshape(full(V),nr,nc));
            else
                str_detail = sv_name(k) + " size " + join(string(size(V)),"x") + sprintf(" (expected %dx%d)",nr,nc);
            end
        end
        flag.(sv_name(k)) = mktab(A, c_row{k}, c_col{k});
    end
    contract = add_row(contract, str_method+" sizes", str_detail == "", str_detail);
end

function sv_src = input_sources(obj)
    % Who drives each input, as in SolverODE: the outputs of the local controller and of
    % the global controllers of the same name; the other inputs stay at the equilibrium.
    a_con = obj.a_LocalController(:).';
    if ~isempty(obj.a_Bus) && ~isempty(obj.a_Bus.a_PowerNetwork)
        c_GC = obj.a_Bus.a_PowerNetwork.a_GlobalController;
        lv_GC = cellfun(@(gc) any(cellfun(@(c) c == obj, gc.controlledUnits)), c_GC);
        a_con = [a_con, reshape(c_GC(lv_GC),1,[])];
    end
    sv_src = repmat("equilibrium (not connected)", numel(obj.sv_u), 1);
    for k = 1:numel(obj.sv_u)
        lv = cellfun(@(c) any(c.sv_y == obj.sv_u(k)), a_con);
        if any(lv)
            sv_src(k) = "output of " + join(cellfun(@(c) c.str_tag, a_con(lv)), ", ");
        end
    end
end

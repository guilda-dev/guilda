function [result, flag, output] = initialize(obj, varargin)
% Compute the operating point of the network and set it as its equilibrium.
%
% The operating point is set as the equilibrium of the buses, components, local
% controllers and global controllers, and the edit log is reset, so the analyses that
% need the equilibrium (simulate, linearize, get_sys) can run. initialize is one of the
% few analysis methods that change the model.
%
% Name-Value options:
%
% - `Method` — How the operating point is obtained. Default: "powerflow".
%   - "powerflow": net.calculate_powerflow (settings of net.solver_PF).
%   - "OPF": net.optimize_powerflow with Method="AC OPF" (settings of net.solver_OPF;
%     the AC formulation gives a complete AC operating point).
%   - "equilibrium": the equilibria the components already hold (from an earlier
%     initialize); buses without components get the voltage of Y*V = I.
% - Other options go unchanged to calculate_powerflow ("powerflow") or
%   optimize_powerflow ("OPF") and are validated there (unknown names stop with
%   GUILDA:resolve_options:UnknownName); "equilibrium" takes no other option. The
%   formulation of that analysis (its own Method) is not set here: use
%   net.solver_PF.Method for the power flow.
%
% When the analysis does not succeed (no convergence, an infeasible OPF, or stored
% equilibria that do not satisfy the network equations), initialize stops with an error
% naming the remedy, and the network keeps its previous equilibrium and edit log (a
% slack bus set by calculate_powerflow is released again).
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% net.initialize();                                % power flow
% net.initialize(Method="equilibrium");            % re-set the stored equilibria
% res = net.initialize(Method="OPF", Solver="fmincon");
% res.r_cost                                       % cost of the OPF operating point
% ```
%
% See also PowerNetwork.calculate_powerflow, PowerNetwork.optimize_powerflow, PowerNetwork.simulate
    arguments (Output)
        result   % PowerFlowResult for "powerflow" and "equilibrium" (str_solver = "equilibrium", no branch flows), OPFResult for "OPF"; result.tab_bus is the bus equilibrium.
        flag     % Success flag of the analysis (positive; a failure stops with an error).
        output   % Details of the analysis; output.message describes the outcome.
    end

    varargin = v3_initialize_args(varargin);                  % COMPAT(v3)
    [str_method, c_nv] = take_method(varargin);

    obj.check_edit();    % rebuild f_* handles made stale by edits

    switch str_method
        case "powerflow"
            lv_slack = tools.vcellfun(@(b) b.l_isSlack, obj.a_Bus);
            try
                [result, flag, output] = obj.calculate_powerflow(c_nv{:});
                l_ok = result.l_success;
            catch ME
                l_ok = false;
            end
            if ~l_ok && ~any(lv_slack)
                release_slack(obj);
            end
            if exist("ME", "var")
                rethrow(ME)
            end
            if ~l_ok
                error('GUILDA:PowerNetwork:InitializePowerflowFailed', '%s', ...
                      msg('GUILDA:PowerNetwork:InitializePowerflowFailed', char(string(output.message))))
            end
        case "OPF"
            [result, flag, output] = obj.optimize_powerflow(c_nv{:}, "Method", "AC OPF");
            if ~result.l_success
                error('GUILDA:PowerNetwork:InitializeOPFFailed', '%s', ...
                      msg('GUILDA:PowerNetwork:InitializeOPFFailed', char(string(output.message))))
            end
        case "equilibrium"
            if ~isempty(c_nv)
                error('GUILDA:resolve_options:UnknownName', '%s', ...
                      msg('GUILDA:PowerNetwork:InitializeEquilibriumOption', char(string(c_nv{1}))))
            end
            [result, flag, output] = calculate_from_equilibrium(obj);
    end
    tab_PFsol = result.tab_bus;

    for i_gc = 1:numel(obj.a_GlobalController)
        a_GC = obj.a_GlobalController{i_gc};
        [a_GC.rv_Xequilibrium, a_GC.rv_Uequilibrium] = a_GC.get_equilibrium();
    end

    % distribute Qcomponent
    for i_bus = 1:numel(obj.a_Bus)
        rr_PFsol = tab_PFsol{i_bus,["Vphasor","Iphasor","P","Q"]};
        c_Vbus = rr_PFsol(1);
        c_Ibus = rr_PFsol(2);
        r_Pbus = rr_PFsol(3);
        r_Qbus = rr_PFsol(4);
        obj.a_Bus{i_bus}.set_equilibrium(c_Vbus,c_Ibus,r_Pbus,r_Qbus)
    end

    % reset log
    obj.reset_edit()
end


function [str_method, c_nv] = take_method(c_in)
% Separates Method (of initialize) from the options passed to the analysis
    sv_method = ["powerflow","OPF","equilibrium"];
    if mod(numel(c_in), 2) ~= 0
        error('GUILDA:resolve_options:InvalidPairs', '%s', msg('GUILDA:PowerNetwork:InitializePairs'))
    end
    str_method = "powerflow";
    lv_method  = false(size(c_in));
    for k = 1:2:numel(c_in)
        x = c_in{k};
        if ((ischar(x) && isrow(x)) || (isstring(x) && isscalar(x))) && strcmpi(x, "Method")
            lv_method(k:k+1) = true;
            v = c_in{k+1};
            l_text = (ischar(v) && isrow(v)) || (isstring(v) && isscalar(v));
            if ~l_text || ~any(strcmpi(v, sv_method))
                error('GUILDA:PowerNetwork:InitializeMethod', '%s', ...
                      msg('GUILDA:PowerNetwork:InitializeMethod', char(join('"' + sv_method + '"', ", "))))
            end
            str_method = sv_method(strcmpi(v, sv_method));
        end
    end
    c_nv = c_in(~lv_method);
end


function release_slack(obj)
% Releases the slack bus that calculate_powerflow set because none was set
    for i_bus = 1:numel(obj.a_Bus)
        obj.a_Bus{i_bus}.l_isSlack = false;
    end
end


function [result, flag, output] = calculate_from_equilibrium(obj)
% Build the bus equilibrium from the equilibria stored in the components
%   Vbus : the voltage the components on the bus hold
%   Ibus : the sum of the currents the components on the bus inject
%   Buses without components inject no current; their voltage is solved from Y*V = I.

    t0      = tic;
    str_Bus = string(obj.a_Bus);
    n_Bus   = numel(str_Bus);
    tab_Y   = obj.get_admittance_matrix;
    cm_Y    = tab_Y{str_Bus,str_Bus};

    cv_Vbus  = nan(n_Bus,1);
    cv_Ibus  = zeros(n_Bus,1);
    lv_known = false(n_Bus,1);
    for i_bus = 1:n_Bus
        a_Comp = obj.a_Bus{i_bus}.a_Component;
        for i_comp = 1:numel(a_Comp)
            comp = a_Comp{i_comp};
            if isempty(comp.c_Vequilibrium) || isempty(comp.c_Iequilibrium)
                error('GUILDA:PowerNetwork:InitializeNoEquilibrium', '%s', ...
                      msg('GUILDA:PowerNetwork:InitializeNoEquilibrium', char(string(comp))))
            end
            cv_Vbus(i_bus)  = comp.c_Vequilibrium;
            cv_Ibus(i_bus)  = cv_Ibus(i_bus) + comp.c_Iequilibrium;
            lv_known(i_bus) = true;
        end
    end

    % voltage of the buses without components (zero injection)
    if any(~lv_known)
        cv_Vbus(~lv_known) = - cm_Y(~lv_known,~lv_known) \ (cm_Y(~lv_known,lv_known)*cv_Vbus(lv_known));
    end

    % consistency check: Kirchhoff's current law at every bus
    tol     = 1e-6;
    r_resid = max(abs(cm_Y*cv_Vbus - cv_Ibus));
    if r_resid >= tol
        error('GUILDA:PowerNetwork:InitializeEquilibriumFailed', '%s', ...
              msg('GUILDA:PowerNetwork:InitializeEquilibriumFailed', char(string(r_resid))))
    end
    flag   = 1;
    output = struct("residual", r_resid, ...
                    "message", "The equilibria of the components satisfy the network equations.");

    cv_Sbus = cv_Vbus .* conj(cv_Ibus);
    tab_bus = array2table(...
        [angle(cv_Vbus),abs(cv_Vbus),real(cv_Sbus),imag(cv_Sbus),cv_Vbus,cv_Ibus], ...
        "VariableNames",["Varg","V","P","Q","Vphasor","Iphasor"],"RowNames",str_Bus);
    result  = PowerFlowResult(obj, "equilibrium", struct("Method","equilibrium","Tolerance",tol), ...
                              flag, output, t0, tab_bus);
end

classdef ResultLIN < ResultBase
% Result of get_sys.
%
% Holds the linear model of a layer at one or more points (time sections), as connected by
% SolverLIN.solve from the linear blocks of its model objects. For the network (output.s_layer "PowerNetwork") it is
% the unreduced linear DAE
%
% ```
% rm_E dx/dt = rm_Axx x + rm_Axv v + rm_Bx u
%          0 = rm_Avx x + rm_Avv v + rm_Bv u
% ```
%
% where x are the states, v = [Vre1; Vim1; Vre2; ...] the bus voltages and u the inputs,
% all in the order of the variable map tab_variable (= net.get_variable_map() at the time
% of the analysis). The algebraic equations are the current balance of each bus,
% 0 = (Y v - I of the components), in the order of v. The values are deviations from the
% point rv_point. Y is the admittance matrix of the model, also at a point inside a fault.
% get_ss returns the model of a Type ("ODE": the bus voltages eliminated, or "DAE"),
% get_contribution the part of elements in the DAE (a ResultLIN of its own, below),
% get_mode the modes (eigenvalue,
% frequency, damping ratio, dominant owner and participation), get_participation the
% participation of the states and of the buses in the modes, and plot_eigenvalue draws the
% eigenvalue map. get_eigenvalue and get_eigenvector return the eigenvalues and
% eigenvectors in the order of get_mode, get_kernel the kernel of the Jacobian of the DAE
% (the rotation of the phases of each island), get_reduced_matrix the Jacobian with the
% variables of chosen elements eliminated (Schur complement), and disp_summary and
% disp_mode display the result and its modes. plot_matrix draws a matrix of the model by
% groups of variables; plot_kernel, plot_participation, plot_eigenvector,
% plot_contribution and plot_reduced_matrix draw the kernel, the participation, the
% eigenvectors, the shares of the elements in an eigenvalue and the reduced matrix on the
% network diagram (the participation, eigenvectors and shares with the mode picked on the
% eigenvalue map).
%
% The properties A, B, C, D, E, StateName, InputName and OutputName hold one linear model
% (E dx/dt = A x + B u, y = C x + D u) with the names of the states, inputs and outputs, as
% in a state-space (ss) object, without the Control System Toolbox: get_ss(Type) with the
% Input, Output and Port of get_sys. They are computed from the DAE when read, and
% Type chooses the model: its default is the Type of get_sys, and setting it (res.Type =
% "DAE") switches all of them. They are empty when get_ss stops (flag false, or "ODE" with
% a singular Avv); get_ss gives the reason.
%
% Form chooses the view of A ... E (also an option of get_ss and of get_sys; res.Form =
% "absorbed" switches A ... OutputName like Type):
%
% - "descriptor" (default): E holds the time constants (the mass matrix of the models).
% - "absorbed": E^-1 multiplied into the rows of the states in A and B; E is the identity
%   there and zero on the bus variables (and on a state without a time constant, whose
%   row is kept). Derived from the descriptor model, so every result has it; the
%   eigenvalues and the transfer function do not change.
% - "hessian": the energy-function form (Nishino et al. 2025, eqs. (21)-(30)), only for a
%   result of net.get_sys(Form="hessian"), which calls get_hessian of every component
%   and local controller at the point of each section. Over z = [x; theta; V] (Port
%   "PI"), E_h dz/dt = H z + B_h u with E_h = -blkdiag(inv(R), 0) and
%   H = [Hxx Hxv; Hvx Hvv + Hvv_net]: dx/dt = -R (Hxx x + Hxv v) and the balance
%   0 = Hvx x + (Hvv + Hvv_net) v, where w = sum of w_dev = dU/dv = -[P; Q/V] of the
%   devices plus w_net = [P; Q/V] of the power from each bus into the network, and
%   Hvv_net its exact Jacobian. H is the Hessian of the energy function (symmetric) when
%   the model is lossless. "PQ" follows by dV = V drho, dQ = V d(Q/V) (H -> T H T,
%   T = diag(1, V)). B_h is the descriptor B with its state rows times E_h E^-1, and C, D
%   are those of the descriptor model (the same variables); the inputs are constants of
%   the point in the energy function. Equal to the descriptor DAE with its state rows
%   times E_h E^-1 where the bus balance holds (the equilibrium, a simulation point; the
%   I dV terms of the devices cancel in the bus sum). Port "I" stops with
%   GUILDA:ResultLIN:HessianPort. rv_asymmetry is the asymmetry of Hvv + Hvv_net of each
%   section (the loss: branch resistances, conductances, impedance and current loads).
%   The descriptor data is kept, so Form switches back.
%
% A result of comp.get_sys, bus.get_sys, con.get_sys or gc.get_sys (output.s_layer
% "Component", "Bus", "LocalController" or "GlobalController") holds the port model of the
% layer in A ... OutputName (see PowerSystemModel.get_sys), the point rv_point and the
% blocks rm_Axx, rm_Axv (the voltage inputs), rm_Bx (the other inputs of tab_variable)
% and rm_E. get_ss returns that model, and Type and Port do not apply.
%
% Time sections: get_sys({sim, rv_t}) with several times, or a matrix of points (one per
% column), gives one section per time or column; the equilibrium and a vector give one.
% rv_t holds the time of each section (the times of {sim, rv_t}, 1:n for a matrix, NaN
% otherwise), and Index (default 1) chooses the section that rv_point, rm_Axx ... rm_E,
% sct_model and A ... OutputName show: res.Index = 3 switches all of them. get_ss,
% get_mode, plot_eigenvalue and the analysis methods (get_eigenvalue ... disp_mode) take
% Index (default res.Index); all but plot_eigenvalue also take Time (the section of the nearest time), and Index "all" returns every section
% (get_eigenvalue: a table; get_mode and the other getters: a struct array, whose tab_mode
% are one table by vertcat). plot_eigenvalue of several sections draws all of them in one chart whose
% set_time shows the section nearest to a time (Index is the section shown first), so it
% links with the graphs of the simulation, and plot_eigenvalue_path draws the largest
% real part and the smallest damping ratio over the sections, marking the first unstable
% one. flag is true only when every section
% is usable; output.lv_flag, sv_issue, sv_message and rv_rcond_Avv describe each section,
% and the scalar fields (message, s_issue, rcond_Avv, sv_faultBus) the whole run. A
% result of the network keeps a snapshot of it, sct_network = struct(net, false).
%
% A contribution result: res.get_contribution(target) returns a ResultLIN with every
% section of res whose sections hold the part of the targets in the connected model (the
% terms of those elements), with sv_target the targets. Its Type is "DAE" only (an "ODE"
% stops with GUILDA:ResultLIN:ContributionDAE) and it has no Form "hessian"; the parts of
% all the elements sum to the DAE of res in every section. Its methods compute on the
% part: on a contribution result (sv_target nonempty) the numbers are of the part alone
% and have no meaning for the whole system.
%
% - `tab_variable` has one row per variable with Index, Kind, Role, Owner, Name, Label, Bus
%   and Equilibrium: the leading rows x, Vre, Vim, u, uc of the variable map of the layer (for
%   a controller: its x, the voltages and its uc), the order of rv_point.
% - `sct_model` holds the connected model (field sct_sys: the descriptor model over
%   [x; v] with its outputs, from SolverLIN.solve) and, for the network, the admittance
%   matrix, the bus voltages at the point and the names of the bus currents: used by the
%   coordinates of get_ss("DAE") and its Output option; sct_sys also holds the terms of
%   each element (sct_term) and their classes (tab_owner) for get_contribution. The
%   result holds computed values only; the network is not changed.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% [result, flag] = net.get_sys();
% eig(full(result.rm_Axx))          % Jacobian blocks of the unreduced DAE
% eig(result.A, result.E)           % model of result.Type (the Type of get_sys)
% result.Type = "DAE";              % A ... OutputName are now the DAE
% sct = result.get_ss("ODE", Format="struct");   % reduced model as a struct
% sys = result.get_ss("ODE");       % ss object (Control System Toolbox)
% res_gen = result.get_contribution("component.generator.abstract");   % part of the generators in the DAE (a ResultLIN)
% res_gen.A                                    % that part of the DAE in the section shown
% sct = result.get_mode(MinFrequency=0.1);     % oscillatory modes: sct.tab_mode, participation, shapes
% sct = result.get_participation();            % participation by state and by bus (tab_bus)
% result.plot_eigenvalue();                    % eigenvalue map
% result.disp_summary();                       % sizes, status, modes and kernel
% sct = result.get_kernel();                   % rotation of the angles: rm_right, rm_left, tab_phase
% sct = result.get_reduced_matrix(["Component","LocalController"]);   % seen from the buses
% result.Form = "absorbed";  eig(result.A)     % E^-1 multiplied in
%
% resH = net.get_sys(Type="DAE", Port="PI", Form="hessian");   % energy-function form (supported devices only)
% resH.rv_asymmetry                            % asymmetry of Hvv + Hvv_net (0 when lossless)
% resH.Form = "descriptor";                    % the Jacobian of the same result
%
% sc = net.add_scenario("fault");  sc.add_fault("B008", [1,1.05]);
% sim = net.simulate("fault", Time=[0,5]);
% res = net.get_sys({sim, [0.5, 2, 4]});       % three time sections
% res.Index = 2;  eig(res.A, res.E)            % the section at t = 2
% sys = res.get_ss(Time=4, Format="struct");   % the section nearest to t = 4
% tab = vertcat(res.get_mode(Index="all").tab_mode);   % modes of every section, with Time and Index
% ```
%
% See also SolverLIN, ResultBase, PowerSystemModel.get_sys

    properties (SetAccess=private) % Result
        tab_variable table = table()           % Variable map at the time of the analysis: the order of the rows and columns of the Jacobian blocks.
        rv_t (1,:) double = NaN                % Time of each section: the times of {sim, rv_t}, 1:n for a matrix of points, NaN for the equilibrium or a vector.
    end
    properties (Dependent) % Section
        Index      % Section shown by rv_point, rm_Axx ... rm_E, sct_model and A ... OutputName: 1 ... numel(rv_t) (default 1). <@Type> double
    end
    properties (Dependent, SetAccess=private) % Result
        rv_point   % Point of the linearization of section Index in the order of tab_variable (the equilibrium when output.l_equilibrium is true). <@Type> double (:,1)
        rm_Axx     % d(dx/dt)/dx: Jacobian of the state equations with respect to the states (section Index). <@Type> double
        rm_Axv     % d(dx/dt)/dv: Jacobian of the state equations with respect to the bus voltages (section Index). <@Type> double
        rm_Bx      % d(dx/dt)/du: Jacobian of the state equations with respect to the inputs (section Index). <@Type> double
        rm_Avx     % Jacobian of the bus current balance (Y v - I) with respect to the states (section Index). <@Type> double
        rm_Avv     % Jacobian of the bus current balance (Y v - I) with respect to the bus voltages: Y minus the component terms (section Index). <@Type> double
        rm_Bv      % Jacobian of the bus current balance (Y v - I) with respect to the inputs (section Index). <@Type> double
        rm_E       % Mass matrix of the state equations (the algebraic equations have none; section Index). <@Type> double
    end
    properties % Model
        Type (1,1) string {mustBeMember(Type, ["ODE","DAE"])} = "ODE"   % Model of A ... OutputName: "ODE" (the bus voltages eliminated) or "DAE" (the connected model). Default: the Type of get_sys.
        Form (1,1) string {mustBeMember(Form, ["descriptor","absorbed","hessian"])} = "descriptor"   % View of A ... E: "descriptor", "absorbed" (E^-1 in the dynamic rows) or "hessian" (energy-function form, from get_sys(Form="hessian")). Default: the Form of get_sys.
    end
    properties (Dependent, SetAccess=private) % Energy function
        rv_asymmetry   % Asymmetry norm(H - H.', "fro")/norm(H, "fro") of the bus block H = Hvv + Hvv_net (port PI) of the hessian form of each section: 0 when lossless; NaN without the form. <@Type> double (1,:)
    end
    properties (Dependent, SetAccess=private) % Model
        A          % State matrix of the model of section Index (E dx/dt = A x + B u, y = C x + D u): get_ss(Type) with the Input and Output of get_sys. <@Type> double
        B          % Input matrix of the model. <@Type> double
        C          % Output matrix of the model. <@Type> double
        D          % Feedthrough matrix of the model. <@Type> double
        E          % Mass matrix of the model (singular for "DAE"). <@Type> double
        StateName  % Names of the states of the model. <@Type> string (:,1)
        InputName  % Names of the inputs of the model. <@Type> string (:,1)
        OutputName % Names of the outputs of the model (the network has none by default). <@Type> string (:,1)
    end
    properties (SetAccess=private) % Data of the calculation
        sct_network struct = struct()          % Snapshot of the network at the linearization: struct(net, false) (the network layer only; otherwise empty).
        sv_target (1,:) string = strings(1,0)  % Targets of a contribution result (get_contribution: its sections are the part of these elements); empty for an ordinary result.
    end
    properties (Dependent, SetAccess=private, Hidden) % Model data
        sct_model  % Data of get_ss for section Index: the connected model sct_sys and, for the network, cm_Y, cv_V, sv_I (see the class help). <@Type> struct
    end
    properties (SetAccess=private, Hidden) % Sections
        c_section cell = {struct()}            % Connected model of each section (SolverLIN.solve; for the network also cm_Y, cv_V, sv_I).
        rm_point double = zeros(0,1)           % Point of each section (one column per section) in the order of tab_variable.
        i_index (1,1) double = 1               % Section of Index.
    end
    properties (Access=private, Hidden) % Cache
        c_cache cell = {struct()}              % Models of A ... OutputName of each section by Type, computed when first read.
    end

    methods
        function obj = ResultLIN(net, solver, options, flag, output, elapsed, tab_variable, rm_point, sys_section, rv_t, sct_network)
        % Create a linearization result.
        %
        % Stores the computed values of a linearization: the connected model of
        % SolverLIN.solve of each section and its point.
            arguments (Input)
                net                 = []           % Analysed network; see ResultBase.
                solver              = "SolverLIN"  % Solver object or its class name; see ResultBase.
                options      struct = struct()     % Effective settings; see ResultBase.
                flag                = false        % Success or convergence flag; see ResultBase.
                output       struct = struct()     % Solver details (n_x, n_v, s_layer, lv_flag, sv_issue, sv_message, ...); see ResultBase.
                elapsed             = NaN          % [s] Elapsed time or tic value; see ResultBase.
                tab_variable table  = table()      % Variable map (leading rows).
                rm_point     double = zeros(0,1)   % Point of each section (columns) in the order of tab_variable.
                sys_section         = struct()     % Connected model (SolverLIN.solve) of each section: a struct (one section) or a 1 x n_t cell; for the network also cm_Y, cv_V, sv_I.
                rv_t   (1,:) double = NaN(1, size(rm_point, 2))  % Time of each section.
                sct_network  struct = struct()     % Snapshot of the network: struct(net, false).
            end
            arguments (Output)
                obj  % The result object.
            end
            obj@ResultBase(net, solver, options, flag, output, elapsed);
            if isfield(options, "Type")
                obj.Type = options.Type;
            end
            if isstruct(sys_section)
                sys_section = {sys_section};
            end
            n_t = numel(sys_section);
            % the fields of each section, from the scalar fields for a single section
            if ~isfield(output, "sv_issue")
                s_issue = "";
                if isfield(output, "s_issue")
                    s_issue = string(output.s_issue);
                end
                s_message = "";
                if isfield(output, "message")
                    s_message = string(output.message);
                end
                obj.output.sv_issue   = repmat(s_issue, 1, n_t);
                obj.output.lv_flag    = obj.output.sv_issue == "";
                obj.output.sv_message = repmat(s_message, 1, n_t);
            end
            obj.tab_variable = tab_variable;
            obj.rm_point     = rm_point;
            obj.c_section    = reshape(sys_section, 1, []);
            obj.rv_t         = rv_t;
            obj.sct_network  = sct_network;
            obj.c_cache      = repmat({struct()}, 1, n_t);
            if isfield(options, "Form")
                obj.Form = options.Form;
            end
        end

        function set.Type(obj, v)
            % (a contribution result is a part of the DAE: it has no ODE)
            if v == "ODE" && ~isempty(obj.sv_target) %#ok<MCSUP>
                error(msg("GUILDA:ResultLIN:ContributionDAE", join(obj.sv_target, ", "))) %#ok<MCSUP>
            end
            obj.Type = v;
        end

        function set.Form(obj, v)
            % (a default c_section: the object is being loaded, its sections come later)
            if v == "hessian" && ~isequal(obj.c_section, {struct()}) && ~all(cellfun(@(S) isfield(S, "sct_hessian"), obj.c_section)) %#ok<MCSUP>
                error(msg("GUILDA:ResultLIN:NoHessianForm"))
            end
            obj.Form = v;
        end
        function v = get.rv_asymmetry(obj)
            v = NaN(1, numel(obj.c_section));
            for k = 1:numel(v)
                if isfield(obj.c_section{k}, "sct_hessian")
                    v(k) = obj.c_section{k}.sct_hessian.r_asymmetry;
                end
            end
        end

        function v = get.Index(obj)
            v = obj.i_index;
        end
        function set.Index(obj, v)
            n_t = numel(obj.c_section);
            if ~(isnumeric(v) && isscalar(v) && v == round(v) && v >= 1 && v <= n_t)
                error(msg("GUILDA:ResultLIN:IndexRange", string(n_t)))
            end
            obj.i_index = double(v);
        end
        function v = get.rv_point(obj)
            v = zeros(0,1);
            if ~isempty(obj.rm_point)
                v = obj.rm_point(:, obj.i_index);
            end
        end
        function v = get.sct_model(obj)
            S = obj.c_section{obj.i_index};
            v = struct("sct_sys", S);
            for s = ["cm_Y","cv_V","sv_I"]
                if isfield(S, s)
                    v.(s) = S.(s);
                end
            end
        end
        function v = get.rm_Axx(obj)
            v = section_block(obj, "Axx");
        end
        function v = get.rm_Axv(obj)
            v = section_block(obj, "Axv");
        end
        function v = get.rm_Bx(obj)
            v = section_block(obj, "Bx");
        end
        function v = get.rm_Avx(obj)
            v = section_block(obj, "Avx");
        end
        function v = get.rm_Avv(obj)
            v = section_block(obj, "Avv");
        end
        function v = get.rm_Bv(obj)
            v = section_block(obj, "Bv");
        end
        function v = get.rm_E(obj)
            v = section_block(obj, "E");
        end

        function v = get.A(obj)
            v = cached_model(obj).A;
        end
        function v = get.B(obj)
            v = cached_model(obj).B;
        end
        function v = get.C(obj)
            v = cached_model(obj).C;
        end
        function v = get.D(obj)
            v = cached_model(obj).D;
        end
        function v = get.E(obj)
            v = cached_model(obj).E;
        end
        function v = get.StateName(obj)
            v = cached_model(obj).StateName;
        end
        function v = get.InputName(obj)
            v = cached_model(obj).InputName;
        end
        function v = get.OutputName(obj)
            v = cached_model(obj).OutputName;
        end

        sys = get_ss(obj, Type, opt)
        [res_e, sct_mask] = get_contribution(obj, target)
        sct_mode = get_mode(obj, opt)
        sct_part = get_participation(obj, opt)
        G = plot_eigenvalue(obj, opt)
        G = plot_eigenvalue_path(obj, opt)
        [G, G_block] = plot_matrix(obj, opt)
        G = plot_kernel(obj, opt)
        sct_graph = plot_participation(obj, opt)
        sct_graph = plot_eigenvector(obj, opt)
        [G, tab_coupling] = plot_reduced_matrix(obj, target, opt)
        sct_graph = plot_contribution(obj, opt)
        cv_lambda = get_eigenvalue(obj, Type, opt)
        sct_vector = get_eigenvector(obj, Type, opt)
        sct_kernel = get_kernel(obj, opt)
        sct_reduced = get_reduced_matrix(obj, target, opt)
        varargout = disp_summary(obj, opt)
        varargout = disp_mode(obj, opt)
    end
end


function M = section_block(obj, s_block)
% A Jacobian block of section Index: from the connected model over [x; v] for the
% network, or the voltage inputs (Axv) and the other inputs of tab_variable (Bx) of a
% port model
    M = zeros(0,0);
    S = obj.c_section{obj.i_index};
    if ~isfield(S, "A")
        return
    end
    n_x = size(S.A,1) - S.n_v;
    ix  = 1:n_x;
    iv  = n_x+1:size(S.A,1);
    if S.n_v > 0
        switch s_block
            case "Axx", M = S.A(ix,ix);
            case "Axv", M = S.A(ix,iv);
            case "Bx",  M = S.B(ix,:);
            case "Avx", M = S.A(iv,ix);
            case "Avv", M = S.A(iv,iv);
            case "Bv",  M = S.B(iv,:);
            case "E",   M = S.E(ix,ix);
        end
        return
    end
    tab = obj.tab_variable;
    lv_V = ismember(S.InputName, tab.Label(tab.Kind == "Vre" | tab.Kind == "Vim"));
    switch s_block
        case "Axx", M = S.A;
        case "Axv", M = S.B(:,lv_V);
        case "Bx",  M = S.B(:, ismember(S.InputName, tab.Label) & ~lv_V);
        case "E",   M = S.E;
    end
end


function sct = cached_model(obj)
% The model of obj.Type of section Index: get_ss(Type) with the Input and Output of
% get_sys, computed when first read, or an empty model when get_ss stops (flag false:
% get_ss gives the reason)
    s_type = obj.Type;
    s_key = s_type + "_" + obj.Form;
    k = obj.i_index;
    if isfield(obj.c_cache{k}, s_key)
        sct = obj.c_cache{k}.(s_key);
        return
    end
    c_nv = cell(1,0);
    for str = ["Input","Output"]
        if isfield(obj.options, str)
            c_nv = [c_nv, {str, obj.options.(str)}]; %#ok<AGROW>
        end
    end
    sct = struct("A", zeros(0,0), "B", zeros(0,0), "C", zeros(0,0), "D", zeros(0,0), "E", zeros(0,0), ...
                 "StateName", strings(0,1), "InputName", strings(0,1), "OutputName", strings(0,1));
    if ~isempty(obj.tab_variable) && isfield(obj.c_section{k}, "A")
        try
            sct = obj.get_ss(s_type, c_nv{:}, Index=k, Form=obj.Form, Format="struct");
        catch
            % no model of this Type: get_ss gives the reason
        end
    end
    obj.c_cache{k}.(s_key) = sct;
end

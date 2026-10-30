function net = import_matpower(mpc, opt)
% Build a network from a MATPOWER case.
%
% Builds a PowerNetwork from a MATPOWER case (version 2); the inverse of
% tools.network_to_mpc. MATPOWER itself is not needed.
% Units are converted to per unit on mpc.baseMVA (net.tab_parameter.base.baseMVA) and
% angles to radians. Buses keep the row order of mpc.bus (bus i = net.a_Bus{i}); the
% bus numbers of mpc.bus(:,1) are only used to resolve gen and branch rows.
%   bus     : Gshunt/Bshunt = GS/BS / baseMVA, Vmin/Vmax = VMIN/VMAX, baseKV = BASE_KV,
%             V0/Varg0 = VM/VA (initial values), Varg = VA, and V = VG of the first
%             in-service generator of the bus (VM without one). The REF bus (type 3) is
%             the slack bus. Isolated buses (type 4) are not supported.
%   load    : a LoadModel component with P = -PD/baseMVA, Q = -QD/baseMVA (GUILDA
%             injection sign: consumed power is negative) on each bus with nonzero PD or
%             QD. Its OPF cost is 0.
%   gen     : a GeneratorModel component per in-service row (GEN_STATUS > 0), before the
%             load of its bus: P = PG/baseMVA and Q = NaN (the bus is a PV bus),
%             Pmin/Pmax/Qmin/Qmax = PMIN/PMAX/QMIN/QMAX / baseMVA, baseMVA = MBASE, OPF
%             initial values PG/QG / baseMVA. Dynamic parameters are GeneratorParameter.
%   gencost : polynomial costs (MODEL = 2) up to quadratic, c2*Pg^2 + c1*Pg + c0 in MW:
%             HP = c2*baseMVA^2, fP = c1*baseMVA, startup/shutdown = STARTUP/SHUTDOWN;
%             rows ng+1:2*ng give HQ and fQ. A constant c0 is dropped (warning
%             GUILDA:import_matpower:ConstantCost). Piecewise-linear costs (MODEL = 1)
%             and higher degrees stop with GUILDA:import_matpower:Unsupported.
%             Without gencost the costs are the add_component defaults.
%   branch  : each in-service row (BR_STATUS > 0) is a "pi" line when TAP is 0 or 1 and
%             SHIFT is 0, else a "pi_transformer" (tap on the from side, as in MATPOWER):
%             R, X, C = BR_B/2, tap = TAP, phase = SHIFT, Smax = RATE_A/baseMVA (0 = Inf),
%             Vargmax = the tighter of |ANGMIN| and |ANGMAX| (Inf when both are 0 or
%             reach 360 degrees). Imax, Pmax and Qmax are Inf.
%
% <@Examples>
% ```matlab
% net = PowerNetwork.import_matpower("case14");              % needs case14.m on the path
% net = PowerNetwork.import_matpower(mpc, GeneratorModel="gen-classical", Initialize=false);
% mpc2 = tools.network_to_mpc(net);                              % back to MATPOWER
% ```
%
% See also PowerNetwork.import_csv, tools.network_to_mpc

    arguments
        mpc   % MATPOWER case: the struct (baseMVA, bus, gen, branch, optional gencost), the name of a case function on the path ("case14"), a .m or .mat case file, or a function handle that returns the struct.
        opt.GeneratorModel      (1,1) string  = "gen-park"   % Component key of every generator (e.g. "gen-park", "gen-classical", "gen-1axis").
        opt.GeneratorParameter                = nan   % Dynamic parameters of every generator (the parameter argument of add_component); NaN uses the defaults of the model class (first row of its parameter.csv).
        opt.LoadModel           (1,1) string  = "load-power"   % Component key of every load.
        opt.Hz                  (1,1) double {mustBePositive} = GUILDA.config("Model","Hz")   % [Hz] Nominal frequency (MATPOWER has none).
        opt.Tag                 (1,1) string   % Tag of the network. Default: the case name, or "PowerNetwork" for a struct.
        opt.Initialize          (1,1) logical = true   % Run net.initialize() after building the network.
    end
    arguments (Output)
        net   % The built network.
    end
    unsupported = @(str) error("GUILDA:import_matpower:Unsupported", "import_matpower: %s", str);

    [mpc, str_name] = load_case(mpc);
    if ~isfield(opt, "Tag")
        opt.Tag = str_name;
    end
    check_case(mpc);
    base = mpc.baseMVA;
    if ~isfield(mpc, "gencost"); mpc.gencost = zeros(0, 4); end

    net = PowerNetwork(opt.Tag);
    net.para_base.Hz      = opt.Hz;
    net.para_base.baseMVA = base;

    rm_bus = mpc.bus;
    rm_gen = mpc.gen;
    rm_br  = mpc.branch;
    n_bus  = size(rm_bus, 1);
    n_gen  = size(rm_gen, 1);
    [l_ok, iv_genbus] = ismember(rm_gen(:,1), rm_bus(:,1));
    if ~all(l_ok)
        unsupported(sprintf("gen row %d refers to bus %d, which is not in mpc.bus.", find(~l_ok,1), rm_gen(find(~l_ok,1),1)));
    end
    [l_ok, im_brbus] = ismember(rm_br(:,1:2), rm_bus(:,1));
    if ~all(l_ok, "all")
        unsupported(sprintf("branch row %d refers to a bus that is not in mpc.bus.", find(~all(l_ok,2),1)));
    end
    if any(rm_bus(:,2) == 4)
        unsupported(sprintf("bus %d is isolated (type 4). Remove isolated buses and their branches and generators first.", rm_bus(find(rm_bus(:,2)==4,1),1)));
    end
    lv_gen = rm_gen(:,8) > 0;

    % ---- generator costs -------------------------------------------------------------
    rm_cost = gen_costs(mpc.gencost, n_gen, base, unsupported);   % [HP fP HQ fQ startup shutdown]

    % ---- buses, generators, loads ----------------------------------------------------
    a_Bus = cell(n_bus, 1);
    for i = 1:n_bus
        r_V = rm_bus(i, 8);
        i_g = find(lv_gen & iv_genbus == i, 1);
        if ~isempty(i_g); r_V = rm_gen(i_g, 6); end
        r_Varg = rm_bus(i, 9)*pi/180;
        a_Bus{i} = net.add_bus("V", r_V, "Varg", r_Varg, "V0", rm_bus(i,8), "Varg0", r_Varg, ...
                               "Gshunt", rm_bus(i,5)/base, "Bshunt", rm_bus(i,6)/base, ...
                               "Vmin", rm_bus(i,13), "Vmax", rm_bus(i,12), "baseKV", rm_bus(i,10));
    end
    for k = find(lv_gen(:)')
        c_cost = {};
        if ~isempty(rm_cost)
            c_cost = {"OPFcost_HP", rm_cost(k,1), "OPFcost_fP", rm_cost(k,2), ...
                      "OPFcost_HQ", rm_cost(k,3), "OPFcost_fQ", rm_cost(k,4), ...
                      "OPFcost_startup", rm_cost(k,5), "OPFcost_shutdown", rm_cost(k,6)};
        end
        a_Bus{iv_genbus(k)}.add_component(char(opt.GeneratorModel), "parameter", opt.GeneratorParameter, ...
            "P", rm_gen(k,2)/base, "Q", nan, "baseMVA", rm_gen(k,7), ...
            "Pmin", rm_gen(k,10)/base, "Pmax", rm_gen(k,9)/base, ...
            "Qmin", rm_gen(k,5)/base,  "Qmax", rm_gen(k,4)/base, ...
            "OPFinit_P0", rm_gen(k,2)/base, "OPFinit_Q0", rm_gen(k,3)/base, c_cost{:});
    end
    for i = 1:n_bus
        PQ = rm_bus(i, [3 4]);
        if any(PQ ~= 0)
            a_Bus{i}.add_component(char(opt.LoadModel), "P", -PQ(1)/base, "Q", -PQ(2)/base, ...
                                   "OPFcost_HP", 0, "OPFcost_fP", 0);
        end
    end
    i_ref = find(rm_bus(:,2) == 3, 1);
    if ~isempty(i_ref)
        bus = a_Bus{i_ref};
        if isempty(bus.a_Component)
            unsupported(sprintf("the reference bus %d has no in-service generator or load.", rm_bus(i_ref,1)));
        end
        evalc("bus.l_isSlack = true;");         % without the SetSlack message
    end

    % ---- branches --------------------------------------------------------------------
    for k = find(rm_br(:,11).' > 0)
        r_tap = rm_br(k, 9);
        if r_tap == 0; r_tap = 1; end
        r_phase = rm_br(k, 10)*pi/180;
        if r_tap == 1 && r_phase == 0
            str_type = 'pi';
        else
            str_type = 'pi_transformer';
        end
        r_Smax = rm_br(k, 6)/base;
        if r_Smax == 0; r_Smax = inf; end
        r_ang = abs(rm_br(k, 12:13));
        r_ang = r_ang(r_ang < 360);
        if isempty(r_ang) || all(r_ang == 0)
            r_ang = inf;
        else
            r_ang = min(r_ang)*pi/180;
        end
        str_fromto = [string(a_Bus{im_brbus(k,1)}), string(a_Bus{im_brbus(k,2)})];
        net.add_branch(str_type, str_fromto, "R", rm_br(k,3), "X", rm_br(k,4), "C", rm_br(k,5)/2, ...
                       "Tap", r_tap, "Phase", r_phase, "Smax", r_Smax, "Vargmax", r_ang);
    end

    if opt.Initialize
        net.initialize;
    end
end


function [mpc, str_name] = load_case(mpc)
% struct | case name | case file (.m/.mat) | function handle -> struct
    str_name = "PowerNetwork";
    if isa(mpc, "function_handle")
        str_name = string(func2str(mpc));
        mpc = mpc();
    elseif (ischar(mpc) || isstring(mpc)) && isscalar(string(mpc))
        str_case = string(mpc);
        [str_dir, str_name, str_ext] = fileparts(str_case);
        if str_ext == ".mat" && isfile(str_case)
            s = load(str_case);
            if isfield(s, "mpc")
                mpc = s.mpc;
            else
                c = struct2cell(s);
                mpc = c{1};
            end
        elseif isfile(str_case) || isfile(str_case + ".m")
            if str_dir == ""; str_dir = pwd; end
            str_old = addpath(str_dir);
            c_restore = onCleanup(@() path(str_old));
            mpc = feval(str_name);
        elseif any(exist(str_case) == [2 3 6])                     %#ok<EXIST>
            mpc = feval(str_case);
        else
            error("GUILDA:import_matpower:CaseNotFound", ...
                  "MATPOWER case not found: %s. Give an mpc struct, the name of a case function on the MATLAB path, or the path of a .m/.mat case file.", str_case);
        end
        if ~isvarname(str_name); str_name = "PowerNetwork"; end
    end
    if ~isstruct(mpc) || ~isscalar(mpc)
        error("GUILDA:import_matpower:InvalidCase", "The MATPOWER case must be a struct with the fields baseMVA, bus, gen and branch (got %s).", class(mpc));
    end
end

function check_case(mpc)
    str_need = ["baseMVA", "bus", "gen", "branch"];
    l_miss   = ~isfield(mpc, str_need);
    if any(l_miss)
        error("GUILDA:import_matpower:InvalidCase", "The MATPOWER case has no field %s.", strjoin(str_need(l_miss), ", "));
    end
    if isfield(mpc, "version") && string(mpc.version) == "1"
        error("GUILDA:import_matpower:Unsupported", ...
              "import_matpower: MATPOWER case version 1 is not supported. Convert it to version 2 first (MATPOWER loadcase does this).");
    end
    n_col = [size(mpc.bus,2), size(mpc.gen,2), size(mpc.branch,2)];
    if any(n_col < [13 10 13])
        error("GUILDA:import_matpower:InvalidCase", ...
              "The MATPOWER case needs at least 13 bus columns, 10 gen columns and 13 branch columns (got %d, %d, %d).", n_col);
    end
end

function rm_cost = gen_costs(rm_gc, n_gen, base, unsupported)
% [HP fP HQ fQ startup shutdown] of each gen row; empty without gencost
    rm_cost = zeros(0, 6);
    if isempty(rm_gc)
        return
    end
    if ~ismember(size(rm_gc,1), [n_gen, 2*n_gen])
        unsupported(sprintf("gencost has %d rows; it needs ng = %d (P costs) or 2*ng (P and Q costs).", size(rm_gc,1), n_gen));
    end
    rm_cost = zeros(n_gen, 6);
    rm_cost(:, 5:6) = rm_gc(1:n_gen, 2:3);
    l_const = false;
    for r = 1:size(rm_gc, 1)
        if rm_gc(r,1) ~= 2
            unsupported(sprintf("gencost row %d is piecewise linear (MODEL = %d). Only polynomial costs (MODEL = 2) are supported: fit it with a polynomial of degree 2 or less first.", r, rm_gc(r,1)));
        end
        n_c = rm_gc(r, 4);
        rv_c = rm_gc(r, 4 + (1:n_c));                 % highest degree first
        if n_c > 3 && any(rv_c(1:n_c-3) ~= 0)
            unsupported(sprintf("gencost row %d is a polynomial of degree %d. Only costs up to quadratic are supported.", r, n_c-1));
        end
        rv_c = [zeros(1, 3), rv_c];
        rv_c = rv_c(end-2:end);                       % [c2 c1 c0]
        l_const = l_const || rv_c(3) ~= 0;
        k = mod(r-1, n_gen) + 1;
        j = 1 + 2*(r > n_gen);                         % P -> columns 1:2, Q -> 3:4
        rm_cost(k, j:j+1) = [rv_c(1)*base^2, rv_c(2)*base];
    end
    if l_const
        warning("GUILDA:import_matpower:ConstantCost", ...
                "import_matpower: the constant terms c0 of gencost are dropped (GUILDA costs have no constant); the OPF solution is the same, its cost is lower by sum(c0).");
    end
end

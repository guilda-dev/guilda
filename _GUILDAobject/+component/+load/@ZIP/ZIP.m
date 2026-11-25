classdef ZIP < component.load.abstract
% ZIP load model: a mix of constant-impedance, constant-current and constant-power parts.
%
% The power of the load is a polynomial of the bus voltage magnitude $|V|$. The inputs
% `Pload` and `Qload` are the power at $|V| = 1$ pu, and the coefficients `kPZ`, `kPI`,
% `kPP` (`kQZ`, `kQI`, `kQP`) split it into the constant-impedance (Z), constant-current (I)
% and constant-power (P) parts. Below `VswitchP` the constant-power parts and below
% `VswitchI` the constant-current parts become constant impedance, matched continuously at
% the threshold, so the load current goes to zero with the voltage. The steady inputs come
% from the power-flow solution (`get_equilibrium`): the load takes the specified `P` and `Q`
% at the power-flow voltage.
%
% **Dynamic model**
% The model is a dynamical system with state $x$, input $u$ and output $y$, connected
% to its bus through the bus voltage $V$ and the current $I$ it injects.
%
% **State variables** $x$ (`sv_x`)
% - none
%
% **Input signals** $u$ (`sv_u`; the ports driven by local controllers and events)
% - `Pload` [pu]: active power injected into the bus at $|V| = 1$ pu (negative for consumption).
% - `Qload` [pu]: reactive power injected into the bus at $|V| = 1$ pu (negative for consumption).
%
% **Output signals** $y$ (`sv_y`; read by local controllers)
% - none
%
% **Parameters** (`sv_para`; the `parameter` argument of `Bus.add_component`)
% - `kPZ`, `kPI`, `kPP`: shares of the constant-impedance, constant-current and constant-power parts of `Pload` (default 0, 1, 0).
% - `kQZ`, `kQI`, `kQP`: the same for `Qload` (default 1, 0, 0).
% - `VswitchP` [pu]: voltage below which the constant-power parts are constant impedance (default 0.7).
% - `VswitchI` [pu]: voltage below which the constant-current parts are constant impedance (default 0.7).
%
% The defaults are the load of the IEEJ standard networks (NLT = 2: constant-current P,
% constant-impedance Q). The `parameter` argument is a one-row table or a scalar struct
% with some of these names; a missing name or a NaN value takes the default, and another
% name stops with an error (`ParameterID`, the key column of an imported `dynamics.csv`, is
% ignored). `VswitchP` and `VswitchI` must be positive and the coefficients finite; a
% coefficient sum other than 1 gives a warning (the load then takes a power other than
% `Pload`, `Qload` at 1 pu, but the power flow is still met).
%
% **Equation**
% ```math
% P = P_\mathrm{load}\, f_P(|V|), \quad Q = Q_\mathrm{load}\, f_Q(|V|), \quad
% I = \overline{\left(\frac{P + jQ}{V}\right)}
% ```
% ```math
% f_P(v) = k_{PZ} v^2 + k_{PI}\, g_I(v) + k_{PP}\, g_P(v), \quad
% g_I(v) = \begin{cases} v & v \ge V_\mathrm{switchI} \\ v^2 / V_\mathrm{switchI} & v < V_\mathrm{switchI} \end{cases}, \quad
% g_P(v) = \begin{cases} 1 & v \ge V_\mathrm{switchP} \\ v^2 / V_\mathrm{switchP}^2 & v < V_\mathrm{switchP} \end{cases}
% ```
% and $f_Q$ the same with $k_{QZ}$, $k_{QI}$, $k_{QP}$.
%
% <@Citations>
% - 電気学会 電力系統モデル標準化調査専門委員会, 「電力系統の標準モデル」,
%   電気学会技術報告 第754号, 1999.
% - 電気学会 電力・エネルギー部門, 「電力系統の標準モデル」,
%   [https://www.iee.jp/pes/ele_systems/base_model](https://www.iee.jp/pes/ele_systems/base_model)
%   (accessed 2026-11-25).
%
% <@Examples>
% ```matlab
% net = PowerNetwork();
% bus = net.add_bus();
% ld  = bus.add_component("load-ZIP", "P", -0.8, "Q", -0.3);
% ld.s_tag                          % "B001LZIP1"
% ld.tab_parameter.dynamics         % kPI = 1, kQZ = 1, VswitchP = VswitchI = 0.7
% ld2 = bus.add_component("load-ZIP", "P", -0.5, "Q", -0.1, ...
%           "parameter", struct("kPZ", 0.3, "kPI", 0.3, "kPP", 0.4));
% ```
%
% See also component.load.abstract, component.load.power, component.load.impedance, Bus.add_component

    properties(Constant) % Model definition
        key = "load-ZIP";        % Model key that selects this class in `Bus.add_component`.
        sv_x = [];               % State names (none).
        sv_u = ["Pload";"Qload"];  % Input port names.
        sv_y = [];               % Output names (none).
        sv_para = ["kPZ";"kPI";"kPP";"kQZ";"kQI";"kQP";"VswitchP";"VswitchI"];  % Dynamic parameter names.
    end

    methods(Access={?Bus})
        function obj = ZIP(index, parameter, varargin)
            % Create the load and read its dynamic parameters; called through `Bus.add_component`.
            %
            % `index` is the tag suffix (the tag is the bus tag + `"LZIP"+index`),
            % `parameter` sets the coefficients and thresholds (see the class description;
            % NaN: all defaults), and `varargin` holds the name-value options of `add_component`.
            arguments (Input)
                index      % Number of the tag.
                parameter  % Dynamic parameters: a one-row table or a scalar struct with some of the names in sv_para, or NaN for the defaults.
            end
            arguments (Input, Repeating)
                varargin  % Options of Bus.add_component, passed on to Component.
            end
            arguments (Output)
                obj  % ZIP load object.
            end
            obj@component.load.abstract("ZIP"+index, varargin{:})

            sct_para = struct("kPZ", 0, "kPI", 1, "kPP", 0, "kQZ", 1, "kQI", 0, "kQP", 0, ...
                              "VswitchP", 0.7, "VswitchI", 0.7);
            if istable(parameter)
                if height(parameter) ~= 1
                    error(msg("GUILDA:Component:ZIPParameterValue", char(obj.s_tag), ...
                              "the parameter table must have one row, not " + height(parameter)))
                end
                parameter = table2struct(parameter);
            end
            if isstruct(parameter)
                if ~isscalar(parameter)
                    error(msg("GUILDA:Component:ZIPParameterValue", char(obj.s_tag), "the parameter struct must be scalar"))
                end
                sv_name = setdiff(string(fieldnames(parameter)), "ParameterID", "stable");
                sv_bad  = setdiff(sv_name, obj.sv_para, "stable");
                if ~isempty(sv_bad)
                    error(msg("GUILDA:Component:UnknownParameter", char(strjoin(sv_bad(:)', ", ")), ...
                              char(obj.s_tag), char(strjoin(obj.sv_para', ", "))))
                end
                for s_name = sv_name'
                    r_val = parameter.(s_name);
                    if ~(isnumeric(r_val) && isscalar(r_val) && isreal(r_val))
                        error(msg("GUILDA:Component:ZIPParameterValue", char(obj.s_tag), s_name + " must be a real number"))
                    end
                    if ~isnan(r_val)
                        sct_para.(s_name) = double(r_val);
                    end
                end
            elseif ~(isnumeric(parameter) && isscalar(parameter) && isnan(parameter))
                error(msg("GUILDA:Component:ZIPParameterValue", char(obj.s_tag), ...
                          "the parameter argument must be a table, a struct or NaN"))
            end

            obj.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", obj.a_Parameter)} = ...
                Parameter(obj, "dynamics", sct_para, @check_zip);
        end
    end

    methods
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, c_V, c_I, r_P, r_Q);
        PQ = getCompPQ(obj, x, V, u, param);
        sct_hessian = get_hessian(obj, x, V, u)
    end

    methods
        dx = fcn_dx(obj, t, x, V, u, param, omega0);
        I  = fcn_I(obj, t, x, V, u, param, omega0);
        y  = fcn_Y(obj, t, x, V, param, omega0);
        M  = fcn_Mass(obj, t, x, V, u, param, omega0);
    end

    methods (Static)
        [Axx,Bxv,Bxu] = Jacobi_dx(t,x,V,u,param,omega0);
        [Cyx,Dyv] = Jacobi_Y(t,x,V,param,omega0);
        [Cix,Div,Diu] = Jacobi_I(t,x,V,u,param,omega0);
    end
end


function check_zip(tab, s_owner)
% Check the dynamics of a ZIP load before they are stored (Parameter.f_validate).
    for s_name = ["kPZ","kPI","kPP","kQZ","kQI","kQP"]
        if ~all(isfinite(tab.(s_name)))
            error(msg("GUILDA:Component:ZIPParameterValue", char(s_owner), s_name + " must be finite"))
        end
    end
    for s_name = ["VswitchP","VswitchI"]
        r_val = tab.(s_name);
        if ~all(r_val > 0 & r_val < inf)
            error(msg("GUILDA:Component:ZIPParameterValue", char(s_owner), s_name + " must be in (0, Inf)"))
        end
    end
    r_sumP = tab.kPZ + tab.kPI + tab.kPP;
    r_sumQ = tab.kQZ + tab.kQI + tab.kQP;
    if any(abs([r_sumP; r_sumQ] - 1) > 1e-9)
        show_msg("warning", "GUILDA:Component:ZIPCoefficientSum", char(s_owner), ...
                 char(string(r_sumP(1))), char(string(r_sumQ(1))))
    end
end

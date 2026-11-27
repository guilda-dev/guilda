function tab = disp_io(obj, x, V, u)
% List the inputs and outputs of the model functions of the controller at a point.
%
% One row per variable: the arguments x, V, u and param of the model functions and the
% values they return, dx (fcn_dx) and y (fcn_y), evaluated at the equilibrium (default)
% or at the given x, V, u (an omitted one is the equilibrium), through the handles f_dx and
% f_Y (built by set_odefcn, which this method brings up to date). V is the voltage of the
% bus of the observed component. The values inside the functions are not shown. Unit
% and Description come from the help of the class (tools.read_model_help); "" where the
% help does not list the name. Source says where each input u is read in the network
% (the connection map of PowerNetwork.get_variable_map): an output or a state of the
% observed component, the output of a nested controller, the outputs of global
% controllers that add to it, or the equilibrium. At the equilibrium, dx is the residual
% that `validate` reports. Before net.initialize, the values at the equilibrium (and dx,
% y) are NaN and the functions are not called.
%
% Without an output, prints the table with a [doc] link to the class; with an output,
% returns it and prints nothing.
%
% <@Examples>
% ```matlab
% net = network.Tutorial10bus();
% net.initialize();
% avr = net.a_Bus{1}.a_Component{1}.a_LocalController{1};
% avr.disp_io()                               % at the equilibrium
% tab = avr.disp_io();
% tab(tab.Kind == "u", ["Name","Value","Source"])
% ```
%
% See also GUILDA.disp_equations, Component.disp_io, PowerNetwork.get_variable_map
%
% <@Group> Queries and checks
    arguments (Input)
        obj
        x (:,1) double = obj.rv_Xequilibrium  % States (numel(sv_x)); default: the equilibrium.
        V (:,1) double = obj.c_Vequilibrium   % Bus voltage of the observed component [pu]: complex scalar or [Vre; Vim]; default: the equilibrium.
        u (:,1) double = obj.rv_Uequilibrium  % Inputs (numel(sv_u)); default: the equilibrium.
    end
    arguments (Output)
        tab  % Table, one row per variable: Kind (x, V, u, para, dx, y), Name, Value, Unit, Description, Source.
    end
    sv_x = reshape(string(obj.sv_x), [], 1);
    sv_u = reshape(string(obj.sv_u), [], 1);
    sv_y = reshape(string(obj.sv_y), [], 1);
    sv_p = reshape(string(obj.sv_para), [], 1);
    if isscalar(V)
        V = [real(V); imag(V)];
    end
    % the equilibrium before net.initialize: NaN of the sizes of the model
    l_nan = nargin == 1 && (~isempty(obj.sct_stale.equilibrium) || numel(V) ~= 2);
    if l_nan
        x = nan(numel(sv_x),1);
        V = nan(2,1);
        u = nan(numel(sv_u),1);
    end
    validateattributes(x, "double", {"numel", numel(sv_x)}, "disp_io", "x", 2)
    validateattributes(V, "double", {"numel", 2}, "disp_io", "V", 3)
    validateattributes(u, "double", {"numel", numel(sv_u)}, "disp_io", "u", 4)

    % the model functions with the parameters bound as the controller binds them (set_odefcn:
    % a subclass may bind other values, e.g. the gain of local_LQR); up to date after this call
    param = obj.tab_parameter.dynamics{:, sv_p};
    dx = nan(numel(sv_x),1);
    y  = nan(numel(sv_y),1);
    if ~l_nan
        obj.set_odefcn();
        dx = reshape(obj.f_dx(0, x, V, u), [], 1);
        y  = reshape(obj.f_Y(0, x, V, u), [], 1);
    end
    if isempty(sv_y)
        y = zeros(0,1);
    end

    % names, units and descriptions of the help
    tv = tools.read_model_help(class(obj)).Variables;
    sv_dx = "d" + sv_x + "/dt";
    sm = [repmat("x",numel(sv_x),1), sv_x; "V","Vre"; "V","Vim"; repmat("u",numel(sv_u),1), sv_u; ...
          repmat("para",numel(sv_p),1), sv_p; repmat("dx",numel(sv_x),1), sv_dx; ...
          repmat("y",numel(sv_y),1), sv_y];
    rv = [x; V; u; reshape(double(param), [], 1); dx; y];
    n = size(sm,1);
    sv_unit = strings(n,1);
    sv_desc = strings(n,1);
    sv_src  = strings(n,1);
    for k = 1:n
        if sm(k,1) == "dx"
            sv_desc(k) = "Time derivative of " + sv_x(find(sv_dx == sm(k,2), 1)) + "; for an algebraic state, the residual of its equation.";
            continue
        end
        i = find(tv.Kind == sm(k,1) & tv.Name == sm(k,2), 1);
        if ~isempty(i)
            sv_unit(k) = tv.Unit(i);
            sv_desc(k) = tv.Description(i);
        end
    end
    sv_unit(sm(:,1) == "V") = "pu";
    sv_desc(sm(:,1) == "V") = ["Real part", "Imaginary part"] + " of the voltage of the bus of the observed component.";

    % sources of the inputs: the connections into them in the map of the network
    net = obj.observed_component().a_Bus.a_PowerNetwork;
    if ~isempty(net)
        [tm, ~, ~, tc] = net.get_variable_map();
        iv_u = find(tm.Kind == "uc" & tm.Owner == string(obj.s_tag));
        lv_u = find(sm(:,1) == "u");
        for k = 1:numel(iv_u)
            tck = tc(tc.TargetIndex == iv_u(k) & tc.Kind ~= "equilibrium", :);
            iv_s = tck.SourceIndex;
            sv_what = repmat("output ", numel(iv_s), 1);
            sv_what(tm.Kind(iv_s) == "x") = "state ";
            sv = sv_what + tm.Name(iv_s) + " of " + tm.Owner(iv_s) + " [" + tck.Kind + "]";
            if isempty(sv)
                sv = "equilibrium (not connected)";
            elseif ~any(ismember(tck.Kind, ["local","observe"]))   % the input keeps its equilibrium; global outputs add to it
                sv = ["equilibrium"; sv]; %#ok<AGROW>
            end
            sv_src(lv_u(k)) = join(sv, " + ");
        end
    end

    tab_out = table(sm(:,1), sm(:,2), rv, sv_unit, sv_desc, sv_src, ...
        'VariableNames', ["Kind","Name","Value","Unit","Description","Source"]);
    if nargout > 0
        tab = tab_out;
        return
    end
    fprintf('Inputs and outputs of %s  <a href="matlab:GUILDA.doc(''class'', ''%s'')">[doc]</a>  %s\n', ...
        obj.s_tag, class(obj), class(obj))
    disp(tab_out)
end

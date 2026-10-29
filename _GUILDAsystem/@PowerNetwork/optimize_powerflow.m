function varargout = optimize_powerflow(obj, varargin)
% <@Desc>
% Calculates the optimal power flow of the network: the operating point that minimizes
% the generation cost (tab_parameter.OPF of the components) under the constraints in
% tab_parameter.operation of the buses, components and branches. The settings are the
% stored defaults of net.solver_OPF; Name-Value options override them for this call only
% (net.solver_OPF is not changed). The network is not changed.
% The cost of each component is HP*P^2 + fP*P + HQ*Q^2 + fQ*Q (tab_parameter.OPF; Q terms
% in "AC OPF" only). Loads keep the P and Q of tab_parameter.powerflow, so their cost is
% a constant in the optimal cost. The columns startup and shutdown of tab_parameter.OPF
% are reserved: unit commitment is not part of the problem. "DC OPF" uses |V| = 1 and
% the branch susceptance b_ij = Im(Y_ij) of the branch admittance matrix (= 1/X when
% R = 0). The angle of the slack bus (the first bus if none is set) is fixed. The solver
% starts from tab_parameter.powerflow V0 and Varg0 of the buses and P0, Q0 of the
% components; branch current and power limits are applied as |I|^2 <= Imax^2 and
% P^2 + Q^2 <= Smax^2 at both ends.
% Accepted options are the names in OptimalPowerFlow.OptionMap plus Plot and Export;
% any other name stops with GUILDA:resolve_options:UnknownName.
% <@Role> Analysis
% <@Summary> Calculate the optimal power flow; returns an OPFResult.
% <@Signatures>
% [
%   "result = net.optimize_powerflow()",
%   "[result, flag, output] = net.optimize_powerflow(Name, Value)"
% ]
% <@Parameters>
% [
%   {"Name": "Method", "Type": "\"ELD\" | \"DC OPF\" | \"AC OPF\"", "Description": "Formulation: economic load dispatch (branches ignored), DC approximation or AC power flow equations (net.solver_OPF.Method).", "Required": false, "Default": "net.solver_OPF.Method"},
%   {"Name": "Solver", "Type": "\"auto\" | \"linprog\" | \"quadprog\" | \"fmincon\"", "Description": "Optimization solver; \"auto\" lets solve choose (net.solver_OPF.Solver).", "Required": false, "Default": "net.solver_OPF.Solver"},
%   {"Name": "Tolerance", "Type": "positive double scalar", "Description": "OptimalityTolerance of the solver (net.solver_OPF.OptimalityTolerance; NaN = solver default).", "Required": false, "Default": "net.solver_OPF.OptimalityTolerance"},
%   {"Name": "MaxIteration", "Type": "positive integer scalar", "Description": "MaxIterations of the solver (net.solver_OPF.MaxIteration; NaN = solver default).", "Required": false, "Default": "net.solver_OPF.MaxIteration"},
%   {"Name": "Verbose", "Type": "logical scalar", "Description": "Print solver progress (sets Display to \"iter\" or \"none\").", "Required": false, "Default": "net.solver_OPF.Display"},
%   {"Name": "Plot", "Type": "logical scalar", "Description": "Call result.Plot after the calculation.", "Required": false, "Default": "false"},
%   {"Name": "Export", "Type": "logical scalar or string scalar", "Description": "Call result.Export after the calculation: true for the default file name, or the file name.", "Required": false, "Default": "false"}
% ]
% <@Returns>
% [
%   {"Name": "result", "Type": "OPFResult", "Description": "Bus values, connection injections, branch flows, cost and Lagrange multipliers of the solution."},
%   {"Name": "flag", "Type": "optim.problemdef.ExitFlag", "Description": "exitflag of solve (positive = solved)."},
%   {"Name": "output", "Type": "struct", "Description": "Solver details; output.message describes the outcome."}
% ]
% <@Examples>
% [
%   "```matlab\n[res, flag] = net.optimize_powerflow();            % AC OPF (net.solver_OPF.Method)\nres.tab_bus                                         % Varg, V, P, Q, Vphasor, Iphasor of each bus\nres.r_cost                                          % optimal cost\nres = net.optimize_powerflow(Method=\"ELD\", Verbose=false, Plot=true);\n```"
% ]

    varargin = v3_opf_args(varargin);                         % COMPAT(v3)
    [c_nv, opt] = take_call_options(varargin);
    s_options   = obj.solver_OPF.get_options(c_nv);

    [result, flag, output] = obj.solver_OPF.solve(obj, s_options);

    if opt.Plot
        result.Plot();
    end
    if isstring(opt.Export)
        result.Export(opt.Export);
    elseif opt.Export
        result.Export();
    end

    varargout = {result, flag, output};
    varargout = legacy_output(varargout, nargout, 6, @v3_optimize_powerflow, "OptimizePowerflowTuple"); % COMPAT(v3)
end


function [c_nv, opt] = take_call_options(c_in)
% Separates the options of this call (Plot, Export) from the solver options
    c_nv = c_in;
    opt  = call_options();
    if mod(numel(c_in), 2) ~= 0
        return              % not Name-Value pairs: tools.resolve_options reports it
    end
    lv_call = false(size(c_in));
    for k = 1:2:numel(c_in)
        lv_call(k:k+1) = (ischar(c_in{k}) || isstring(c_in{k})) && any(strcmpi(c_in{k}, ["Plot","Export"]));
    end
    c_call = c_in(lv_call);
    c_nv   = c_in(~lv_call);
    opt    = call_options(c_call{:});
end

function opt = call_options(opt)
    arguments
        opt.Plot   (1,1) logical = false
        opt.Export {mustBeA(opt.Export, ["logical","string","char"])} = false
    end
    if ischar(opt.Export)
        opt.Export = string(opt.Export);
    end
    mustBeScalarOrEmpty(opt.Export);
end

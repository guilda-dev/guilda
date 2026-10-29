function [result, flag, output] = calculate_powerflow(obj, varargin)
% <@Desc>
% Calculates the power flow of the network. The settings are the stored defaults of
% net.solver_PF; Name-Value options override them for this call only (net.solver_PF is
% not changed). The network is not changed either, except that the first bus is made the
% slack bus when none is set (with an INFO message).
% Accepted options are the names in PowerFlowCalculation.OptionMap plus Plot and Export;
% any other name stops with GUILDA:resolve_options:UnknownName.
% <@Role> Analysis
% <@Summary> Calculate the power flow; returns a PowerFlowResult.
% <@Signatures>
% [
%   "result = net.calculate_powerflow()",
%   "[result, flag, output] = net.calculate_powerflow(Name, Value)"
% ]
% <@Parameters>
% [
%   {"Name": "Method", "Type": "\"algebraic\" | \"dynamic\"", "Description": "Calculation method (net.solver_PF.Method).", "Required": false, "Default": "net.solver_PF.Method"},
%   {"Name": "Tolerance", "Type": "double scalar", "Description": "Convergence tolerance; 0 for the solver default (net.solver_PF.Tolerance).", "Required": false, "Default": "net.solver_PF.Tolerance"},
%   {"Name": "MaxIteration", "Type": "integer scalar", "Description": "Maximum number of fsolve iterations; 0 for the fsolve default (net.solver_PF.MaxIterations).", "Required": false, "Default": "net.solver_PF.MaxIterations"},
%   {"Name": "Verbose", "Type": "logical scalar", "Description": "Print fsolve progress (sets Display to \"iter\" or \"none\").", "Required": false, "Default": "net.solver_PF.Display ~= \"none\""},
%   {"Name": "Plot", "Type": "logical scalar", "Description": "Call result.Plot after the calculation.", "Required": false, "Default": "false"},
%   {"Name": "Export", "Type": "logical scalar or string scalar", "Description": "Call result.Export after the calculation: true for the default file name, or the file name.", "Required": false, "Default": "false"}
% ]
% <@Returns>
% [
%   {"Name": "result", "Type": "PowerFlowResult", "Description": "Bus voltages, injections and branch flows of the solution."},
%   {"Name": "flag", "Type": "double or logical", "Description": "exitflag of fsolve (\"algebraic\", positive = converged) or convergence (\"dynamic\")."},
%   {"Name": "output", "Type": "struct", "Description": "Solver details; output.message describes the outcome."}
% ]
% <@Examples>
% [
%   "```matlab\n[res, flag] = net.calculate_powerflow();\nres.tab_bus            % Varg, V, P, Q, Vphasor, Iphasor of each bus\nres = net.calculate_powerflow(Method=\"dynamic\", Tolerance=1e-8, Plot=true);\n```"
% ]

    [c_nv, opt] = take_call_options(varargin);
    s_options   = obj.solver_PF.get_options(c_nv);

    lv_isSlack = tools.vcellfun(@(b) b.l_isSlack, obj.a_Bus);
    if ~any(lv_isSlack)
        try
            disp("INFO: Slack bus not found. Setting the first bus '"+string(obj.a_Bus{1})+"' as the slack bus.")
            obj.a_Bus{1}.l_isSlack = true;
        catch
            error("ERROR: Failed to set BUS001 as the slack bus."+newline+...
                  "       Please designate one Bus class as the slack bus from those that have at least one connected Component class."+newline+...
                  "       To specify the slack bus, set the 'l_isSlack' property of the designated Bus class to true.")
        end
    end

    [result, flag, output] = obj.solver_PF.solve(obj, s_options);

    if opt.Plot
        result.Plot();
    end
    if isstring(opt.Export)
        result.Export(opt.Export);
    elseif opt.Export
        result.Export();
    end
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

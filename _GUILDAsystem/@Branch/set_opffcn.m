function set_opffcn(obj, varargin)
% <@Desc>
% Sets user terms of the optimal power flow (net.optimize_powerflow) for this branch.
% Each term is a function handle @(v, p): v holds the optimization variables at the two
% ends of the branch (from = a_Bus{1}, to = a_Bus{2}) and p its parameters (p.Method,
% p.operation, p.dynamics as structs, e.g. p.dynamics.X, p.operation.Pmax).
%   "DC OPF" and "AC OPF": v.Pfrom, v.Pto (power flowing into the branch, as in
%     result.tab_branch), v.Vargfrom, v.Vargto (angles of the end buses)
%   "AC OPF" only: v.Qfrom, v.Qto, v.Ifrom_re, v.Ifrom_im, v.Ito_re, v.Ito_im (current
%     into the branch), v.Vfrom, v.Vto (voltage magnitudes of the end buses)
% "ELD" ignores branches, so the branch terms are not used there.
% Cost: fcnCost(v, p) returns a scalar expression that REPLACES the default cost of the
% branch (none), i.e. it is added to the objective.
% Constraint: fcnCon(v, p) returns a struct of named constraints that are ADDED to the
% defaults; field <name> becomes prob.Constraints.<name>_<branch tag>, which is also the
% label of its dual in result.lambda.Constraints.
% DefaultConstraint=false removes the default constraints of the branch: the limits
% Pmax, Vargmax, Imax and Smax. The branch flow equations are always kept.
% Given names replace the stored ones, the others are kept; Cost=[] or Constraint=[]
% clears that term. reset_opffcn restores all defaults. The edit is logged in
% tab_editLog and does not make the equilibrium stale.
% <@Role> Settings
% <@Summary> Set the OPF cost and constraints of the branch.
% <@Signatures>
% [
%   "obj.set_opffcn(\"Cost\", fcnCost)",
%   "obj.set_opffcn(\"Constraint\", fcnCon)",
%   "obj.set_opffcn(\"Cost\", fcnCost, \"Constraint\", fcnCon, \"DefaultConstraint\", false)"
% ]
% <@Parameters>
% [
%   {"Name": "Cost", "Type": "function_handle @(v, p) or []", "Description": "Cost of the branch; added to the objective.", "Required": false, "Default": "[] (none)"},
%   {"Name": "Constraint", "Type": "function_handle @(v, p) or []", "Description": "Returns struct(name1, constraint1, ...); added to the default constraints.", "Required": false, "Default": "[] (none)"},
%   {"Name": "DefaultConstraint", "Type": "logical scalar", "Description": "false removes the default limits Pmax, Vargmax, Imax and Smax.", "Required": false, "Default": "true"}
% ]
% <@Returns>
% []
% <@Examples>
% [
%   "```matlab\n% One-directional limit: at most 0.5 p.u. from a_Bus{1} to a_Bus{2} (dual: lambda.Constraints.Pfwd_<tag>)\nbr = net.a_Branch{1};\nbr.set_opffcn(\"Constraint\", @(v, p) struct(\"Pfwd\", v.Pfrom <= 0.5));\nres = net.optimize_powerflow(Method=\"DC OPF\");\nbr.reset_opffcn();\n```"
% ]
    [obj.s_opffcn, str_log] = opffcn.update(obj.s_opffcn, varargin{:});
    obj.log_edit(str_log, "OPF");
end

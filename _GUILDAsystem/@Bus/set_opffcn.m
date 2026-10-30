function set_opffcn(obj, varargin)
% Set the OPF cost and constraints of the bus.
%
% Sets user terms of the optimal power flow (net.optimize_powerflow) for this bus.
% Each term is a function handle @(v, p): v holds the optimization variables of the bus
% (v.Varg in "DC OPF" and "AC OPF"; v.V in "AC OPF" only) and p its parameters
% (p.Method, p.operation, p.powerflow, p.dynamics as structs, e.g. p.operation.Vmax).
% "ELD" has no bus variables, so the bus terms are not used there.
% Cost: fcnCost(v, p) returns a scalar expression that REPLACES the default cost of the
% bus (none), i.e. it is added to the objective.
% Constraint: fcnCon(v, p) returns a struct of named constraints that are ADDED to the
% defaults; field <name> becomes prob.Constraints.<name>_<bus tag>, which is also the
% label of its dual in result.lambda.Constraints.
% DefaultConstraint=false removes the default constraints of the bus: the voltage
% bounds Vmin/Vmax. The power balance of the bus is always kept.
% Given names replace the stored ones, the others are kept; Cost=[] or Constraint=[]
% clears that term. reset_opffcn restores all defaults. The edit is logged in
% tab_editLog and does not make the equilibrium stale.
%
% Name-Value options:
%
% - `Cost` — Cost of the bus; added to the objective. Default: [] (none).
% - `Constraint` — Returns struct(name1, constraint1, ...); added to the default constraints. Default: [] (none).
% - `DefaultConstraint` — false removes the default voltage bounds Vmin/Vmax. Default: true.
%
% <@Examples>
% ```matlab
% % Voltage band 0.98-1.02 on one bus (AC OPF; duals: lambda.Constraints.Vhigh_B005, Vlow_B005)
% bus = net.a_Bus{5};
% bus.set_opffcn("Constraint", @(v, p) struct("Vhigh", v.V <= 1.02, "Vlow", v.V >= 0.98));
% res = net.optimize_powerflow(Method="AC OPF");
% bus.reset_opffcn();
% ```
%
% See also Bus.reset_opffcn, PowerNetwork.set_opffcn
    [obj.s_opffcn, str_log] = opffcn.update(obj.s_opffcn, varargin{:});
    obj.log_edit(str_log, "OPF");
end

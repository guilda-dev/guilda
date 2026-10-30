function set_opffcn(obj, varargin)
% Set the OPF cost and constraints of the component.
%
% Sets user terms of the optimal power flow (net.optimize_powerflow) for this component.
% Each term is a function handle @(v, p): v holds the optimization variables of the
% component (v.P; v.Q in "AC OPF" only) and p its parameters (p.Method, p.OPF, p.operation,
% p.powerflow, p.dynamics as structs, e.g. p.OPF.HP, p.operation.Pmax).
% Cost: fcnCost(v, p) returns a scalar expression that REPLACES the default cost
% HP*P^2 + fP*P (+ HQ*Q^2 + fQ*Q in "AC OPF") of the component.
% Constraint: fcnCon(v, p) returns a struct of named constraints that are ADDED to the
% defaults; field <name> becomes prob.Constraints.<name>_<component tag>, which is also
% the label of its dual in result.lambda.Constraints.
% DefaultConstraint=false removes the default constraints of the component: the bounds
% Pmin/Pmax/Qmin/Qmax and, for a load, fixing P and Q to tab_parameter.powerflow. The
% component's injection into the bus power balance is always kept.
% Given names replace the stored ones, the others are kept; Cost=[] or Constraint=[]
% clears that term. reset_opffcn restores all defaults. Terms that need variables of
% other objects go through net.set_opffcn. The edit is logged in tab_editLog and does
% not make the equilibrium stale.
%
% Name-Value options:
%
% - `Cost` — Cost of the component; replaces the default cost. Default: [] (default cost).
% - `Constraint` — Returns struct(name1, constraint1, ...); added to the default constraints. Default: [] (none).
% - `DefaultConstraint` — false removes the default bounds of P and Q. Default: true.
%
% <@Examples>
% ```matlab
% % CO2 cost on one generator: fuel cost + 30 per t-CO2 at 0.8 t per p.u. output
% gen = net.a_Bus{1}.a_Component{1};
% gen.set_opffcn("Cost", @(v, p) p.OPF.HP*v.P^2 + p.OPF.fP*v.P + 30*0.8*v.P);
% % Ramp-down limit from the current output: P >= P0 - 0.2 (dual: lambda.Constraints.Ramp_<tag>)
% gen.set_opffcn("Constraint", @(v, p) struct("Ramp", v.P >= p.OPF.P0 - 0.2));
% res = net.optimize_powerflow(Method="DC OPF");
% gen.reset_opffcn();                                  % back to the defaults
% ```
%
% See also Component.reset_opffcn, PowerNetwork.set_opffcn
    [obj.s_opffcn, str_log] = opffcn.update(obj.s_opffcn, varargin{:});
    obj.log_edit(str_log, "OPF");
end

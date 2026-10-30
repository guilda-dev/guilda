function set_opffcn(obj, varargin)
% Set network-wide OPF cost and constraints over several objects.
%
% Sets network-wide user terms of the optimal power flow (net.optimize_powerflow): terms
% that need variables of several objects, such as a reserve requirement over several
% generators. Each term is a function handle @(v, p). v holds the variables of every
% object, addressed by tag, with the same fields as the handles of that object receive:
%   v.Component.(tag).P, v.Component.(tag).Q ("AC OPF")
%   v.Bus.(tag).Varg, v.Bus.(tag).V ("AC OPF"); no fields in "ELD"
%   v.Branch.(tag).Pfrom, .Pto, .Vargfrom, .Vargto, ... (see Branch.set_opffcn); no fields in "ELD"
% p holds p.Method and p.base (baseMVA, Hz). Parameters of other objects are read from
% the objects themselves when the handle is written (e.g. gen.para_operation.Pmax).
% Cost: fcnCost(v, p) returns a scalar expression that is added to the objective (the
% network itself has no default cost).
% Constraint: fcnCon(v, p) returns a struct of named constraints that are ADDED to the
% problem; field <name> becomes prob.Constraints.<name>, which is also the label of its
% dual in result.lambda.Constraints.
% DefaultConstraint=false removes the default constraint of the network: the fixed angle
% of the reference (slack) bus. The power balance of every bus is always kept.
% Given names replace the stored ones, the others are kept; Cost=[] or Constraint=[]
% clears that term. reset_opffcn restores all defaults. Per-object terms are set with
% set_opffcn of the Component, Bus or Branch. The edit is logged in tab_editLog and
% does not make the equilibrium stale.
%
% Name-Value options:
%
% - `Cost` — Network-wide cost; added to the objective. Default: [] (none).
% - `Constraint` — Returns struct(name1, constraint1, ...); added to the problem. Default: [] (none).
% - `DefaultConstraint` — false removes the fixed angle of the reference bus. Default: true.
%
% <@Examples>
% ```matlab
% % Spinning reserve: the headroom Pmax - P of two generators is at least 0.5 p.u.
% g1 = net.a_Bus{1}.a_Component{1};  g2 = net.a_Bus{2}.a_Component{1};
% Pmax1 = g1.para_operation.Pmax;   Pmax2 = g2.para_operation.Pmax;
% net.set_opffcn("Constraint", @(v, p) struct("Reserve", ...
%     (Pmax1 - v.Component.(string(g1)).P) + (Pmax2 - v.Component.(string(g2)).P) >= 0.5));
% res = net.optimize_powerflow(Method="DC OPF");
% res.lambda.Constraints.Reserve                      % price of the reserve requirement
% net.reset_opffcn();
% ```
%
% See also PowerNetwork.reset_opffcn, Component.set_opffcn, Bus.set_opffcn, Branch.set_opffcn
    [obj.s_opffcn, str_log] = opffcn.update(obj.s_opffcn, varargin{:});
    obj.log_edit(str_log, "OPF");
end

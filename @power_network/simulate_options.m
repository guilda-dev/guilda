function options = simulate_options(obj, varargin)

p = inputParser;
p.CaseSensitive = false;
addParameter(p, 'linear', false);
addParameter(p, 'fault', {});
addParameter(p, 'x0_sys', obj.x_equilibrium);
addParameter(p, 'V0', obj.V_equilibrium);
addParameter(p, 'I0', obj.I_equilibrium);
x0_con_local = tools.vcellfun(@(c) c.get_x0(), obj.a_controller_local);
addParameter(p, 'x0_con_local', x0_con_local);
x0_con_global = tools.vcellfun(@(c) c.get_x0(), obj.a_controller_global);
addParameter(p, 'x0_con_global', x0_con_global);
addParameter(p, 'method', 'zoh', @(method) ismember(method, {'zoh', 'foh'}));
addParameter(p, 'AbsTol', 1e-8);
addParameter(p, 'RelTol', 1e-8);
addParameter(p, 'do_report', true);
addParameter(p, 'reset_time', inf);
addParameter(p, 'do_retry', true);
addParameter(p, 'OutputFcn', []);

parse(p, varargin{:});
options = p.Results;
end
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
addParameter(p, 'tools', false);
addParameter(p, 'with_grid_code', true);

parse(p, varargin{:});
options = p.Results;

% 機器の接続状況を確認する
idx_connected_comp = tools.vcellfun(@(b) b.component.is_connected_to_grid,obj.a_bus);
idx_connected_br = tools.vcellfun(@(br) br.is_connected,obj.a_branch);

if any(~idx_connected_comp)
    disp('Some component is disconnected from grid.')
    fprintf('Connect all devices to the grid?')
    get_start = false;
    while get_start==false
        yes_or_no = input('(y/n):','s');
        switch yes_or_no
            case {'y','yes'}
                cellfun(@(b) b.component.connect,obj.a_bus);
                get_start =true;
            case {'n', 'no'}
                get_start =true;
        end
    end
end

if any(~idx_connected_br)
    disp('Some branch is disconnected.')
    fprintf('Connect all branch?')
    get_start = false;
    while get_start==false
        yes_or_no = input('(y/n):','s');
        switch yes_or_no
            case {'y','yes'}
                cellfun(@(br) br.branch.connect,obj.a_branch);
                get_start =true;
            case {'n', 'no'}
                get_start =true;
        end
    end
end

end
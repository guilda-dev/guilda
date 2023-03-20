classdef power_network < handle
    
    properties(Dependent)
        x_equilibrium
        V_equilibrium
        I_equilibrium
    end
    
    properties(SetAccess = protected)
        a_bus = {}
        a_controller_global = {}
        a_controller_local = {}
        a_branch = {}
    end
    
    methods(Static)
        varargout = get_dx(varargin);
        sys = get_sys_controllers(varargin);
    end
    
    methods
        out = simulate(obj, t, u, index_u, varargin);
        options = simulate_options(obj, varargin);
        func = get_func_dx(obj, t, u, u_idx, fault, options);
        [Y, Ymat, A, Amat] = reduce_admittance_matrix(obj, Y, index);
        data = information(obj, varargin);

        function initialize(obj)
            [V, I] = obj.calculate_power_flow();
            obj.set_equilibrium(V, I);
        end
        
        function x = get.x_equilibrium(obj)
            x = tools_vcellfun(@(b) b.component.x_equilibrium, obj.a_bus);
        end

        function x = get.V_equilibrium(obj)
            x = tools_vcellfun(@(b) b.V_equilibrium, obj.a_bus);
        end
        
        function x = get.I_equilibrium(obj)
            x = tools_vcellfun(@(b) b.I_equilibrium, obj.a_bus);
        end
        
        function add_controller_local(obj, controller)
            obj.remove_controller_local(controller.index_all);
            obj.a_controller_local{numel(obj.a_controller_local)+1} = controller;
        end
        
        function add_controller_global(obj, controller)
            obj.a_controller_global{numel(obj.a_controller_global)+1} = controller;
        end
        
        function remove_controller_local(obj, idx)
            remove_idx = [];
            for itr = 1:numel(obj.a_controller_local)
                if ~isempty(intersect(obj.a_controller_local{itr}.index_all, idx))
                    remove_idx = [remove_idx; itr]; %#ok
                end
            end
            obj.a_controller_local(remove_idx) = [];
        end
        
        function remove_controller_global(obj, idx)
            remove_idx = [];
            for itr = 1:numel(obj.a_controller_global)
                if ~isempty(intersect(obj.a_controller_global{itr}.index_all, idx))
                    remove_idx = [remove_idx; itr]; %#ok
                end
            end
            obj.a_controller_local(remove_idx) = [];
        end
        
        function check_bus_edited(obj)
            edited = tools_hcellfun(@(bus) bus.edited, obj.a_bus);
            if any(edited)
                disp(['bus',mat2str(find(edited)),'の潮流設定が変更されています.'])
                sw = input('再度,潮流計算しますか？(y/n)：',"str");
                if strcmp(sw,'y')
                    obj.initialize();
                end
            end
        end
        
        function add_bus(obj, bus)
            if iscell(bus)
                if any(tools_vcellfun(@(b) ~isa(b, 'bus'), bus))
                   error('must be a child of bus');
                end
                obj.a_bus = [obj.a_bus; bus];
            else
                if isa(bus, 'bus')
                    obj.a_bus = [obj.a_bus; {bus}];
                else
                   error('must be a child of bus'); 
                end
            end
        end
        
        function add_branch(obj, branch)
            if iscell(branch)
                if any(tools_vcellfun(@(l) ~isa(l, 'branch'), branch))
                   error();
                end
                obj.a_branch = [obj.a_branch; branch];
            else
                if isa(branch, 'branch')
                    obj.a_branch = [obj.a_branch; {branch}];
                else
                   error(); 
                end
            end
        end
        
        function [V, I] = calculate_power_flow(obj, varargin)
            n = numel(obj.a_bus);
            x0_all = kron(ones(n, 1), [1; 0]);

            p = inputParser;
            p.CaseSensitive = false;
            p.addParameter('MaxFunEvals', 1e6);
            p.addParameter('MaxIterations', 2e4);
            p.addParameter('Display', 'none');
            p.addParameter('UseParallel', false);
            p.addOptional('return_vector', false);
            p.parse(varargin{:});

            options = optimoptions('fsolve', 'MaxFunEvals', p.Results.MaxFunEvals,...
                'MaxIterations', p.Results.MaxIterations, 'Display', p.Results.Display,...
                'UseParallel', p.Results.UseParallel);

            [Y, Ymat] = obj.get_admittance_matrix();
            V = fsolve(@(x) func_eq(obj.a_bus, Ymat, x), x0_all, options);
            I = Ymat*V;

            if ~p.Results.return_vector
                V = tools_vec2complex(V);
                I = tools_vec2complex(I);
            end
        end
        
        function set_equilibrium(obj, V, I)
            for i = 1:numel(obj.a_bus)
               obj.a_bus{i}.set_equilibrium(V(i), I(i)); 
            end
        end
    end
    
    methods(Access = private)
        function [Y, Ymat] = get_admittance_matrix(obj, a_idx_bus)
            if nargin < 2
                a_idx_bus = 1:numel(obj.a_bus);
            end

            n_bus = numel(obj.a_bus);
            Y = sparse(n_bus, n_bus);

            for i = 1:numel(obj.a_branch)
               br = obj.a_branch{i};
               if ismember(br.from, a_idx_bus) || ismember(br.to, a_idx_bus)
                   Y_branch = br.get_admittance_matrix();
                   Y([br.from, br.to], [br.from, br.to]) = Y([br.from, br.to], [br.from, br.to]) + Y_branch;
               end
            end

            shunt = tools_vcellfun(@(b) b.shunt, obj.a_bus(a_idx_bus));
            S = sparse(a_idx_bus, a_idx_bus, shunt, n_bus, n_bus);

            Y = Y + S;
            if nargout == 2
                Ymat = tools_complex2matrix(Y);
            end
       end
    end
end

function out = func_eq(bus, Ymat, x)
    n = numel(bus);
    Vmat = x;
    Vr = x(1:2:end);
    Vi = x(2:2:end);
    YV = Ymat*Vmat;
    YV_mat = cell(n, 1);
    for itr = 1:n
        YV_mat{itr} = sparse([YV(2*itr-1), YV(2*itr); -YV(2*itr), YV(2*itr-1)]);
    end
    YV_mat = blkdiag(YV_mat{:});
    PQhat = YV_mat*Vmat;
    Phat = PQhat(1:2:end);
    Qhat = PQhat(2:2:end);

    eq_consts = cell(n, 1);
    for itr = 1:numel(eq_consts)
        eq_consts{itr} = bus{itr}.get_constraint(Vr(itr), Vi(itr), Phat(itr), Qhat(itr));
    end
    out = vertcat(eq_consts{:});
end

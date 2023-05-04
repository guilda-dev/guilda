classdef power_network  < base_class.handleCopyable

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

    properties
        omega0
    end
    
    methods(Static)
        varargout = get_dx(varargin);
        sys = get_sys_controllers(varargin);
    end
    methods
        [V, I] = calculate_power_flow(obj, varargin);
        out = simulate(obj, t, u, index_u, varargin);
        options = simulate_options(obj, varargin);
        func = get_func_dx(obj, t, u, u_idx, fault, options);
        [Y, Ymat, A, Amat] = reduce_admittance_matrix(obj, Y, index);
        data = information(obj, varargin);
        [cost_total,cost_branch,cost_component] = get_cost_function(obj,varargin)
        controller_list(obj,fig)
        out = solve_odes2(obj, t, options)
        out = new_simulate(obj, t, varargin)

        options = simulate_options_refactoring(obj, t, u, uidx, varargin)
        out = simulate_refactoring(obj, t, varargin)

        function initialize(obj)
            [V, I] = obj.calculate_power_flow();
            obj.set_equilibrium(V, I);
        end

        function set_equilibrium(obj, V, I)
            for i = 1:numel(obj.a_bus)
               obj.a_bus{i}.set_equilibrium(V(i), I(i)); 
            end
        end
        
        function x = get.x_equilibrium(obj)
            x = tools.vcellfun(@(b) b.component.x_equilibrium, obj.a_bus);
        end

        function x = get.V_equilibrium(obj)
            x = tools.vcellfun(@(b) b.V_equilibrium, obj.a_bus);
        end
        
        function x = get.I_equilibrium(obj)
            x = tools.vcellfun(@(b) b.I_equilibrium, obj.a_bus);
        end
        

        % プロパティへのクラスの追加に関するメソッド
        function add_bus(obj, bus)
            if iscell(bus)
                if any(tools.vcellfun(@(b) ~isa(b, 'bus')&&~isa(b, 'base_class.bus'), bus))
                   error('must be a child of bus');
                end
                obj.a_bus = [obj.a_bus; bus];
            else
                if isa(bus, 'bus')||isa(bus, 'base_class.bus')
                    obj.a_bus = [obj.a_bus; {bus}];
                else
                   error('must be a child of bus'); 
                end
            end
        end

        function add_branch(obj, branch)
            if iscell(branch)
                if any(tools.vcellfun(@(l) ~isa(l, 'branch')&&~isa(l, 'base_class.branch'), branch))
                   error('must be a child of branch');
                end
                obj.a_branch = [obj.a_branch; branch];
            else
                if isa(branch, 'branch')||isa(branch, 'base_class.branch')
                    obj.a_branch = [obj.a_branch; {branch}];
                else
                   error('must be a child of branch');
                end
            end
        end

        function add_controller_local(obj, controller)
            controller.register_net(obj)
            %obj.remove_controller_local(controller.index_all);
            obj.a_controller_local{numel(obj.a_controller_local)+1} = controller;
        end
        
        function add_controller_global(obj, controller)
            controller.register_net(obj)
            obj.a_controller_global{numel(obj.a_controller_global)+1} = controller;
        end

        
        % 制御器の取り外しに関するメソッド
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
            edited = tools.hcellfun(@(bus) bus.edited, obj.a_bus);
            if any(edited)
                disp(['bus',mat2str(find(edited)),'の潮流設定が変更されています.'])
                sw = input('再度,潮流計算しますか？(y/n)：',"str");
                if strcmp(sw,'y')
                    obj.initialize();
                end
            end
        end

        function set.omega0(~,value)
            if ~isnumeric(value); error('omega0 must be numeric'); end
            set_omega0(value);
        end

    end
    methods(Access=protected)
        function set_omega0(value)
            cellfun(@(b) b.component.set_omega0(value), obj.a_bus);
        end
        function PropEditor_Set(obj,prop,val)
            obj.(prop) = val;
        end
        function val = PropEditor_Get(obj,prop)
            val = obj.(prop);
        end
    end
    
end


